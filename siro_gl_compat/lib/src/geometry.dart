import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:siro_gl/siro_gl.dart' show LatLng;

const _earthRadiusMeters = 6371000.0;

/// A circle of [radiusMeters] around [center] as a ring of [points] vertices,
/// computed on the sphere, so its size is correct in metres at any latitude.
List<LatLng> geodesicCircle(
  LatLng center,
  double radiusMeters, {
  int points = 64,
}) {
  final angular = radiusMeters / _earthRadiusMeters;
  final lat1 = center.latitude * math.pi / 180;
  final lng1 = center.longitude * math.pi / 180;
  final ring = <LatLng>[];
  for (var i = 0; i < points; i++) {
    final bearing = 2 * math.pi * i / points;
    final lat2 = math.asin(
      math.sin(lat1) * math.cos(angular) +
          math.cos(lat1) * math.sin(angular) * math.cos(bearing),
    );
    final lng2 =
        lng1 +
        math.atan2(
          math.sin(bearing) * math.sin(angular) * math.cos(lat1),
          math.cos(angular) - math.sin(lat1) * math.sin(lat2),
        );
    ring.add(LatLng(lat2 * 180 / math.pi, lng2 * 180 / math.pi));
  }
  return ring;
}

/// A CSS `rgba(...)` string for the native engine, from a Flutter colour.
String colorToCss(Color color) {
  final r = (color.r * 255).round();
  final g = (color.g * 255).round();
  final b = (color.b * 255).round();
  return 'rgba($r, $g, $b, ${color.a.toStringAsFixed(3)})';
}
