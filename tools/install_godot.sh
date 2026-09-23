#!/bin/bash
# Installs the pinned Godot editor binary (headless-capable) for CI and
# Claude Code web sessions. Idempotent: does nothing if already installed.
# Prints the binary path on the last line of stdout.
set -euo pipefail

GODOT_VERSION="${GODOT_VERSION:-4.6.1}"
GODOT_HOME="${GODOT_HOME:-$HOME/.local/share/godot}"
BIN_NAME="Godot_v${GODOT_VERSION}-stable_linux.x86_64"
BIN_PATH="$GODOT_HOME/$BIN_NAME"
URL="https://github.com/godotengine/godot/releases/download/${GODOT_VERSION}-stable/${BIN_NAME}.zip"

if [ ! -x "$BIN_PATH" ]; then
	mkdir -p "$GODOT_HOME"
	tmp_zip="$(mktemp --suffix=.zip)"
	curl -sSfL --retry 4 --retry-delay 2 -o "$tmp_zip" "$URL"
	unzip -o -q "$tmp_zip" -d "$GODOT_HOME"
	rm -f "$tmp_zip"
	chmod +x "$BIN_PATH"
fi

mkdir -p "$HOME/.local/bin"
ln -sf "$BIN_PATH" "$HOME/.local/bin/godot"
echo "$BIN_PATH"
