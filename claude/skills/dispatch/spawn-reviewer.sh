#!/usr/bin/env bash
# spawn-reviewer.sh — The SINGLE, idempotent entry point for starting a
# /pr-review watcher on a PR.
#
# Both callers route through here:
#   - the dispatch runner (Completion step), and
#   - `/pr-review`'s background dispatch (skill step 0).
# So there is exactly ONE place that builds the reviewer's session name and ONE
# guard against duplicates. This is what prevents the double-review bug: if two
# paths derive the name from different inputs (different repo-identity source,
# different ticket source) the guard can't see the other path's reviewer and the
# PR gets reviewed twice. One builder ⇒ one name ⇒ the guard always sees it.
#
# Spawns exactly ONE background reviewer per PR. If a live reviewer with the
# deterministic name already exists, it is reused (no second session).
#
# Usage: spawn-reviewer.sh <pr-ref> [gh-args...]
#   <pr-ref> [gh-args...] is anything `gh pr view` accepts AND that preserves
#   repo context — so any of:
#     spawn-reviewer.sh 42
#     spawn-reviewer.sh https://github.com/owner/repo/pull/42
#     spawn-reviewer.sh 42 -R owner/repo
#
# Output (key:value on stdout):
#   reviewer_status:already-running|spawned
#   session_id:<short id>
#   name:<review session name>
#
# Exit 0 on success (spawned or reused), 1 on bad usage / resolution / spawn failure.

set -uo pipefail

if [[ $# -lt 1 ]]; then
  echo "usage: spawn-reviewer.sh <pr-ref> [gh-args...]" >&2
  exit 1
fi

# Resolve EVERYTHING the name depends on from the PR itself (not from cwd or the
# local branch), so the name is identical no matter who calls this or from where.
PR_JSON=$(gh pr view "$@" --json number,headRefName,title,url 2>/dev/null)
if [[ -z "$PR_JSON" ]]; then
  echo "error: could not resolve PR from: $*" >&2
  exit 1
fi

PR=$(jq -r '.number // empty' <<<"$PR_JSON")
PR_URL=$(jq -r '.url // empty' <<<"$PR_JSON")
if [[ -z "$PR" || -z "$PR_URL" ]]; then
  echo "error: PR lookup returned no number/url for: $*" >&2
  exit 1
fi

# Deterministic name: review-<repo>[-<ticket>]-pr-<pr>.
# Project = repo basename (matches the dispatcher's dispatch-<repo>-<ticket>);
# parse it from the canonical PR url: https://github.com/<owner>/<repo>/pull/<n>.
REPO_PART=${PR_URL%/pull/*}      # https://github.com/<owner>/<repo>
PROJECT_SAFE=${REPO_PART##*/}    # <repo>

# Ticket (best-effort) from the PR's branch + title — first ABC-123 token wins.
TICKET=$(jq -r '"\(.headRefName // "") \(.title // "")"' <<<"$PR_JSON" \
  | grep -ioE '[a-z]+-[0-9]+' | head -1 | tr '[:upper:]' '[:lower:]')

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

# Mutually exclude check-then-spawn so two near-simultaneous callers can't both
# pass the guard before either reviewer appears in `claude agents` (the old
# TOCTOU double). mkdir is atomic and portable (macOS ships no flock). Best
# effort: if we can't take the lock in time, degrade to the unlocked check
# rather than fail — the name-level guard below still catches the common cases.
LOCK_DIR="${TMPDIR:-/tmp}/spawn-reviewer-${REVIEW_NAME}.lock"
for _ in 1 2 3 4 5 6 7 8 9 10; do
  if mkdir "$LOCK_DIR" 2>/dev/null; then
    trap 'rmdir "$LOCK_DIR" 2>/dev/null' EXIT
    break
  fi
  sleep 1
done

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

# Spawn the watcher with the PR url so the child always has repo context,
# regardless of the cwd it lands in.
SPAWN_OUT=$(claude --bg --permission-mode bypassPermissions --name "$REVIEW_NAME" "/pr-review --fg $PR_URL" 2>&1)

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
