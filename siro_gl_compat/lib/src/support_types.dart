// Google's API uses static factories and a Cap class; keep that shape.
// ignore_for_file: prefer_constructors_over_static_methods, use_enums

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:siro_gl/siro_gl.dart' as siro show CameraUpdate;
import 'package:siro_gl/siro_gl.dart' show CameraPosition, LatLng, LatLngBounds;

/// The kind of map. Siro has day, night and tactical styles; see [GoogleMap].
enum MapType { none, normal, satellite, terrain, hybrid }

/// Light or dark map, as in google_maps_flutter.
enum MapColorScheme { light, dark, followSystem }

/// A pixel position inside the map view.
@immutable
class ScreenCoordinate {
  const ScreenCoordinate({required this.x, required this.y});

  final int x;
  final int y;

  @override
  bool operator ==(Object other) =>
      other is ScreenCoordinate && other.x == x && other.y == y;

  @override
  int get hashCode => Object.hash(x, y);

  @override
  String toString() => 'ScreenCoordinate($x, $y)';
}

/// How two segments of a polyline join.
enum JointType { mitered, bevel, round }

/// How the end of a polyline is drawn. Accepted for compatibility.
@immutable
class Cap {
  const Cap._(this.name);

  static const Cap buttCap = Cap._('butt');
  static const Cap roundCap = Cap._('round');
  static const Cap squareCap = Cap._('square');

  final String name;
}

/// A dash or gap of a polyline pattern. Accepted for compatibility.
@immutable
class PatternItem {
  const PatternItem._(this.length);

  static const PatternItem dot = PatternItem._(0);
  static PatternItem dash(double length) => PatternItem._(length);
  static PatternItem gap(double length) => PatternItem._(-length);

  final double length;
}

/// Text shown above a marker when it is tapped.
@immutable
class InfoWindow {
  const InfoWindow({
    this.title,
    this.snippet,
    this.anchor = const Offset(0.5, 0.0),
    this.onTap,
  });

  static const InfoWindow noText = InfoWindow();

  final String? title;
  final String? snippet;
  final Offset anchor;
  final VoidCallback? onTap;

  @override
  bool operator ==(Object other) =>
      other is InfoWindow &&
      other.title == title &&
      other.snippet == snippet &&
      other.anchor == anchor;

  @override
  int get hashCode => Object.hash(title, snippet, anchor);
}

/// The icon of a [Marker]: the default pin tinted by hue, or your own image.
@immutable
class BitmapDescriptor {
  const BitmapDescriptor._({this.hue, this.bytes, this.scale, this.multiplier});

  static const double hueRed = 0;
  static const double hueOrange = 30;
  static const double hueYellow = 60;
  static const double hueGreen = 120;
  static const double hueCyan = 180;
  static const double hueAzure = 210;
  static const double hueBlue = 240;
  static const double hueViolet = 270;
  static const double hueMagenta = 300;
  static const double hueRose = 330;

  static const BitmapDescriptor defaultMarker = BitmapDescriptor._(hue: hueRed);

  static BitmapDescriptor defaultMarkerWithHue(double hue) =>
      BitmapDescriptor._(hue: hue);

  /// An image from PNG bytes, drawn at [multiplier] times its own size. A Siro
  /// extension, not part of Google's API: it maps straight to the engine's icon size.
  static BitmapDescriptor scaledBytes(Uint8List byteData, double multiplier) =>
      BitmapDescriptor._(bytes: byteData, multiplier: multiplier);

  /// An image from PNG bytes. [size] scales the image to that many logical
  /// pixels wide, keeping its aspect ratio; the image's own size is used otherwise.
  static BitmapDescriptor fromBytes(Uint8List byteData, {Size? size}) =>
      BitmapDescriptor._(
        bytes: byteData,
        scale: size?.width,
      );

  /// An image from a PNG in the app's assets.
  static Future<BitmapDescriptor> asset(
    ImageConfiguration configuration,
    String assetName, {
    Size? size,
  }) async {
    final data = await rootBundle.load(assetName);
    return BitmapDescriptor._(
      bytes: data.buffer.asUint8List(),
      scale: size?.width,
    );
  }

  /// The tint of the default pin, or null for an image icon.
  final double? hue;

  /// The PNG bytes of an image icon, or null for the default pin.
  final Uint8List? bytes;

  /// The width in logical pixels an image icon is drawn at, or null for its own size.
  final double? scale;

  /// The engine icon-size multiplier of an image icon, or null to derive it from [scale].
  final double? multiplier;

  /// The CSS colour of the default pin.
  String get cssColor =>
      HSVColor.fromAHSV(1, (hue ?? hueRed) % 360, 0.85, 0.9).toColor().toCss();

  @override
  bool operator ==(Object other) =>
      other is BitmapDescriptor &&
      other.hue == hue &&
      listEquals(other.bytes, bytes);

  @override
  int get hashCode =>
      Object.hash(hue, bytes == null ? 0 : Object.hashAll(bytes!));
}

extension on Color {
  String toCss() =>
      'rgb(${(r * 255).round()}, ${(g * 255).round()}, ${(b * 255).round()})';
}

/// Moves the camera, with the same factories and signatures as Google's.
class CameraUpdate {
  const CameraUpdate._(this.native);

  /// The engine's own update.
  final siro.CameraUpdate native;

  static CameraUpdate newCameraPosition(CameraPosition cameraPosition) =>
      CameraUpdate._(siro.CameraUpdate.newCameraPosition(cameraPosition));

  static CameraUpdate newLatLng(LatLng latLng) =>
      CameraUpdate._(siro.CameraUpdate.newLatLng(latLng));

  /// Fits [bounds] with [padding] logical pixels on every side.
  static CameraUpdate newLatLngBounds(LatLngBounds bounds, double padding) =>
      CameraUpdate._(
        siro.CameraUpdate.newLatLngBounds(
          bounds,
          left: padding,
          top: padding,
          right: padding,
          bottom: padding,
        ),
      );

  static CameraUpdate newLatLngZoom(LatLng latLng, double zoom) =>
      CameraUpdate._(siro.CameraUpdate.newLatLngZoom(latLng, zoom));

  static CameraUpdate scrollBy(double dx, double dy) =>
      CameraUpdate._(siro.CameraUpdate.scrollBy(dx, dy));

  static CameraUpdate zoomBy(double amount, {Offset? focus}) =>
      CameraUpdate._(siro.CameraUpdate.zoomBy(amount, focus));

  static CameraUpdate zoomIn() => CameraUpdate._(siro.CameraUpdate.zoomIn());

  static CameraUpdate zoomOut() => CameraUpdate._(siro.CameraUpdate.zoomOut());

  static CameraUpdate zoomTo(double zoom) =>
      CameraUpdate._(siro.CameraUpdate.zoomTo(zoom));
}
