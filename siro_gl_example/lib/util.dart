import 'package:flutter/services.dart';
import 'package:siro_gl/siro_gl.dart';

/// Adds an asset image to the currently displayed style
Future<void> addImageFromAsset(
  SiroMapController controller,
  String name,
  String assetName,
) async {
  final bytes = await rootBundle.load(assetName);
  final list = bytes.buffer.asUint8List();
  return controller.addImage(name, list);
}
