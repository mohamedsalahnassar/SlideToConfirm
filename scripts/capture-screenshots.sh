#!/usr/bin/env bash
# Launches the demo app on each screen and saves a screenshot.
# Usage: scripts/capture-screenshots.sh <simulator-udid> <path/to/SlideToConfirmDemo.app> <output-dir>
set -euo pipefail

SIMULATOR="$1"
APP="$2"
OUTPUT="$3"
BUNDLE_ID="io.github.mohamedsalahnassar.SlideToConfirmDemo"

mkdir -p "$OUTPUT"
xcrun simctl install "$SIMULATOR" "$APP"

shot() {
    local name="$1"
    shift
    xcrun simctl terminate "$SIMULATOR" "$BUNDLE_ID" >/dev/null 2>&1 || true
    xcrun simctl launch "$SIMULATOR" "$BUNDLE_ID" "$@" >/dev/null
    sleep 4
    xcrun simctl io "$SIMULATOR" screenshot --type=png "$OUTPUT/$name.png" >/dev/null 2>&1
    # Half size keeps the repository light; READMEs show them at ~300 px anyway.
    sips --resampleHeightWidthMax 1400 "$OUTPUT/$name.png" >/dev/null
    echo "Captured $name"
}

shot showcase-light    -screen showcase   -appearance light
shot showcase-dark     -screen showcase   -appearance dark
shot scenarios-light   -screen scenarios  -appearance light
shot scenarios-dark    -screen scenarios  -appearance dark
shot playground-light  -screen playground -appearance light
shot playground-dark   -screen playground -appearance dark
shot states-light      -screen states     -appearance light
shot states-dark       -screen states     -appearance dark -surface dark
shot send-light        -screen send       -appearance light
shot send-arabic-dark  -screen send       -appearance dark  -language ar
shot receipt-light     -screen send       -appearance light -step receipt
shot unlock-dark       -screen unlock     -appearance dark
shot checkout          -screen checkout   -appearance dark
shot delete-light      -screen delete     -appearance light
shot sos-light         -screen sos        -appearance light
shot garage-light      -screen garage     -appearance light
shot tabzone-light     -screen tabzone    -appearance light -step review
shot tabzone-arabic    -screen tabzone    -appearance dark  -step review -language ar -tabs minimized
shot uikit-light       -screen uikit      -appearance light
shot workout-dark      -screen workout    -appearance dark
shot hold-light        -screen hold       -appearance light
shot hold-dark         -screen hold       -appearance dark
shot hold-compose-light -screen hold-compose -appearance light
shot hold-reach-light  -screen hold-reach -appearance light
shot hold-reach-left-dark -screen hold-reach -appearance dark -hand left -placement edge
shot hold-duo-zone-light  -screen tabzone -appearance light -step review -control ring -ring zone
shot hold-duo-above-dark  -screen tabzone -appearance dark  -step review -control ring -ring above
shot hold-duo-thumb-arabic -screen tabzone -appearance light -step review -control ring -ring thumb -language ar

xcrun simctl terminate "$SIMULATOR" "$BUNDLE_ID" >/dev/null 2>&1 || true
