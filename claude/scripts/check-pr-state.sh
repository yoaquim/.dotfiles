#!/usr/bin/env bash
# check-pr-state.sh — Source-agnostic PR review state for the runner's
# ping-pong loop. Replaces check-pr-reviews.sh (which was bot-only).
#
# Returns JSON:
#   { review_decision: APPROVED|CHANGES_REQUESTED|REVIEW_REQUIRED|null,
#     pr_state:        OPEN|MERGED|CLOSED,
#     head_sha:        <40-char SHA of the PR's head commit>,
#     ci_green:        true|false,
#     approved_at_head: true|false,   # reviewer posted its approved.md for THIS HEAD
#     unresolved_threads: [
#       { id, path, line, body, author }
#     ] }
#
# Usage: check-pr-state.sh <pr-number>
# Exit 0 always (errors are reported in JSON when possible).

set -uo pipefail

PR="${1:-}"
if [[ -z "$PR" ]]; then
  echo '{"error":"usage: check-pr-state.sh <pr-number>"}' >&2
  exit 1
fi

OWNER_REPO=$(gh repo view --json nameWithOwner -q '.nameWithOwner' 2>/dev/null || echo "")
if [[ -z "$OWNER_REPO" ]]; then
  echo '{"error":"could not resolve owner/repo from current dir"}' >&2
  exit 1
fi
OWNER="${OWNER_REPO%/*}"
REPO="${OWNER_REPO#*/}"

# 1. PR-level state: reviewDecision, state, CI rollup, head SHA
PR_VIEW=$(gh pr view "$PR" --json reviewDecision,state,statusCheckRollup,headRefOid 2>/dev/null || echo '{}')
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

# 1b. Reviewer sign-off at the current HEAD.
# GitHub's reviewDecision can never become APPROVED on a self-authored dispatch
# PR (you can't approve your own PR), so we detect the reviewer's OWN sign-off
# instead: a review whose body carries the approved.md sentinel AND was submitted
# against the current HEAD (commit_id == head SHA). The sentinel is read from the
# single source of truth (pr-review-markers.sh → approved.md), the same one
# check-post.sh/record-sha.sh use; the commit_id scope means a stale approval on
# an older commit correctly does NOT count.
# --paginate concatenates one JSON array per page; `jq -s 'add'` slurps them.
APPROVED_MARKER=""
# shellcheck disable=SC1091  # installed at runtime; not resolvable at lint time
source "$HOME/.claude/scripts/lib/pr-review-markers.sh" 2>/dev/null && APPROVED_MARKER=$(pr_review_approved_marker)
APPROVED_AT_HEAD=false
if [[ -n "$HEAD_SHA" && -n "$APPROVED_MARKER" ]]; then
  APPROVED_AT_HEAD=$(gh api --paginate "repos/$OWNER/$REPO/pulls/$PR/reviews" 2>/dev/null \
    | jq -s --arg sha "$HEAD_SHA" --arg marker "$APPROVED_MARKER" '
        [ (add // [])[]
          | select((.commit_id // "") == $sha)
          | select((.body // "") | contains($marker)) ]
        | (length > 0)
      ' 2>/dev/null || echo false)
  [[ "$APPROVED_AT_HEAD" == "true" || "$APPROVED_AT_HEAD" == "false" ]] || APPROVED_AT_HEAD=false
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
  --argjson approved "$APPROVED_AT_HEAD" \
  --argjson threads "$UNRESOLVED" \
  '{
     review_decision: (if $rd == "null" or $rd == "" then null else $rd end),
     pr_state: $ps,
     head_sha: $sha,
     ci_green: $green,
     approved_at_head: $approved,
     unresolved_threads: $threads
   }'
