import 'dart:async';

import 'package:flutter/material.dart';
// The one import that changes when moving from google_maps_flutter:
import 'package:siro_gl_compat/siro_gl_compat.dart';
import '../../page.dart';
import '../../shared/siro_api.dart';

/// Google Maps Flutter API on Siro's engine: a route, a polygon, a circle, a
/// marker and a search bar, with the same widget and types as
/// google_maps_flutter.
class GoogleCompatExample extends ExamplePage {
  const GoogleCompatExample({super.key})
    : super(
        const Icon(Icons.layers),
        'Google Maps API on Siro',
        category: ExampleCategory.basics,
      );

  @override
  Widget build(BuildContext context) => const _GoogleCompatBody();
}

class _GoogleCompatBody extends StatefulWidget {
  const _GoogleCompatBody();

  @override
  State<_GoogleCompatBody> createState() => _GoogleCompatBodyState();
}

class _GoogleCompatBodyState extends State<_GoogleCompatBody> {
  static const _amman = LatLng(31.9539, 35.9106);
  static const _zarqa = LatLng(32.0728, 36.0880);

  final _api = SiroApi();
  final _geocoder = SiroGeocoder(apiKey: SiroApi.publicKey);
  GoogleMapController? _map;
  Set<Polyline> _polylines = {};
  SiroPlace? _picked;
  final Set<Marker> _tapped = {};
  bool _night = false;
  String? _status;

  @override
  void initState() {
    super.initState();
    unawaited(_loadRoute());
  }

  Future<void> _loadRoute() async {
    try {
      final route = await _api.route(_amman, _zarqa);
      if (!mounted) return;
      setState(() {
        _polylines = {
          Polyline(
            polylineId: PolylineId('amman-dashed'),
            points: [_amman, LatLng(31.9, 35.85)],
            color: Color(0xFFE53935),
            width: 4,
            patterns: [PatternItem.dash(20), PatternItem.gap(10)],
          ),
          Polyline(
            polylineId: const PolylineId('amman-zarqa'),
            points: route.points,
            color: const Color(0xFF1976D2),
            width: 6,
          ),
        };
        _status =
            '${(route.distanceMeters / 1000).toStringAsFixed(1)} km, '
            '${(route.durationSeconds / 60).round()} min';
      });
    } catch (error) {
      if (mounted) setState(() => _status = '$error');
    }
  }

  Future<void> _onPlacePicked(SiroPlace place) async {
    setState(() => _picked = place);
    await _map?.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(target: place.position, zoom: 14),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        GoogleMap(
          initialCameraPosition: const CameraPosition(target: _amman, zoom: 10),
          onMapCreated: (controller) => _map = controller,
          colorScheme: _night ? MapColorScheme.dark : MapColorScheme.light,
          onTap:
              (position) => setState(() {
                _tapped.add(
                  Marker(
                    markerId: MarkerId('tap-${_tapped.length}'),
                    position: position,
                    infoWindow: InfoWindow(
                      title: 'Dropped pin',
                      snippet:
                          '${position.latitude.toStringAsFixed(4)}, '
                          '${position.longitude.toStringAsFixed(4)}',
                    ),
                  ),
                );
              }),
          polylines: _polylines,
          polygons: {
            const Polygon(
              polygonId: PolygonId('zarqa-box'),
              points: [
                LatLng(32.02, 36.03),
                LatLng(32.02, 36.14),
                LatLng(32.12, 36.14),
                LatLng(32.12, 36.03),
              ],
              fillColor: Color(0x3381C784),
              strokeColor: Color(0xFF2E7D32),
              strokeWidth: 2,
            ),
          },
          circles: {
            const Circle(
              circleId: CircleId('amman-2km'),
              center: _amman,
              radius: 2000,
              fillColor: Color(0x331976D2),
              strokeColor: Color(0xFF1976D2),
              strokeWidth: 2,
            ),
          },
          markers: {
            const Marker(
              markerId: MarkerId('amman'),
              position: _amman,
              infoWindow: InfoWindow(title: 'Amman', snippet: 'Jordan'),
            ),
            ..._tapped,
            if (_picked != null)
              Marker(
                markerId: const MarkerId('picked'),
                position: _picked!.position,
                infoWindow: InfoWindow(title: _picked!.displayName),
              ),
          },
        ),
        Positioned(
          top: 12,
          left: 12,
          right: 12,
          child: SiroSearchBar(
            geocoder: _geocoder,
            near: _amman,
            country: 'JO',
            onSelected: _onPlacePicked,
          ),
        ),
        Positioned(
          top: 76,
          right: 12,
          child: FilterChip(
            label: Text(_night ? 'Night' : 'Day'),
            selected: _night,
            onSelected: (value) => setState(() => _night = value),
          ),
        ),
        if (_status != null)
          Positioned(
            bottom: 12,
            left: 0,
            right: 0,
            child: Center(child: Chip(label: Text(_status!))),
          ),
      ],
    );
  }
}
