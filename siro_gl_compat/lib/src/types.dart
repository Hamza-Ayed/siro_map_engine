import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:siro_gl/siro_gl.dart' show LatLng;

import 'support_types.dart';

/// Called with one argument, such as a tapped position.
typedef ArgumentCallback<T> = void Function(T argument);

/// Identifies a [Polyline] within a [GoogleMap].
@immutable
class PolylineId {
  const PolylineId(this.value);
  final String value;

  @override
  bool operator ==(Object other) => other is PolylineId && other.value == value;

  @override
  int get hashCode => value.hashCode;

  @override
  String toString() => 'PolylineId($value)';
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

  @override
  String toString() => 'PolygonId($value)';
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

  @override
  String toString() => 'CircleId($value)';
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

  @override
  String toString() => 'MarkerId($value)';
}

/// A line through [points]. Same fields as google_maps_flutter.
///
/// [endCap], [startCap] and [patterns] are accepted and not drawn yet.
@immutable
class Polyline {
  const Polyline({
    required this.polylineId,
    this.consumeTapEvents = false,
    this.color = const Color(0xFF000000),
    this.endCap = Cap.buttCap,
    this.geodesic = false,
    this.jointType = JointType.mitered,
    this.points = const <LatLng>[],
    this.patterns = const <PatternItem>[],
    this.startCap = Cap.buttCap,
    this.visible = true,
    this.width = 10,
    this.zIndex = 0,
    this.onTap,
  });

  final PolylineId polylineId;
  final bool consumeTapEvents;
  final Color color;
  final Cap endCap;
  final bool geodesic;
  final JointType jointType;
  final List<LatLng> points;
  final List<PatternItem> patterns;
  final Cap startCap;
  final bool visible;
  final int width;
  final int zIndex;
  final VoidCallback? onTap;

  /// A copy with the given fields replaced, as in google_maps_flutter.
  Polyline copyWith({
    bool? consumeTapEventsParam,
    Color? colorParam,
    Cap? endCapParam,
    bool? geodesicParam,
    JointType? jointTypeParam,
    List<LatLng>? pointsParam,
    List<PatternItem>? patternsParam,
    Cap? startCapParam,
    bool? visibleParam,
    int? widthParam,
    int? zIndexParam,
    VoidCallback? onTapParam,
  }) => Polyline(
    polylineId: polylineId,
    consumeTapEvents: consumeTapEventsParam ?? consumeTapEvents,
    color: colorParam ?? color,
    endCap: endCapParam ?? endCap,
    geodesic: geodesicParam ?? geodesic,
    jointType: jointTypeParam ?? jointType,
    points: pointsParam ?? points,
    patterns: patternsParam ?? patterns,
    startCap: startCapParam ?? startCap,
    visible: visibleParam ?? visible,
    width: widthParam ?? width,
    zIndex: zIndexParam ?? zIndex,
    onTap: onTapParam ?? onTap,
  );

  @override
  bool operator ==(Object other) =>
      other is Polyline &&
      other.polylineId == polylineId &&
      other.color == color &&
      other.geodesic == geodesic &&
      other.jointType == jointType &&
      listEquals(other.points, points) &&
      other.visible == visible &&
      other.width == width &&
      other.zIndex == zIndex;

  @override
  int get hashCode => Object.hash(
    polylineId,
    color,
    geodesic,
    jointType,
    Object.hashAll(points),
    visible,
    width,
    zIndex,
  );
}

/// A filled area bounded by [points], with optional [holes].
@immutable
class Polygon {
  const Polygon({
    required this.polygonId,
    this.consumeTapEvents = false,
    this.fillColor = Colors.black12,
    this.geodesic = false,
    this.points = const <LatLng>[],
    this.holes = const <List<LatLng>>[],
    this.strokeColor = Colors.black,
    this.strokeWidth = 10,
    this.visible = true,
    this.zIndex = 0,
    this.onTap,
  });

  final PolygonId polygonId;
  final bool consumeTapEvents;
  final Color fillColor;
  final bool geodesic;
  final List<LatLng> points;
  final List<List<LatLng>> holes;
  final Color strokeColor;
  final int strokeWidth;
  final bool visible;
  final int zIndex;
  final VoidCallback? onTap;

  /// A copy with the given fields replaced, as in google_maps_flutter.
  Polygon copyWith({
    bool? consumeTapEventsParam,
    Color? fillColorParam,
    bool? geodesicParam,
    List<LatLng>? pointsParam,
    List<List<LatLng>>? holesParam,
    Color? strokeColorParam,
    int? strokeWidthParam,
    bool? visibleParam,
    int? zIndexParam,
    VoidCallback? onTapParam,
  }) => Polygon(
    polygonId: polygonId,
    consumeTapEvents: consumeTapEventsParam ?? consumeTapEvents,
    fillColor: fillColorParam ?? fillColor,
    geodesic: geodesicParam ?? geodesic,
    points: pointsParam ?? points,
    holes: holesParam ?? holes,
    strokeColor: strokeColorParam ?? strokeColor,
    strokeWidth: strokeWidthParam ?? strokeWidth,
    visible: visibleParam ?? visible,
    zIndex: zIndexParam ?? zIndex,
    onTap: onTapParam ?? onTap,
  );

  static bool _holesEqual(List<List<LatLng>> a, List<List<LatLng>> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (!listEquals(a[i], b[i])) return false;
    }
    return true;
  }

  @override
  bool operator ==(Object other) =>
      other is Polygon &&
      other.polygonId == polygonId &&
      other.fillColor == fillColor &&
      other.geodesic == geodesic &&
      listEquals(other.points, points) &&
      _holesEqual(other.holes, holes) &&
      other.strokeColor == strokeColor &&
      other.strokeWidth == strokeWidth &&
      other.visible == visible &&
      other.zIndex == zIndex;

  @override
  int get hashCode => Object.hash(
    polygonId,
    fillColor,
    geodesic,
    Object.hashAll(points),
    holes.length,
    strokeColor,
    strokeWidth,
    visible,
    zIndex,
  );
}

/// A circle of [radius] metres around [center].
@immutable
class Circle {
  const Circle({
    required this.circleId,
    this.consumeTapEvents = false,
    this.fillColor = Colors.transparent,
    this.center = const LatLng(0, 0),
    this.radius = 0,
    this.strokeColor = Colors.black,
    this.strokeWidth = 10,
    this.visible = true,
    this.zIndex = 0,
    this.onTap,
  });

  final CircleId circleId;
  final bool consumeTapEvents;
  final Color fillColor;
  final LatLng center;
  final double radius;
  final Color strokeColor;
  final int strokeWidth;
  final bool visible;
  final int zIndex;
  final VoidCallback? onTap;

  /// A copy with the given fields replaced, as in google_maps_flutter.
  Circle copyWith({
    bool? consumeTapEventsParam,
    Color? fillColorParam,
    LatLng? centerParam,
    double? radiusParam,
    Color? strokeColorParam,
    int? strokeWidthParam,
    bool? visibleParam,
    int? zIndexParam,
    VoidCallback? onTapParam,
  }) => Circle(
    circleId: circleId,
    consumeTapEvents: consumeTapEventsParam ?? consumeTapEvents,
    fillColor: fillColorParam ?? fillColor,
    center: centerParam ?? center,
    radius: radiusParam ?? radius,
    strokeColor: strokeColorParam ?? strokeColor,
    strokeWidth: strokeWidthParam ?? strokeWidth,
    visible: visibleParam ?? visible,
    zIndex: zIndexParam ?? zIndex,
    onTap: onTapParam ?? onTap,
  );

  @override
  bool operator ==(Object other) =>
      other is Circle &&
      other.circleId == circleId &&
      other.fillColor == fillColor &&
      other.center == center &&
      other.radius == radius &&
      other.strokeColor == strokeColor &&
      other.strokeWidth == strokeWidth &&
      other.visible == visible &&
      other.zIndex == zIndex;

  @override
  int get hashCode => Object.hash(
    circleId,
    fillColor,
    center,
    radius,
    strokeColor,
    strokeWidth,
    visible,
    zIndex,
  );
}

/// A point marker. Tap, [infoWindow], [icon], [alpha] and [rotation] work.
/// Dragging is accepted and not active yet, so the drag callbacks never fire.
@immutable
class Marker {
  const Marker({
    required this.markerId,
    this.alpha = 1.0,
    this.anchor = const Offset(0.5, 1.0),
    this.consumeTapEvents = false,
    this.draggable = false,
    this.flat = false,
    this.icon = BitmapDescriptor.defaultMarker,
    this.infoWindow = InfoWindow.noText,
    this.position = const LatLng(0, 0),
    this.rotation = 0.0,
    this.visible = true,
    this.zIndex = 0.0,
    this.onTap,
    this.onDragStart,
    this.onDrag,
    this.onDragEnd,
  });

  final MarkerId markerId;
  final double alpha;
  final Offset anchor;
  final bool consumeTapEvents;
  final bool draggable;
  final bool flat;
  final BitmapDescriptor icon;
  final InfoWindow infoWindow;
  final LatLng position;
  final double rotation;
  final bool visible;
  final double zIndex;
  final VoidCallback? onTap;
  final ValueChanged<LatLng>? onDragStart;
  final ValueChanged<LatLng>? onDrag;
  final ValueChanged<LatLng>? onDragEnd;

  /// A copy with the given fields replaced, as in google_maps_flutter.
  Marker copyWith({
    double? alphaParam,
    Offset? anchorParam,
    bool? consumeTapEventsParam,
    bool? draggableParam,
    bool? flatParam,
    BitmapDescriptor? iconParam,
    InfoWindow? infoWindowParam,
    LatLng? positionParam,
    double? rotationParam,
    bool? visibleParam,
    double? zIndexParam,
    VoidCallback? onTapParam,
    ValueChanged<LatLng>? onDragStartParam,
    ValueChanged<LatLng>? onDragParam,
    ValueChanged<LatLng>? onDragEndParam,
  }) => Marker(
    markerId: markerId,
    alpha: alphaParam ?? alpha,
    anchor: anchorParam ?? anchor,
    consumeTapEvents: consumeTapEventsParam ?? consumeTapEvents,
    draggable: draggableParam ?? draggable,
    flat: flatParam ?? flat,
    icon: iconParam ?? icon,
    infoWindow: infoWindowParam ?? infoWindow,
    position: positionParam ?? position,
    rotation: rotationParam ?? rotation,
    visible: visibleParam ?? visible,
    zIndex: zIndexParam ?? zIndex,
    onTap: onTapParam ?? onTap,
    onDragStart: onDragStartParam ?? onDragStart,
    onDrag: onDragParam ?? onDrag,
    onDragEnd: onDragEndParam ?? onDragEnd,
  );

  @override
  bool operator ==(Object other) =>
      other is Marker &&
      other.markerId == markerId &&
      other.alpha == alpha &&
      other.icon == icon &&
      other.infoWindow == infoWindow &&
      other.position == position &&
      other.rotation == rotation &&
      other.visible == visible &&
      other.zIndex == zIndex;

  @override
  int get hashCode => Object.hash(
    markerId,
    alpha,
    icon,
    infoWindow,
    position,
    rotation,
    visible,
    zIndex,
  );
}
