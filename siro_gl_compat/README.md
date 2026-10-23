# Siro Maps for Flutter (siro_gl_compat)

**الحالة / Status: Beta.** API compatible with `google_maps_flutter`, on Siro's engine (`siro_gl`). Not affiliated with or endorsed by Google. Siro Maps is a separate package, so the API matches Google's, but the map, styles and data are Siro's.

## التثبيت / Install

Published on [pub.dev](https://pub.dev/packages/siro_gl_compat) as the Beta `1.0.0-beta.1`:

```yaml
dependencies:
  siro_gl_compat: ^1.0.0-beta.1
```

## الاستخدام / Usage

Change only the import. The widget, types and names are the same as `google_maps_flutter`:

```dart
// import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:siro_gl_compat/siro_gl_compat.dart';
```

The example in `siro_gl_example` (*Siro Maps (Google-compatible API)*) shows a route, a polygon, a circle, a marker and the search bar.

## البحث / Search

`SiroGeocoder` replaces Google's Places and Geocoding. It needs a publishable key, passed at build time with `--dart-define=SIRO_PUBLIC_KEY=...`. The key is never stored in the repo.

## ما يعمل / What works

- `GoogleMap` with set-based `markers`, `polylines`, `polygons` and `circles`, and their events.
- `CameraPosition`, `CameraUpdate`, the map options, and the gesture settings.
- `mapType`: `normal` shows Siro's day style, `terrain` shows the 3D style. Night style with a Siro style URL.
- `SiroGeocoder` for search.

## الفجوات / Known gaps

Not supported yet (the code does not provide them):
- Cluster managers, ground overlays, heatmaps, tile overlays.
- Traffic, indoor maps, 45° imagery, web camera controls.
- Google Places and Geocoding by name. Use `SiroGeocoder`.

Behaves differently:
- `MapType.satellite` and `MapType.hybrid` fall back to the normal map.
- Google style arrays are rejected. Pass a Siro style URL or style JSON.

## الاختبار / Testing

```bash
flutter test
```

Unit tests cover the Google API surface, geocoding, and dashed polylines.

Verified on an itel A665L (Android, physical device): the Google-compatible example loads, a route draws between Amman and Zarqa with the key, search returns results and the camera moves to the chosen result. Not verified on iOS in this compat layer, and not on other devices yet.

## الترخيص / License

BSD-3-Clause for Siro's code. Map data © OpenStreetMap contributors. Third-party components are listed in [THIRD_PARTY_LICENSES.md](../THIRD_PARTY_LICENSES.md).
