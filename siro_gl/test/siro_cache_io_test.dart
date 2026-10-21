@TestOn('vm')
library;

import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:siro_gl/siro_gl.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const channel = MethodChannel('com.siro.gl/global');
  late String? databasePathReply;

  setUp(() {
    databasePathReply = null;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (methodCall) async {
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

  group('SiroCache.stats', () {
    test('reports the database size and the limit this app set', () async {
      final dir = await Directory.systemTemp.createTemp('siro_cache_test');
      addTearDown(() => dir.delete(recursive: true));
      final dbPath = '${dir.path}/offline.db';
      await File(dbPath).writeAsBytes(List<int>.filled(1234, 0));
      databasePathReply = dbPath;

      await SiroCache.setMaximumAmbientCacheSize(42);
      final stats = await SiroCache.stats();

      expect(stats.databasePath, dbPath);
      expect(stats.databaseSizeBytes, 1234);
      expect(stats.maxAmbientBytes, 42);
    });

    test('reports null size when there is no database file yet', () async {
      databasePathReply = '${Directory.systemTemp.path}/no-such-siro-file.db';

      final stats = await SiroCache.stats();

      expect(stats.databaseSizeBytes, isNull);
    });
  });
}
