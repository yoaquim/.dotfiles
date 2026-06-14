#!/usr/bin/env bash
# check-pr-state.sh — Source-agnostic PR review state for the runner's
# ping-pong loop. Replaces check-pr-reviews.sh (which was bot-only).
#
# Returns JSON:
#   { review_decision: APPROVED|CHANGES_REQUESTED|REVIEW_REQUIRED|null,
#     pr_state:        OPEN|MERGED|CLOSED,
#     head_sha:        <40-char SHA of the PR's head commit>,
#     ci_green:        true|false,
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

# CI green = no FAILURE/ERROR/PENDING/IN_PROGRESS/QUEUED rollups.
# A rollup item shape: {state|conclusion, name, ...}.
# CHECK_RUN: uses .conclusion (SUCCESS/FAILURE/...). STATUS_CONTEXT: uses .state (SUCCESS/FAILURE/PENDING).
CI_GREEN=$(jq -r '
  ([.statusCheckRollup // []
    | .[]
    | (.conclusion // .state // "")
    | ascii_upcase
   ]
   | map(select(. != "" and . != "SUCCESS" and . != "NEUTRAL" and . != "SKIPPED"))
   | length) == 0
' <<<"$PR_VIEW")

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
  --argjson threads "$UNRESOLVED" \
  '{
     review_decision: (if $rd == "null" or $rd == "" then null else $rd end),
     pr_state: $ps,
     head_sha: $sha,
     ci_green: $green,
     unresolved_threads: $threads
   }'
