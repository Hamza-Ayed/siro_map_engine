part of '../siro_gl_platform_interface.dart';

/// Where the web implementation loads MapLibre GL JS from.
///
/// The library has to be on the page before the first map is built. By default
/// the plugin imports the exact build it is tested against, so `web/index.html`
/// needs no `<script>` or `<link>` tag. Apps with other constraints pick a
/// named constructor and assign it to `SiroMap.webLibrarySource` before the
/// first map is built.
///
/// Lives in the platform interface so apps can configure it without importing
/// the web package. Ignored on Android and iOS, where the engine is linked into
/// the app binary.
@immutable
class SiroJsSource {
  /// The build this plugin is tested against, fetched from the unpkg CDN.
  ///
  /// This is what the plugin uses when nothing is configured.
  const SiroJsSource.cdn({this.timeout = _defaultTimeout})
    : scriptUrl = null,
      styleUrl = null,
      preloaded = false;

  /// A self-hosted copy of MapLibre GL JS, or files shipped as web assets.
  ///
  /// For apps whose Content-Security-Policy rules out a CDN, or that cannot
  /// rely on one being reachable. [styleUrl] is optional, but without a
  /// stylesheet the map controls and the location puck lose their styling, so
  /// leave it unset only when the page provides `maplibre-gl.css` some other
  /// way.
  ///
  /// [scriptUrl] has to point at the ES module build (`maplibre-gl.mjs`), which
  /// is the only one MapLibre GL JS 6 ships, and its `dist` directory has to be
  /// served whole: the library resolves its worker relative to its own URL. A
  /// classic `maplibre-gl.js` bundle still works, but it keeps the app on
  /// version 5 while this plugin's interop is written against 6.
  const SiroJsSource.urls({
    required String this.scriptUrl,
    this.styleUrl,
    this.timeout = _defaultTimeout,
  }) : preloaded = false;

  /// The page loads MapLibre GL JS itself; the plugin loads nothing and only
  /// waits for the `maplibregl` global to appear.
  ///
  /// Needed rather than optional for such pages: a `<script type="module">` is
  /// deferred, so the global may still be missing when the first map is built
  /// and the plugin has to wait for it. Such a page also has to publish the
  /// global itself, since an ES module defines none.
  const SiroJsSource.preloaded({this.timeout = _defaultTimeout})
    : scriptUrl = null,
      styleUrl = null,
      preloaded = true;

  static const _defaultTimeout = Duration(seconds: 20);

  /// URL of the maplibre-gl-js ES module to import, or null when the plugin's
  /// pinned build is used ([SiroJsSource.cdn]) or nothing is loaded at all
  /// ([SiroJsSource.preloaded]).
  final String? scriptUrl;

  /// URL of the `maplibre-gl.css` stylesheet to inject alongside [scriptUrl].
  final String? styleUrl;

  /// Whether the page loads the library itself ([SiroJsSource.preloaded]).
  final bool preloaded;

  /// How long the web implementation waits for the library before failing.
  final Duration timeout;

  /// The app's choice, assigned through `SiroMap.webLibrarySource`.
  ///
  /// Null means the default [SiroJsSource.cdn].
  static SiroJsSource? configured;

  @override
  String toString() =>
      'SiroJsSource('
      '${preloaded ? 'preloaded' : scriptUrl ?? 'cdn'}, '
      'timeout: $timeout)';
}
