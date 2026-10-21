import 'package:flutter/material.dart';
import 'package:siro_gl/siro_gl.dart';
import '../../page.dart';
import '../../shared/shared.dart';
import '../../shared/siro_api.dart';

/// Draws a driving route from our routing API on the map: Amman to Zarqa.
class RouteExample extends ExamplePage {
  const RouteExample({super.key})
    : super(
        const Icon(Icons.route),
        'Route: Amman to Zarqa',
        category: ExampleCategory.basics,
      );

  @override
  Widget build(BuildContext context) => const _RouteBody();
}

class _RouteBody extends StatefulWidget {
  const _RouteBody();

  @override
  State<_RouteBody> createState() => _RouteBodyState();
}

class _RouteBodyState extends State<_RouteBody> {
  static const _amman = LatLng(31.9539, 35.9106);
  static const _zarqa = LatLng(32.0728, 36.0880);

  final _api = SiroApi();
  SiroMapController? _controller;
  Line? _line;
  bool _busy = false;
  String? _summary;
  String? _error;

  void _onMapCreated(SiroMapController controller) {
    _controller = controller;
  }

  Future<void> _drawRoute() async {
    final controller = _controller;
    if (controller == null || _busy) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final route = await _api.route(_amman, _zarqa);
      final old = _line;
      if (old != null) await controller.removeLine(old);
      final line = await controller.addLine(
        LineOptions(
          geometry: route.points,
          lineColor: '#1976D2',
          lineWidth: 6,
          lineOpacity: 0.9,
        ),
      );
      await controller.animateCamera(
        CameraUpdate.newLatLngBounds(
          route.bounds,
          left: 40,
          top: 40,
          right: 40,
          bottom: 40,
        ),
      );
      if (!mounted) return;
      setState(() {
        _line = line;
        _summary =
            '${(route.distanceMeters / 1000).toStringAsFixed(1)} km, '
            '${(route.durationSeconds / 60).round()} min';
      });
    } catch (error) {
      if (mounted) setState(() => _error = '$error');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return MapExampleScaffold(
      map: SiroMap(
        styleString: ExampleConstants.sovereignMapStyle,
        onMapCreated: _onMapCreated,
        initialCameraPosition: const CameraPosition(target: _amman, zoom: 9),
        logoEnabled: false,
      ),
      controls: [
        ControlGroup(
          title: 'Routing (Siro server)',
          children: [
            TextButton(
              onPressed: _busy ? null : _drawRoute,
              child: Text(
                _busy ? 'Drawing route...' : 'Draw route Amman → Zarqa',
              ),
            ),
            if (_summary != null)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(_summary!),
              ),
            if (_error != null)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(_error!, style: const TextStyle(color: Colors.red)),
              ),
          ],
        ),
      ],
    );
  }
}
