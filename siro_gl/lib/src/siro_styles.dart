part of '../siro_gl.dart';

/// Siro's own map styles. Each one is served from our server and names no
/// third-party host.
abstract class SiroStyles {
  /// Day style.
  static const String day =
      'https://map-saas.intaleqapp.com/siro/style-sovereign.json';

  /// Night style.
  static const String night =
      'https://map-saas.intaleqapp.com/siro/style-sovereign-night.json';

  /// Tactical 3D style, with terrain.
  static const String tactical =
      'https://map-saas.intaleqapp.com/siro/style-sovereign-tactical.json';
}
