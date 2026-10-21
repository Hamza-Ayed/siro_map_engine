import 'dart:async' show Timer, unawaited;
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:siro_gl/siro_gl.dart';

import '../../page.dart';
import '../../shared/shared.dart';
import 'bench_memory.dart';
import 'bench_stats.dart';

/// Fixed-scenario benchmark for the map.
///
/// Open the page to run it once: the timer starts in `initState`, the map loads
/// the Amman Ring Road route from `assets/bench/amman_route.geojson`, and the
/// camera then travels along it for two minutes, one step every 100 ms, with
/// tilt 60. When the run ends, the results appear as JSON and can be copied.
///
/// What is measured:
/// - time to first style load, first map idle and first camera idle, from
///   `initState`;
/// - Flutter frame timings (FPS, jank, build and raster time). These measure
///   the Flutter side only. Native GL frames need a native hook (PF-01);
/// - resident memory of the whole process, sampled once a second;
/// - camera steps sent and steps skipped because the previous move had not
///   completed yet.
///
/// Network totals come from the plugin's network counter: requests always,
/// bytes on Android only (iOS reports null for bytes).
class BenchPage extends ExamplePage {
  const BenchPage({super.key})
    : super(
        const Icon(Icons.speed),
        'Bench (performance)',
        category: ExampleCategory.advanced,
        needsLocationPermission: false,
      );

  @override
  Widget build(BuildContext context) => const _BenchBody();
}

const _routeAsset = 'assets/bench/amman_route.geojson';
const _sourceId = 'bench_route';
const _layerId = 'bench_route_line';
const _runDuration = Duration(seconds: 120);
const _cameraInterval = Duration(milliseconds: 100);
const _totalCameraSteps = 1200; // _runDuration / _cameraInterval
const _cameraZoom = 16.0;
const _cameraTilt = 60.0;
const double _frameBudgetMs = 1000 / 60;
const int _bytesPerMb = 1024 * 1024;
const LatLng _initialTarget = LatLng(31.9539, 35.9106);

class _BenchBody extends StatefulWidget {
  const _BenchBody();

  @override
  State<_BenchBody> createState() => _BenchBodyState();
}

class _BenchBodyState extends State<_BenchBody> {
  final Stopwatch _wall = Stopwatch();

  SiroMapController? _controller;
  BenchRoute? _route;
  Map<String, dynamic>? _routeGeoJson;
  String? _loadError;
  bool _routeAdded = false;

  double? _firstStyleLoadedMs;
  double? _routeReadyMs;
  double? _firstMapIdleMs;
  double? _firstCameraIdleMs;

  bool _measuring = false;
  bool _done = false;
  Duration _runStart = Duration.zero;
  Duration _runEnd = Duration.zero;
  int _cameraSteps = 0;
  int _cameraSkipped = 0;
  bool _cameraBusy = false;

  int _frames = 0;
  int _jankFrames = 0;
  final List<double> _buildMs = [];
  final List<double> _rasterMs = [];
  final List<double> _totalMs = [];

  final List<int> _rssBytes = [];
  int? _rssAtRunStart;

  Timer? _memoryTimer;
  Timer? _cameraTimer;
  Timer? _finishTimer;
  String? _resultJson;

  @override
  void initState() {
    super.initState();
    _wall.start();
    SchedulerBinding.instance.addTimingsCallback(_onFrameTimings);
    _memoryTimer = Timer.periodic(
      const Duration(seconds: 1),
      (_) => _sampleRss(),
    );
    _sampleRss();
    unawaited(_startNetworkCount());
    unawaited(_loadRoute());
  }

  Future<void> _startNetworkCount() async {
    try {
      await setNetworkStatsEnabled(true);
      await resetNetworkStats();
    } on Object {
      // Counting is best-effort: the run still reports timings without it.
    }
  }

  @override
  void dispose() {
    SchedulerBinding.instance.removeTimingsCallback(_onFrameTimings);
    _memoryTimer?.cancel();
    _cameraTimer?.cancel();
    _finishTimer?.cancel();
    _wall.stop();
    // Leave counting off for the other examples, which rebuild nothing themselves.
    unawaited(setNetworkStatsEnabled(false).catchError((_) {}));
    super.dispose();
  }

  double _elapsedMs() => _wall.elapsedMicroseconds / 1000;

  Future<void> _loadRoute() async {
    try {
      final raw = await rootBundle.loadString(_routeAsset);
      final geoJson = jsonDecode(raw) as Map<String, dynamic>;
      final feature =
          (geoJson['features'] as List).first as Map<String, dynamic>;
      final coordinates =
          (feature['geometry'] as Map<String, dynamic>)['coordinates'] as List;
      // GeoJSON stores positions as [lon, lat].
      final points = [
        for (final c in coordinates)
          (
            lat: ((c as List)[1] as num).toDouble(),
            lon: (c[0] as num).toDouble(),
          ),
      ];
      if (!mounted) return;
      setState(() {
        _routeGeoJson = geoJson;
        _route = BenchRoute(points);
      });
      await _tryStartRun();
    } on Object catch (e) {
      if (mounted) setState(() => _loadError = '$e');
    }
  }

  void _onMapCreated(SiroMapController controller) {
    _controller = controller;
  }

  void _onStyleLoaded() {
    _firstStyleLoadedMs ??= _elapsedMs();
    unawaited(_tryStartRun());
  }

  void _onMapIdle() {
    _firstMapIdleMs ??= _elapsedMs();
  }

  void _onCameraIdle() {
    _firstCameraIdleMs ??= _elapsedMs();
  }

  /// Adds the route once the style and the route data are both ready, then
  /// starts the camera run. Runs at most once.
  Future<void> _tryStartRun() async {
    final controller = _controller;
    final geoJson = _routeGeoJson;
    if (_routeAdded ||
        controller == null ||
        geoJson == null ||
        _firstStyleLoadedMs == null) {
      return;
    }
    _routeAdded = true;
    await controller.addGeoJsonSource(_sourceId, geoJson);
    await controller.addLineLayer(
      _sourceId,
      _layerId,
      const LineLayerProperties(lineColor: '#D32F2F', lineWidth: 4),
    );
    if (!mounted) return;
    _routeReadyMs = _elapsedMs();
    _startRun();
  }

  void _startRun() {
    _rssAtRunStart = _lastRssBytes;
    _runStart = _wall.elapsed;
    _measuring = true;
    _cameraTimer = Timer.periodic(_cameraInterval, (_) => _cameraTick());
    _finishTimer = Timer(_runDuration, () => unawaited(_finish()));
    setState(() {});
  }

  void _cameraTick() {
    final controller = _controller;
    final route = _route;
    if (controller == null || route == null || !mounted) return;
    if (_cameraBusy) {
      _cameraSkipped++;
      return;
    }
    if (_cameraSteps >= _totalCameraSteps) return;

    final position = route.at(_cameraSteps / _totalCameraSteps);
    _cameraSteps++;
    _cameraBusy = true;
    unawaited(
      controller
          .moveCamera(
            CameraUpdate.newCameraPosition(
              CameraPosition(
                target: LatLng(position.lat, position.lon),
                zoom: _cameraZoom,
                tilt: _cameraTilt,
                bearing: position.bearing,
              ),
            ),
          )
          .whenComplete(() => _cameraBusy = false),
    );
  }

  void _onFrameTimings(List<FrameTiming> timings) {
    if (!_measuring) return;
    for (final timing in timings) {
      final build = timing.buildDuration.inMicroseconds / 1000;
      final raster = timing.rasterDuration.inMicroseconds / 1000;
      final total = timing.totalSpan.inMicroseconds / 1000;
      _frames++;
      _buildMs.add(build);
      _rasterMs.add(raster);
      _totalMs.add(total);
      if (total > _frameBudgetMs) _jankFrames++;
    }
  }

  void _sampleRss() {
    final bytes = benchCurrentRssBytes();
    if (bytes != null) _rssBytes.add(bytes);
  }

  int? get _lastRssBytes => _rssBytes.isEmpty ? null : _rssBytes.last;

  int? get _maxRssBytes =>
      _rssBytes.isEmpty ? null : _rssBytes.reduce((a, b) => a > b ? a : b);

  Future<void> _finish() async {
    _cameraTimer?.cancel();
    _memoryTimer?.cancel();
    _sampleRss();
    _measuring = false;
    _runEnd = _wall.elapsed;
    final network = await _readNetworkStats();

    final runDuration = _runEnd - _runStart;
    final result = <String, Object?>{
      'scenario': 'amman_ring_road_8km',
      'routeLengthM': _route?.lengthMeters.round(),
      'platform': defaultTargetPlatform.name,
      'buildMode':
          kReleaseMode
              ? 'release'
              : kProfileMode
              ? 'profile'
              : 'debug',
      'style': ExampleConstants.demoMapStyle,
      'firstStyleLoadedMs': _round(_firstStyleLoadedMs),
      'routeReadyMs': _round(_routeReadyMs),
      'firstMapIdleMs': _round(_firstMapIdleMs),
      'firstCameraIdleMs': _round(_firstCameraIdleMs),
      'runSeconds': _round(runDuration.inMicroseconds / 1e6),
      'cameraStepsSent': _cameraSteps,
      'cameraTicksSkipped': _cameraSkipped,
      'frames': _frames,
      'fps': _round(benchFps(_frames, runDuration)),
      'jankFrames': _jankFrames,
      'frameBuildMsMean': _round(benchMean(_buildMs)),
      'frameRasterMsMean': _round(benchMean(_rasterMs)),
      'frameTotalMsP95': _round(benchPercentile(_totalMs, 0.95)),
      'rssStartMb': _mb(_rssAtRunStart),
      'rssMaxMb': _mb(_maxRssBytes),
      'rssEndMb': _mb(_lastRssBytes),
      'network': network,
    };
    setState(() {
      _resultJson = const JsonEncoder.withIndent('  ').convert(result);
      _done = true;
    });
  }

  Future<Map<String, Object?>?> _readNetworkStats() async {
    try {
      final stats = await getNetworkStats();
      return {'requests': stats.requests, 'bytes': stats.bytes};
    } on Object catch (e) {
      return {'error': '$e'};
    }
  }

  static double? _round(double? value) {
    if (value == null || value.isNaN) return null;
    return (value * 100).round() / 100;
  }

  static double? _mb(int? bytes) =>
      bytes == null ? null : _round(bytes / _bytesPerMb);

  String get _phaseText {
    if (_loadError != null) return 'Route failed to load: $_loadError';
    if (_done) return 'Done. Copy the results below.';
    if (_measuring) return 'Running: step $_cameraSteps / $_totalCameraSteps';
    if (_controller == null) return 'Waiting for the map…';
    if (_firstStyleLoadedMs == null) return 'Waiting for the style…';
    return 'Adding the route…';
  }

  void _copyResults() {
    final json = _resultJson;
    if (json == null) return;
    unawaited(Clipboard.setData(ClipboardData(text: json)));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Results copied')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: Stack(
        children: [
          SiroMap(
            styleString: ExampleConstants.demoMapStyle,
            initialCameraPosition: const CameraPosition(
              target: _initialTarget,
              zoom: 11,
            ),
            onMapCreated: _onMapCreated,
            onStyleLoadedCallback: _onStyleLoaded,
            onMapIdle: _onMapIdle,
            onCameraIdle: _onCameraIdle,
          ),
          Positioned(
            left: ExampleConstants.paddingStandard,
            right: ExampleConstants.paddingStandard,
            bottom: ExampleConstants.paddingStandard,
            child: Card(
              color: theme.colorScheme.surface.withValues(alpha: 0.92),
              child: Padding(
                padding: const EdgeInsets.all(ExampleConstants.paddingSmall),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(_phaseText, style: theme.textTheme.bodyMedium),
                    if (_resultJson != null) ...[
                      const SizedBox(height: ExampleConstants.paddingSmall),
                      ConstrainedBox(
                        constraints: const BoxConstraints(maxHeight: 180),
                        child: SingleChildScrollView(
                          child: SelectableText(
                            _resultJson!,
                            style: const TextStyle(
                              fontFamily: 'monospace',
                              fontSize: 10,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: ExampleConstants.paddingSmall),
                      ExampleButton(
                        label: 'Copy results',
                        icon: Icons.copy,
                        onPressed: _copyResults,
                        style: ExampleButtonStyle.tonal,
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
