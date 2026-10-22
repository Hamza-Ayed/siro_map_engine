#!/usr/bin/env bash
# Proves the import-swap claim: the same Google-style screen must compile
# against the real google_maps_flutter package. Run it after changing the API.
set -euo pipefail
HERE="$(cd "$(dirname "$0")/.." && pwd)"
WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT
mkdir -p "$WORK/lib"
cat > "$WORK/pubspec.yaml" <<'YAML'
name: parity_probe
publish_to: none
environment:
  sdk: '>=3.7.0 <4.0.0'
dependencies:
  flutter:
    sdk: flutter
  google_maps_flutter: any
YAML
for source in "$HERE"/test/google_style/*.dart; do
  sed "s#package:siro_gl_compat/siro_gl_compat.dart#package:google_maps_flutter/google_maps_flutter.dart#" \
    "$source" > "$WORK/lib/$(basename "$source")"
done
(cd "$WORK" && flutter pub get >/dev/null && dart analyze lib)
echo "OK: every file in test/google_style compiles against google_maps_flutter with only the import changed."
