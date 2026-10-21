// swift-tools-version: 5.9
// Siro Maps for iOS: the Google Maps SDK for iOS API, on Siro's MapLibre engine.
//
// Apps move from GoogleMaps to SiroMaps by changing imports; the classes and
// methods keep Google's names and signatures.
import PackageDescription

let package = Package(
    name: "SiroMaps",
    platforms: [.iOS(.v13)],
    products: [
        .library(name: "SiroMaps", targets: ["SiroMaps"]),
    ],
    dependencies: [
        // The same MapLibre version the siro_gl Flutter plugin pins (MapLibre 6.28.0).
        .package(url: "https://github.com/maplibre/maplibre-gl-native-distribution", exact: "6.28.0"),
    ],
    targets: [
        .target(
            name: "SiroMaps",
            dependencies: [
                .product(name: "MapLibre", package: "maplibre-gl-native-distribution"),
            ]
        ),
    ]
)
