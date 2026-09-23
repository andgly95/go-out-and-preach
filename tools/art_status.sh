#!/bin/bash
# Lists every image the game references and whether the file exists yet.
#   bash tools/art_status.sh            all slots
#   bash tools/art_status.sh --missing  only the ones still to make
# Slots are wired before the art exists and fall back to current art;
# see docs/design/asset-brief.md for what goes in each.
cd "$(dirname "$0")/.."
grep -rhoE 'res://assets/[A-Za-z0-9_/.-]+\.png' data scripts scenes | sort -u | while read -r path; do
	file="${path#res://}"
	if [ -f "$file" ]; then
		[ "${1:-}" = "--missing" ] || echo "have     $file"
	else
		echo "MISSING  $file"
	fi
done
