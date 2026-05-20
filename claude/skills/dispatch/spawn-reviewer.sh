#!/usr/bin/env bash
# spawn-reviewer.sh — Idempotent spawner for /pr-review.
#
# Ensures AT MOST one /pr-review session is alive per PR. Callers (the runner
# loop, scripts, etc.) can invoke this every iteration without piling up
# duplicate reviewers — the wrapper checks an existing session's liveness via
# ~/.claude/jobs/<session_id>/state.json and skips if it's still working.
#
# Usage:
#   spawn-reviewer.sh <pr-number> [--name <session-name>]
#
# Exit:
#   0 — spawned a new reviewer OR confirmed an existing one is alive.
#   1 — usage error or spawn failure.
#
# Prints to stdout:
#   "skip: reviewer alive for PR <n> (session <id>)"
#   "spawned: <id>"

set -uo pipefail

PR="${1:-}"
shift || true
NAME=""
while [[ $# -gt 0 ]]; do
  case "$1" in
    --name) NAME="${2:-}"; shift 2 ;;
    *)      shift ;;
  esac
done

if [[ -z "$PR" || ! "$PR" =~ ^[0-9]+$ ]]; then
  echo "usage: spawn-reviewer.sh <pr-number> [--name <session-name>]" >&2
  exit 1
fi

# Marker is per-PR (not per-commit). /pr-review's internal watch loop handles
# re-reviewing on new commits, so one session covers the whole PR lifecycle.
MARKER_DIR="$HOME/.dispatch/state"
mkdir -p "$MARKER_DIR"
MARKER="$MARKER_DIR/reviewer-pr-${PR}.session"

is_alive() {
  local session_id="$1"
  [[ -z "$session_id" ]] && return 1
  local state_file="$HOME/.claude/jobs/$session_id/state.json"
  [[ -f "$state_file" ]] || return 1
  jq -e '.state == "working" or .state == "needs_input"' "$state_file" >/dev/null 2>&1
}

# Skip if existing session is still working.
if [[ -f "$MARKER" ]]; then
  EXISTING=$(cat "$MARKER" 2>/dev/null || echo "")
  if is_alive "$EXISTING"; then
    echo "skip: reviewer alive for PR $PR (session $EXISTING)"
    exit 0
  fi
fi

# Compose default name if caller didn't supply one.
if [[ -z "$NAME" ]]; then
  PROJECT=$(gh repo view --json name -q '.name' 2>/dev/null || echo "pr")
  NAME="${PROJECT}-review-pr-${PR}"
fi

SPAWN_OUTPUT=$(claude --bg \
  --permission-mode bypassPermissions \
  --name "$NAME" \
  "/pr-review --fg $PR" 2>&1) || true

SESSION_ID=$(echo "$SPAWN_OUTPUT" | grep 'backgrounded' | grep -oE '[a-f0-9]{8}' | head -1)

if [[ -z "$SESSION_ID" ]]; then
  echo "spawn failed for PR $PR:" >&2
  echo "$SPAWN_OUTPUT" >&2
  exit 1
fi

echo "$SESSION_ID" > "$MARKER"
echo "spawned: $SESSION_ID"
