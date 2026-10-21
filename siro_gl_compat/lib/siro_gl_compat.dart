/// A Google Maps Flutter compatible API on top of Siro GL.
///
/// To move an app from google_maps_flutter, change only the import:
///
///   import 'package:google_maps_flutter/google_maps_flutter.dart';
///   import 'package:siro_gl_compat/siro_gl_compat.dart';
///
/// The types, names and set-based annotations match google_maps_flutter.
/// Differences are listed in the README.
library;

export 'package:siro_gl/siro_gl.dart'
    show
        CameraPosition,
        CameraUpdate,
        LatLng,
        LatLngBounds,
        SiroAttributionButton;

export 'src/geocoder.dart';
export 'src/google_map.dart';
export 'src/search_bar.dart';
export 'src/types.dart';
export 'src/geometry.dart' show colorToCss, geodesicCircle;
