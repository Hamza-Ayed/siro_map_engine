import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:siro_gl_platform_interface/siro_gl_platform_interface.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('RenderStats', () {
    test('fps is frames over the window in seconds', () {
      const stats = RenderStats(frames: 450, elapsedMs: 15000);

      expect(stats.fps, 30);
    });

    test('fps is 0 for an empty window', () {
      const stats = RenderStats(frames: 0, elapsedMs: 0);

      expect(stats.fps, 0);
    });

    test('fromJson reads the platform map', () {
      final stats = RenderStats.fromJson(const {
        'frames': 12,
        'elapsedMs': 400.5,
      });

      expect(stats, const RenderStats(frames: 12, elapsedMs: 400.5));
    });
  });

  group('MethodChannel render stats', () {
    late SiroMethodChannel platform;
    late List<MethodCall> methodCalls;
    Object? stopReply;

    setUp(() async {
      platform = SiroMethodChannel();
      methodCalls = [];
      stopReply = {'frames': 90, 'elapsedMs': 3000.0};

      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
            const MethodChannel('${siroMapChannelPrefix}0'),
            (methodCall) async {
              methodCalls.add(methodCall);
              return methodCall.method == 'map#stopRenderStats'
                  ? stopReply
                  : null;
            },
          );

      await platform.initPlatform(0);
      methodCalls.clear();
    });

    tearDown(() {
      debugDefaultTargetPlatformOverride = null;
    });

    test('startRenderStats sends map#startRenderStats', () async {
      await platform.startRenderStats();

      expect(methodCalls.length, 1);
      expect(methodCalls[0].method, 'map#startRenderStats');
    });

    test('stopRenderStats returns the frames the platform counted', () async {
      final stats = await platform.stopRenderStats();

      expect(methodCalls[0].method, 'map#stopRenderStats');
      expect(stats, const RenderStats(frames: 90, elapsedMs: 3000));
    });

    test('stopRenderStats returns null when no count was running', () async {
      stopReply = null;

      expect(await platform.stopRenderStats(), isNull);
    });

    test('render stats throw UnsupportedError on iOS', () async {
      debugDefaultTargetPlatformOverride = TargetPlatform.iOS;

      await expectLater(platform.startRenderStats(), throwsUnsupportedError);
      await expectLater(platform.stopRenderStats(), throwsUnsupportedError);
      expect(methodCalls, isEmpty);
    });
  });
}
