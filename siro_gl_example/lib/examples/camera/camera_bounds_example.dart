import 'package:flutter/material.dart';
import 'package:siro_gl/siro_gl.dart';
import '../../page.dart';
import '../../shared/shared.dart';

/// Example demonstrating camera bounds and constraints
class CameraBoundsExample extends ExamplePage {
  const CameraBoundsExample({super.key})
    : super(
        const Icon(Icons.crop),
        'Camera Bounds & Constraints',
        category: ExampleCategory.camera,
      );

  @override
  Widget build(BuildContext context) => const _CameraBoundsBody();
}

class _CameraBoundsBody extends StatefulWidget {
  const _CameraBoundsBody();

  @override
  State<_CameraBoundsBody> createState() => _CameraBoundsBodyState();
}

class _CameraBoundsBodyState extends State<_CameraBoundsBody> {
  SiroMapController? _controller;
  LatLngBounds? _currentBounds;
  LatLngBounds? _constrainedBounds;
  double? _minZoom;
  double? _maxZoom;

  // Predefined bounds
  static final _ammanBounds = LatLngBounds(
    southwest: const LatLng(31.8, 35.75),
    northeast: const LatLng(32.1, 36.1),
  );

  static final _aqabaBounds = LatLngBounds(
    southwest: const LatLng(29.45, 34.95),
    northeast: const LatLng(29.6, 35.1),
  );

  static final _jordanBounds = LatLngBounds(
    southwest: const LatLng(29.0, 34.9),
    northeast: const LatLng(33.4, 39.3),
  );

  Future<void> _onMapCreated(SiroMapController controller) async {
    _controller = controller;
    await _updateInfo();
  }

  Future<void> _updateInfo() async {
    if (_controller == null) return;
    final bounds = await _controller!.getVisibleRegion();
    if (mounted) {
      setState(() => _currentBounds = bounds);
    }
  }

  Future<void> _setBounds(LatLngBounds bounds, String name) async {
    if (_controller == null) return;
    var padding = 150.0;
    if (bounds == _jordanBounds) padding = 50.0;

    await _controller!.animateCamera(
      CameraUpdate.newLatLngBounds(
        bounds,
        left: padding,
        top: padding,
        right: padding,
        bottom: padding,
      ),
    );

    _updateInfo();
  }

  Future<void> _setMinZoom(double zoom) async {
    if (_controller == null) return;
    // Note: min/max zoom can be set via style, initial confing or options.
    setState(() => _minZoom = zoom);
  }

  Future<void> _setMaxZoom(double zoom) async {
    if (_controller == null) return;
    setState(() => _maxZoom = zoom);
  }

  Future<void> _clearZoomConstraints() async {
    if (_controller == null) return;
    setState(() {
      _minZoom = null;
      _maxZoom = null;
    });
  }

  Future<void> _setCameraBounds(LatLngBounds bounds, String name) async {
    if (_controller == null) return;

    final adjustedBounds = LatLngBounds(
      southwest: LatLng(
        bounds.southwest.latitude - 0.2,
        bounds.southwest.longitude - 0.2,
      ),
      northeast: LatLng(
        bounds.northeast.latitude + 0.2,
        bounds.northeast.longitude + 0.2,
      ),
    );

    setState(() => _constrainedBounds = adjustedBounds);
  }

  Future<void> _clearCameraBounds() async {
    if (_controller == null) return;
    setState(() => _constrainedBounds = null);
  }

  @override
  Widget build(BuildContext context) {
    final hasController = _controller != null;
    final boundsInfo =
        _currentBounds != null
            ? 'SW: ${_currentBounds!.southwest.latitude.toStringAsFixed(2)}, ${_currentBounds!.southwest.longitude.toStringAsFixed(2)}\n'
                'NE: ${_currentBounds!.northeast.latitude.toStringAsFixed(2)}, ${_currentBounds!.northeast.longitude.toStringAsFixed(2)}'
            : 'Loading...';

    return MapExampleScaffold(
      map: SiroMap(
        styleString: ExampleConstants.demoMapStyle,
        onMapCreated: _onMapCreated,
        onCameraIdle: _updateInfo,
        trackCameraPosition: true,
        initialCameraPosition: ExampleConstants.defaultCameraPosition,
        minMaxZoomPreference: MinMaxZoomPreference(_minZoom, _maxZoom),
        cameraTargetBounds:
            _constrainedBounds != null
                ? CameraTargetBounds(_constrainedBounds)
                : CameraTargetBounds.unbounded,
      ),
      controls: [
        InfoCard(
          title: 'Visible Bounds',
          subtitle: boundsInfo,
          icon: Icons.crop,
        ),
        if (_minZoom != null || _maxZoom != null)
          InfoCard(
            title: 'Zoom Constraints',
            subtitle:
                'Min: ${_minZoom?.toStringAsFixed(0) ?? "None"} | Max: ${_maxZoom?.toStringAsFixed(0) ?? "None"}',
            icon: Icons.lock,
            color: Colors.orange.shade100,
          ),
        if (_constrainedBounds != null)
          InfoCard(
            title: 'Camera Target Bounds',
            subtitle: 'Panning restricted to defined region',
            icon: Icons.lock_outline,
            color: Colors.red.shade100,
          ),
        const SizedBox(height: 8),
        ControlGroup(
          title: 'Move to Bounds',
          children: [
            ExampleButton(
              label: 'Amman',
              icon: Icons.map,
              onPressed:
                  hasController
                      ? () => _setBounds(_ammanBounds, 'Amman')
                      : null,
            ),
            ExampleButton(
              label: 'Aqaba',
              icon: Icons.map,
              onPressed:
                  hasController
                      ? () => _setBounds(_aqabaBounds, 'Aqaba')
                      : null,
            ),
            ExampleButton(
              label: 'Jordan',
              icon: Icons.map,
              onPressed:
                  hasController
                      ? () => _setBounds(_jordanBounds, 'Jordan')
                      : null,
            ),
          ],
        ),
        const SizedBox(height: 8),
        ControlGroup(
          title: 'Zoom Limits',
          children: [
            ExampleButton(
              label: 'Min Zoom: 3',
              icon: Icons.zoom_out,
              onPressed: hasController ? () => _setMinZoom(3) : null,
              style: ExampleButtonStyle.tonal,
            ),
            ExampleButton(
              label: 'Max Zoom: 8',
              icon: Icons.zoom_in,
              onPressed: hasController ? () => _setMaxZoom(8) : null,
              style: ExampleButtonStyle.tonal,
            ),
            ExampleButton(
              label: 'Clear',
              icon: Icons.clear,
              onPressed:
                  hasController && (_minZoom != null || _maxZoom != null)
                      ? _clearZoomConstraints
                      : null,
              style: ExampleButtonStyle.outlined,
            ),
          ],
        ),
        ControlGroup(
          title: 'Camera Target Bounds',
          children: [
            ExampleButton(
              label: 'Lock to Amman',
              icon: Icons.lock,
              onPressed:
                  hasController
                      ? () => _setCameraBounds(_ammanBounds, 'Amman')
                      : null,
              style: ExampleButtonStyle.tonal,
            ),
            ExampleButton(
              label: 'Lock to SF',
              icon: Icons.lock,
              onPressed:
                  hasController
                      ? () => _setCameraBounds(_aqabaBounds, 'Aqaba')
                      : null,
              style: ExampleButtonStyle.tonal,
            ),
            ExampleButton(
              label: 'Lock to Jordan',
              icon: Icons.lock,
              onPressed:
                  hasController
                      ? () => _setCameraBounds(_jordanBounds, 'Jordan')
                      : null,
              style: ExampleButtonStyle.tonal,
            ),
            ExampleButton(
              label: 'Clear',
              icon: Icons.clear,
              onPressed:
                  hasController && _constrainedBounds != null
                      ? _clearCameraBounds
                      : null,
              style: ExampleButtonStyle.outlined,
            ),
          ],
        ),
      ],
    );
  }
}
