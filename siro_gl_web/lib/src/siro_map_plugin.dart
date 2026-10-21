part of '../siro_gl_web.dart';

class SiroMapPlugin {
  /// Registers this class as the default instance of [SiroGlPlatform].
  static void registerWith(Registrar registrar) {
    SiroGlPlatform.createInstance = () => SiroMapController();
    // Plugin-global calls that run before any map widget exists. The
    // generated web bootstrap invokes registerWith before the app's main(),
    // so preWarm() and ensureWebLibraryLoaded() reach the web implementation
    // even as the first statement of main().
    SiroGlobalPlatform.instance = SiroGlobalWeb();
  }
}
