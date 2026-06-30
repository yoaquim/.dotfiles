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
#   reviewer_status:already-reviewed|already-running|spawned
#   session_id:<short id>          # omitted for already-reviewed (no live session)
#   name:<review session name>
#
# already-reviewed = the PR's current HEAD already has a review (approve or
# findings); this code is covered, so nothing is spawned. A new reviewer spawns
# only when HEAD is genuinely unreviewed AND no live reviewer exists.
#
# Exit 0 on success (reviewed, spawned, or reused), 1 on bad usage / resolution / spawn failure.

set -uo pipefail

if [[ $# -lt 1 ]]; then
  echo "usage: spawn-reviewer.sh <pr-ref> [gh-args...]" >&2
  exit 1
fi

# Machine-local kill switch. Some machines (e.g. a personal/work box where you
# review your own PRs by hand) don't want an auto-spawned reviewer at all. Set
# DISPATCH_NO_REVIEWER=1 in that machine's bash_profile_local to short-circuit
# here. This is the single chokepoint, so it covers BOTH callers — the dispatch
# runner and /pr-review's background dispatch. Exit 0 so the caller treats it as
# success (no reviewer was needed), not a failure.
if [[ -n "${DISPATCH_NO_REVIEWER:-}" ]]; then
  echo "reviewer_status:disabled"
  echo "name:(auto-reviewer disabled on this machine via DISPATCH_NO_REVIEWER)"
  exit 0
fi

# Resolve EVERYTHING the name depends on from the PR itself (not from cwd or the
# local branch), so the name is identical no matter who calls this or from where.
PR_JSON=$(gh pr view "$@" --json number,headRefName,title,url,headRefOid 2>/dev/null)
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

# Reviewed-at-HEAD gate (authoritative dedup) — runs BEFORE the session-liveness
# check. Session-liveness alone is the wrong signal: a reviewer that finished a
# pass sits in state `done`, which the liveness filter (TERMINAL, below) reads as
# "not alive" → it would re-spawn a second reviewer to re-review a SHA that was
# ALREADY reviewed (the double-review bug). So first ask GitHub the real question:
# does the PR's CURRENT HEAD already have ANY review (approve OR findings, by
# commit_id)? If so this code is covered — do NOT spawn. The runner advances by
# fixing findings and pushing; that moves HEAD, the commit_id no longer matches,
# and this gate reopens for the genuinely-new SHA. (Approve vs findings doesn't
# matter for spawning — either way this exact HEAD has been reviewed.)
HEAD_SHA=$(jq -r '.headRefOid // empty' <<<"$PR_JSON")
# owner/repo from the canonical url, host-agnostic (handles GHE too).
NO_SCHEME=${REPO_PART#*://}   # <host>/<owner>/<repo>
OWNER_REPO=${NO_SCHEME#*/}    # <owner>/<repo>
if [[ -n "$HEAD_SHA" ]]; then
  REVIEWED_AT_HEAD=$(gh api --paginate "repos/$OWNER_REPO/pulls/$PR/reviews" 2>/dev/null \
    | jq -s --arg sha "$HEAD_SHA" '[ (add // [])[] | select((.commit_id // "") == $sha) ] | (length > 0)' \
      2>/dev/null || echo false)
  if [[ "$REVIEWED_AT_HEAD" == "true" ]]; then
    echo "reviewer_status:already-reviewed"
    echo "name:$REVIEW_NAME"
    exit 0
  fi
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
# Spawn as the `pr-reviewer` AGENT with a PLAIN prompt — this is what makes the
# watch loop work. The Stop hook (enforce-watch) that keeps the reviewer alive
# between commits only fires for an agent session, exactly like the runner's
# enforce-completion. Two things matter and BOTH are mirrored from the runner:
#   1. --agent pr-reviewer  → registers enforce-watch at the session level
#      (skill-frontmatter hooks do NOT register for a spawned session).
#   2. a PLAIN prompt (NOT a leading "/pr-review …") → a slash-command as the
#      initial prompt makes the harness treat it as a skill session, which does
#      not apply the agent's hooks. The agent's body invokes /pr-review --inline.
SPAWN_OUT=$(claude --bg --agent pr-reviewer --permission-mode bypassPermissions --name "$REVIEW_NAME" "Review and watch pull request: $PR_URL" 2>&1)

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
