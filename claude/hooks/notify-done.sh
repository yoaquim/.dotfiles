#!/bin/bash
# Stop Hook: Notify when a runner session finishes.
# Fires macOS notification + terminal bell.

set -euo pipefail

INPUT=$(cat)
CWD=$(echo "$INPUT" | jq -r '.cwd // ""')
DIR=$(basename "$CWD" 2>/dev/null || true)
MSG="Session finished${DIR:+ — $DIR}"

# macOS notification. Pass MSG as an argv value, never interpolated into the
# AppleScript source — a directory basename containing a double quote would
# otherwise break the script or inject statements.
if command -v osascript &>/dev/null; then
  osascript - "$MSG" >/dev/null 2>&1 <<'APPLESCRIPT' || true
on run argv
  display notification (item 1 of argv) with title "Claude Code"
end run
APPLESCRIPT
fi

# Terminal bell
printf '\a'

exit 0
