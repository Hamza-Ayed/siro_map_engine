import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:siro_gl_compat/siro_gl_compat.dart';

/// The parts of google_maps_flutter that apps call most, checked by behaviour.
void main() {
  const amman = LatLng(31.9539, 35.9106);

  test('Marker.copyWith changes only the given fields', () {
    const marker = Marker(markerId: MarkerId('a'), position: amman, alpha: 0.5);
    final moved = marker.copyWith(
      positionParam: const LatLng(32, 36),
      rotationParam: 90,
    );
    expect(moved.markerId, marker.markerId);
    expect(moved.alpha, 0.5);
    expect(moved.position, const LatLng(32, 36));
    expect(moved.rotation, 90);
  });

  test('Polyline, Polygon, Circle and InfoWindow copyWith keep their ids', () {
    const line = Polyline(
      polylineId: PolylineId('l'),
      points: [amman],
      width: 4,
    );
    expect(line.copyWith(widthParam: 8).polylineId, line.polylineId);
    expect(line.copyWith(widthParam: 8).width, 8);

    const area = Polygon(
      polygonId: PolygonId('p'),
      points: [amman],
      strokeWidth: 2,
    );
    expect(area.copyWith(strokeWidthParam: 6).strokeWidth, 6);

    const circle = Circle(circleId: CircleId('c'), center: amman, radius: 100);
    expect(circle.copyWith(radiusParam: 250).radius, 250);
    expect(circle.copyWith(radiusParam: 250).center, amman);

    const info = InfoWindow(title: 'Amman');
    expect(info.copyWith(snippetParam: 'Jordan').title, 'Amman');
    expect(info.copyWith(snippetParam: 'Jordan').snippet, 'Jordan');
  });

  test('BitmapDescriptor.bytes keeps the image and its width', () {
    final bytes = Uint8List.fromList(List.filled(32, 1));
    final icon = BitmapDescriptor.bytes(bytes, width: 40);
    expect(icon.imageBytes, bytes);
    expect(icon.scale, 40);
  });

  test('scaledBytes carries the multiplier the engine draws with', () {
    final icon = BitmapDescriptor.scaledBytes(Uint8List(8), 1.8);
    expect(icon.multiplier, 1.8);
  });

  test(
    'GoogleMap accepts mapId and cloudMapId, as code written for Google passes them',
    () {
      const map = GoogleMap(
        initialCameraPosition: CameraPosition(target: amman, zoom: 12),
        mapId: 'abc',
        cloudMapId: 'def',
      );
      expect(map.mapId, 'abc');
    },
  );
}
