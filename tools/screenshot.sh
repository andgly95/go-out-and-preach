#!/bin/bash
# Renders a scene to a PNG under a virtual display so agents can see the UI:
#   bash tools/screenshot.sh res://scenes/week_view.tscn out.png [setup.gd] [frames]
# setup.gd (optional) stages game state first — see tools/ci/screenshot.gd.
set -uo pipefail

cd "$(dirname "$0")/.."
xvfb-run -a -s "-screen 0 1920x1080x24" \
	bash tools/godot.sh --rendering-driver opengl3 --audio-driver Dummy \
	--script res://tools/ci/screenshot.gd -- "$@" 2>&1 | grep -E '^saved|SCRIPT ERROR|^ERROR' | grep -vE 'resources still in use'
