#!/usr/bin/env bash
# Records the hold → drag → early-release demo with a UI test and turns it into a GIF.
# Usage: scripts/record-demo.sh <simulator-udid> <derived-data-path> <output.gif> [light|dark]
set -euo pipefail

SIMULATOR="$1"
DERIVED_DATA="$2"
OUTPUT="$3"
APPEARANCE="${4:-light}"
WORK="$(mktemp -d)"
META="$WORK/meta.json"
VIDEO="$WORK/demo.mov"

command -v ffmpeg >/dev/null || brew install ffmpeg >/dev/null

xcrun simctl io "$SIMULATOR" recordVideo --codec=h264 --force "$VIDEO" >"$WORK/record.log" 2>&1 &
RECORDER=$!
# The first frame is written when simctl reports that recording started, not when it launches.
for _ in $(seq 1 100); do
    grep -qi "recording started" "$WORK/record.log" && break
    sleep 0.1
done
RECORD_START=$(python3 -c 'import time; print(time.time())')
sleep 1

TEST_RUNNER_RECORD_DEMO=1 \
TEST_RUNNER_RECORD_META="$META" \
TEST_RUNNER_RECORD_APPEARANCE="$APPEARANCE" \
xcodebuild test-without-building \
    -project Example/SlideToConfirmDemo.xcodeproj \
    -scheme SlideToConfirmDemo \
    -destination "id=$SIMULATOR" \
    -derivedDataPath "$DERIVED_DATA" \
    -only-testing:SlideToConfirmDemoUITests/DemoRecordingTests/testRecordDemo \
    > "$WORK/test.log" 2>&1 || { tail -50 "$WORK/test.log"; kill -INT "$RECORDER"; exit 1; }

sleep 1
kill -INT "$RECORDER"
wait "$RECORDER" || true

read -r OFFSET CROP < <(python3 - "$META" "$RECORD_START" "$VIDEO" <<'PY'
import json, subprocess, sys
meta = json.load(open(sys.argv[1]))
record_start = float(sys.argv[2])
probe = subprocess.run(
    ["ffprobe", "-v", "error", "-select_streams", "v:0", "-show_entries", "stream=width,height", "-of", "csv=p=0", sys.argv[3]],
    capture_output=True, text=True, check=True,
).stdout.strip().split(",")
video_width, video_height = int(probe[0]), int(probe[1])
scale = video_width / meta["screenWidth"]
pad = 12 * scale
x = max(0, int(meta["x"] * scale - pad))
y = max(0, int(meta["y"] * scale - pad))
w = min(video_width - x, int(meta["width"] * scale + 2 * pad))
h = min(video_height - y, int(meta["height"] * scale + 2 * pad))
w -= w % 2
h -= h % 2
offset = max(0, meta["start"] - record_start + 0.2)
print(f"{offset:.2f} {w}:{h}:{x}:{y}")
PY
)

echo "Trimming from ${OFFSET}s, crop ${CROP}"
ffmpeg -y -loglevel error -ss "$OFFSET" -t 16.4 -i "$VIDEO" \
    -vf "crop=${CROP},fps=22,scale=680:-1:flags=lanczos,split[a][b];[a]palettegen=stats_mode=diff:max_colors=200[p];[b][p]paletteuse=dither=sierra2_4a:diff_mode=rectangle" \
    -loop 0 "$OUTPUT"
ls -lh "$OUTPUT"
