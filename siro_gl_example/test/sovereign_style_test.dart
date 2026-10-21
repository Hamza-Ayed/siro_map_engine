@TestOn('vm')
library;

import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Every host the Siro styles name must be ours. A third-party host in a style
/// means the map depends on that host at runtime, which the data-sovereignty
/// rule forbids.
const _allowedHosts = {'map-saas.intaleqapp.com', 'tiles.intaleqapp.com'};

const _styleNames = [
  'style-sovereign.json',
  'style-sovereign-night.json',
  'style-sovereign-tactical.json',
];

File _styleFile(String name) =>
    File('../../../apps/consumer-map/public/siro/$name');

Iterable<String> _urls(Object? node) sync* {
  if (node is Map) {
    for (final value in node.values) {
      yield* _urls(value);
    }
  } else if (node is List) {
    for (final value in node) {
      yield* _urls(value);
    }
  } else if (node is String && node.startsWith('http')) {
    yield node;
  }
}

void main() {
  for (final name in _styleNames) {
    test('$name names only our hosts', () {
      final file = _styleFile(name);
      expect(
        file.existsSync(),
        isTrue,
        reason: 'style file missing: ${file.path}',
      );
      final style = jsonDecode(file.readAsStringSync());
      final hosts = _urls(
        style,
      ).map((url) => Uri.parse(url.split('{').first).host);

      final external = hosts.where((host) => !_allowedHosts.contains(host));
      expect(external, isEmpty, reason: 'third-party hosts in $name');
    });
  }

  test('the day style uses the glyphs we host', () {
    final style =
        jsonDecode(_styleFile('style-sovereign.json').readAsStringSync())
            as Map;
    expect(
      style['glyphs'],
      'https://map-saas.intaleqapp.com/fonts/{fontstack}/{range}.pbf',
    );
  });
}
