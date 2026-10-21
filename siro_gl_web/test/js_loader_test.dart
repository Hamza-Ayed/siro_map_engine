// These tests exercise dart:js_interop and the real browser global scope, so
// they only run under `flutter test --platform chrome`; the VM run skips them.
@TestOn('browser')
library;

import 'dart:async';
import 'dart:js_interop';
import 'dart:js_interop_unsafe';

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_web_plugins/flutter_web_plugins.dart';
import 'package:siro_gl_platform_interface/siro_gl_platform_interface.dart';
import 'package:siro_gl_web/siro_gl_web.dart';
import 'package:siro_gl_web/src/global_web_platform.dart';
import 'package:siro_gl_web/src/js_loader.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SiroJsLoader.debugReset();
    SiroJsSource.configured = null;
    globalContext.delete('maplibregl'.toJS);
  });

  tearDown(() {
    SiroJsLoader.debugReset();
    SiroJsSource.configured = null;
    globalContext.delete('maplibregl'.toJS);
    SiroGlobalPlatform.instance = SiroGlobalMethodChannel();
  });

  group('SiroJsLoader.ensureLoaded', () {
    test('runs the work once for concurrent and repeated callers', () async {
      var calls = 0;
      final gate = Completer<void>();
      SiroJsLoader.loadResources = (source) {
        calls++;
        return gate.future;
      };

      final first = SiroJsLoader.ensureLoaded();
      final second = SiroJsLoader.ensureLoaded();
      gate.complete();
      await first;
      await second;
      // A call after completion must reuse the memo, not load again.
      await SiroJsLoader.ensureLoaded();

      expect(calls, 1);
    });

    test('a failure clears the memo so a later call retries', () async {
      var calls = 0;
      SiroJsLoader.loadResources = (source) async {
        calls++;
        throw SiroJsLoaderException('boom');
      };

      await expectLater(
        SiroJsLoader.ensureLoaded(),
        throwsA(isA<SiroJsLoaderException>()),
      );

      SiroJsLoader.loadResources = (source) async {
        calls++;
      };
      await SiroJsLoader.ensureLoaded();

      expect(calls, 2);
    });

    test('returns immediately when the global is already present', () async {
      globalContext.setProperty('maplibregl'.toJS, JSObject());
      SiroJsLoader.loadResources = (source) async {
        fail('loadResources must not run when maplibregl already exists');
      };

      await expectLater(SiroJsLoader.ensureLoaded(), completes);
    });

    test('defaults to the pinned CDN source', () async {
      SiroJsSource? seen;
      SiroJsLoader.loadResources = (source) async {
        seen = source;
      };

      await SiroJsLoader.ensureLoaded();

      expect(seen, isNotNull);
      expect(seen!.scriptUrl, isNull);
      expect(seen!.preloaded, isFalse);
      expect(seen!.timeout, const Duration(seconds: 20));
    });

    test(
      'the pinned default is an ES module, which is what it is imported as',
      () {
        // maplibre-gl-js 6 ships only ESM, and the loader imports the URL as a
        // module. A bump that pointed this back at a classic bundle would fail at
        // runtime, in a browser, on the first map.
        expect(SiroJsLoader.defaultScriptUrl, endsWith('.mjs'));
        expect(SiroJsLoader.defaultScriptUrl, contains(kMapLibreJsVersion));
        expect(SiroJsLoader.defaultStyleUrl, endsWith('.css'));
        expect(SiroJsLoader.defaultStyleUrl, contains(kMapLibreJsVersion));
        expect(kMapLibreJsVersion, startsWith('6.'));
      },
    );

    test('publishes the imported namespace as the maplibregl global', () async {
      // A data: URL is a real ES module, so this exercises the import path
      // without reaching the network.
      SiroJsSource.configured = const SiroJsSource.urls(
        scriptUrl: 'data:text/javascript,export const Map = class {};',
        timeout: Duration(seconds: 5),
      );

      await SiroJsLoader.ensureLoaded();

      final published = globalContext['maplibregl'] as JSObject?;
      expect(published, isNotNull);
      expect(
        published!.has('Map'),
        isTrue,
        reason: 'the published namespace must carry the library',
      );
    });

    test(
      'leaves a working global alone when the import exports nothing',
      () async {
        // What an app pointing at an older, non-module bundle gets: the import
        // succeeds, exports nothing, and the bundle defines the global itself.
        // Publishing that empty namespace would break every later call.
        final existing = JSObject()..setProperty('Map'.toJS, JSObject());
        globalContext.setProperty('maplibregl'.toJS, existing);
        SiroJsSource.configured = const SiroJsSource.urls(
          scriptUrl: 'data:text/javascript,globalThis.__sideEffect = true;',
          timeout: Duration(seconds: 5),
        );

        // The fast path in ensureLoaded would skip the import entirely, so drive
        // the real loadResources directly.
        await SiroJsLoader.loadResources(SiroJsSource.configured!);

        expect(
          globalContext['maplibregl'],
          same(existing),
          reason: 'the working global must survive an empty module namespace',
        );
      },
    );

    test('reports a URL that provides no library at all', () async {
      SiroJsSource.configured = const SiroJsSource.urls(
        scriptUrl: 'data:text/javascript,export const nothing = 1;',
        timeout: Duration(seconds: 5),
      );

      await expectLater(
        SiroJsLoader.ensureLoaded(),
        throwsA(
          isA<SiroJsLoaderException>().having(
            (e) => e.message,
            'message',
            contains('no maplibre-gl-js'),
          ),
        ),
      );
    });

    test('passes the configured source through unchanged', () async {
      const configured = SiroJsSource.urls(
        scriptUrl: 'assets/maplibre-gl.js',
        styleUrl: 'assets/maplibre-gl.css',
        timeout: Duration(seconds: 5),
      );
      SiroJsSource.configured = configured;
      SiroJsSource? seen;
      SiroJsLoader.loadResources = (source) async {
        seen = source;
      };

      await SiroJsLoader.ensureLoaded();

      expect(seen, same(configured));
    });

    test(
      'preloaded times out with a clear error, then retries clean',
      () async {
        // The preloaded path injects nothing, so this exercises the real
        // loadResources without touching the network.
        SiroJsSource.configured = const SiroJsSource.preloaded(
          timeout: Duration(milliseconds: 50),
        );

        await expectLater(
          SiroJsLoader.ensureLoaded(),
          throwsA(
            isA<SiroJsLoaderException>().having(
              (e) => e.message,
              'message',
              contains('preloaded'),
            ),
          ),
        );

        // The failure must not poison the session: once the page-provided
        // global appears, the next call succeeds.
        globalContext.setProperty('maplibregl'.toJS, JSObject());
        await expectLater(SiroJsLoader.ensureLoaded(), completes);
      },
    );
  });

  group('plugin registration', () {
    test('registerWith installs the web global platform, so preWarm from '
        'main() reaches the loader and not the method channel', () async {
      SiroMapPlugin.registerWith(webPluginRegistrar);

      expect(SiroGlobalPlatform.instance, isA<SiroGlobalWeb>());

      var loaderCalls = 0;
      var prewarmCalls = 0;
      SiroJsLoader.loadResources = (source) async {
        loaderCalls++;
        // Simulate the injected script having executed: the global appears,
        // exposing the prewarm() entry point.
        final fake = JSObject();
        fake.setProperty(
          'prewarm'.toJS,
          (() {
            prewarmCalls++;
          }).toJS,
        );
        globalContext.setProperty('maplibregl'.toJS, fake);
      };

      await SiroGlobalPlatform.instance.preWarm();

      expect(loaderCalls, 1);
      expect(prewarmCalls, 1);
    });

    test(
      'ensureLibraryLoaded on the web platform goes through the loader',
      () async {
        var loaderCalls = 0;
        SiroJsLoader.loadResources = (source) async {
          loaderCalls++;
        };

        await SiroGlobalWeb().ensureLibraryLoaded();

        expect(loaderCalls, 1);
      },
    );
  });
}
