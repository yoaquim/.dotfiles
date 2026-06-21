#!/usr/bin/env bash
# spawn-reviewer.sh — Idempotently spawn the /pr-review watcher for a PR.
#
# Spawns exactly ONE background reviewer per PR. If a live reviewer with the
# deterministic name already exists, it is reused (no second session). This is
# the guard against the double-review bug: a runner that gets kicked back by its
# Stop hook can re-run its Completion step and reach this spawn again — without
# this check that produced a second reviewer posting competing reviews.
#
# Usage: spawn-reviewer.sh <pr-number>
# Output (key:value on stdout):
#   reviewer_status:already-running|spawned
#   session_id:<short id>
#   name:<review session name>
#
# Exit 0 on success (spawned or reused), 1 on bad usage / spawn failure.

set -uo pipefail

PR="${1:-}"
if [[ -z "$PR" ]]; then
  echo "usage: spawn-reviewer.sh <pr-number>" >&2
  exit 1
fi

# Deterministic name: review-<owner>-<repo>[-<ticket>]-pr-<pr>.
# Use nameWithOwner (not basename) so repos like orgA/api and orgB/api don't
# collide and reuse each other's reviewer; sanitize the slash to be name-safe.
REPO_SLUG=$(gh repo view --json nameWithOwner -q '.nameWithOwner' 2>/dev/null || echo "")
if [[ -z "$REPO_SLUG" ]]; then
  echo "error: could not resolve repo identity (gh repo view)" >&2
  exit 1
fi
PROJECT_SAFE=${REPO_SLUG//\//-}
BRANCH=$(git rev-parse --abbrev-ref HEAD 2>/dev/null || echo "")
TICKET=$(grep -ioE '[a-z]+-[0-9]+' <<<"$BRANCH" | head -1 | tr '[:upper:]' '[:lower:]')
if [[ -n "$TICKET" ]]; then
  REVIEW_NAME="review-${PROJECT_SAFE}-${TICKET}-pr-${PR}"
else
  REVIEW_NAME="review-${PROJECT_SAFE}-pr-${PR}"
fi

# States a background session can be in that mean "not alive" (finished/gone).
TERMINAL='["completed","done","failed","stopped","exited","cancelled","canceled"]'

# Short id of a LIVE background session with our name, or "" if none.
live_reviewer_id() {
  claude agents --json 2>/dev/null | jq -r --arg n "$REVIEW_NAME" --argjson term "$TERMINAL" '
    [ .[]
      | select((.kind // "") == "background")
      | select((.name // "") == $n)
      | select(((.state // .status // "") | ascii_downcase) as $s | ($term | index($s) | not))
      | (.id // .sessionId // "")
    ] | first // ""
  ' 2>/dev/null || echo ""
}

# A reviewer spawned moments ago (e.g. by a prior Completion turn) may not be in
# `claude agents` yet; a single missed check would re-introduce the double-review
# bug. Retry briefly — the same latency tolerance the id-resolution loop uses below.
EXISTING=""
for _ in 1 2 3; do
  EXISTING=$(live_reviewer_id)
  if [[ -n "$EXISTING" ]]; then break; fi
  sleep 1
done
if [[ -n "$EXISTING" ]]; then
  echo "reviewer_status:already-running"
  echo "session_id:$EXISTING"
  echo "name:$REVIEW_NAME"
  exit 0
fi

SPAWN_OUT=$(claude --bg --permission-mode bypassPermissions --name "$REVIEW_NAME" "/pr-review --fg $PR" 2>&1)

# Resolve the id by the NAME we set (robust to --bg stdout wording). Retry a few
# times for agent-list latency, then fall back to scraping --bg stdout.
SESSION_ID=""
for _ in 1 2 3 4 5; do
  SESSION_ID=$(live_reviewer_id)
  if [[ -n "$SESSION_ID" ]]; then break; fi
  sleep 1
done
if [[ -z "$SESSION_ID" ]]; then
  SESSION_ID=$(grep 'backgrounded' <<<"$SPAWN_OUT" | grep -oE '[a-f0-9]{8}' | head -1)
fi

if [[ -z "$SESSION_ID" ]]; then
  echo "error: reviewer spawn produced no resolvable session id" >&2
  echo "$SPAWN_OUT" >&2
  exit 1
fi

echo "reviewer_status:spawned"
echo "session_id:$SESSION_ID"
echo "name:$REVIEW_NAME"
exit 0
