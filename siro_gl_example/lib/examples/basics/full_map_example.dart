import 'package:flutter/material.dart';
import 'package:siro_gl/siro_gl.dart';
import '../../page.dart';
import '../../shared/shared.dart';

/// Example demonstrating basic full-screen map
class FullMapExample extends ExamplePage {
  const FullMapExample({super.key})
    : super(
        const Icon(Icons.map),
        'Full screen map',
        category: ExampleCategory.basics,
      );

  @override
  Widget build(BuildContext context) => const _FullMapBody();
}

class _FullMapBody extends StatefulWidget {
  const _FullMapBody();

  @override
  State<_FullMapBody> createState() => _FullMapBodyState();
}

class _FullMapBodyState extends State<_FullMapBody> {
  void _onMapCreated(SiroMapController controller) {}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SiroMap(
        styleString: ExampleConstants.demoMapStyle,
        onMapCreated: _onMapCreated,
        initialCameraPosition: ExampleConstants.defaultCameraPosition,
        logoEnabled: false,
        trackCameraPosition: true,
        compassEnabled: true,
        myLocationEnabled: true,
      ),
    );
  }
}
