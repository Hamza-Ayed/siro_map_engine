import 'dart:math' as math;

/// Pure helpers for the bench page. They have no widget or map dependency, so
/// the unit tests in `test/bench_stats_test.dart` can run them directly.
typedef BenchPoint = ({double lat, double lon});

/// Arithmetic mean. Returns NaN for an empty list.
double benchMean(List<double> values) {
  if (values.isEmpty) return double.nan;
  return values.reduce((a, b) => a + b) / values.length;
}

/// Sample standard deviation (n - 1). Returns 0 for fewer than two values.
double benchStdDev(List<double> values) {
  if (values.length < 2) return 0;
  final mean = benchMean(values);
  final sumSq = values.fold<double>(
    0,
    (acc, v) => acc + (v - mean) * (v - mean),
  );
  return math.sqrt(sumSq / (values.length - 1));
}

/// Linear-interpolated percentile, [p] in 0..1. Returns NaN for an empty list.
double benchPercentile(List<double> values, double p) {
  if (values.isEmpty) return double.nan;
  final sorted = [...values]..sort();
  final rank = p.clamp(0, 1) * (sorted.length - 1);
  final low = rank.floor();
  final high = rank.ceil();
  final t = rank - low;
  return sorted[low] + (sorted[high] - sorted[low]) * t;
}

/// Frames per second for [frames] rendered over [elapsed].
double benchFps(int frames, Duration elapsed) {
  if (elapsed.inMicroseconds == 0) return 0;
  return frames * Duration.microsecondsPerSecond / elapsed.inMicroseconds;
}

/// Great-circle distance in metres (haversine).
double benchDistanceMeters(BenchPoint a, BenchPoint b) {
  const earthRadius = 6371000.0;
  final lat1 = _radians(a.lat);
  final lat2 = _radians(b.lat);
  final dLat = _radians(b.lat - a.lat);
  final dLon = _radians(b.lon - a.lon);
  final h =
      math.pow(math.sin(dLat / 2), 2) +
      math.cos(lat1) * math.cos(lat2) * math.pow(math.sin(dLon / 2), 2);
  return 2 * earthRadius * math.asin(math.sqrt(h));
}

/// Initial bearing from [a] to [b], in degrees clockwise from north (0..360).
double benchBearingDegrees(BenchPoint a, BenchPoint b) {
  final lat1 = _radians(a.lat);
  final lat2 = _radians(b.lat);
  final dLon = _radians(b.lon - a.lon);
  final y = math.sin(dLon) * math.cos(lat2);
  final x =
      math.cos(lat1) * math.sin(lat2) -
      math.sin(lat1) * math.cos(lat2) * math.cos(dLon);
  return (_degrees(math.atan2(y, x)) + 360) % 360;
}

double _radians(double degrees) => degrees * math.pi / 180;

double _degrees(double radians) => radians * 180 / math.pi;

/// A polyline with precomputed cumulative lengths, so the camera can be placed
/// at any fraction of the total length.
class BenchRoute {
  BenchRoute(this.points)
    : assert(points.length >= 2, 'A route needs at least two points.') {
    _cumulative = List<double>.filled(points.length, 0);
    for (var i = 1; i < points.length; i++) {
      _cumulative[i] =
          _cumulative[i - 1] + benchDistanceMeters(points[i - 1], points[i]);
    }
  }

  final List<BenchPoint> points;
  late final List<double> _cumulative;

  double get lengthMeters => _cumulative.last;

  /// Position and heading at [fraction] (0..1) of the total length.
  ({double lat, double lon, double bearing}) at(double fraction) {
    final target = fraction.clamp(0, 1) * lengthMeters;
    var i = 0;
    while (i < points.length - 2 && _cumulative[i + 1] < target) {
      i++;
    }
    final a = points[i];
    final b = points[i + 1];
    final segment = _cumulative[i + 1] - _cumulative[i];
    final t = segment == 0 ? 0.0 : (target - _cumulative[i]) / segment;
    return (
      lat: a.lat + (b.lat - a.lat) * t,
      lon: a.lon + (b.lon - a.lon) * t,
      bearing: benchBearingDegrees(a, b),
    );
  }
}
