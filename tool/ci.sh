#!/usr/bin/env bash
# Local gate for the Siro GL engine. Run it before each commit.
#
#   tool/ci.sh              every step (format, analyze, tests, codegen check, builds)
#   SKIP_WEB=1 tool/ci.sh   skip the Chrome test run
#   SKIP_BUILD=1 tool/ci.sh skip the example builds
#
# Prints one line per step and exits non-zero if any step failed.
set -u

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT" || exit 1

# melos scripts call a `melos` binary, which is not on PATH here. A temporary
# shim runs the workspace copy instead, so nothing is installed globally.
SHIM="$(mktemp -d)"
printf '#!/bin/sh\nexec dart run melos "$@"\n' > "$SHIM/melos"
chmod +x "$SHIM/melos"
export PATH="$SHIM:$PATH"
LOGS="$SHIM/logs"
mkdir -p "$LOGS"

results=()
failed=0

step() {
  local name="$1"; shift
  local log="$LOGS/$(echo "$name" | tr ' /' '__').log"
  printf '>> %s\n' "$name"
  if "$@" >"$log" 2>&1; then
    results+=("PASS  $name")
  else
    results+=("FAIL  $name  (log: $log)")
    failed=1
  fi
}

# Generated files must match what the generator writes from style.json.
generate_check() {
  dart run melos run generate --no-select >/dev/null 2>&1 || return 1
  git diff --exit-code -- \
    siro_gl/lib/src/layer_properties.dart \
    siro_gl/lib/src/layer_expressions.dart \
    siro_gl_web/lib/src/layer_tools.dart \
    siro_gl_platform_interface/lib/src/source_properties.dart \
    siro_gl/android/src/main/java/com/siro/gl/LayerPropertyConverter.java \
    siro_gl/ios/siro_gl/Sources/siro_gl/LayerPropertyConverter.swift
}

step "pub get"               flutter pub get
step "format"                dart format --set-exit-if-changed .
step "analyze"               dart run melos run analyze-all --no-select
step "test io"               dart run melos run test:io --no-select
step "test scripts"          dart run melos run test:scripts --no-select
step "test example"        sh -c 'cd siro_gl_example && flutter test'
if [ "${SKIP_WEB:-0}" != "1" ]; then
  step "test web"            dart run melos run test:web --no-select
fi
step "generate (no diff)"    generate_check
if [ "${SKIP_BUILD:-0}" != "1" ]; then
  step "build apk (example)" sh -c 'cd siro_gl_example && flutter build apk --debug'
  if [ "$(uname)" = "Darwin" ]; then
    step "build ios sim (example)" sh -c 'cd siro_gl_example && LANG=en_US.UTF-8 LC_ALL=en_US.UTF-8 flutter build ios --simulator --debug'
  fi
fi

echo
echo "== summary"
printf '%s\n' "${results[@]}"
exit "$failed"
