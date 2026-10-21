#!/usr/bin/env bash
# Checks the licensing files for the Siro GL engine (R-02). Exits non-zero on
# the first missing piece.
#
# It checks that:
#   - NOTICE exists at the root, with a section for each package LICENSE;
#   - every package LICENSE starts with the Siro Maps copyright;
#   - every notice in the packages' LICENSE files also appears in NOTICE;
#   - THIRD_PARTY_LICENSES.md lists the bundled components.
set -eu

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

fail() { echo "check_notices: $1" >&2; exit 1; }

[ -f NOTICE ] || fail "NOTICE is missing at the root"
[ -f THIRD_PARTY_LICENSES.md ] || fail "THIRD_PARTY_LICENSES.md is missing"

for license in siro_gl/LICENSE siro_gl_web/LICENSE siro_gl_platform_interface/LICENSE; do
  [ -f "$license" ] || fail "$license is missing"
  head -1 "$license" | grep -q "^Siro Maps copyright" \
    || fail "$license does not start with the Siro Maps copyright"
  # Each upstream notice (the name line after an 80-dash separator) must be in NOTICE.
  python3 - "$license" <<'PY' || exit 1
import re, sys
path = sys.argv[1]
text = open(path, encoding="utf-8").read()
notice = open("NOTICE", encoding="utf-8").read()
for block in re.split(r"\n-{80}\n", text)[1:]:
    body = block.split("\n", 1)
    name = body[0].strip()
    if not name:
        continue
    if name not in notice:
        sys.exit(f"check_notices: notice '{name}' from {path} is missing in NOTICE")
PY
done

for component in maplibre-native maplibre-gl-js flutter-maplibre-gl flutter-mapbox-gl okhttp; do
  grep -qi "$component" THIRD_PARTY_LICENSES.md || fail "THIRD_PARTY_LICENSES.md does not list $component"
done

echo "check_notices: ok"
