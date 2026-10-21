// Native integration checks for Android and iOS: the map loads, layer
// visibility round-trips, the network counter sees the style request,
// forced offline can be toggled, and the calls the SDK cannot serve on iOS
// fail with a clear code.
//
// Run on the iOS simulator (or an Android device):
//   flutter test integration_test/native_smoke_test.dart -d <device-id>
//
// On web the suite is a no-op. web_feature_state_test.dart covers the web side.
import 'dart:async';

import 'package:flutter/foundation.dart' show defaultTargetPlatform, kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show PlatformException;
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:siro_gl/siro_gl.dart';

import 'package:siro_gl_example/shared/shared.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('the map loads and reports layers', (tester) async {
    if (kIsWeb) return;
    final controller = await _pumpMap(tester);

    final layers = await controller.getLayerIds();
    expect(layers, isNotEmpty);
  });

  testWidgets('layer visibility round-trips', (tester) async {
    if (kIsWeb) return;
    final controller = await _pumpMap(tester);
    final layerId = (await controller.getLayerIds()).first;

    await controller.setLayerVisibility(layerId, false);
    expect(await controller.getLayerVisibility(layerId), isFalse);

    await controller.setLayerVisibility(layerId, true);
    expect(await controller.getLayerVisibility(layerId), isTrue);
  });

  testWidgets('the network counter sees the style request', (tester) async {
    if (kIsWeb) return;
    await setNetworkStatsEnabled(true);
    await resetNetworkStats();

    await _pumpMap(tester);

    final stats = await getNetworkStats();
    expect(stats.requests, greaterThan(0));
    await setNetworkStatsEnabled(false);
  });

  testWidgets('forced offline toggles without error', (tester) async {
    if (kIsWeb) return;
    await setOffline(true);
    await setOffline(false);
  });

  testWidgets('feature state is refused on iOS before reaching the SDK', (
    tester,
  ) async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.iOS) return;
    final controller = await _pumpMap(tester);

    // The platform layer refuses first, with UnsupportedError. The native
    // side also answers UNSUPPORTED if it is ever reached.
    await expectLater(
      controller.setFeatureState('any-source', '1', {'selected': true}),
      throwsUnsupportedError,
    );
  });

  testWidgets('offline metadata update reports UNSUPPORTED on iOS', (
    tester,
  ) async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.iOS) return;

    await expectLater(
      updateOfflineRegionMetadata(1, {'name': 'x'}),
      throwsA(
        isA<PlatformException>().having((e) => e.code, 'code', 'UNSUPPORTED'),
      ),
    );
  });
}

/// Pumps a map with the demo style and waits until the style has loaded.
Future<SiroMapController> _pumpMap(WidgetTester tester) async {
  await ExampleConstants.resolveDemoMapStyle();
  // Tear down the map a previous test left behind, and let its native view go
  // before the next one starts. Otherwise a style call can reach the old view.
  await tester.pumpWidget(const SizedBox());
  await tester.runAsync(() => Future<void>.delayed(const Duration(seconds: 2)));
  final controllerCompleter = Completer<SiroMapController>();
  final styleLoaded = Completer<void>();

  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: SiroMap(
          styleString: ExampleConstants.demoMapStyle,
          initialCameraPosition: ExampleConstants.defaultCameraPosition,
          onMapCreated: controllerCompleter.complete,
          onStyleLoadedCallback: () {
            if (!styleLoaded.isCompleted) styleLoaded.complete();
          },
        ),
      ),
    ),
  );

  final controller = await tester.runAsync(
    () => controllerCompleter.future.timeout(const Duration(seconds: 30)),
  );
  await tester.runAsync(
    () => styleLoaded.future.timeout(const Duration(seconds: 60)),
  );
  return controller!;
}
