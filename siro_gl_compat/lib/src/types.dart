import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:siro_gl/siro_gl.dart' hide Circle;

/// Identifies a [Polyline] within a [GoogleMap].
@immutable
class PolylineId {
  const PolylineId(this.value);
  final String value;

  @override
  bool operator ==(Object other) => other is PolylineId && other.value == value;

  @override
  int get hashCode => value.hashCode;
}

/// A line through [points], drawn on the map in [width] pixels.
@immutable
class Polyline {
  const Polyline({
    required this.polylineId,
    this.points = const [],
    this.color = const Color(0xFF000000),
    this.width = 10,
    this.visible = true,
  });

  final PolylineId polylineId;
  final List<LatLng> points;
  final Color color;
  final int width;
  final bool visible;

  @override
  bool operator ==(Object other) =>
      other is Polyline &&
      other.polylineId == polylineId &&
      listEquals(other.points, points) &&
      other.color == color &&
      other.width == width &&
      other.visible == visible;

  @override
  int get hashCode =>
      Object.hash(polylineId, Object.hashAll(points), color, width, visible);
}

/// Identifies a [Polygon] within a [GoogleMap].
@immutable
class PolygonId {
  const PolygonId(this.value);
  final String value;

  @override
  bool operator ==(Object other) => other is PolygonId && other.value == value;

  @override
  int get hashCode => value.hashCode;
}

/// A filled area bounded by [points], with a stroke around its edge.
@immutable
class Polygon {
  const Polygon({
    required this.polygonId,
    this.points = const [],
    this.fillColor = const Color(0x00000000),
    this.strokeColor = const Color(0xFF000000),
    this.strokeWidth = 2,
    this.visible = true,
  });

  final PolygonId polygonId;
  final List<LatLng> points;
  final Color fillColor;
  final Color strokeColor;
  final int strokeWidth;
  final bool visible;

  @override
  bool operator ==(Object other) =>
      other is Polygon &&
      other.polygonId == polygonId &&
      listEquals(other.points, points) &&
      other.fillColor == fillColor &&
      other.strokeColor == strokeColor &&
      other.strokeWidth == strokeWidth &&
      other.visible == visible;

  @override
  int get hashCode => Object.hash(
    polygonId,
    Object.hashAll(points),
    fillColor,
    strokeColor,
    strokeWidth,
    visible,
  );
}

/// Identifies a [Circle] within a [GoogleMap].
@immutable
class CircleId {
  const CircleId(this.value);
  final String value;

  @override
  bool operator ==(Object other) => other is CircleId && other.value == value;

  @override
  int get hashCode => value.hashCode;
}

/// A circle of [radius] metres around [center]. The radius is on the ground,
/// so the circle keeps its real size as the map zooms.
@immutable
class Circle {
  const Circle({
    required this.circleId,
    required this.center,
    this.radius = 0,
    this.fillColor = const Color(0x00000000),
    this.strokeColor = const Color(0xFF000000),
    this.strokeWidth = 2,
    this.visible = true,
  });

  final CircleId circleId;
  final LatLng center;
  final double radius;
  final Color fillColor;
  final Color strokeColor;
  final int strokeWidth;
  final bool visible;

  @override
  bool operator ==(Object other) =>
      other is Circle &&
      other.circleId == circleId &&
      other.center == center &&
      other.radius == radius &&
      other.fillColor == fillColor &&
      other.strokeColor == strokeColor &&
      other.strokeWidth == strokeWidth &&
      other.visible == visible;

  @override
  int get hashCode => Object.hash(
    circleId,
    center,
    radius,
    fillColor,
    strokeColor,
    strokeWidth,
    visible,
  );
}

/// Identifies a [Marker] within a [GoogleMap].
@immutable
class MarkerId {
  const MarkerId(this.value);
  final String value;

  @override
  bool operator ==(Object other) => other is MarkerId && other.value == value;

  @override
  int get hashCode => value.hashCode;
}

/// A point marker at [position]. Drawn as a dot until icon support lands.
@immutable
class Marker {
  const Marker({
    required this.markerId,
    required this.position,
    this.visible = true,
  });

  final MarkerId markerId;
  final LatLng position;
  final bool visible;

  @override
  bool operator ==(Object other) =>
      other is Marker &&
      other.markerId == markerId &&
      other.position == position &&
      other.visible == visible;

  @override
  int get hashCode => Object.hash(markerId, position, visible);
}
