import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:siro_gl/siro_gl.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const channel = MethodChannel('com.siro.gl/global');
  late List<MethodCall> calls;
  late String? databasePathReply;

  setUp(() {
    calls = [];
    databasePathReply = null;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (methodCall) async {
          calls.add(methodCall);
          if (methodCall.method == 'getOfflineDatabasePath') {
            return databasePathReply;
          }
          return null;
        });
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  group('SiroCache.boundsAround', () {
    test('at the equator a radius of 111.32 km spans one degree each way', () {
      final bounds = SiroCache.boundsAround(const LatLng(0, 0), 111.32);

      expect(bounds.southwest.latitude, closeTo(-1, 1e-9));
      expect(bounds.northeast.latitude, closeTo(1, 1e-9));
      expect(bounds.southwest.longitude, closeTo(-1, 1e-9));
      expect(bounds.northeast.longitude, closeTo(1, 1e-9));
    });

    test('longitude widens with latitude to keep the box the same size', () {
      final bounds = SiroCache.boundsAround(const LatLng(60, 0), 111.32);

      // cos(60) = 0.5, so the longitude span is two degrees each way.
      expect(bounds.northeast.longitude, closeTo(2, 1e-9));
      expect(bounds.northeast.latitude, closeTo(61, 1e-9));
    });

    test('the box contains its centre', () {
      const center = LatLng(31.9539, 35.9106);
      final bounds = SiroCache.boundsAround(center, 8);

      expect(bounds.southwest.latitude, lessThan(center.latitude));
      expect(bounds.northeast.latitude, greaterThan(center.latitude));
      expect(bounds.southwest.longitude, lessThan(center.longitude));
      expect(bounds.northeast.longitude, greaterThan(center.longitude));
    });

    test('latitude is clamped near the poles and longitude to ±180', () {
      final bounds = SiroCache.boundsAround(const LatLng(84, 179), 1000);

      expect(bounds.northeast.latitude, 85);
      expect(bounds.northeast.longitude, closeTo(179.9999, 1e-6));
    });
  });

  group('SiroCache channel calls', () {
    test('setMaximumAmbientCacheSize sends the byte limit', () async {
      await SiroCache.setMaximumAmbientCacheSize(300 * 1024 * 1024);
      if (kIsWeb) {
        expect(calls, isEmpty);
        return;
      }

      expect(calls.single.method, 'setMaximumAmbientCacheSize');
      expect(calls.single.arguments, {'bytes': 300 * 1024 * 1024});
    });

    test('setMaximumAmbientCacheSize refuses a negative limit', () async {
      await expectLater(
        SiroCache.setMaximumAmbientCacheSize(-1),
        throwsArgumentError,
      );
      expect(calls, isEmpty);
    });

    test(
      'invalidateAmbientCache and packDatabase call their methods',
      () async {
        await SiroCache.invalidateAmbientCache();
        await SiroCache.packDatabase();
        if (kIsWeb) {
          expect(calls, isEmpty);
          return;
        }

        expect(calls.map((c) => c.method), [
          'invalidateAmbientCache',
          'packDatabase',
        ]);
      },
    );

    test('setOfflineMode goes through setOffline', () async {
      await SiroCache.setOfflineMode(true);
      if (kIsWeb) {
        expect(calls, isEmpty);
        return;
      }

      expect(calls.single.method, 'setOffline');
      expect(calls.single.arguments, {'offline': true});
    });
  });

  test('setSiroRequestHeaders sends the two Siro headers', () async {
    await setSiroRequestHeaders(app: 'tactical', version: '1.2.3');

    expect(calls.single.method, 'setHttpHeaders');
    expect(calls.single.arguments, {
      'headers': {'X-Siro-App': 'tactical', 'X-Siro-Version': '1.2.3'},
    });
  });
}
