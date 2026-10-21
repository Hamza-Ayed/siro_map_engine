/// A Google Maps Flutter compatible API on top of Siro GL.
///
/// To move an app from google_maps_flutter, change only the import:
///
///   import 'package:google_maps_flutter/google_maps_flutter.dart';
///   import 'package:siro_gl_compat/siro_gl_compat.dart';
///
/// The widget, types, names and set-based annotations match
/// google_maps_flutter. The README lists what is not supported yet.
library;

export 'package:siro_gl/siro_gl.dart'
    show
        CameraPosition,
        CameraTargetBounds,
        LatLng,
        LatLngBounds,
        MinMaxZoomPreference,
        SiroAttributionButton;

export 'src/geocoder.dart';
export 'src/geometry.dart' show colorToCss, geodesicCircle, geodesicLine;
export 'src/google_map.dart';
export 'src/search_bar.dart';
export 'src/support_types.dart';
export 'src/types.dart';
