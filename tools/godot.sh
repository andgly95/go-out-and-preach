#!/bin/bash
# Runs Godot against this project: bash tools/godot.sh <godot args...>
# Restores project.godot afterwards. Any run that triggers an editor-mode
# import lets the Dialogic plugin rewrite its directory tables before its
# .dch/.dtl loaders are registered, which empties them. The tables are only
# a cache (door_knock rescans at runtime), but the diff is noise.
set -uo pipefail

cd "$(dirname "$0")/.."

GODOT="${GODOT:-$(command -v godot || true)}"
if [ -z "$GODOT" ]; then
	GODOT="$(bash tools/install_godot.sh | tail -n 1)"
fi

backup="$(mktemp)"
cp project.godot "$backup"
"$GODOT" "$@"
status=$?
cp "$backup" project.godot
rm -f "$backup"
exit $status
