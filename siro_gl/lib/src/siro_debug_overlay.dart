part of '../siro_gl.dart';

/// Panel with the numbers that matter while tuning a map: Flutter frame rate,
/// network requests, and the offline database size. Turn it on with
/// `SiroMap(debugOverlay: true)`.
///
/// The frame rate counts Flutter frames only. The map draws natively, so its
/// own frame rate needs a native hook (PF-01) and is not shown here. Network
/// counting is turned on while the overlay is shown, and off again after.
class SiroDebugOverlay extends StatefulWidget {
  /// Creates the overlay.
  const SiroDebugOverlay({super.key});

  @override
  State<SiroDebugOverlay> createState() => _SiroDebugOverlayState();
}

class _SiroDebugOverlayState extends State<SiroDebugOverlay> {
  Timer? _timer;
  int _framesSinceLastTick = 0;
  double _fps = 0;
  NetworkStats? _network;
  SiroCacheStats? _cache;

  @override
  void initState() {
    super.initState();
    SchedulerBinding.instance.addTimingsCallback(_onFrameTimings);
    if (!kIsWeb) unawaited(_startNetworkCount());
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => _refresh());
  }

  @override
  void dispose() {
    SchedulerBinding.instance.removeTimingsCallback(_onFrameTimings);
    _timer?.cancel();
    if (!kIsWeb) unawaited(_stopNetworkCount());
    super.dispose();
  }

  void _onFrameTimings(List<FrameTiming> timings) {
    _framesSinceLastTick += timings.length;
  }

  Future<void> _startNetworkCount() async {
    try {
      await setNetworkStatsEnabled(true);
      await resetNetworkStats();
    } on Object {
      // The overlay still shows frame rate without the network numbers.
    }
  }

  Future<void> _stopNetworkCount() async {
    try {
      await setNetworkStatsEnabled(false);
    } on Object {
      // Nothing to undo if the platform never started counting.
    }
  }

  Future<void> _refresh() async {
    final fps = _framesSinceLastTick.toDouble();
    _framesSinceLastTick = 0;
    NetworkStats? network;
    SiroCacheStats? cache;
    if (!kIsWeb) {
      try {
        network = await getNetworkStats();
        cache = await SiroCache.stats();
      } on Object {
        // Keep the last numbers on screen when a read fails.
      }
    }
    if (!mounted) return;
    setState(() {
      _fps = fps;
      _network = network ?? _network;
      _cache = cache ?? _cache;
    });
  }

  @override
  Widget build(BuildContext context) {
    final network = _network;
    final cache = _cache;
    final dbKb =
        cache?.databaseSizeBytes == null
            ? 'n/a'
            : '${(cache!.databaseSizeBytes! / 1024).toStringAsFixed(0)} KB';
    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xCC000000),
        borderRadius: BorderRadius.circular(6),
      ),
      child: DefaultTextStyle(
        style: const TextStyle(
          color: Color(0xFFFFFFFF),
          fontSize: 11,
          fontFamily: 'monospace',
        ),
        child: Padding(
          padding: const EdgeInsets.all(6),
          child: Text(
            'FPS (Flutter) ${_fps.toStringAsFixed(0)}\n'
            'requests ${network?.requests ?? 'n/a'}\n'
            'offline db $dbKb',
          ),
        ),
      ),
    );
  }
}
