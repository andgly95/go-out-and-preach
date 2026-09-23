#!/bin/bash
# Headless verification for Go Out and Preach. Run before every commit:
#   bash tools/check.sh
# 1. Imports the project (via tools/godot.sh, which restores project.godot).
# 2. Boots every scene under scenes/ for a few frames.
# 3. Runs the GDScript test suite (tools/ci/run_tests.gd), which includes the
#    month-long balance simulation.
# Fails on any engine ERROR / SCRIPT ERROR line or a failing test.
set -uo pipefail

cd "$(dirname "$0")/.."

# Engine noise that appears on every clean headless exit.
IGNORE='ObjectDB instances leaked|resources still in use at exit|at: cleanup|at: clear'
fail=0

run_godot() {
	# Usage: run_godot <label> <args...>
	local label="$1"; shift
	local out
	out="$(bash tools/godot.sh --headless "$@" 2>&1)"
	local status=$?
	local errors
	errors="$(echo "$out" | grep -E 'SCRIPT ERROR|Parse Error|^ERROR' | grep -vE "$IGNORE")"
	if [ $status -ne 0 ] || [ -n "$errors" ]; then
		echo "FAIL  $label (exit $status)"
		echo "$out" | grep -E -A2 'SCRIPT ERROR|Parse Error|^ERROR|FAILED|failed' | grep -vE "$IGNORE" | head -40
		fail=1
	else
		echo "ok    $label"
	fi
	if [ -n "${VERBOSE:-}" ]; then echo "$out"; fi
}

bash tools/godot.sh --headless --import >/dev/null 2>&1

for scene in scenes/*.tscn; do
	run_godot "boot $scene" --quit-after 60 "res://$scene"
done

run_godot "tests" --script res://tools/ci/run_tests.gd

if [ $fail -ne 0 ]; then
	echo "check.sh: FAILED"
	exit 1
fi
echo "check.sh: all clean"
