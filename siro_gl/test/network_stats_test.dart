import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:siro_gl/maplibre_gl.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const channel = MethodChannel('plugins.flutter.io/maplibre_gl');
  late List<MethodCall> calls;
  late Object? statsReply;

  setUp(() {
    calls = [];
    statsReply = {'requests': 0, 'bytes': 0};
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (methodCall) async {
          calls.add(methodCall);
          if (methodCall.method == 'getNetworkStats') return statsReply;
          return null;
        });
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  test('setNetworkStatsEnabled sends the enabled flag', () async {
    await setNetworkStatsEnabled(true);
    await setNetworkStatsEnabled(false);

    expect(calls.map((c) => c.method), [
      'setNetworkStatsEnabled',
      'setNetworkStatsEnabled',
    ]);
    expect(calls[0].arguments, {'enabled': true});
    expect(calls[1].arguments, {'enabled': false});
  });

  test('resetNetworkStats calls the channel with no arguments', () async {
    await resetNetworkStats();

    expect(calls.single.method, 'resetNetworkStats');
    expect(calls.single.arguments, isNull);
  });

  test('getNetworkStats maps requests and bytes', () async {
    statsReply = {'requests': 42, 'bytes': 1234567};

    final stats = await getNetworkStats();

    expect(stats.requests, 42);
    expect(stats.bytes, 1234567);
  });

  test('getNetworkStats keeps bytes null when the platform has none', () async {
    statsReply = {'requests': 7, 'bytes': null};

    final stats = await getNetworkStats();

    expect(stats.requests, 7);
    expect(stats.bytes, isNull);
  });

  test('getNetworkStats treats a missing reply as zero', () async {
    statsReply = null;

    final stats = await getNetworkStats();

    expect(stats.requests, 0);
    expect(stats.bytes, isNull);
  });

  test('NetworkStats.toString shows both totals', () {
    const stats = NetworkStats(requests: 3);

    expect(stats.toString(), 'NetworkStats(requests: 3, bytes: null)');
  });
}
