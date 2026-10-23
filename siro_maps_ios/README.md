# Siro Maps for iOS

**Status: Beta.** The API surface is in place. Known gaps are listed below.

An API compatible with the Google Maps SDK for iOS, on Siro's MapLibre engine. Not affiliated with or endorsed by Google. Apps move from `GoogleMaps` to
`SiroMaps` by changing the import. Classes and methods keep Google's names and signatures
(`GMSMapView`, `GMSMarker`, `GMSPolyline`, `GMSPolygon`, `GMSCircle`, `GMSCameraUpdate`,
`GMSMapViewDelegate`, and so on).

## Install

Add the package in Xcode, or in `Package.swift`:

```swift
dependencies: [
    .package(path: "../packages/siro_map_engine/siro_maps_ios"),
],
targets: [
    .target(name: "MyApp", dependencies: [
        .product(name: "SiroMaps", package: "siro_maps_ios"),
    ]),
]
```

Requirements: iOS 13 or later, Swift 5.9 or later. The package pins MapLibre 6.28.0 from the
official distribution, the same version the `siro_gl` Flutter plugin uses.

## Migrate from Google Maps SDK

1. Replace `import GoogleMaps` with `import SiroMaps`.
2. Remove `GMSServices.provideAPIKey(...)`. Siro's styles need no key.
3. The rest of the code stays the same. `GMSMapView(frame:camera:)`, `map.animate(to:)`,
   `marker.map = map`, `GMSMapViewDelegate` callbacks, and the overlay classes all have Google's
   signatures.

## What works

- `GMSMapView`: `camera`, `mapType`, `mapStyle`, `delegate`, `animate(to:)`, `animate(with:)`,
  `moveCamera(_:)`, `clear()`, `selectedMarker`, `setMinZoom(_:maxZoom:)`, `isMyLocationEnabled`.
- `GMSCameraPosition`, `GMSCameraUpdate` (`setTarget`, `zoomIn`, `zoomOut`, `zoomTo`, `zoomBy`,
  `zoomBy(_:at:)` keeping the focus still, `scrollBy`, `fit`), `GMSCoordinateBounds`.
- `GMSPath`, `GMSMutablePath`, `GMSProjection`, `GMSVisibleRegion`, `GMSUISettings`.
- `GMSMarker`: position, title, snippet, icon, `groundAnchor`, rotation, opacity, flat, tappable,
  draggable. `GMSMarker.markerImage(with:)` for the default pin in a colour.
- `GMSPolyline`, `GMSPolygon` (with holes), `GMSCircle`, all with `isTappable` and `geodesic`.
- Taps: `didTapAt`, `didLongPressAt`, `didTap marker`, `didTap overlay`, `didTapInfoWindowOf`.
- Info windows: the default window, `markerInfoWindow`, and `markerInfoContents`.
- Dragging: a long press on a draggable marker, with `didBeginDragging`, `didDrag`, `didEndDragging`.
- Camera callbacks: `willMove`, `didChange`, `idleAt`.
- My-location button: `settings.myLocationButton = true` with `isMyLocationEnabled = true`.
- Map types: `.normal` shows Siro's day style, `.terrain` shows the 3D style, `.none` shows a plain
  background. `GMSMapStyle(siroStyleURL: SiroStyleURL.night)` takes Siro's night style.

## Known gaps

Checked against Google's `GMSMapView`, overlays, camera, path, bounds, settings, projection,
delegate and global function names: 105 of 105 checked names are present, and the geometry
functions are tested against known answers (including Google's documented polyline example).

Not implemented (these do not exist, so code using them will not compile):
- `GMSGroundOverlay`, `GMSTileLayer` and `GMSURLTileLayer`, clustering, heatmaps.
- `GMSGeocoder` and the `GMSPlaces` family. Siro's geocoder is in the Flutter package.
- `GMSMapView` delegate callbacks for points of interest and the blue dot.
- `GMSMapPoint` functions.

Present but stored only (the call compiles and runs, the map does not change):
- `isTrafficEnabled`, `isIndoorEnabled`, `indoorPicker`, `appearAnimation`, `infoWindowAnchor`,
  `tracksViewChanges`, `consumesGesturesInView`, `GMSServices.provideAPIKey` (Siro needs no key).
- `.satellite` and `.hybrid` show the day style, `.none` a plain background.
- Gradients in `GMSStrokeStyle` are drawn in eight colour steps. `GMSMarker.iconView` is drawn
  once into an image when it is set, so later changes to the view do not show.

The attribution is "© OpenStreetMap contributors · Siro Maps" in place of Google's logo.

## Testing

```bash
xcodebuild -scheme SiroMaps -destination 'platform=iOS Simulator,name=iPhone 17 Pro' test
```

The tests cover the geometry helpers, paths, bounds, styles, the default marker image, and
zoom about a point on a real map view.

The sample app is in `Example/`. Build and pack it for the simulator with:

```bash
cd Example && ./make_app.sh
xcrun simctl install booted ../.build/example/SiroMapsExample.app
xcrun simctl launch booted com.siro.maps.example
```

`make_app.sh` is needed because SwiftPM's `iOSApplication` product builds the binary and the
frameworks, but not the `.app` bundle.

Verified on the iPhone 17 Pro simulator (iOS 26.0): the three styles, overlays, marker and overlay
taps, info windows, dragging a marker with a long press, zoom about a point, and the location button.
Not yet verified on a physical iPhone.
