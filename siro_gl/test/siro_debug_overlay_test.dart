import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:siro_gl/siro_gl.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const channel = MethodChannel('com.siro.gl/global');

  setUp(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (methodCall) async {
          switch (methodCall.method) {
            case 'getNetworkStats':
              return {'requests': 5, 'bytes': null};
            default:
              return null;
          }
        });
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  testWidgets('the overlay shows its labels and builds without a map', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: SiroDebugOverlay())),
    );

    expect(find.textContaining('FPS (Flutter)'), findsOneWidget);
    expect(find.textContaining('requests'), findsOneWidget);
    expect(find.textContaining('offline db'), findsOneWidget);
  });
}
