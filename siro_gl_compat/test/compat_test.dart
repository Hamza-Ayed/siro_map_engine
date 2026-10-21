import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:siro_gl_compat/siro_gl_compat.dart';

double _haversineMeters(LatLng a, LatLng b) {
  const r = 6371000.0;
  final dLat = (b.latitude - a.latitude) * math.pi / 180;
  final dLng = (b.longitude - a.longitude) * math.pi / 180;
  final h =
      math.pow(math.sin(dLat / 2), 2) +
      math.cos(a.latitude * math.pi / 180) *
          math.cos(b.latitude * math.pi / 180) *
          math.pow(math.sin(dLng / 2), 2);
  return 2 * r * math.asin(math.sqrt(h));
}

void main() {
  group('geodesicCircle', () {
    const center = LatLng(31.9539, 35.9106); // Amman

    test('every vertex is the requested radius away', () {
      final ring = geodesicCircle(center, 2000, points: 48);

      expect(ring.length, 48);
      for (final point in ring) {
        expect(_haversineMeters(center, point), closeTo(2000, 2));
      }
    });

    test('keeps its size in metres at high latitude', () {
      const north = LatLng(60, 10);
      final ring = geodesicCircle(north, 5000);

      for (final point in ring) {
        expect(_haversineMeters(north, point), closeTo(5000, 5));
      }
    });
  });

  group('colorToCss', () {
    test('formats colour and alpha for the native engine', () {
      expect(
        colorToCss(const Color.fromARGB(128, 255, 0, 0)),
        'rgba(255, 0, 0, 0.502)',
      );
    });
  });

  group('value types', () {
    test('equal polylines compare and hash equal', () {
      const a = Polyline(
        polylineId: PolylineId('route'),
        points: [LatLng(31.9, 35.9), LatLng(32.0, 36.0)],
        color: Color(0xFF1976D2),
        width: 6,
      );
      const b = Polyline(
        polylineId: PolylineId('route'),
        points: [LatLng(31.9, 35.9), LatLng(32.0, 36.0)],
        color: Color(0xFF1976D2),
        width: 6,
      );

      expect(a, b);
      expect(a.hashCode, b.hashCode);
    });

    test('a set is unchanged when it holds equal items', () {
      final before = <Circle>{
        const Circle(
          circleId: CircleId('zone'),
          center: LatLng(31.9539, 35.9106),
          radius: 1500,
        ),
      };
      final after = <Circle>{
        const Circle(
          circleId: CircleId('zone'),
          center: LatLng(31.9539, 35.9106),
          radius: 1500,
        ),
      };

      expect(setEquals(before, after), isTrue);
    });

    test('changing a radius makes the set different', () {
      const zone = CircleId('zone');
      final before = <Circle>{
        const Circle(circleId: zone, center: LatLng(31.9, 35.9), radius: 1500),
      };
      final after = <Circle>{
        const Circle(circleId: zone, center: LatLng(31.9, 35.9), radius: 2500),
      };

      expect(setEquals(before, after), isFalse);
    });
  });
}
