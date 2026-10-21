// This file is written exactly as an app written for google_maps_flutter.
// The only line that differs between the two worlds is the import below.
// tool/check_google_parity.sh compiles this same file against the real
// google_maps_flutter package to prove it.
import 'package:flutter/material.dart';
import 'package:siro_gl_compat/siro_gl_compat.dart';

class TripScreen extends StatefulWidget {
  const TripScreen({super.key});

  @override
  State<TripScreen> createState() => _TripScreenState();
}

class _TripScreenState extends State<TripScreen> {
  static const _amman = LatLng(31.9539, 35.9106);
  static const _zarqa = LatLng(32.0728, 36.0880);

  GoogleMapController? _controller;
  final Set<Marker> _markers = {};

  Set<Polyline> get polylines => {
    const Polyline(
      polylineId: PolylineId('route'),
      points: [_amman, _zarqa],
      color: Colors.blue,
      width: 6,
      jointType: JointType.round,
      geodesic: true,
      zIndex: 1,
    ),
  };

  Set<Polygon> get polygons => {
    const Polygon(
      polygonId: PolygonId('zone'),
      points: [
        LatLng(32.0, 36.0),
        LatLng(32.0, 36.2),
        LatLng(32.2, 36.2),
        LatLng(32.2, 36.0),
      ],
      holes: [
        [LatLng(32.05, 36.05), LatLng(32.05, 36.1), LatLng(32.1, 36.1)],
      ],
      fillColor: Color(0x331976D2),
      strokeColor: Color(0xFF1976D2),
      strokeWidth: 2,
    ),
  };

  Set<Circle> get circles => {
    const Circle(
      circleId: CircleId('pickup'),
      center: _amman,
      radius: 1500,
      fillColor: Color(0x3300AA00),
      strokeColor: Color(0xFF00AA00),
      strokeWidth: 2,
    ),
  };

  void _addMarker(LatLng position) {
    setState(() {
      _markers.add(
        Marker(
          markerId: MarkerId('${position.latitude},${position.longitude}'),
          position: position,
          alpha: 0.9,
          rotation: 15,
          infoWindow: const InfoWindow(
            title: 'Pickup',
            snippet: 'Tap to confirm',
          ),
          icon: BitmapDescriptor.defaultMarkerWithHue(
            BitmapDescriptor.hueAzure,
          ),
          onTap: () {},
        ),
      );
    });
  }

  Future<void> fitTrip() async {
    final bounds = LatLngBounds(
      southwest: const LatLng(31.9, 35.9),
      northeast: const LatLng(32.1, 36.1),
    );
    await _controller?.animateCamera(CameraUpdate.newLatLngBounds(bounds, 48));
    await _controller?.animateCamera(CameraUpdate.newLatLngZoom(_amman, 15));
    await _controller?.animateCamera(
      CameraUpdate.newCameraPosition(
        const CameraPosition(target: _amman, zoom: 14, tilt: 30),
      ),
    );
    await _controller?.moveCamera(CameraUpdate.zoomIn());
    await _controller?.moveCamera(CameraUpdate.zoomTo(12));
    await _controller?.moveCamera(CameraUpdate.scrollBy(10, 10));
    final zoom = await _controller?.getZoomLevel();
    final region = await _controller?.getVisibleRegion();
    final screen = await _controller?.getScreenCoordinate(_amman);
    final back = await _controller?.getLatLng(
      const ScreenCoordinate(x: 100, y: 200),
    );
    await _controller?.showMarkerInfoWindow(const MarkerId('x'));
    await _controller?.hideMarkerInfoWindow(const MarkerId('x'));
    debugPrint('$zoom $region $screen $back');
  }

  @override
  Widget build(BuildContext context) {
    return GoogleMap(
      initialCameraPosition: const CameraPosition(target: _amman, zoom: 12),
      mapType: MapType.normal,
      myLocationEnabled: true,
      myLocationButtonEnabled: false,
      zoomControlsEnabled: false,
      compassEnabled: true,
      rotateGesturesEnabled: true,
      tiltGesturesEnabled: false,
      minMaxZoomPreference: const MinMaxZoomPreference(3, 19),
      padding: const EdgeInsets.only(bottom: 80),
      onMapCreated: (controller) => _controller = controller,
      onTap: _addMarker,
      onLongPress: _addMarker,
      onCameraMoveStarted: () {},
      onCameraMove: (CameraPosition position) {},
      onCameraIdle: () {},
      markers: _markers,
      polylines: polylines,
      polygons: polygons,
      circles: circles,
    );
  }
}
