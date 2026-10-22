# Siro Maps for iOS

The Google Maps SDK for iOS API, on Siro's MapLibre engine. Apps move from `GoogleMaps` to
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

## Migrate from Google Maps

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

These are not implemented. Calls to them compile, or are stored, but do not change the map.

- `GMSStrokeStyle` and polyline `spans`, so gradients and dash patterns on polylines.
- `.satellite` and `.hybrid` show the day style.
- Tile overlays, clusters, heatmaps and ground overlays.
- Padding (`mapView.padding`) and indoor maps.
- The `myLocationButton` setting is drawn, but the blue dot needs the user's permission. The app
  must request `NSLocationWhenInUseUsageDescription` in its `Info.plist`.
- Attribution is "© OpenStreetMap contributors · Siro Maps", in place of Google's logo. Keep it visible.

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
