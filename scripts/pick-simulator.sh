#!/usr/bin/env bash
# Prints the UDID of the newest available iPhone Pro simulator (falls back to any iPhone).
set -euo pipefail
xcrun simctl list devices available -j | python3 -c '
import json, sys
devices = json.load(sys.stdin)["devices"]
candidates = []
for runtime, entries in devices.items():
    if ".iOS-" not in runtime:
        continue
    version = tuple(int(part) for part in runtime.split(".iOS-")[1].split("-"))
    for device in entries:
        name = device["name"]
        if not name.startswith("iPhone"):
            continue
        score = 2 if (" Pro" in name and "Max" not in name) else 1
        candidates.append((version, score, name, device["udid"]))
if not candidates:
    sys.exit("No iPhone simulator available")
candidates.sort()
version, score, name, udid = candidates[-1]
label = ".".join(str(part) for part in version)
print(udid)
print("Using " + name + " (iOS " + label + ")", file=sys.stderr)
'
