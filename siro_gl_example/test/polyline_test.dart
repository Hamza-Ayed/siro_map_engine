import 'package:flutter_test/flutter_test.dart';

import 'package:siro_gl_example/shared/polyline.dart';

void main() {
  test('decodes the reference Google polyline example', () {
    // Example from Google's encoded polyline documentation.
    final points = decodePolyline('_p~iF~ps|U_ulLnnqC_mqNvxq`@');

    expect(points.length, 3);
    expect(points[0].latitude, closeTo(38.5, 1e-6));
    expect(points[0].longitude, closeTo(-120.2, 1e-6));
    expect(points[1].latitude, closeTo(40.7, 1e-6));
    expect(points[1].longitude, closeTo(-120.95, 1e-6));
    expect(points[2].latitude, closeTo(43.252, 1e-6));
    expect(points[2].longitude, closeTo(-126.453, 1e-6));
  });

  test('an empty string decodes to no points', () {
    expect(decodePolyline(''), isEmpty);
  });
}
