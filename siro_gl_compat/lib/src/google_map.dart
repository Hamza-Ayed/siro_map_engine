import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:siro_gl/siro_gl.dart' hide CameraUpdate, Circle;
import 'package:siro_gl/siro_gl.dart' as siro show Circle;

import 'geometry.dart';
import 'support_types.dart';
import 'types.dart';

/// Siro's day style, served from our server.
const String defaultMapStyleUrl =
    'https://map-saas.intaleqapp.com/siro/style-sovereign.json';

/// Siro's night style, used for a dark [MapColorScheme].
const String nightMapStyleUrl =
    'https://map-saas.intaleqapp.com/siro/style-sovereign-night.json';

/// Siro's tactical 3D style, used for [MapType.terrain].
const String terrainMapStyleUrl =
    'https://map-saas.intaleqapp.com/siro/style-sovereign-tactical.json';

/// Attributions shown by default in the info sheet.
const List<String> defaultAttributions = [
  '© OpenStreetMap contributors',
  'Siro Maps',
];

typedef MapCreatedCallback = void Function(GoogleMapController controller);
typedef CameraPositionCallback = void Function(CameraPosition position);

/// Controls a [GoogleMap]. Names and signatures match google_maps_flutter.
class GoogleMapController {
  GoogleMapController._(this._state);

  final _GoogleMapState _state;

  SiroMapController get _map => _state._map!;

  Future<void> animateCamera(CameraUpdate cameraUpdate, {Duration? duration}) =>
      _map.animateCamera(cameraUpdate.native, duration: duration);

  Future<void> moveCamera(CameraUpdate cameraUpdate) =>
      _map.moveCamera(cameraUpdate.native);

  Future<LatLngBounds> getVisibleRegion() => _map.getVisibleRegion();

  Future<ScreenCoordinate> getScreenCoordinate(LatLng latLng) async {
    final point = await _map.toScreenLocation(latLng);
    return ScreenCoordinate(x: point.x.round(), y: point.y.round());
  }

  Future<LatLng> getLatLng(ScreenCoordinate screenCoordinate) => _map.toLatLng(
    math.Point<num>(screenCoordinate.x, screenCoordinate.y),
  );

  Future<double> getZoomLevel() async {
    final camera = await _map.queryCameraPosition();
    return camera?.zoom ?? _map.cameraPosition?.zoom ?? 0;
  }

  Future<Uint8List?> takeSnapshot() => _map.takeSnapshot();

  /// Loads a Siro style URL or a style JSON object. Google's style arrays are
  /// not supported; [getStyleError] reports that.
  Future<void> setMapStyle(String? mapStyle) => _state._setMapStyle(mapStyle);

  Future<String?> getStyleError() async => _state._styleError;

  Future<void> showMarkerInfoWindow(MarkerId markerId) =>
      _state._showInfoWindow(markerId);

  Future<void> hideMarkerInfoWindow(MarkerId markerId) async =>
      _state._hideInfoWindow(markerId);

  Future<bool> isMarkerInfoWindowShown(MarkerId markerId) async =>
      _state._infoMarker == markerId;

  void dispose() {}
}

/// A map with Google Maps Flutter's API: set-based markers, polylines,
/// polygons and circles, and the same events and options.
///
/// Not supported yet: cluster managers, ground overlays, heatmaps, tile
/// overlays, traffic, indoor maps, 45° imagery and web camera controls.
/// [mapType] uses Siro styles: [MapType.terrain] is the tactical 3D style, and
/// satellite and hybrid fall back to the normal map.
class GoogleMap extends StatefulWidget {
  const GoogleMap({
    super.key,
    required this.initialCameraPosition,
    this.onMapCreated,
    this.gestureRecognizers,
    this.compassEnabled = true,
    this.mapToolbarEnabled = true,
    this.cameraTargetBounds = CameraTargetBounds.unbounded,
    this.mapType = MapType.normal,
    this.minMaxZoomPreference = MinMaxZoomPreference.unbounded,
    this.rotateGesturesEnabled = true,
    this.scrollGesturesEnabled = true,
    this.zoomControlsEnabled = true,
    this.zoomGesturesEnabled = true,
    this.liteModeEnabled = false,
    this.tiltGesturesEnabled = true,
    this.fortyFiveDegreeImageryEnabled = false,
    this.myLocationEnabled = false,
    this.myLocationButtonEnabled = true,
    this.layoutDirection,
    this.padding = EdgeInsets.zero,
    this.indoorViewEnabled = false,
    this.trafficEnabled = false,
    this.buildingsEnabled = true,
    this.mapTypeControlEnabled = true,
    this.streetViewControlEnabled = true,
    this.fullscreenControlEnabled = true,
    this.markers = const <Marker>{},
    this.polygons = const <Polygon>{},
    this.polylines = const <Polyline>{},
    this.circles = const <Circle>{},
    this.onCameraMoveStarted,
    this.onCameraMove,
    this.onCameraIdle,
    this.onTap,
    this.onLongPress,
    this.style,
    this.colorScheme,
    this.styleUrl,
    this.attributions = defaultAttributions,
  });

  final CameraPosition initialCameraPosition;
  final MapCreatedCallback? onMapCreated;
  final Set<Factory<OneSequenceGestureRecognizer>>? gestureRecognizers;
  final bool compassEnabled;
  final bool mapToolbarEnabled;
  final CameraTargetBounds cameraTargetBounds;
  final MapType mapType;
  final MinMaxZoomPreference minMaxZoomPreference;
  final bool rotateGesturesEnabled;
  final bool scrollGesturesEnabled;
  final bool zoomControlsEnabled;
  final bool zoomGesturesEnabled;
  final bool liteModeEnabled;
  final bool tiltGesturesEnabled;
  final bool fortyFiveDegreeImageryEnabled;
  final bool myLocationEnabled;
  final bool myLocationButtonEnabled;
  final TextDirection? layoutDirection;
  final EdgeInsets padding;
  final bool indoorViewEnabled;
  final bool trafficEnabled;
  final bool buildingsEnabled;
  final bool mapTypeControlEnabled;
  final bool streetViewControlEnabled;
  final bool fullscreenControlEnabled;
  final Set<Marker> markers;
  final Set<Polygon> polygons;
  final Set<Polyline> polylines;
  final Set<Circle> circles;
  final VoidCallback? onCameraMoveStarted;
  final CameraPositionCallback? onCameraMove;
  final VoidCallback? onCameraIdle;
  final ArgumentCallback<LatLng>? onTap;
  final ArgumentCallback<LatLng>? onLongPress;

  /// A Siro style URL or style JSON. Google's style arrays are not supported.
  final String? style;

  /// Light or dark map. Dark uses Siro's night style.
  final MapColorScheme? colorScheme;

  /// Siro addition: any style URL. Overrides [mapType] and [colorScheme].
  final String? styleUrl;

  /// Siro addition: the lines shown in the info sheet.
  final List<String> attributions;

  @override
  State<GoogleMap> createState() => _GoogleMapState();
}

class _GoogleMapState extends State<GoogleMap> {
  SiroMapController? _map;
  bool _styleReady = false;
  bool _freshStyle = true;
  bool _syncing = false;
  bool _syncAgain = false;
  bool _moving = false;
  String? _loadedStyle;
  String? _styleOverride;
  String? _styleError;

  final List<Line> _lines = [];
  final List<Fill> _fills = [];
  final List<siro.Circle> _dots = [];
  final List<Symbol> _symbols = [];
  final Map<String, Object> _tapTargets = {};
  final Set<String> _addedImages = {};

  MarkerId? _infoMarker;
  Offset? _infoOffset;

  String get _wantedStyle {
    if (_styleOverride != null) return _styleOverride!;
    if (widget.styleUrl != null) return widget.styleUrl!;
    final style = widget.style;
    if (style != null && (style.startsWith('http') || style.startsWith('{'))) {
      return style;
    }
    final dark =
        widget.colorScheme == MapColorScheme.dark ||
        (widget.colorScheme == MapColorScheme.followSystem &&
            MediaQuery.platformBrightnessOf(context) == Brightness.dark);
    if (dark) return nightMapStyleUrl;
    if (widget.mapType == MapType.terrain) return terrainMapStyleUrl;
    return defaultMapStyleUrl;
  }

  @override
  void didUpdateWidget(covariant GoogleMap oldWidget) {
    super.didUpdateWidget(oldWidget);
    final map = _map;
    if (map == null) return;
    final wanted = _wantedStyle;
    if (_loadedStyle != null && wanted != _loadedStyle) {
      _styleReady = false;
      _loadedStyle = wanted;
      unawaited(map.setStyle(wanted));
      return;
    }
    if (widget.padding != oldWidget.padding) {
      unawaited(map.updateContentInsets(widget.padding, true));
    }
    final changed =
        !setEquals(oldWidget.polylines, widget.polylines) ||
        !setEquals(oldWidget.polygons, widget.polygons) ||
        !setEquals(oldWidget.circles, widget.circles) ||
        !setEquals(oldWidget.markers, widget.markers);
    if (changed && _styleReady) unawaited(_sync());
  }

  @override
  void dispose() {
    final map = _map;
    if (map != null) {
      map.onLineTapped.remove(_onLineTapped);
      map.onFillTapped.remove(_onFillTapped);
      map.onCircleTapped.remove(_onCircleTapped);
      map.onSymbolTapped.remove(_onSymbolTapped);
    }
    super.dispose();
  }

  void _onMapCreated(SiroMapController map) {
    _map = map;
    _loadedStyle ??= _wantedStyle;
    map.onLineTapped.add(_onLineTapped);
    map.onFillTapped.add(_onFillTapped);
    map.onCircleTapped.add(_onCircleTapped);
    map.onSymbolTapped.add(_onSymbolTapped);
    widget.onMapCreated?.call(GoogleMapController._(this));
  }

  Future<void> _onStyleLoaded() async {
    final map = _map;
    if (map == null) return;
    _styleReady = true;
    _freshStyle = true; // handles from a previous style are gone
    if (widget.padding != EdgeInsets.zero) {
      await map.updateContentInsets(widget.padding);
    }
    await _sync();
  }

  Future<void> _setMapStyle(String? style) async {
    final map = _map;
    if (map == null) return;
    _styleError = null;
    if (style == null) {
      _styleOverride = null;
    } else if (style.startsWith('http') || style.startsWith('{')) {
      _styleOverride = style;
    } else {
      _styleError =
          'Google style arrays are not supported. Pass a Siro style URL or a '
          'style JSON object.';
      return;
    }
    final wanted = _wantedStyle;
    if (wanted == _loadedStyle) return;
    _styleReady = false;
    _loadedStyle = wanted;
    await map.setStyle(wanted);
  }

  // ---------------------------------------------------------------- taps

  void _onLineTapped(Line line) {
    final id = _tapTargets[line.id];
    if (id is PolylineId) {
      for (final p in widget.polylines) {
        if (p.polylineId == id) p.onTap?.call();
      }
    } else if (id is PolygonId) {
      for (final p in widget.polygons) {
        if (p.polygonId == id) p.onTap?.call();
      }
    } else if (id is CircleId) {
      for (final c in widget.circles) {
        if (c.circleId == id) c.onTap?.call();
      }
    }
  }

  void _onFillTapped(Fill fill) => _onLineTappedById(_tapTargets[fill.id]);

  void _onLineTappedById(Object? id) {
    if (id is PolygonId) {
      for (final p in widget.polygons) {
        if (p.polygonId == id) p.onTap?.call();
      }
    } else if (id is CircleId) {
      for (final c in widget.circles) {
        if (c.circleId == id) c.onTap?.call();
      }
    }
  }

  void _onCircleTapped(siro.Circle dot) => _markerTapped(_tapTargets[dot.id]);

  void _onSymbolTapped(Symbol symbol) => _markerTapped(_tapTargets[symbol.id]);

  void _markerTapped(Object? id) {
    if (id is! MarkerId) return;
    final marker = _markerFor(id);
    if (marker == null) return;
    marker.onTap?.call();
    if (marker.infoWindow.title != null || marker.infoWindow.snippet != null) {
      unawaited(_showInfoWindow(id));
    }
  }

  // --------------------------------------------------------- info window

  Marker? _markerFor(MarkerId id) {
    for (final m in widget.markers) {
      if (m.markerId == id) return m;
    }
    return null;
  }

  Future<void> _showInfoWindow(MarkerId id) async {
    if (_markerFor(id) == null) return;
    _infoMarker = id;
    await _updateInfoOffset();
  }

  void _hideInfoWindow(MarkerId id) {
    if (_infoMarker != id) return;
    setState(() {
      _infoMarker = null;
      _infoOffset = null;
    });
  }

  Future<void> _updateInfoOffset() async {
    final map = _map;
    final id = _infoMarker;
    if (map == null || id == null) return;
    final marker = _markerFor(id);
    if (marker == null) return;
    final point = await map.toScreenLocation(marker.position);
    if (!mounted || _infoMarker != id) return;
    // Android reports physical pixels; iOS reports points.
    final ratio =
        defaultTargetPlatform == TargetPlatform.android
            ? MediaQuery.devicePixelRatioOf(context)
            : 1.0;
    setState(() => _infoOffset = Offset(point.x / ratio, point.y / ratio));
  }

  // ---------------------------------------------------------- annotations

  Future<void> _sync() async {
    if (_syncing) {
      _syncAgain = true;
      return;
    }
    _syncing = true;
    try {
      do {
        _syncAgain = false;
        await _syncOnce();
      } while (_syncAgain && mounted);
    } finally {
      _syncing = false;
    }
  }

  Future<void> _syncOnce() async {
    final map = _map;
    if (map == null || !_styleReady) return;
    if (_freshStyle) {
      _freshStyle = false;
      _addedImages.clear();
    } else {
      await map.removeLines(_lines);
      await map.removeFills(_fills);
      await map.removeCircles(_dots);
      await map.removeSymbols(_symbols);
    }
    _lines.clear();
    _fills.clear();
    _dots.clear();
    _symbols.clear();
    _tapTargets.clear();

    final polygons =
        widget.polygons.where((p) => p.visible).toList()
          ..sort((a, b) => a.zIndex.compareTo(b.zIndex));
    for (final polygon in polygons) {
      if (polygon.points.length < 3) continue;
      final ring =
          polygon.geodesic
              ? geodesicLine([...polygon.points, polygon.points.first])
              : polygon.points;
      await _addArea(
        map,
        [ring, ...polygon.holes],
        polygon.fillColor,
        polygon.strokeColor,
        polygon.strokeWidth,
        polygon.polygonId,
      );
    }

    final circles =
        widget.circles.where((c) => c.visible).toList()
          ..sort((a, b) => a.zIndex.compareTo(b.zIndex));
    for (final circle in circles) {
      if (circle.radius <= 0) continue;
      await _addArea(
        map,
        [geodesicCircle(circle.center, circle.radius)],
        circle.fillColor,
        circle.strokeColor,
        circle.strokeWidth,
        circle.circleId,
      );
    }

    final polylines =
        widget.polylines.where((p) => p.visible).toList()
          ..sort((a, b) => a.zIndex.compareTo(b.zIndex));
    for (final polyline in polylines) {
      if (polyline.points.length < 2) continue;
      final line = await map.addLine(
        LineOptions(
          geometry:
              polyline.geodesic
                  ? geodesicLine(polyline.points)
                  : polyline.points,
          lineColor: colorToCss(polyline.color),
          lineWidth: polyline.width.toDouble(),
          lineJoin: switch (polyline.jointType) {
            JointType.round => 'round',
            JointType.bevel => 'bevel',
            JointType.mitered => 'miter',
          },
        ),
      );
      _lines.add(line);
      _tapTargets[line.id] = polyline.polylineId;
    }

    final markers =
        widget.markers.where((m) => m.visible).toList()
          ..sort((a, b) => a.zIndex.compareTo(b.zIndex));
    for (final marker in markers) {
      await _addMarker(map, marker);
    }

    if (_infoMarker != null) unawaited(_updateInfoOffset());
  }

  Future<void> _addMarker(SiroMapController map, Marker marker) async {
    final bytes = marker.icon.bytes;
    if (bytes != null) {
      final name = 'siro_marker_${Object.hashAll(bytes)}';
      if (_addedImages.add(name)) await map.addImage(name, bytes);
      final symbol = await map.addSymbol(
        SymbolOptions(
          geometry: marker.position,
          iconImage: name,
          iconRotate: marker.rotation,
          iconAnchor:
              marker.anchor.dy >= 0.75
                  ? 'bottom'
                  : (marker.anchor.dy <= 0.25 ? 'top' : 'center'),
        ),
      );
      _symbols.add(symbol);
      _tapTargets[symbol.id] = marker.markerId;
      return;
    }
    final dot = await map.addCircle(
      CircleOptions(
        geometry: marker.position,
        circleRadius: 8,
        circleColor: marker.icon.cssColor,
        circleOpacity: marker.alpha,
        circleStrokeWidth: 2,
        circleStrokeColor: '#FFFFFF',
      ),
    );
    _dots.add(dot);
    _tapTargets[dot.id] = marker.markerId;
  }

  /// A filled area plus its stroke. A fill has no stroke width of its own, so
  /// the stroke is a line along each ring.
  Future<void> _addArea(
    SiroMapController map,
    List<List<LatLng>> rings,
    Color fillColor,
    Color strokeColor,
    int strokeWidth,
    Object id,
  ) async {
    if (fillColor.a > 0) {
      final fill = await map.addFill(
        FillOptions(
          geometry: rings,
          fillColor: colorToCss(fillColor),
          fillOpacity: fillColor.a,
        ),
      );
      _fills.add(fill);
      _tapTargets[fill.id] = id;
    }
    if (strokeWidth > 0 && strokeColor.a > 0) {
      for (final ring in rings) {
        final line = await map.addLine(
          LineOptions(
            geometry: [...ring, ring.first],
            lineColor: colorToCss(strokeColor),
            lineWidth: strokeWidth.toDouble(),
          ),
        );
        _lines.add(line);
        _tapTargets[line.id] = id;
      }
    }
  }

  // ----------------------------------------------------------------- ui

  void _onCameraMove(CameraPosition position) {
    if (!_moving) {
      _moving = true;
      widget.onCameraMoveStarted?.call();
    }
    widget.onCameraMove?.call(position);
    if (_infoMarker != null) unawaited(_updateInfoOffset());
  }

  void _onCameraIdle() {
    _moving = false;
    widget.onCameraIdle?.call();
    if (_infoMarker != null) unawaited(_updateInfoOffset());
  }

  Widget _infoWindow() {
    final id = _infoMarker;
    final marker = id == null ? null : _markerFor(id);
    final offset = _infoOffset;
    if (marker == null || offset == null) return const SizedBox.shrink();
    final info = marker.infoWindow;
    return Positioned(
      left: offset.dx,
      top: offset.dy - 28,
      child: FractionalTranslation(
        translation: const Offset(-0.5, -1),
        child: GestureDetector(
          onTap: info.onTap,
          child: Material(
            elevation: 4,
            borderRadius: BorderRadius.circular(8),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (info.title != null)
                    Text(
                      info.title!,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  if (info.snippet != null) Text(info.snippet!),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _controls() {
    final android = defaultTargetPlatform == TargetPlatform.android;
    final showZoom = widget.zoomControlsEnabled && android;
    final showLocation =
        widget.myLocationEnabled && widget.myLocationButtonEnabled;
    if (!showZoom && !showLocation) return const SizedBox.shrink();
    return Positioned(
      right: 8,
      bottom: 56 + widget.padding.bottom,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (showLocation)
            FloatingActionButton.small(
              heroTag: null,
              onPressed: () async {
                final position = await _map?.requestMyLocationLatLng();
                if (position != null) {
                  await _map?.animateCamera(
                    CameraUpdate.newLatLngZoom(position, 15).native,
                  );
                }
              },
              child: const Icon(Icons.my_location),
            ),
          if (showZoom) ...[
            const SizedBox(height: 8),
            FloatingActionButton.small(
              heroTag: null,
              onPressed:
                  () => _map?.animateCamera(CameraUpdate.zoomIn().native),
              child: const Icon(Icons.add),
            ),
            const SizedBox(height: 8),
            FloatingActionButton.small(
              heroTag: null,
              onPressed:
                  () => _map?.animateCamera(CameraUpdate.zoomOut().native),
              child: const Icon(Icons.remove),
            ),
          ],
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        SiroMap(
          styleString: _loadedStyle ?? _wantedStyle,
          onMapCreated: _onMapCreated,
          onStyleLoadedCallback: _onStyleLoaded,
          initialCameraPosition: widget.initialCameraPosition,
          gestureRecognizers: widget.gestureRecognizers,
          myLocationEnabled: widget.myLocationEnabled,
          compassEnabled: widget.compassEnabled,
          cameraTargetBounds: widget.cameraTargetBounds,
          minMaxZoomPreference: widget.minMaxZoomPreference,
          rotateGesturesEnabled: widget.rotateGesturesEnabled,
          scrollGesturesEnabled: widget.scrollGesturesEnabled,
          zoomGesturesEnabled: widget.zoomGesturesEnabled,
          tiltGesturesEnabled: widget.tiltGesturesEnabled,
          trackCameraPosition: true,
          // Bottom to top: fills, lines, marker dots, marker icons. Markers sit
          // above everything, so one inside a circle is visible and tappable.
          annotationOrder: const [
            AnnotationType.fill,
            AnnotationType.line,
            AnnotationType.circle,
            AnnotationType.symbol,
          ],
          annotationConsumeTapEvents: const [
            AnnotationType.symbol,
            AnnotationType.circle,
            AnnotationType.line,
            AnnotationType.fill,
          ],
          attributionEnabled: false,
          onMapClick:
              widget.onTap == null
                  ? null
                  : (point, coordinates) => widget.onTap!(coordinates),
          onMapLongClick:
              widget.onLongPress == null
                  ? null
                  : (point, coordinates) => widget.onLongPress!(coordinates),
          onCameraMove: _onCameraMove,
          onCameraIdle: _onCameraIdle,
        ),
        _controls(),
        _infoWindow(),
        Positioned(
          right: 4,
          bottom: 4,
          child: SiroAttributionButton(attributions: widget.attributions),
        ),
      ],
    );
  }
}
