import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:maplibre_gl_example/examples/advanced/bench_stats.dart';

void main() {
  group('benchMean', () {
    test('averages values', () {
      expect(benchMean([1, 2, 3, 4]), 2.5);
    });

    test('returns NaN for an empty list', () {
      expect(benchMean([]).isNaN, isTrue);
    });
  });

  group('benchStdDev', () {
    test('uses the sample standard deviation (n - 1)', () {
      // Mean 5, squared deviations sum to 32, sample variance 32 / 7.
      final expected = math.sqrt(32 / 7);
      expect(
        benchStdDev([2, 4, 4, 4, 5, 5, 7, 9]),
        closeTo(expected, 1e-12),
      );
    });

    test('is zero for fewer than two values', () {
      expect(benchStdDev([]), 0);
      expect(benchStdDev([3]), 0);
    });
  });

  group('benchPercentile', () {
    test('interpolates between ranks', () {
      expect(benchPercentile([1, 2, 3, 4, 5], 0.5), 3);
      expect(benchPercentile([1, 2, 3, 4], 0.5), 2.5);
    });

    test('p95 of 1..100 is 95.05 with linear interpolation', () {
      final values = [for (var i = 1; i <= 100; i++) i.toDouble()];
      expect(benchPercentile(values, 0.95), closeTo(95.05, 1e-9));
    });

    test('does not depend on input order', () {
      expect(benchPercentile([5, 1, 4, 2, 3], 0.5), 3);
    });
  });

  group('benchFps', () {
    test('frames over elapsed time', () {
      expect(benchFps(600, const Duration(seconds: 10)), 60);
    });

    test('is zero for a zero duration', () {
      expect(benchFps(10, Duration.zero), 0);
    });
  });

  group('benchDistanceMeters', () {
    test('one degree of latitude is about 111.2 km', () {
      final d = benchDistanceMeters((lat: 0, lon: 0), (lat: 1, lon: 0));
      expect(d, closeTo(111195, 50));
    });

    test('is zero for identical points', () {
      expect(
        benchDistanceMeters((lat: 31.95, lon: 35.91), (lat: 31.95, lon: 35.91)),
        0,
      );
    });
  });

  group('benchBearingDegrees', () {
    const origin = (lat: 0.0, lon: 0.0);

    test('north is 0', () {
      expect(benchBearingDegrees(origin, (lat: 1, lon: 0)), closeTo(0, 1e-9));
    });

    test('east is 90', () {
      expect(benchBearingDegrees(origin, (lat: 0, lon: 1)), closeTo(90, 1e-9));
    });

    test('south is 180', () {
      expect(
        benchBearingDegrees(origin, (lat: -1, lon: 0)),
        closeTo(180, 1e-9),
      );
    });

    test('west is 270, never negative', () {
      expect(
        benchBearingDegrees(origin, (lat: 0, lon: -1)),
        closeTo(270, 1e-9),
      );
    });
  });

  group('BenchRoute', () {
    // Three points on the equator, roughly 1 km apart each (0.009 deg lon).
    final route = BenchRoute([
      (lat: 0, lon: 0),
      (lat: 0, lon: 0.009),
      (lat: 0, lon: 0.018),
    ]);

    test('length is the sum of segment lengths', () {
      final segment = benchDistanceMeters(
        (lat: 0, lon: 0),
        (lat: 0, lon: 0.009),
      );
      expect(route.lengthMeters, closeTo(2 * segment, 1e-6));
    });

    test('start and end fractions hit the endpoints', () {
      final start = route.at(0);
      final end = route.at(1);
      expect(start.lon, closeTo(0, 1e-12));
      expect(end.lon, closeTo(0.018, 1e-12));
    });

    test('middle fraction is the middle point', () {
      final middle = route.at(0.5);
      expect(middle.lon, closeTo(0.009, 1e-9));
      expect(middle.lat, closeTo(0, 1e-12));
    });

    test('heading follows the segment being walked', () {
      expect(route.at(0.25).bearing, closeTo(90, 1e-6));
    });

    test('fractions outside 0..1 are clamped', () {
      expect(route.at(-1).lon, closeTo(0, 1e-12));
      expect(route.at(2).lon, closeTo(0.018, 1e-12));
    });

    test('zero-length segments do not divide by zero', () {
      final degenerate = BenchRoute([
        (lat: 0, lon: 0),
        (lat: 0, lon: 0),
        (lat: 0, lon: 0.01),
      ]);
      final point = degenerate.at(0.5);
      expect(point.lon.isFinite, isTrue);
      expect(point.bearing.isFinite, isTrue);
    });
  });
}
