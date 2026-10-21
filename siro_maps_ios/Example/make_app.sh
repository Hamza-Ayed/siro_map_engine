#!/bin/sh
# Builds the sample and packs it into SiroMapsExample.app for the iOS Simulator.
# SwiftPM's iOSApplication product builds the executable and frameworks but not the bundle.
set -e
cd "$(dirname "$0")"
DERIVED=../.build/example
PRODUCTS="$DERIVED/Build/Products/Debug-iphonesimulator"
APP="$DERIVED/SiroMapsExample.app"

xcodebuild -scheme SiroMapsExample -destination 'generic/platform=iOS Simulator' -derivedDataPath "$DERIVED" build >/dev/null

rm -rf "$APP"
mkdir -p "$APP/Frameworks"
cp "$PRODUCTS/SiroMapsExample" "$APP/SiroMapsExample"
cp -R "$PRODUCTS/MapLibre.framework" "$APP/Frameworks/"
install_name_tool -add_rpath "@executable_path/Frameworks" "$APP/SiroMapsExample" 2>/dev/null || true

cat > "$APP/Info.plist" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleExecutable</key><string>SiroMapsExample</string>
    <key>CFBundleIdentifier</key><string>com.siro.maps.example</string>
    <key>CFBundleName</key><string>SiroMapsExample</string>
    <key>CFBundlePackageType</key><string>APPL</string>
    <key>CFBundleShortVersionString</key><string>1.0</string>
    <key>CFBundleVersion</key><string>1</string>
    <key>MinimumOSVersion</key><string>16.0</string>
    <key>NSLocationWhenInUseUsageDescription</key><string>Shows your position on the map.</string>
    <key>UIDeviceFamily</key><array><integer>1</integer></array>
    <key>UILaunchScreen</key><dict/>
    <key>UISupportedInterfaceOrientations</key><array><string>UIInterfaceOrientationPortrait</string></array>
</dict>
</plist>
PLIST

codesign --force --sign - --timestamp=none "$APP/Frameworks/MapLibre.framework" >/dev/null
codesign --force --sign - --timestamp=none "$APP" >/dev/null
echo "$APP"
