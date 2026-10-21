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

/// Points along the great circle through [points], so a line drawn with
/// `geodesic: true` follows the curve of the earth. Segments shorter than
/// [stepMeters] are left as they are.
List<LatLng> geodesicLine(List<LatLng> points, {double stepMeters = 50000}) {
  if (points.length < 2) return points;
  final out = <LatLng>[points.first];
  for (var i = 1; i < points.length; i++) {
    final a = points[i - 1];
    final b = points[i];
    final lat1 = a.latitude * math.pi / 180;
    final lng1 = a.longitude * math.pi / 180;
    final lat2 = b.latitude * math.pi / 180;
    final lng2 = b.longitude * math.pi / 180;
    final dLat = lat2 - lat1;
    final dLng = lng2 - lng1;
    final h =
        math.pow(math.sin(dLat / 2), 2) +
        math.cos(lat1) * math.cos(lat2) * math.pow(math.sin(dLng / 2), 2);
    final angular = 2 * math.asin(math.sqrt(h.toDouble()));
    final steps = (angular * _earthRadiusMeters / stepMeters).floor();
    for (var s = 1; s <= steps; s++) {
      final f = s / (steps + 1);
      final sinAngular = math.sin(angular);
      if (sinAngular == 0) break;
      final k1 = math.sin((1 - f) * angular) / sinAngular;
      final k2 = math.sin(f * angular) / sinAngular;
      final x =
          k1 * math.cos(lat1) * math.cos(lng1) +
          k2 * math.cos(lat2) * math.cos(lng2);
      final y =
          k1 * math.cos(lat1) * math.sin(lng1) +
          k2 * math.cos(lat2) * math.sin(lng2);
      final z = k1 * math.sin(lat1) + k2 * math.sin(lat2);
      out.add(
        LatLng(
          math.atan2(z, math.sqrt(x * x + y * y)) * 180 / math.pi,
          math.atan2(y, x) * 180 / math.pi,
        ),
      );
    }
    out.add(b);
  }
  return out;
}

/// Google's dash pattern in pixels, as the engine's dash array in line-width
/// units. Alternating dash and gap lengths; a zero-length item is a dot. An
/// odd count repeats, as in Google, and a single item is doubled, because a
/// dash array needs an even count. Returns null for no pattern.
List<double>? dashArrayFor(List<double> patternPixels, int width) {
  if (patternPixels.isEmpty) return null;
  final unit = width <= 0 ? 1.0 : width.toDouble();
  var items = patternPixels.map((p) => math.max(p.abs(), 0.1) / unit).toList();
  if (items.length.isOdd) items = [...items, ...items];
  return items;
}
