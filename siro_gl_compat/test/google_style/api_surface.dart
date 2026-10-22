// Written for google_maps_flutter. The parity script compiles this file against the real
// package, then against siro_gl_compat with only the import changed.
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:siro_gl_compat/siro_gl_compat.dart';

Widget buildMap(Uint8List iconBytes) {
  const marker = Marker(
    markerId: MarkerId('m'),
    position: LatLng(31.95, 35.91),
  );
  final moved = marker.copyWith(
    positionParam: const LatLng(32, 36),
    alphaParam: 0.8,
    rotationParam: 45,
  );
  final line = const Polyline(
    polylineId: PolylineId('l'),
    width: 4,
  ).copyWith(colorParam: Colors.blue, widthParam: 6);
  final area = const Polygon(
    polygonId: PolygonId('p'),
  ).copyWith(fillColorParam: Colors.green, strokeWidthParam: 3);
  final circle = const Circle(
    circleId: CircleId('c'),
  ).copyWith(radiusParam: 500, centerParam: const LatLng(31.9, 35.9));
  final icon = BitmapDescriptor.bytes(iconBytes, width: 48);
  final info = const InfoWindow(title: 'a').copyWith(snippetParam: 'b');

  return GoogleMap(
    initialCameraPosition: const CameraPosition(
      target: LatLng(31.95, 35.91),
      zoom: 12,
    ),
    mapId: 'DEMO_MAP_ID',
    markers: {moved.copyWith(iconParam: icon, infoWindowParam: info)},
    polylines: {line},
    polygons: {area},
    circles: {circle},
  );
}
