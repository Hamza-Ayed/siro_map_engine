import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:siro_gl/siro_gl.dart' show LatLng;

/// A place returned by the Siro geocoding search.
@immutable
class SiroPlace {
  const SiroPlace({
    required this.id,
    required this.name,
    required this.position,
    this.nameAr,
    this.category = '',
    this.address = '',
    this.distanceMeters,
  });

  /// Reads one entry of the `results` list of `/api/geocoding/search`.
  factory SiroPlace.fromJson(Map<String, dynamic> json) {
    return SiroPlace(
      id: '${json['id']}',
      name: '${json['name'] ?? ''}',
      nameAr: json['name_ar'] is String ? json['name_ar'] as String : null,
      category: '${json['category'] ?? ''}',
      address: '${json['address'] ?? ''}',
      position: LatLng(
        (json['latitude'] as num).toDouble(),
        (json['longitude'] as num).toDouble(),
      ),
      distanceMeters:
          json['distance'] is num ? (json['distance'] as num).toDouble() : null,
    );
  }

  final String id;
  final String name;
  final String? nameAr;
  final String category;
  final String address;
  final LatLng position;

  /// Distance from the search centre, when the search had one.
  final double? distanceMeters;

  /// The Arabic name when we have one, otherwise the name.
  String get displayName =>
      (nameAr != null && nameAr!.isNotEmpty) ? nameAr! : name;

  @override
  bool operator ==(Object other) =>
      other is SiroPlace && other.id == id && other.position == position;

  @override
  int get hashCode => Object.hash(id, position);
}

class SiroGeocodingException implements Exception {
  SiroGeocodingException(this.message);
  final String message;

  @override
  String toString() => 'SiroGeocodingException: $message';
}

/// Client for the Siro geocoding API. Every request goes to our own server.
class SiroGeocoder {
  SiroGeocoder({
    required this.apiKey,
    this.baseUrl = defaultBaseUrl,
    http.Client? client,
  }) : _client = client ?? http.Client();

  static const defaultBaseUrl = 'https://map-saas.intaleqapp.com';

  /// The publishable client key, sent as the `x-api-key` header.
  final String apiKey;
  final String baseUrl;
  final http.Client _client;

  /// Searches places by name. [near] biases the results towards a point,
  /// [country] is an ISO code such as `JO`.
  Future<List<SiroPlace>> search(
    String query, {
    LatLng? near,
    String? country,
    int? radiusMeters,
  }) async {
    final params = <String, String>{'q': query.trim()};
    if (near != null) {
      params['lat'] = '${near.latitude}';
      params['lng'] = '${near.longitude}';
    }
    if (country != null) params['country'] = country;
    if (radiusMeters != null) params['radius'] = '$radiusMeters';

    final json = await _get('/api/geocoding/search', params);
    final results = (json['results'] as List?) ?? const [];
    return [
      for (final item in results)
        SiroPlace.fromJson(item as Map<String, dynamic>),
    ];
  }

  Future<Map<String, dynamic>> _get(
    String path,
    Map<String, String> params,
  ) async {
    if (apiKey.isEmpty) {
      throw SiroGeocodingException(
        'No API key. Build with --dart-define=SIRO_PUBLIC_KEY=...',
      );
    }
    final uri = Uri.parse('$baseUrl$path').replace(queryParameters: params);
    final response = await _client
        .get(uri, headers: {'x-api-key': apiKey})
        .timeout(const Duration(seconds: 15));
    if (response.statusCode != 200) {
      throw SiroGeocodingException('HTTP ${response.statusCode}');
    }
    return jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
  }

  void close() => _client.close();
}
