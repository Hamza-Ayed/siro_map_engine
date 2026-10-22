import 'package:flutter/material.dart';
import 'package:siro_gl/siro_gl.dart';

/// Common constants used across examples
class ExampleConstants {
  ExampleConstants._();

  // ============================================================================
  // Map Coordinates
  // ============================================================================

  /// Amman, Jordan: the example data covers Jordan and its neighbours, so every example starts inside it
  static const LatLng ammanCenter = LatLng(31.9539, 35.9106);

  /// Other cities inside our coverage
  static const LatLng aqaba = LatLng(29.5321, 35.0063);
  static const LatLng irbid = LatLng(32.5556, 35.85);
  static const LatLng zarqa = LatLng(32.0728, 36.088);

  // ============================================================================
  // Map Configuration
  // ============================================================================

  /// Default zoom level
  static const double defaultZoom = 4.0;

  /// Default map bounds (Amman)
  static final LatLngBounds defaultBounds = LatLngBounds(
    southwest: const LatLng(31.85, 35.8),
    northeast: const LatLng(32.05, 36.05),
  );

  // ============================================================================
  // Spacing & Layout
  // ============================================================================

  /// Standard padding for content
  static const double paddingStandard = 16.0;

  /// Small padding
  static const double paddingSmall = 8.0;

  /// Tiny padding for tight spaces
  static const double paddingTiny = 4.0;

  /// Spacing between buttons in control panels
  static const double buttonSpacing = 8.0;

  /// Run spacing for wrapped button groups
  static const double buttonRunSpacing = 8.0;

  /// Map height ratio (portion of screen height)
  static const double mapHeightRatio = 0.5;

  /// Border radius for cards and containers
  static const double borderRadius = 12.0;

  // ============================================================================
  // Map Styles
  // ============================================================================

  /// The example app's map style: Siro's own style, served from our server.
  /// Tiles, glyphs and elevation all come from our domain, so the example
  /// shows what our users see and makes no request to a third-party host.
  static const String demoMapStyle = sovereignMapStyle;

  /// Siro's night style, from our server.
  static const String sovereignNightStyle =
      'https://map-saas.intaleqapp.com/siro/style-sovereign-night.json';

  /// Siro's tactical 3D style, from our server.
  static const String sovereignTacticalStyle =
      'https://map-saas.intaleqapp.com/siro/style-sovereign-tactical.json';

  /// Siro's sovereign style. Its sources, glyphs and DEM are on our server;
  /// the test in test/sovereign_style_test.dart fails if that changes.
  static const String sovereignMapStyle =
      'https://map-saas.intaleqapp.com/siro/style-sovereign.json';

  /// Glyph fonts we host on our server (Noto Sans, OFL).
  static const List<String> demoFontStack = ['Noto Sans Regular'];

  /// Bold variant of [demoFontStack], used for cluster counts.
  static const List<String> demoBoldFontStack = ['Noto Sans Bold'];

  /// Kept so the startup code keeps its shape. Nothing needs probing now:
  /// the style is ours, and a failed load shows as an error, not a fallback.
  static Future<void> resolveDemoMapStyle() async {}

  /// Style asset paths
  static const String translucenStyleAsset = 'assets/translucent_style.json';

  // ============================================================================
  // Colors
  // ============================================================================

  /// Primary accent color for UI elements
  static const Color primaryColor = Color(0xFF1976D2);

  /// Secondary accent color
  static const Color secondaryColor = Color(0xFF388E3C);

  /// Error/destructive action color
  static const Color errorColor = Color(0xFFD32F2F);

  /// Warning color
  static const Color warningColor = Color(0xFFFFA726);

  // ============================================================================
  // Animation Durations
  // ============================================================================

  /// Standard animation duration
  static const Duration animationDuration = Duration(milliseconds: 300);

  /// Camera animation duration
  static const Duration cameraAnimationDuration = Duration(milliseconds: 1000);

  /// Long animation duration
  static const Duration longAnimationDuration = Duration(milliseconds: 2000);

  // ============================================================================
  // Camera Positions
  // ============================================================================

  /// Default camera position: Amman, inside the 11-country data coverage.
  static CameraPosition defaultCameraPosition = toCameraPosition(
    const LatLng(31.9539, 35.9106),
    10,
  );

  /// Camera position for Amman
  static CameraPosition ammanCameraPosition = toCameraPosition(ammanCenter);

  /// Camera position for Aqaba
  static CameraPosition aqabaCameraPosition = toCameraPosition(
    aqaba,
  );

  /// Camera position for Irbid
  static CameraPosition irbidCameraPosition = toCameraPosition(irbid);

  /// Camera position for Zarqa
  static CameraPosition zarqaCameraPosition = toCameraPosition(zarqa);

  /// Helper to create a CameraPosition with default zoom.
  static CameraPosition toCameraPosition(
    LatLng target, [
    double zoom = defaultZoom,
  ]) {
    return CameraPosition(target: target, zoom: zoom);
  }

  // ============================================================================
  // Map Settings
  // ============================================================================

  /// Default tilt angle
  static const double defaultTilt = 0.0;

  /// Default bearing (rotation)
  static const double defaultBearing = 0.0;

  /// Minimum zoom level
  static const double minZoom = 0.0;

  /// Maximum zoom level
  static const double maxZoom = 22.0;

  // ===========================================================================
  // Pattern images paths
  // ===========================================================================

  /// Pattern image for fill layer example
  static const String catPatternPath =
      'assets/pattern/cat_silhouette_pattern.png';

  /// Pattern image for line layer example
  static const String markerPatternPath = 'assets/pattern/marker_pattern.png';
}
