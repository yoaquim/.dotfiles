#!/bin/bash
# Stop Hook: Notify when a session finishes.
# Fires macOS notification + terminal bell.
#
# Registered globally on Stop, so it also fires on every BLOCKED stop attempt
# of the background loops (enforce-completion / enforce-watch retry for hours).
# The gates below keep it to one notification per real finish of an interactive
# session — never the loop machinery.

set -euo pipefail

INPUT=$(cat)

# A retry after another Stop hook blocked — the first attempt already notified.
if [[ "$(echo "$INPUT" | jq -r '.stop_hook_active // false')" == "true" ]]; then
  exit 0
fi

# Dispatch runner sessions carry this marker (spawn.sh sets it).
if [[ -n "${CLAUDE_DISPATCH_WORKTREE:-}" ]]; then
  exit 0
fi

# Background agent sessions (runner / pr-reviewer): same jobs-dir template gate
# enforce-watch.sh uses (bg sessions name the job dir by the SHORT session id,
# hence the fallback). Catches runners even if the env marker didn't propagate.
SID=$(echo "$INPUT" | jq -r '.session_id // ""')
if [[ -n "$SID" ]]; then
  JOBDIR="$HOME/.claude/jobs/$SID"
  [[ -d "$JOBDIR" ]] || JOBDIR="$HOME/.claude/jobs/${SID%%-*}"
  if [[ -f "$JOBDIR/state.json" ]]; then
    TEMPLATE=$(jq -r '.template // ""' "$JOBDIR/state.json" 2>/dev/null || true)
    case "$TEMPLATE" in
      pr-reviewer|runner) exit 0 ;;
    esac
  fi
fi

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
