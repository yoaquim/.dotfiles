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

# Shared dispatch definitions (session-id resolution). Not a hook — a missing
# lib is a hard error, never fail-open.
# shellcheck disable=SC1091
. "$HOME/.claude/scripts/lib/dispatch.sh" \
  || { echo "error: cannot source ~/.claude/scripts/lib/dispatch.sh" >&2; exit 1; }

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

# Work-machine gate. The augment-risk/engineering plugin being installed IS the
# work-machine signal (it provides /engineering:pr, which runs CodeRabbit): there,
# PR review is dispatcher ⇄ CodeRabbit SaaS on the PR — never a Claude reviewer.
# Enforced HERE, at the single chokepoint, so every caller stands down: the
# auto-spawn hook, the runner's fallback call, /pr-review's background dispatch,
# AND the watchdog's reviewer-revive (which would otherwise resurrect a reviewer
# no one meant to exist). Same availability test runner.md uses for the skill.
if compgen -G "$HOME/.claude/plugins/cache/augment-risk/engineering/*/skills/pr/SKILL.md" >/dev/null 2>&1; then
  echo "reviewer_status:disabled"
  echo "name:(work machine — /engineering:pr + CodeRabbit reviews PRs here; no Claude reviewer)"
  exit 0
fi

# Resolve EVERYTHING the name depends on from the PR itself (not from cwd or the
# local branch), so the name is identical no matter who calls this or from where.
#
# Resolution is pure REST (`gh api repos/...`), NOT `gh pr view` (GraphQL): the
# two draw from separate rate-limit buckets, and the scarce graphql one being
# empty must never block reviewer spawning (observed: dispatchers idling ~30 min
# for the graphql window while core sat well under half used). Accepts the same
# refs callers pass: a PR url, a bare number, a number/branch with -R owner/repo.
resolve_pr_json() {
  local ref="${1#\#}"; shift
  local repo_arg="" owner_repo="" number=""
  while [[ $# -gt 0 ]]; do
    case "$1" in
      -R|--repo) repo_arg="${2:-}"; shift 2 ;;
      *) shift ;;
    esac
  done

  if [[ "$ref" =~ ^https?://[^/]+/([^/]+/[^/]+)/pull/([0-9]+) ]]; then
    owner_repo="${BASH_REMATCH[1]}"
    number="${BASH_REMATCH[2]}"
  else
    owner_repo="$repo_arg"
    if [[ -z "$owner_repo" ]]; then
      # owner/repo from the cwd's origin remote — plain git, zero API cost.
      local url
      url=$(git remote get-url origin 2>/dev/null) || return 1
      url="${url%/}"; url="${url%.git}"
      [[ "$url" =~ ([^/:]+)/([^/]+)$ ]] || return 1
      owner_repo="${BASH_REMATCH[1]}/${BASH_REMATCH[2]}"
    fi
    if [[ "$ref" =~ ^[0-9]+$ ]]; then
      number="$ref"
    else
      # Branch ref: newest matching PR, open preferred — same pick gh pr view makes.
      number=$(gh api "repos/$owner_repo/pulls?head=${owner_repo%%/*}:$ref&state=all&sort=created&direction=desc" 2>/dev/null \
        | jq -r '(map(select(.state == "open")) + .) | .[0].number // empty' 2>/dev/null)
      [[ -n "$number" ]] || return 1
    fi
  fi

  gh api "repos/$owner_repo/pulls/$number" 2>/dev/null \
    | jq -c '{number, url: .html_url, headRefName: .head.ref, title, headRefOid: .head.sha}' 2>/dev/null
}

PR_JSON=$(resolve_pr_json "$@")
if [[ -z "$PR_JSON" || "$PR_JSON" == "null" ]]; then
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
#
# One class of review object does NOT count: replying to an inline review
# thread (POST /pulls/:n/comments/:id/replies) makes GitHub synthesize an
# EMPTY body COMMENTED review at the reply's HEAD. Counting those broke the
# fix-then-respawn loop (NUL-147): author pushes a fix, replies to the
# findings, and the reply artifact convinces this gate the new HEAD was
# already reviewed. A review only counts as a verdict if it is a non-COMMENTED
# state or a COMMENTED with an actual body.
HEAD_SHA=$(jq -r '.headRefOid // empty' <<<"$PR_JSON")
# owner/repo from the canonical url, host-agnostic (handles GHE too).
NO_SCHEME=${REPO_PART#*://}   # <host>/<owner>/<repo>
OWNER_REPO=${NO_SCHEME#*/}    # <owner>/<repo>
if [[ -n "$HEAD_SHA" ]]; then
  REVIEWED_AT_HEAD=$(gh api --paginate "repos/$OWNER_REPO/pulls/$PR/reviews" 2>/dev/null \
    | jq -s --arg sha "$HEAD_SHA" '[ (add // [])[]
        | select((.commit_id // "") == $sha)
        | select((.state // "") != "COMMENTED" or (((.body // "") | length) > 0)) ] | (length > 0)' \
      2>/dev/null || echo false)
  if [[ "$REVIEWED_AT_HEAD" == "true" ]]; then
    echo "reviewer_status:already-reviewed"
    echo "name:$REVIEW_NAME"
    exit 0
  fi
fi

# Liveness + id resolution come from scripts/lib/dispatch.sh
# (dispatch_session_id_by_name) — the same name-based, terminal-state-filtered
# lookup the watchdog and spawn.sh use. (It drops the old kind=="background"
# filter; harmless — interactive sessions carry no --name, so the deterministic
# reviewer name can only match a background session.)

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
# bug. Retry briefly — the same latency tolerance the id-resolution below uses.
EXISTING=$(dispatch_session_id_by_name "$REVIEW_NAME" 3) || EXISTING=""
if [[ -n "$EXISTING" ]]; then
  echo "reviewer_status:already-running"
  echo "session_id:$EXISTING"
  echo "name:$REVIEW_NAME"
  exit 0
fi

# Give the reviewer a REAL checkout before spawning: a detached worktree at the
# PR HEAD (ensure-review-checkout.sh), so it reviews files — guards, callers —
# not just diff hunks. Best effort: if no local clone exists and cloning fails,
# spawn from the caller's cwd as before and the skill degrades to diff-only
# (and says so). The skill re-runs the same script each pass to re-sync HEAD.
CHECKOUT=""
CO_OUT=$(bash "$HOME/.claude/skills/pr-review/ensure-review-checkout.sh" "$PR_URL" 2>&1) \
  && CHECKOUT=$(grep '^checkout:' <<<"$CO_OUT" | cut -d: -f2-)
SPAWN_DIR="${CHECKOUT:-$PWD}"

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
SPAWN_OUT=$(cd "$SPAWN_DIR" && claude --bg --agent pr-reviewer --model default --permission-mode bypassPermissions --name "$REVIEW_NAME" "Review and watch pull request: $PR_URL${CHECKOUT:+ (review checkout, already synced to HEAD: $CHECKOUT)}" 2>&1)

# Resolve the id by the NAME we set (robust to --bg stdout wording). The lib
# retries for agent-list latency; then fall back to scraping --bg stdout.
SESSION_ID=$(dispatch_session_id_by_name "$REVIEW_NAME" 5) || SESSION_ID=""
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
