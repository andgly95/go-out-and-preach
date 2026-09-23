#!/bin/bash
# SessionStart hook for Claude Code on the web: installs Godot so the agent
# can import the project, boot scenes headless, and run tools/check.sh.
set -euo pipefail

if [ "${CLAUDE_CODE_REMOTE:-}" != "true" ]; then
	exit 0
fi

cd "$CLAUDE_PROJECT_DIR"
godot_bin="$(bash tools/install_godot.sh | tail -n 1)"

if [ -n "${CLAUDE_ENV_FILE:-}" ]; then
	echo "export GODOT=\"$godot_bin\"" >> "$CLAUDE_ENV_FILE"
	echo "export PATH=\"\$HOME/.local/bin:\$PATH\"" >> "$CLAUDE_ENV_FILE"
fi

# Build the .godot/ import cache once so the first boot in the session is fast
# (tools/godot.sh restores project.godot, which the import would otherwise dirty).
bash tools/godot.sh --headless --import >/dev/null 2>&1 || true
