import 'package:flutter_test/flutter_test.dart';
import 'package:siro_gl_compat/siro_gl_compat.dart';

void main() {
  group('dashArrayFor', () {
    test('no pattern is no dash array', () {
      expect(dashArrayFor(const [], 4), isNull);
    });

    test('pixels become line-width units', () {
      expect(dashArrayFor(const [20, 10], 5), [4, 2]);
    });

    test('an odd count repeats, as Google does', () {
      expect(dashArrayFor(const [20, 10, 5], 5), [4, 2, 1, 4, 2, 1]);
    });

    test('a single item is doubled into a valid dash array', () {
      expect(dashArrayFor(const [8], 2), [4, 4]);
    });

    test('a dot gets a short visible length, never zero', () {
      final dot = dashArrayFor(const [0, 10], 1)!;
      expect(dot.first, greaterThan(0));
    });
  });
}
