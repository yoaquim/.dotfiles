#!/bin/bash
# Stop Hook: Notify when a runner session finishes.
# Fires macOS notification + terminal bell.

set -euo pipefail

INPUT=$(cat)
STOP_REASON=$(echo "$INPUT" | jq -r '.stop_hook_active // false')

# macOS notification
if command -v osascript &>/dev/null; then
  osascript -e 'display notification "Runner session finished" with title "Claude Code"' 2>/dev/null || true
fi

# Terminal bell
printf '\a'

exit 0
