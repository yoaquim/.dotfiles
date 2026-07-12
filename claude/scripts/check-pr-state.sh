#!/usr/bin/env bash
# check-pr-state.sh — Source-agnostic PR review state for the runner's
# ping-pong loop. Replaces check-pr-reviews.sh (which was bot-only).
#
# Returns JSON:
#   { review_decision: APPROVED|CHANGES_REQUESTED|REVIEW_REQUIRED|null,
#     pr_state:        OPEN|MERGED|CLOSED,
#     head_sha:        <40-char SHA of the PR's head commit>,
#     ci_green:        true|false,
#     reviewed_at_head: true|false,   # ANY review exists for THIS HEAD (approve or findings)
#     approved_at_head: true|false,   # a review at THIS HEAD carries the approved.md sentinel
#     codex_state:      clean|pending|waiting|absent,  # Codex bot verdict (see 1c below)
#     unresolved_threads: [
#       { id, path, line, body, author }
#     ] }
#
# Usage: check-pr-state.sh <pr-number> [owner/repo]
#   Pass owner/repo to resolve the PR explicitly (cwd-independent). Callers that
#   may run from the wrong directory — e.g. enforce-watch.sh after the runner's
#   worktree is cleaned up — should always pass it. Falls back to `gh repo view`
#   (current dir) when omitted.
# Exit 0 always (errors are reported in JSON when possible).

set -uo pipefail

# iso_to_epoch (BSD/GNU date portable) for the codex "waiting" freshness window.
# shellcheck disable=SC1091
. "$HOME/.claude/scripts/lib/dispatch.sh" 2>/dev/null || true

PR="${1:-}"
if [[ -z "$PR" ]]; then
  echo '{"error":"usage: check-pr-state.sh <pr-number> [owner/repo]"}' >&2
  exit 1
fi

OWNER_REPO="${2:-}"
if [[ -z "$OWNER_REPO" ]]; then
  OWNER_REPO=$(gh repo view --json nameWithOwner -q '.nameWithOwner' 2>/dev/null || echo "")
fi
if [[ -z "$OWNER_REPO" ]]; then
  echo '{"error":"could not resolve owner/repo (pass owner/repo or run inside the repo)"}' >&2
  exit 1
fi
OWNER="${OWNER_REPO%/*}"
REPO="${OWNER_REPO#*/}"

# 1. One GraphQL call for everything GitHub's graph can give in a single request:
# PR-level state (reviewDecision, state, headRefOid), the CI status rollup, AND the
# review threads. This replaces the old two-call path — `gh pr view --json` (itself
# a GraphQL request) plus a separate `gh api graphql` for threads — halving the
# GraphQL points this script spends per invocation. The reviews list (step 1b) stays
# on REST on purpose: it draws from the roomier `core` bucket, not the scarce
# `graphql` one, so there's no reason to spend graphql points on it.
# `rateLimit { cost remaining resetAt }` rides along as an observability probe
# (logged to stderr below), so the running GraphQL cost is visible instead of only
# discoverable once the bucket hits zero.
# The call's stderr is captured (not discarded): it's the only way to tell
# "graphql bucket exhausted" apart from any other failure, and the two need
# different handling downstream (REST fallback vs. plain transient retry).
_gqlerr=$(mktemp)
# shellcheck disable=SC2016  # $vars are GraphQL variables, not shell
GRAPHQL_JSON=$(gh api graphql \
  -F owner="$OWNER" -F repo="$REPO" -F pr="$PR" \
  -f query='
    query($owner:String!, $repo:String!, $pr:Int!) {
      repository(owner:$owner, name:$repo) {
        pullRequest(number:$pr) {
          state
          reviewDecision
          headRefOid
          commits(last:1) {
            nodes {
              commit {
                committedDate
                statusCheckRollup {
                  contexts(first:100) {
                    nodes {
                      __typename
                      ... on CheckRun    { name status conclusion }
                      ... on StatusContext { context state }
                    }
                  }
                }
              }
            }
          }
          reviewThreads(first:100) {
            nodes {
              id
              isResolved
              comments(first:1) {
                nodes {
                  path
                  line
                  body
                  author { login }
                }
              }
            }
          }
        }
      }
      rateLimit { cost remaining resetAt }
    }
  ' 2>"$_gqlerr" || echo '{}')
GH_ERR=$(cat "$_gqlerr" 2>/dev/null || true); rm -f "$_gqlerr"

# GraphQL enum `state` is OPEN|CLOSED|MERGED — same values the old --json state gave.
PR_NODE='.data.repository.pullRequest'
REVIEW_DECISION=$(jq -r "$PR_NODE.reviewDecision // \"null\"" <<<"$GRAPHQL_JSON")
PR_STATE=$(jq -r "$PR_NODE.state // \"OPEN\"" <<<"$GRAPHQL_JSON")
HEAD_SHA=$(jq -r "$PR_NODE.headRefOid // \"\"" <<<"$GRAPHQL_JSON")

# Every real PR has a headRefOid — an empty one means the GraphQL call failed
# (or the PR doesn't exist). Rate-limit exhaustion gets its own two-step path:
# the graphql and core (REST) buckets are SEPARATE quotas, and everything the
# watch loop decides on — pr_state, head_sha, ci_green, review coverage — is
# also reachable over REST. Thread resolution is the one GraphQL-only field, so
# the fallback serves a degraded snapshot (threads_unavailable) instead of
# stalling the whole loop for the reset window. Any other failure keeps the
# explicit transient error: emitting the defaults (OPEN, vacuously-green CI,
# unreviewed HEAD) would make enforce-watch kick a duplicate review and show
# the runner fake green.
MODE=graphql
RATE_LIMITED=false
grep -qiE 'rate.?limit|RATE_LIMITED' <<<"$GH_ERR" && RATE_LIMITED=true
if [[ -z "$HEAD_SHA" && "$RATE_LIMITED" == "true" ]]; then
  PR_REST=$(gh api "repos/$OWNER/$REPO/pulls/$PR" 2>/dev/null || echo '{}')
  HEAD_SHA=$(jq -r '.head.sha // ""' <<<"$PR_REST" 2>/dev/null || echo "")
  if [[ -n "$HEAD_SHA" ]]; then
    MODE=rest
    echo "check-pr-state: PR #$PR graphql rate-limited — serving REST fallback (threads unavailable)" >&2
    # reviewDecision is GraphQL-only; approved_at_head (computed from the REST
    # reviews list below) is the primary approval signal anyway.
    REVIEW_DECISION="null"
    if [[ "$(jq -r '.merged // false' <<<"$PR_REST")" == "true" ]]; then
      PR_STATE="MERGED"
    else
      PR_STATE=$(jq -r '.state // "open"' <<<"$PR_REST" | tr '[:lower:]' '[:upper:]')
    fi
  fi
fi
if [[ -z "$HEAD_SHA" ]]; then
  if [[ "$RATE_LIMITED" == "true" ]]; then
    # Both buckets dry (or REST failing too). /rate_limit is exempt from rate
    # limiting, so the reset time is always fetchable — emit it so consumers
    # can back off until the bucket refills instead of burning attempts.
    RESET_EPOCH=$(gh api rate_limit --jq '.resources.graphql.reset' 2>/dev/null || echo 0)
    [[ "$RESET_EPOCH" =~ ^[0-9]+$ ]] || RESET_EPOCH=0
    jq -n --arg pr "$PR" --argjson reset "$RESET_EPOCH" '{
      error: "rate_limited",
      rate_reset_epoch: $reset,
      pr_state: "UNKNOWN", review_decision: null, head_sha: "",
      ci_green: false, reviewed_at_head: false, approved_at_head: false,
      codex_state: "absent", unresolved_threads: []
    }'
    exit 0
  fi
  jq -n --arg pr "$PR" '{
    error: ("transient: could not fetch PR #\($pr) state from GitHub"),
    pr_state: "UNKNOWN", review_decision: null, head_sha: "",
    ci_green: false, reviewed_at_head: false, approved_at_head: false,
    codex_state: "absent", unresolved_threads: []
  }'
  exit 0
fi

# CI green = no failing AND no still-running/queued checks.
# A rollup node is a CheckRun (.status = QUEUED|IN_PROGRESS|COMPLETED, plus
# .conclusion once COMPLETED) or a StatusContext (.state = SUCCESS|PENDING|...).
# A running CheckRun has .status=IN_PROGRESS and an empty .conclusion, so we must
# look at .status too — otherwise an in-flight check reads as green.
# Not-green if: status is set and not COMPLETED, OR the conclusion/state is set
# and not one of SUCCESS/NEUTRAL/SKIPPED. Same logic as before; the rollup array now
# lives under the last commit instead of a flattened `.statusCheckRollup`.
if [[ "$MODE" == "rest" ]]; then
  # Same green definition as the GraphQL rollup, from two REST sources:
  # check-runs (Actions etc.) and the combined commit status (legacy contexts).
  # The combined status reports "pending" when there are ZERO statuses, so an
  # empty statuses list must read as green, not pending.
  CHECK_RUNS=$(gh api --paginate "repos/$OWNER/$REPO/commits/$HEAD_SHA/check-runs" 2>/dev/null \
    | jq -s '[ .[].check_runs // [] ] | add // []' 2>/dev/null || echo '[]')
  [[ -n "$CHECK_RUNS" ]] || CHECK_RUNS='[]'
  COMBINED_STATUS=$(gh api "repos/$OWNER/$REPO/commits/$HEAD_SHA/status" 2>/dev/null || echo '{}')
  CI_GREEN=$(jq -n --argjson runs "$CHECK_RUNS" --argjson combined "$COMBINED_STATUS" '
    ([ $runs[]
       | { st: ((.status // "") | ascii_upcase),
           cc: ((.conclusion // "") | ascii_upcase) }
       | select(
           (.st != "" and .st != "COMPLETED")
           or (.cc != "" and .cc != "SUCCESS" and .cc != "NEUTRAL" and .cc != "SKIPPED")
         )
     ] | length) == 0
    and (
      ((($combined.statuses // []) | length) == 0)
      or (($combined.state // "") == "success")
    )' 2>/dev/null || echo false)
else
CI_GREEN=$(jq -r "
  ([ ($PR_NODE.commits.nodes[0].commit.statusCheckRollup.contexts.nodes // [])
     | .[]
     | { st: ((.status // \"\") | ascii_upcase),
         cc: ((.conclusion // .state // \"\") | ascii_upcase) }
     | select(
         (.st != \"\" and .st != \"COMPLETED\")
         or (.cc != \"\" and .cc != \"SUCCESS\" and .cc != \"NEUTRAL\" and .cc != \"SKIPPED\")
       )
   ] | length) == 0
" <<<"$GRAPHQL_JSON")
fi
[[ "$CI_GREEN" == "true" || "$CI_GREEN" == "false" ]] || CI_GREEN=false

# Observability probe: surface the GraphQL cost/remaining on stderr (never stdout —
# stdout is the JSON contract). Silent when the field is absent (e.g. the '{}'
# fallback on a failed call).
RL=$(jq -rc "if .data.rateLimit then \"graphql cost=\\(.data.rateLimit.cost) remaining=\\(.data.rateLimit.remaining) resetAt=\\(.data.rateLimit.resetAt)\" else empty end" <<<"$GRAPHQL_JSON" 2>/dev/null || true)
[[ -n "$RL" ]] && echo "check-pr-state: PR #$PR $RL" >&2

# 1b. Review coverage at the current HEAD — the authoritative dedup/exit signal.
# GitHub's reviewDecision can never become APPROVED on a self-authored dispatch PR
# (you can't approve your own PR), so coverage is decided from the reviews
# themselves, scoped to the current HEAD via commit_id. Both are computed from one
# fetch of the reviews list:
#   reviewed_at_head — ANY review submitted against this HEAD (approve OR findings).
#                      "This code has been reviewed" → don't re-review, don't spawn
#                      a second reviewer for it. Moves off when HEAD changes.
#   approved_at_head — a review at this HEAD carrying the approved.md sentinel (the
#                      same one check-post.sh uses, read from the single source of
#                      truth pr-review-markers.sh → approved.md).
# --paginate concatenates one JSON array per page; `jq -s 'add'` slurps them.
APPROVED_MARKER=""
# shellcheck disable=SC1091  # installed at runtime; not resolvable at lint time
source "$HOME/.claude/scripts/lib/pr-review-markers.sh" 2>/dev/null && APPROVED_MARKER=$(pr_review_approved_marker)
REVIEWED_AT_HEAD=false
APPROVED_AT_HEAD=false
ALL_REVIEWS=$(gh api --paginate "repos/$OWNER/$REPO/pulls/$PR/reviews" 2>/dev/null \
  | jq -sc 'add // []' 2>/dev/null || echo '[]')
[[ -n "$ALL_REVIEWS" ]] || ALL_REVIEWS='[]'
if [[ -n "$HEAD_SHA" ]]; then
  REVIEWS_AT_HEAD=$(jq -c --arg sha "$HEAD_SHA" \
    '[ .[] | select((.commit_id // "") == $sha) ]' <<<"$ALL_REVIEWS" 2>/dev/null || echo '[]')
  [[ -n "$REVIEWS_AT_HEAD" ]] || REVIEWS_AT_HEAD='[]'
  [[ "$(jq 'length' <<<"$REVIEWS_AT_HEAD" 2>/dev/null || echo 0)" -gt 0 ]] && REVIEWED_AT_HEAD=true
  if [[ -n "$APPROVED_MARKER" ]]; then
    APPROVED_AT_HEAD=$(jq --arg marker "$APPROVED_MARKER" \
      '[ .[] | select((.body // "") | contains($marker)) ] | (length > 0)' <<<"$REVIEWS_AT_HEAD" 2>/dev/null || echo false)
    [[ "$APPROVED_AT_HEAD" == "true" || "$APPROVED_AT_HEAD" == "false" ]] || APPROVED_AT_HEAD=false
  fi
fi

# 1c. Codex (chatgpt-codex-connector[bot]) verdict — the second reviewer on
# personal-machine dispatches. Its signals, observed on real PRs 2026-07-07:
#   clean       → a 👍 (+1) reaction on the PR BODY (no review is posted)
#   findings    → a COMMENTED "Codex Review" review with inline threads
#   out of credits → an issue comment "You have reached your Codex usage limits…"
# The verdict is whichever signal is NEWEST (ISO timestamps compare lexically):
#   codex_state: "clean"   — thumbs-up is the latest signal → Codex is satisfied
#                "pending" — a findings review is the latest signal → address its
#                            threads and push until it thumbs-ups
#                "waiting" — no Codex signal yet AND the head commit is < 15 min
#                            old: its first verdict may still be in flight (it
#                            lags PR creation by minutes) — don't complete into
#                            the race window; keep looping
#                "absent"  — Codex never engaged (head is old, still silent), or
#                            its latest signal is the usage-limits comment (no
#                            credits): Codex cannot rule, so the Claude reviewer
#                            is the final say
# Empty-body COMMENTED reviews are excluded — replying to an inline thread makes
# GitHub synthesize one (same artifact spawn-reviewer.sh's gate filters).
CODEX_LOGIN="chatgpt-codex-connector[bot]"
CODEX_LAST_REVIEW=$(jq -r --arg u "$CODEX_LOGIN" '
  [ .[] | select((.user.login // "") == $u)
    | select((.state // "") != "COMMENTED" or (((.body // "") | length) > 0))
    | .submitted_at // empty
  ] | max // ""' <<<"$ALL_REVIEWS" 2>/dev/null || echo "")
CODEX_LAST_THUMB=$(gh api --paginate "repos/$OWNER/$REPO/issues/$PR/reactions" 2>/dev/null \
  | jq -sr --arg u "$CODEX_LOGIN" '
    [ (add // [])[] | select((.user.login // "") == $u and .content == "+1")
      | .created_at // empty
    ] | max // ""' 2>/dev/null || echo "")
CODEX_LAST_QUOTA=$(gh api --paginate "repos/$OWNER/$REPO/issues/$PR/comments" 2>/dev/null \
  | jq -sr --arg u "$CODEX_LOGIN" '
    [ (add // [])[] | select((.user.login // "") == $u)
      | select((.body // "") | test("usage limits"; "i"))
      | .created_at // empty
    ] | max // ""' 2>/dev/null || echo "")
CODEX_STATE="absent"
if [[ -n "$CODEX_LAST_REVIEW" || -n "$CODEX_LAST_THUMB" ]]; then
  if [[ "$CODEX_LAST_THUMB" > "$CODEX_LAST_REVIEW" || "$CODEX_LAST_THUMB" == "$CODEX_LAST_REVIEW" ]]; then
    CODEX_STATE="clean"
  elif [[ -n "$CODEX_LAST_QUOTA" && "$CODEX_LAST_QUOTA" > "$CODEX_LAST_REVIEW" ]]; then
    CODEX_STATE="absent"   # findings exist but Codex ran out of credits after — it can never thumbs-up
  else
    CODEX_STATE="pending"
  fi
elif [[ -z "$CODEX_LAST_QUOTA" ]]; then
  # No Codex signal at all — but its first verdict LAGS the PR by minutes
  # (observed: runner exited terminal 13s before Codex's findings landed on
  # PR parcha#186). While the head commit is fresh, report "waiting" so the
  # runner keeps looping instead of completing into the race window; once the
  # head is old and Codex stayed silent, it isn't installed / isn't coming →
  # absent, the Claude reviewer is the final say. A quota comment (elif guard)
  # means Codex can't ever answer → absent immediately, no pointless wait.
  if [[ "$MODE" == "rest" ]]; then
    HEAD_COMMITTED=$(gh api "repos/$OWNER/$REPO/commits/$HEAD_SHA" \
      --jq '.commit.committer.date // ""' 2>/dev/null || echo "")
  else
    HEAD_COMMITTED=$(jq -r "$PR_NODE.commits.nodes[0].commit.committedDate // \"\"" <<<"$GRAPHQL_JSON")
  fi
  HEAD_EPOCH=$(iso_to_epoch "$HEAD_COMMITTED")
  if [[ "$HEAD_EPOCH" -gt 0 ]] && (( $(date +%s) - HEAD_EPOCH < 900 )); then
    CODEX_STATE="waiting"
  fi
fi

# 2. Unresolved review threads — already fetched in the combined GraphQL call above,
# so this is a pure jq reshape of GRAPHQL_JSON, no second round-trip to GitHub.
# REST fallback: thread resolution is GraphQL-only — report none, flagged as
# unavailable in the output so consumers don't mistake it for "all resolved".
if [[ "$MODE" == "rest" ]]; then
  UNRESOLVED='[]'
else
UNRESOLVED=$(jq -c '
  [ (.data.repository.pullRequest.reviewThreads.nodes // [])[]
    | select(.isResolved == false)
    | .comments.nodes[0] as $c
    | select($c != null)
    | {
        id: .id,
        path: ($c.path // ""),
        line: ($c.line // 0),
        body: ($c.body // ""),
        author: ($c.author.login // "")
      }
  ]
' <<<"$GRAPHQL_JSON" 2>/dev/null || echo '[]')
fi

jq -n \
  --arg rd "$REVIEW_DECISION" \
  --arg ps "$PR_STATE" \
  --arg sha "$HEAD_SHA" \
  --arg codex "$CODEX_STATE" \
  --arg mode "$MODE" \
  --argjson green "$CI_GREEN" \
  --argjson reviewed "$REVIEWED_AT_HEAD" \
  --argjson approved "$APPROVED_AT_HEAD" \
  --argjson threads "$UNRESOLVED" \
  '{
     review_decision: (if $rd == "null" or $rd == "" then null else $rd end),
     pr_state: $ps,
     head_sha: $sha,
     ci_green: $green,
     reviewed_at_head: $reviewed,
     approved_at_head: $approved,
     codex_state: $codex,
     unresolved_threads: $threads
   }
   + (if $mode == "rest"
      then { degraded: "rest-fallback", threads_unavailable: true }
      else {} end)'
