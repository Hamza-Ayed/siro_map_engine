// swift-tools-version: 6.1
// The sample app. It uses the SDK the way a Google Maps app does: the same calls, the
// same delegate, the same overlays. Open this package in Xcode, or build it with xcodebuild.
import AppleProductTypes
import PackageDescription

let package = Package(
    name: "SiroMapsExample",
    platforms: [.iOS(.v16)],
    products: [
        .iOSApplication(
            name: "SiroMapsExample",
            targets: ["SiroMapsExample"],
            bundleIdentifier: "com.siro.maps.example",
            teamIdentifier: nil,
            displayVersion: "1.0",
            bundleVersion: "1",
            supportedDeviceFamilies: [.phone],
            supportedInterfaceOrientations: [.portrait]
        ),
    ],
    dependencies: [
        .package(path: ".."),
    ],
    targets: [
        .executableTarget(
            name: "SiroMapsExample",
            dependencies: [
                .product(name: "SiroMaps", package: "siro_maps_ios"),
            ]
        ),
    ]
)
