import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:siro_gl_compat/siro_gl_compat.dart';

const Map<String, Object> _searchBody = {
  'results': [
    {
      'id': 'regional_JO_1',
      'name': 'Zarqa',
      'name_ar': 'الزرقاء',
      'category': 'place',
      'address': '',
      'latitude': 32.06331,
      'longitude': 36.08184,
      'distance': 20216.5,
    },
  ],
};

http.Response _jsonResponse(Object body, int status) {
  return http.Response.bytes(
    utf8.encode(jsonEncode(body)),
    status,
    headers: {'content-type': 'application/json; charset=utf-8'},
  );
}

SiroGeocoder _geocoderReturning(
  http.Response response, {
  void Function(http.Request request)? onRequest,
}) {
  final client = MockClient((request) async {
    onRequest?.call(request);
    return response;
  });
  return SiroGeocoder(apiKey: 'in_pub_test', client: client);
}

void main() {
  group('SiroGeocoder', () {
    test('sends the query, the bias point, the country and the key', () async {
      late http.Request sent;
      final geocoder = _geocoderReturning(
        _jsonResponse(_searchBody, 200),
        onRequest: (request) => sent = request,
      );

      await geocoder.search(
        ' Zarqa ',
        near: const LatLng(31.9539, 35.9106),
        country: 'JO',
        radiusMeters: 30000,
      );

      expect(sent.url.path, '/api/geocoding/search');
      expect(sent.url.queryParameters['q'], 'Zarqa');
      expect(
        double.parse(sent.url.queryParameters['lat']!),
        closeTo(31.9539, 1e-9),
      );
      expect(
        double.parse(sent.url.queryParameters['lng']!),
        closeTo(35.9106, 1e-9),
      );
      expect(sent.url.queryParameters['country'], 'JO');
      expect(sent.url.queryParameters['radius'], '30000');
      expect(sent.headers['x-api-key'], 'in_pub_test');
    });

    test('parses results into places with the Arabic name first', () async {
      final geocoder = _geocoderReturning(
        _jsonResponse(_searchBody, 200),
      );

      final places = await geocoder.search('Zarqa');

      expect(places.length, 1);
      expect(places.single.displayName, 'الزرقاء');
      expect(places.single.position.latitude, closeTo(32.06331, 1e-6));
      expect(places.single.position.longitude, closeTo(36.08184, 1e-6));
      expect(places.single.distanceMeters, closeTo(20216.5, 1e-3));
    });

    test('an empty result list is an empty list, not an error', () async {
      final geocoder = _geocoderReturning(
        _jsonResponse({'results': []}, 200),
      );

      expect(await geocoder.search('nowhere'), isEmpty);
    });

    test('a non-200 response throws a SiroGeocodingException', () async {
      final geocoder = _geocoderReturning(http.Response('nope', 401));

      await expectLater(
        geocoder.search('Zarqa'),
        throwsA(isA<SiroGeocodingException>()),
      );
    });

    test('an empty key fails before any request is made', () async {
      var requests = 0;
      final client = MockClient((request) async {
        requests++;
        return http.Response('{}', 200);
      });
      final geocoder = SiroGeocoder(apiKey: '', client: client);

      await expectLater(
        geocoder.search('Zarqa'),
        throwsA(isA<SiroGeocodingException>()),
      );
      expect(requests, 0);
    });
  });

  group('SiroSearchBar', () {
    testWidgets('typing searches and picking a result reports the place', (
      tester,
    ) async {
      final geocoder = _geocoderReturning(
        _jsonResponse(_searchBody, 200),
      );
      SiroPlace? picked;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SiroSearchBar(
              geocoder: geocoder,
              country: 'JO',
              onSelected: (place) => picked = place,
            ),
          ),
        ),
      );

      await tester.enterText(find.byType(TextField), 'Zarqa');
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pumpAndSettle();

      expect(find.text('الزرقاء'), findsOneWidget);

      await tester.tap(find.text('الزرقاء'));
      await tester.pumpAndSettle();

      expect(picked, isNotNull);
      expect(picked!.id, 'regional_JO_1');
    });

    testWidgets('one character does not search', (tester) async {
      var requests = 0;
      final client = MockClient((request) async {
        requests++;
        return _jsonResponse(_searchBody, 200);
      });

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SiroSearchBar(
              geocoder: SiroGeocoder(apiKey: 'k', client: client),
              onSelected: (_) {},
            ),
          ),
        ),
      );

      await tester.enterText(find.byType(TextField), 'Z');
      await tester.pump(const Duration(seconds: 1));
      await tester.pumpAndSettle();

      expect(requests, 0);
    });
  });
}
