#!/bin/bash
# Stop Hook: Notify when a runner session finishes.
# Fires macOS notification + terminal bell.

set -euo pipefail

INPUT=$(cat)
CWD=$(echo "$INPUT" | jq -r '.cwd // ""')
DIR=$(basename "$CWD" 2>/dev/null || true)
MSG="Session finished${DIR:+ — $DIR}"

# macOS notification
if command -v osascript &>/dev/null; then
  osascript -e "display notification \"$MSG\" with title \"Claude Code\"" 2>/dev/null || true
fi

# Terminal bell
printf '\a'

exit 0
