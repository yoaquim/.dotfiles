#!/usr/bin/env bash
# resolve-thread.sh — Mark a PR review thread as resolved via GraphQL.
#
# Usage: resolve-thread.sh <thread-id>
# Thread IDs come from check-pr-state.sh's unresolved_threads[].id field
# (GitHub global node IDs, e.g. PRT_kwDOABCDEF4).
#
# Exit 0 on success, 1 on error.

set -uo pipefail

THREAD_ID="${1:-}"
if [[ -z "$THREAD_ID" ]]; then
  echo "usage: resolve-thread.sh <thread-id>" >&2
  exit 1
fi

# shellcheck disable=SC2016  # $id is a GraphQL variable, not shell
RESULT=$(gh api graphql \
  -F id="$THREAD_ID" \
  -f query='mutation($id: ID!) {
    resolveReviewThread(input: { threadId: $id }) {
      thread { id isResolved }
    }
  }' 2>&1) || {
    echo "resolve-thread failed: $RESULT" >&2
    exit 1
  }

RESOLVED=$(jq -r '.data.resolveReviewThread.thread.isResolved // false' <<<"$RESULT" 2>/dev/null)
if [[ "$RESOLVED" != "true" ]]; then
  echo "resolve-thread did not confirm resolution: $RESULT" >&2
  exit 1
fi

echo "resolved: $THREAD_ID"
