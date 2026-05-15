#!/usr/bin/env bash
# check-pr-reviews.sh — Check if machine reviewers (Codex, CodeRabbit) are satisfied.
# Returns JSON with review status. Ignores human reviews entirely.
#
# Usage: check-pr-reviews.sh <pr-number>
# Output: JSON { clean, unresolved_comments, failing_checks, pending }
# Exit 0 always.

set -euo pipefail

PR="${1:-}"
if [[ -z "$PR" ]]; then
  echo '{"error": "usage: check-pr-reviews.sh <pr-number>"}' >&2
  exit 1
fi

OWNER_REPO=$(gh repo view --json nameWithOwner -q '.nameWithOwner')

# Bot usernames to track (case-insensitive match)
BOT_PATTERN="codex|coderabbit|github-actions"

# 1. Unresolved bot review comments
UNRESOLVED=$(gh api "repos/$OWNER_REPO/pulls/$PR/comments" --paginate 2>/dev/null | \
  jq "[.[] | select(
    (.user.type == \"Bot\" or (.user.login | test(\"$BOT_PATTERN\"; \"i\")))
    and (.in_reply_to_id == null)
    and (.resolved // false | not)
  )] | length" 2>/dev/null || echo 0)

# 2. PR check runs matching bot names
CHECKS_JSON=$(gh pr checks "$PR" --json name,state 2>/dev/null || echo "[]")

FAILING=$(echo "$CHECKS_JSON" | jq "[.[] | select(
  (.name | test(\"$BOT_PATTERN\"; \"i\"))
  and .state == \"FAILURE\"
)] | [.[].name]" 2>/dev/null || echo "[]")

PENDING=$(echo "$CHECKS_JSON" | jq "[.[] | select(
  (.name | test(\"$BOT_PATTERN\"; \"i\"))
  and (.state == \"PENDING\" or .state == \"IN_PROGRESS\" or .state == \"QUEUED\")
)] | length" 2>/dev/null || echo 0)

# 3. Clean = no unresolved comments, no failing checks, no pending checks
CLEAN=false
if [[ "$UNRESOLVED" == "0" && "$FAILING" == "[]" && "$PENDING" == "0" ]]; then
  CLEAN=true
fi

jq -n \
  --argjson clean "$CLEAN" \
  --argjson unresolved "$UNRESOLVED" \
  --argjson failing "$FAILING" \
  --argjson pending "$PENDING" \
  '{clean: $clean, unresolved_comments: $unresolved, failing_checks: $failing, pending_checks: $pending}'
