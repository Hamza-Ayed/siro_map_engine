import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:siro_gl/siro_gl.dart' hide Circle;
import 'package:siro_gl/siro_gl.dart' as siro show Circle;

import 'geometry.dart';
import 'types.dart';

/// Our own sovereign style, served from our server.
const String defaultMapStyleUrl =
    'https://map-saas.intaleqapp.com/siro/style-sovereign.json';

/// Attributions shown by default in the info sheet.
const List<String> defaultAttributions = [
  '© OpenStreetMap contributors',
  'Siro Maps',
];

typedef GoogleMapCreatedCallback =
    void Function(GoogleMapController controller);

/// Controls a [GoogleMap]. Method names match google_maps_flutter.
class GoogleMapController {
  GoogleMapController._(this._map);

  final SiroMapController _map;

  Future<void> animateCamera(CameraUpdate cameraUpdate) =>
      _map.animateCamera(cameraUpdate);

  Future<void> moveCamera(CameraUpdate cameraUpdate) =>
      _map.moveCamera(cameraUpdate);

  Future<LatLngBounds> getVisibleRegion() => _map.getVisibleRegion();
}

/// A map with Google Maps Flutter's API: set-based polylines, polygons,
/// circles and markers.
class GoogleMap extends StatefulWidget {
  const GoogleMap({
    super.key,
    required this.initialCameraPosition,
    this.onMapCreated,
    this.polylines = const <Polyline>{},
    this.polygons = const <Polygon>{},
    this.circles = const <Circle>{},
    this.markers = const <Marker>{},
    this.myLocationEnabled = false,
    this.compassEnabled = true,
    this.styleUrl = defaultMapStyleUrl,
    this.attributions = defaultAttributions,
  });

  final CameraPosition initialCameraPosition;
  final GoogleMapCreatedCallback? onMapCreated;
  final Set<Polyline> polylines;
  final Set<Polygon> polygons;
  final Set<Circle> circles;
  final Set<Marker> markers;
  final bool myLocationEnabled;
  final bool compassEnabled;

  /// The style to load. Defaults to Siro's own style on our server.
  final String styleUrl;

  /// Shown in the info sheet. The native attribution is always hidden.
  final List<String> attributions;

  @override
  State<GoogleMap> createState() => _GoogleMapState();
}

class _GoogleMapState extends State<GoogleMap> {
  SiroMapController? _map;
  final List<Line> _lines = [];
  final List<Fill> _fills = [];
  final List<siro.Circle> _dots = [];
  bool _styleReady = false;

  @override
  void didUpdateWidget(covariant GoogleMap oldWidget) {
    super.didUpdateWidget(oldWidget);
    final changed =
        !setEquals(oldWidget.polylines, widget.polylines) ||
        !setEquals(oldWidget.polygons, widget.polygons) ||
        !setEquals(oldWidget.circles, widget.circles) ||
        !setEquals(oldWidget.markers, widget.markers);
    if (changed && _styleReady) unawaited(_sync());
  }

  void _onMapCreated(SiroMapController map) {
    _map = map;
    widget.onMapCreated?.call(GoogleMapController._(map));
  }

  Future<void> _onStyleLoaded() async {
    _styleReady = true;
    await _sync();
  }

  /// Replaces every annotation on the map with the current sets. Simple and
  /// correct; per-item diffing can come later if sets get large.
  Future<void> _sync() async {
    final map = _map;
    if (map == null) return;
    await map.removeLines(_lines);
    await map.removeFills(_fills);
    await map.removeCircles(_dots);
    _lines.clear();
    _fills.clear();
    _dots.clear();

    for (final polyline in widget.polylines) {
      if (!polyline.visible || polyline.points.length < 2) continue;
      _lines.add(
        await map.addLine(
          LineOptions(
            geometry: polyline.points,
            lineColor: colorToCss(polyline.color),
            lineWidth: polyline.width.toDouble(),
          ),
        ),
      );
    }

    for (final polygon in widget.polygons) {
      if (!polygon.visible || polygon.points.length < 3) continue;
      await _addArea(
        map,
        polygon.points,
        polygon.fillColor,
        polygon.strokeColor,
        polygon.strokeWidth,
      );
    }

    for (final circle in widget.circles) {
      if (!circle.visible || circle.radius <= 0) continue;
      await _addArea(
        map,
        geodesicCircle(circle.center, circle.radius),
        circle.fillColor,
        circle.strokeColor,
        circle.strokeWidth,
      );
    }

    for (final marker in widget.markers) {
      if (!marker.visible) continue;
      _dots.add(
        await map.addCircle(
          CircleOptions(
            geometry: marker.position,
            circleRadius: 8,
            circleColor: '#E53935',
            circleStrokeWidth: 2,
            circleStrokeColor: '#FFFFFF',
          ),
        ),
      );
    }
  }

  /// A filled ring plus its stroke. The fill has no stroke width of its own,
  /// so the stroke is a line on the same ring.
  Future<void> _addArea(
    SiroMapController map,
    List<LatLng> ring,
    Color fillColor,
    Color strokeColor,
    int strokeWidth,
  ) async {
    if (fillColor.a > 0) {
      _fills.add(
        await map.addFill(
          FillOptions(
            geometry: [ring],
            fillColor: colorToCss(fillColor),
            fillOpacity: fillColor.a,
          ),
        ),
      );
    }
    if (strokeWidth > 0 && strokeColor.a > 0) {
      _lines.add(
        await map.addLine(
          LineOptions(
            geometry: [...ring, ring.first],
            lineColor: colorToCss(strokeColor),
            lineWidth: strokeWidth.toDouble(),
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        SiroMap(
          styleString: widget.styleUrl,
          onMapCreated: _onMapCreated,
          onStyleLoadedCallback: _onStyleLoaded,
          initialCameraPosition: widget.initialCameraPosition,
          myLocationEnabled: widget.myLocationEnabled,
          compassEnabled: widget.compassEnabled,
          attributionEnabled: false,
        ),
        Positioned(
          right: 4,
          bottom: 4,
          child: SiroAttributionButton(attributions: widget.attributions),
        ),
      ],
    );
  }
}
