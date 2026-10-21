import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:siro_gl_platform_interface/siro_gl_platform_interface.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('MethodChannel Terrain', () {
    late SiroMethodChannel platform;
    late List<MethodCall> methodCalls;

    setUp(() async {
      platform = SiroMethodChannel();
      methodCalls = [];

      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
            const MethodChannel('${siroMapChannelPrefix}0'),
            (methodCall) async {
              methodCalls.add(methodCall);
              return null;
            },
          );

      await platform.initPlatform(0);
      methodCalls.clear();
    });

    tearDown(() {
      debugDefaultTargetPlatformOverride = null;
    });

    test('setTerrain sends the source and exaggeration', () async {
      await platform.setTerrain(
        const TerrainProperties(source: 'dem', exaggeration: 1.5),
      );

      expect(methodCalls.length, 1);
      expect(methodCalls[0].method, 'map#setTerrain');
      final terrain = (methodCalls[0].arguments as Map)['terrain'] as Map;
      expect(terrain['source'], 'dem');
      expect(terrain['exaggeration'], 1.5);
    });

    test('setTerrain(null) sends a null terrain to remove it', () async {
      await platform.setTerrain(null);

      expect(methodCalls.length, 1);
      expect(methodCalls[0].method, 'map#setTerrain');
      expect((methodCalls[0].arguments as Map)['terrain'], isNull);
    });

    test(
      'setTerrain throws UnsupportedError on iOS and sends nothing',
      () async {
        debugDefaultTargetPlatformOverride = TargetPlatform.iOS;

        await expectLater(
          platform.setTerrain(const TerrainProperties(source: 'dem')),
          throwsUnsupportedError,
        );
        expect(methodCalls, isEmpty);
      },
    );
  });
}
