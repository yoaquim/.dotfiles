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

# 1. PR-level state: reviewDecision, state, CI rollup, head SHA.
# -R makes this cwd-independent so the right PR is read even if cwd drifted.
PR_VIEW=$(gh pr view "$PR" -R "$OWNER_REPO" --json reviewDecision,state,statusCheckRollup,headRefOid 2>/dev/null || echo '{}')
REVIEW_DECISION=$(jq -r '.reviewDecision // "null"' <<<"$PR_VIEW")
PR_STATE=$(jq -r '.state // "OPEN"' <<<"$PR_VIEW")
HEAD_SHA=$(jq -r '.headRefOid // ""' <<<"$PR_VIEW")

# CI green = no failing AND no still-running/queued checks.
# A rollup item is a CHECK_RUN (.status = QUEUED|IN_PROGRESS|COMPLETED, plus
# .conclusion once COMPLETED) or a STATUS_CONTEXT (.state = SUCCESS|PENDING|...).
# A running CHECK_RUN has .status=IN_PROGRESS and an empty .conclusion, so we must
# look at .status too — otherwise an in-flight check reads as green.
# Not-green if: status is set and not COMPLETED, OR the conclusion/state is set
# and not one of SUCCESS/NEUTRAL/SKIPPED.
CI_GREEN=$(jq -r '
  ([ .statusCheckRollup // []
     | .[]
     | { st: ((.status // "") | ascii_upcase),
         cc: ((.conclusion // .state // "") | ascii_upcase) }
     | select(
         (.st != "" and .st != "COMPLETED")
         or (.cc != "" and .cc != "SUCCESS" and .cc != "NEUTRAL" and .cc != "SKIPPED")
       )
   ] | length) == 0
' <<<"$PR_VIEW")

# 1b. Review coverage at the current HEAD — the authoritative dedup/exit signal.
# GitHub's reviewDecision can never become APPROVED on a self-authored dispatch PR
# (you can't approve your own PR), so coverage is decided from the reviews
# themselves, scoped to the current HEAD via commit_id. Both are computed from one
# fetch of the reviews list:
#   reviewed_at_head — ANY review submitted against this HEAD (approve OR findings).
#                      "This code has been reviewed" → don't re-review, don't spawn
#                      a second reviewer for it. Moves off when HEAD changes.
#   approved_at_head — a review at this HEAD carrying the approved.md sentinel (the
#                      same one check-post.sh/record-sha.sh use, read from the
#                      single source of truth pr-review-markers.sh → approved.md).
# --paginate concatenates one JSON array per page; `jq -s 'add'` slurps them.
APPROVED_MARKER=""
# shellcheck disable=SC1091  # installed at runtime; not resolvable at lint time
source "$HOME/.claude/scripts/lib/pr-review-markers.sh" 2>/dev/null && APPROVED_MARKER=$(pr_review_approved_marker)
REVIEWED_AT_HEAD=false
APPROVED_AT_HEAD=false
if [[ -n "$HEAD_SHA" ]]; then
  REVIEWS_AT_HEAD=$(gh api --paginate "repos/$OWNER/$REPO/pulls/$PR/reviews" 2>/dev/null \
    | jq -sc --arg sha "$HEAD_SHA" '[ (add // [])[] | select((.commit_id // "") == $sha) ]' 2>/dev/null || echo '[]')
  [[ -n "$REVIEWS_AT_HEAD" ]] || REVIEWS_AT_HEAD='[]'
  [[ "$(jq 'length' <<<"$REVIEWS_AT_HEAD" 2>/dev/null || echo 0)" -gt 0 ]] && REVIEWED_AT_HEAD=true
  if [[ -n "$APPROVED_MARKER" ]]; then
    APPROVED_AT_HEAD=$(jq --arg marker "$APPROVED_MARKER" \
      '[ .[] | select((.body // "") | contains($marker)) ] | (length > 0)' <<<"$REVIEWS_AT_HEAD" 2>/dev/null || echo false)
    [[ "$APPROVED_AT_HEAD" == "true" || "$APPROVED_AT_HEAD" == "false" ]] || APPROVED_AT_HEAD=false
  fi
fi

# 2. Unresolved review threads via GraphQL
# shellcheck disable=SC2016  # $vars are GraphQL variables, not shell
THREADS_JSON=$(gh api graphql \
  -F owner="$OWNER" -F repo="$REPO" -F pr="$PR" \
  -f query='
    query($owner:String!, $repo:String!, $pr:Int!) {
      repository(owner:$owner, name:$repo) {
        pullRequest(number:$pr) {
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
    }
  ' 2>/dev/null || echo '{}')

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
' <<<"$THREADS_JSON" 2>/dev/null || echo '[]')

jq -n \
  --arg rd "$REVIEW_DECISION" \
  --arg ps "$PR_STATE" \
  --arg sha "$HEAD_SHA" \
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
     unresolved_threads: $threads
   }'
