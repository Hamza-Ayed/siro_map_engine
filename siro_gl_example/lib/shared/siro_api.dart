import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:siro_gl/siro_gl.dart';

import 'polyline.dart';

/// A route from our routing API.
class SiroRoute {
  const SiroRoute({
    required this.points,
    required this.distanceMeters,
    required this.durationSeconds,
    required this.bounds,
  });

  final List<LatLng> points;
  final double distanceMeters;
  final double durationSeconds;
  final LatLngBounds bounds;
}

class SiroApiException implements Exception {
  SiroApiException(this.message);
  final String message;

  @override
  String toString() => 'SiroApiException: $message';
}

/// Client for the Siro server API. Every request goes to our own domain.
class SiroApi {
  SiroApi({http.Client? client}) : _client = client ?? http.Client();

  static const baseUrl = 'https://map-saas.intaleqapp.com';

  /// The publishable client key. Pass it at build time with
  /// `--dart-define=SIRO_PUBLIC_KEY=...`; it is never stored in the repo.
  static const publicKey = String.fromEnvironment('SIRO_PUBLIC_KEY');

  final http.Client _client;

  Future<SiroRoute> route(LatLng from, LatLng to) async {
    if (publicKey.isEmpty) {
      throw SiroApiException(
        'No SIRO_PUBLIC_KEY. Build with --dart-define=SIRO_PUBLIC_KEY=...',
      );
    }
    final uri = Uri.parse('$baseUrl/api/maps/route').replace(
      queryParameters: {
        'fromLat': '${from.latitude}',
        'fromLng': '${from.longitude}',
        'toLat': '${to.latitude}',
        'toLng': '${to.longitude}',
        'profile': 'car',
        'steps': 'false',
        'alternatives': 'false',
      },
    );
    final response = await _client
        .get(uri, headers: {'x-api-key': publicKey})
        .timeout(const Duration(seconds: 30));
    if (response.statusCode != 200) {
      throw SiroApiException('route returned HTTP ${response.statusCode}');
    }
    final json =
        jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
    final box = (json['bbox'] as List).cast<num>();
    return SiroRoute(
      points: decodePolyline(json['points'] as String),
      distanceMeters: (json['distance'] as num).toDouble(),
      durationSeconds: (json['duration'] as num).toDouble(),
      // bbox is [minLng, minLat, maxLng, maxLat].
      bounds: LatLngBounds(
        southwest: LatLng(box[1].toDouble(), box[0].toDouble()),
        northeast: LatLng(box[3].toDouble(), box[2].toDouble()),
      ),
    );
  }
}
