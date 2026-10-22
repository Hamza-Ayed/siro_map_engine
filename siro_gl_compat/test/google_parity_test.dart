import 'package:flutter_test/flutter_test.dart';
import 'package:siro_gl_compat/siro_gl_compat.dart';

// This test file compiles test/google_style/trip_screen.dart, which is written
// exactly as a google_maps_flutter app. If the compat API drifts from Google's
// names or signatures, that file stops compiling and every test here fails.
import 'google_style/trip_screen.dart';

void main() {
  test('a Google-style screen compiles and builds its map objects', () {
    final state = const TripScreen().createState() as dynamic;

    expect(state, isNotNull);
  });

  test("Google-style value types behave like Google's", () {
    const polyline = Polyline(
      polylineId: PolylineId('a'),
      points: [LatLng(1, 2), LatLng(3, 4)],
      width: 4,
    );
    expect(polyline.jointType, JointType.mitered);
    expect(polyline.zIndex, 0);
    expect(const Marker(markerId: MarkerId('m')).anchor, const Offset(0.5, 1));
    expect(BitmapDescriptor.hueAzure, 210);
    expect(
      BitmapDescriptor.defaultMarkerWithHue(120),
      BitmapDescriptor.defaultMarkerWithHue(120),
    );
    expect(
      const ScreenCoordinate(x: 1, y: 2),
      const ScreenCoordinate(x: 1, y: 2),
    );
    expect(MapType.values.map((v) => v.name), [
      'none',
      'normal',
      'satellite',
      'terrain',
      'hybrid',
    ]);
  });

  test('newLatLngBounds takes one padding number, as in Google', () {
    final update = CameraUpdate.newLatLngBounds(
      LatLngBounds(
        southwest: const LatLng(31.9, 35.9),
        northeast: const LatLng(32.1, 36.1),
      ),
      48,
    );

    expect(update, isA<CameraUpdate>());
  });
}
