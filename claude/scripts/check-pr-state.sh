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
#     codex_state:      clean|pending|absent,  # Codex bot verdict (see 1c below)
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
  ' 2>/dev/null || echo '{}')

# GraphQL enum `state` is OPEN|CLOSED|MERGED — same values the old --json state gave.
PR_NODE='.data.repository.pullRequest'
REVIEW_DECISION=$(jq -r "$PR_NODE.reviewDecision // \"null\"" <<<"$GRAPHQL_JSON")
PR_STATE=$(jq -r "$PR_NODE.state // \"OPEN\"" <<<"$GRAPHQL_JSON")
HEAD_SHA=$(jq -r "$PR_NODE.headRefOid // \"\"" <<<"$GRAPHQL_JSON")

# Every real PR has a headRefOid — an empty one means the GraphQL call failed
# (or the PR doesn't exist). Say so explicitly instead of emitting the defaults
# (OPEN, vacuously-green CI, unreviewed HEAD), which consumers would act on:
# enforce-watch would kick a duplicate review, the runner would see fake green.
if [[ -z "$HEAD_SHA" ]]; then
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
#                "absent"  — Codex never engaged, or its latest signal is the
#                            usage-limits comment (no credits): Codex cannot rule,
#                            so the Claude reviewer is the final say
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
fi

# 2. Unresolved review threads — already fetched in the combined GraphQL call above,
# so this is a pure jq reshape of GRAPHQL_JSON, no second round-trip to GitHub.
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

jq -n \
  --arg rd "$REVIEW_DECISION" \
  --arg ps "$PR_STATE" \
  --arg sha "$HEAD_SHA" \
  --arg codex "$CODEX_STATE" \
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
   }'
