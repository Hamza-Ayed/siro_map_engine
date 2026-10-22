# Siro Maps for Android

The Google Maps SDK for Android API, on Siro's MapLibre engine. Apps move from
`com.google.android.gms.maps` to `com.siro.maps` by changing imports. Classes and
methods keep Google's names and signatures.

## Install

The library is published to Maven Local for now:

```bash
./gradlew publishReleasePublicationToMavenLocal
```

Then, in the app:

```gradle
repositories {
    mavenLocal()
}

dependencies {
    implementation 'com.siro.maps:siro-maps-android:1.0.0'
}
```

Minimum Android version: **23** (the engine's manifest requires it; Google's SDK goes to 21).

## Migrate from Google Maps

1. Replace the dependency, `com.google.android.gms:play-services-maps` with
   `com.siro.maps:siro-maps-android`.
2. Replace the import prefix. Google splits its classes between `com.google.android.gms.maps`
   and `com.google.android.gms.maps.model`. Siro keeps them all in `com.siro.maps`:

   ```
   com.google.android.gms.maps.model.  ->  com.siro.maps.
   com.google.android.gms.maps.        ->  com.siro.maps.
   ```

3. In layouts, point the fragment at Siro:

   ```xml
   <fragment
       android:name="com.siro.maps.SupportMapFragment"
       android:layout_width="match_parent"
       android:layout_height="match_parent" />
   ```

4. Location: request `ACCESS_FINE_LOCATION` as before. `isMyLocationEnabled` throws
   `SecurityException` without it, as Google's does.

## What works

- `MapView`, `SupportMapFragment`, `OnMapReadyCallback`, the lifecycle methods.
- Camera: `moveCamera`, `animateCamera` (with duration and `CancelableCallback`),
  `CameraUpdateFactory` (`newLatLng`, `newLatLngZoom`, `newLatLngBounds`, `zoomBy`, `scrollBy`).
- `Marker`: position, title, snippet, icon, alpha, anchor, rotation, visibility, z-index,
  `remove`, `showInfoWindow`, `hideInfoWindow`.
- Marker icons: `BitmapDescriptorFactory.defaultMarker`, `fromBitmap`, `fromResource`, `fromAsset`.
- Dragging: a long press on a draggable marker starts a drag, with `OnMarkerDragListener`.
- Info windows, with `InfoWindowAdapter` for custom views.
- `Polyline` (solid and dashed), `Polygon` (with holes), `Circle` (geodesic).
- Taps: `OnMapClickListener`, `OnMapLongClickListener`, and marker, polyline, polygon and circle clicks.
- Camera listeners, `Projection`, `VisibleRegion`, `UiSettings` gestures and compass.
- Map types: `MAP_TYPE_NORMAL` shows Siro's day style, `MAP_TYPE_TERRAIN` shows the 3D style.
  `setMapStyle(MapStyleOptions.fromSiroStyleUrl(url))` takes Siro's night style.
- My-location dot and recentring button (`UiSettings.isMyLocationButtonEnabled`).

## Known gaps

These are not implemented. Calls to them compile, or are stored, but do not change the map.

- Zoom controls are not drawn. `UiSettings.isZoomControlsEnabled` does not exist yet.
- `MAP_TYPE_SATELLITE` and `MAP_TYPE_HYBRID` show the day style.
- `MAP_TYPE_NONE` shows the day style.
- Polyline caps and joins are not drawn. Dash patterns are; dot patterns are not.
- Tile overlays, clusters, heatmaps and ground overlays are not implemented.
- Attribution is "© OpenStreetMap contributors · Siro Maps", in place of Google's logo.
  Keep it visible in the app.

## Testing

```bash
./gradlew :testDebugUnitTest      # JVM tests for the geometry and colour helpers
./gradlew :example:assembleDebug  # the sample app
```

The sample is in `example/`. It has a fragment map, markers (one draggable), a dashed
route, a polygon, a circle, the day/night/3D buttons, and the location button.

Verified on an itel A665L (Android): the overlays draw, taps on each overlay report, the info
window opens, a long press drags a marker, the three styles switch, and the location button
recentres the map. Not yet verified on other devices.
