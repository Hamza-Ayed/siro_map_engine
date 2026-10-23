import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:siro_gl/siro_gl.dart';
import '../../page.dart';
import '../../shared/shared.dart';

/// 3D terrain on the native Android engine, on the Siro style and the
/// Siro server's elevation tiles. The map finds the user by GPS, and
/// `setTerrain` raises it there. iOS has no terrain binding yet, so the page
/// says so instead of drawing.
class AndroidTerrainPage extends ExamplePage {
  const AndroidTerrainPage({super.key})
    : super(
        const Icon(Icons.terrain),
        'Terrain (Android)',
        category: ExampleCategory.advanced,
      );

  @override
  Widget build(BuildContext context) => const _AndroidTerrainBody();
}

class _AndroidTerrainBody extends StatefulWidget {
  const _AndroidTerrainBody();

  @override
  State<_AndroidTerrainBody> createState() => _AndroidTerrainBodyState();
}

class _AndroidTerrainBodyState extends State<_AndroidTerrainBody> {
  /// Terrarium elevation tiles from the Siro server. They are the AWS
  /// terrain tiles (SRTM based) cached on our server.
  static const _demTiles =
      'https://map-saas.intaleqapp.com/api/tactical/dem/{z}/{x}/{y}.png';
  static const _demSourceId = 'siro-server-dem';

  /// Where the map opens until the first GPS fix: Amman.
  static const _ammanCamera = CameraPosition(
    target: LatLng(31.9539, 35.9106),
    zoom: 10,
  );

  SiroMapController? _controller;
  bool _hasPermission = false;
  bool _terrain = false;
  UserLocation? _fix;
  bool _centeredOnFirstFix = false;
  String? _error;

  static const _terrainProperties = TerrainProperties(
    source: _demSourceId,
    exaggeration: 1.5,
  );

  /// The benchmark runs each condition on the same view: the tilt and terrain
  /// are the only things that change.
  static const List<({String name, double tilt, bool terrain})>
  _benchConditions = [
    (name: 'flat, no terrain', tilt: 0.0, terrain: false),
    (name: 'flat, terrain', tilt: 0.0, terrain: true),
    (name: 'tilted 60, no terrain', tilt: 60.0, terrain: false),
    (name: 'tilted 60, terrain', tilt: 60.0, terrain: true),
  ];

  final List<String> _benchLines = [];
  bool _benchRunning = false;

  @override
  void initState() {
    super.initState();
    if (defaultTargetPlatform != TargetPlatform.iOS) {
      unawaited(_requestPermission());
    }
  }

  Future<void> _requestPermission() async {
    final status = await Permission.locationWhenInUse.request();
    if (mounted) setState(() => _hasPermission = status.isGranted);
  }

  void _onMapCreated(SiroMapController controller) {
    _controller = controller;
  }

  Future<void> _onStyleLoaded() async {
    final controller = _controller;
    if (controller == null) return;
    try {
      await controller.addSource(
        _demSourceId,
        const RasterDemSourceProperties(
          tiles: [_demTiles],
          minzoom: 0,
          maxzoom: 15,
          tileSize: 256,
          encoding: 'terrarium',
        ),
      );
    } catch (error) {
      if (mounted) setState(() => _error = 'DEM source: $error');
    }
  }

  void _onUserLocationUpdated(UserLocation location) {
    if (!mounted) return;
    setState(() => _fix = location);
    if (!_centeredOnFirstFix) {
      _centeredOnFirstFix = true;
      unawaited(_flyToFix());
    }
  }

  Future<void> _flyToFix() async {
    final fix = _fix;
    final controller = _controller;
    if (fix == null || controller == null) return;
    await controller.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(
          target: fix.position,
          zoom: _terrain ? 13 : 14,
          tilt: _terrain ? 60 : 0,
          bearing: _terrain ? 30 : 0,
        ),
      ),
      duration: const Duration(milliseconds: 1500),
    );
  }

  Future<void> _setTerrain(bool on) async {
    final controller = _controller;
    if (controller == null) return;
    setState(() {
      _terrain = on;
      _error = null;
    });
    try {
      await controller.setTerrain(
        on ? _terrainProperties : null,
      );
      await _flyToFix();
    } catch (error) {
      if (mounted) setState(() => _error = '$error');
    }
  }

  /// Turns the map once around in four steps per condition and counts the
  /// frames the engine draws, so the frame rate of each condition can be
  /// compared on the same view.
  Future<void> _runBenchmark() async {
    final controller = _controller;
    if (controller == null || _benchRunning) return;
    final center = _fix?.position ?? _ammanCamera.target;
    setState(() {
      _benchRunning = true;
      _error = null;
      _benchLines.clear();
    });
    try {
      for (final condition in _benchConditions) {
        await controller.setTerrain(
          condition.terrain ? _terrainProperties : null,
        );
        await controller.moveCamera(
          CameraUpdate.newCameraPosition(
            CameraPosition(target: center, zoom: 13, tilt: condition.tilt),
          ),
        );
        // Let the tiles of the new view load before counting.
        await Future<void>.delayed(const Duration(seconds: 6));
        await controller.startRenderStats();
        for (var step = 1; step <= 4; step++) {
          await Future.wait([
            controller.animateCamera(
              CameraUpdate.newCameraPosition(
                CameraPosition(
                  target: center,
                  zoom: 13,
                  tilt: condition.tilt,
                  bearing: 90.0 * step,
                ),
              ),
              duration: const Duration(seconds: 3),
            ),
            Future<void>.delayed(const Duration(seconds: 3)),
          ]);
        }
        final stats = await controller.stopRenderStats();
        final line =
            '${condition.name}: ${stats?.fps.toStringAsFixed(1)} fps '
            '(${stats?.frames} frames)';
        debugPrint('BENCH $line');
        if (mounted) setState(() => _benchLines.add(line));
      }
      await controller.setTerrain(_terrain ? _terrainProperties : null);
    } catch (error) {
      if (mounted) setState(() => _error = '$error');
    } finally {
      if (mounted) setState(() => _benchRunning = false);
    }
  }

  String _status() {
    if (!_hasPermission) return 'Location permission not granted.';
    final fix = _fix;
    if (fix == null) return 'Waiting for the GPS fix...';
    final altitude = fix.altitude;
    return 'GPS: ${fix.position.latitude.toStringAsFixed(5)}, '
        '${fix.position.longitude.toStringAsFixed(5)}'
        '${altitude == null ? '' : ', altitude ${altitude.toStringAsFixed(0)} m'}';
  }

  @override
  Widget build(BuildContext context) {
    if (defaultTargetPlatform == TargetPlatform.iOS) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text(
            'setTerrain is not available on iOS yet. The native iOS engine '
            'does not bind 3D terrain. Open this page on Android.',
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    return MapExampleScaffold(
      map: SiroMap(
        styleString: ExampleConstants.sovereignMapStyle,
        onMapCreated: _onMapCreated,
        onStyleLoadedCallback: _onStyleLoaded,
        initialCameraPosition: _ammanCamera,
        myLocationEnabled: _hasPermission,
        myLocationTrackingMode: MyLocationTrackingMode.none,
        onUserLocationUpdated: _onUserLocationUpdated,
      ),
      controls: [
        ControlGroup(
          title: '3D terrain (native)',
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(_status()),
            ),
            SwitchListTile(
              title: const Text('3D terrain'),
              subtitle: const Text(
                'Raises the map by the server elevation, exaggerated 1.5 '
                'times, tilted around you',
              ),
              value: _terrain,
              onChanged: _setTerrain,
            ),
            if (!_hasPermission)
              TextButton(
                onPressed: _requestPermission,
                child: const Text('Allow location'),
              ),
            if (_fix != null)
              TextButton(
                onPressed: _flyToFix,
                child: const Text('Go to my location'),
              ),
            TextButton(
              onPressed: _benchRunning ? null : _runBenchmark,
              child: Text(
                _benchRunning
                    ? 'Benchmark running...'
                    : 'Run frame rate benchmark (about 90 s)',
              ),
            ),
            for (final line in _benchLines)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(line),
              ),
            if (_error != null)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(_error!, style: const TextStyle(color: Colors.red)),
              ),
          ],
        ),
      ],
    );
  }
}
