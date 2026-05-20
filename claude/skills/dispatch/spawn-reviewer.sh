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

# Marker records the SHA we last triggered a review for. One spawn per
# unique HEAD SHA — the authoritative dedup. /pr-review's internal watch
# loop is opportunistic; this is the hard guarantee.
#
# Format (single line, space-separated):
#   <session_id> <head_sha> <timestamp_epoch>
MARKER_DIR="$HOME/.dispatch/state"
mkdir -p "$MARKER_DIR"
MARKER="$MARKER_DIR/reviewer-pr-${PR}.session"

# Treat anything NOT in this terminal-state list as alive (covers
# "working", "needs_input", "blocked", "starting", future states, etc.).
# Empirically observed states include: working | blocked | done.
TERMINAL_STATES_RE='^(done|failed|errored|completed|killed)$'

is_alive() {
  local session_id="$1"
  [[ -z "$session_id" ]] && return 1
  local state_file="$HOME/.claude/jobs/$session_id/state.json"
  [[ -f "$state_file" ]] || return 1
  local state
  state=$(jq -r '.state // ""' "$state_file" 2>/dev/null)
  [[ -z "$state" ]] && return 1
  [[ "$state" =~ $TERMINAL_STATES_RE ]] && return 1
  return 0
}

CURRENT_SHA=$(gh pr view "$PR" --json headRefOid -q '.headRefOid' 2>/dev/null || echo "")

# Authoritative dedup: skip if we already triggered a review for this SHA.
# This holds even after /pr-review's session exits (state=done) — same SHA
# means same review, no need to re-run.
#
# Crash recovery: if the marker is older than 5 min AND the session is dead
# AND the prior run never produced a posted review (we can't easily detect
# that here, so we just allow a single retry past the 5-min mark), allow a
# fresh spawn for the same SHA.
if [[ -f "$MARKER" ]]; then
  read -r EXISTING LAST_SHA TIMESTAMP < "$MARKER" 2>/dev/null || true
  TIMESTAMP="${TIMESTAMP:-0}"
  AGE=$(( $(date +%s) - TIMESTAMP ))

  if [[ -n "$LAST_SHA" && "$LAST_SHA" == "$CURRENT_SHA" ]]; then
    if (( AGE < 300 )) || is_alive "$EXISTING"; then
      echo "skip: PR $PR @ ${CURRENT_SHA:0:8} already triggered (session $EXISTING, ${AGE}s ago)"
      exit 0
    fi
    echo "respawn: prior session $EXISTING dead and >5min old; retrying ${CURRENT_SHA:0:8}"
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

echo "$SESSION_ID $CURRENT_SHA $(date +%s)" > "$MARKER"
echo "spawned: $SESSION_ID for PR $PR @ ${CURRENT_SHA:0:8}"
