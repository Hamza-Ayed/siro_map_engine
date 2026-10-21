@JS('maplibregl')
library;

import 'dart:js_interop';
import 'package:siro_gl_web/src/interop/ui/map_interop.dart';

/// A LogoControl is a control that adds the watermark.
///
/// @implements {IControl}
/// @private
@JS('LogoControl')
@staticInterop
class LogoControlJsImpl {
  external factory LogoControlJsImpl();
}

extension LogoControlJsImplExtension on LogoControlJsImpl {
  external JSAny? onAdd(JsMapImpl map);
  external void onRemove();
  external JSAny? getDefaultPosition();
}
