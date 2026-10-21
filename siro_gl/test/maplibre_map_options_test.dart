import 'package:flutter_test/flutter_test.dart';
import 'package:siro_gl/siro_gl.dart';

void main() {
  group('SiroMapOptions.updatesMap', () {
    test(
      'returns empty diff when only nested-list options (cameraTargetBounds) are equal by value',
      () {
        // Two SiroMap widgets with the *same* cameraTargetBounds value
        // (deeply nested list when serialized to JSON). The diff between
        // their derived SiroMapOptions must be empty: nothing changed,
        // so no platform update should be triggered.
        final bounds = LatLngBounds(
          southwest: const LatLng(10, 20),
          northeast: const LatLng(30, 40),
        );

        final mapA = SiroMap(
          cameraTargetBounds: CameraTargetBounds(bounds),
        );
        final mapB = SiroMap(
          cameraTargetBounds: CameraTargetBounds(
            LatLngBounds(
              southwest: const LatLng(10, 20),
              northeast: const LatLng(30, 40),
            ),
          ),
        );

        final optionsA = SiroMapOptions.fromWidget(mapA);
        final optionsB = SiroMapOptions.fromWidget(mapB);

        final diff = optionsA.updatesMap(optionsB);

        expect(
          diff,
          isEmpty,
          reason:
              'Nested-list values that are deeply equal must be detected as '
              'unchanged. Otherwise the platform receives spurious updates '
              'on every rebuild.',
        );
      },
    );

    test('detects an actual cameraTargetBounds change', () {
      final mapA = SiroMap(
        cameraTargetBounds: CameraTargetBounds(
          LatLngBounds(
            southwest: const LatLng(10, 20),
            northeast: const LatLng(30, 40),
          ),
        ),
      );
      final mapB = SiroMap(
        cameraTargetBounds: CameraTargetBounds(
          LatLngBounds(
            southwest: const LatLng(11, 21),
            northeast: const LatLng(31, 41),
          ),
        ),
      );

      final diff = SiroMapOptions.fromWidget(
        mapA,
      ).updatesMap(SiroMapOptions.fromWidget(mapB));

      expect(diff.containsKey('cameraTargetBounds'), isTrue);
    });

    test('returns empty diff when no widget property changed at all', () {
      final mapA = SiroMap();
      final mapB = SiroMap();

      final diff = SiroMapOptions.fromWidget(
        mapA,
      ).updatesMap(SiroMapOptions.fromWidget(mapB));

      expect(diff, isEmpty);
    });
  });
}
