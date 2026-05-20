#!/usr/bin/env bash
# Stop hook for /pr-review. Allows Stop only when:
#   - PR is MERGED or CLOSED
#   - 8hr cap reached (state.json .createdAt)
#   - --once was in args
#   - no PR identifier in args (branch mode)
# Otherwise blocks; Claude re-enters the watch loop.

set -uo pipefail
trap 'exit 0' ERR

INPUT=$(cat 2>/dev/null || echo '{}')
SID=$(jq -r '.session_id // ""' <<<"$INPUT")
[[ -z "$SID" ]] && exit 0

STATE="$HOME/.claude/jobs/$SID/state.json"
[[ -f "$STATE" ]] || exit 0

INTENT=$(jq -r '.intent // ""' "$STATE")
[[ "$INTENT" == *"--once"* ]] && exit 0

PR=$(echo "$INTENT" | grep -oE '[0-9]+' | tail -1)
[[ -z "$PR" ]] && exit 0   # branch mode

CREATED=$(jq -r '.createdAt // ""' "$STATE")
if [[ -n "$CREATED" ]]; then
  EPOCH=$(date -j -f '%Y-%m-%dT%H:%M:%S' "${CREATED%.*}" '+%s' 2>/dev/null \
       || date -d "$CREATED" +%s 2>/dev/null || echo 0)
  if (( EPOCH > 0 )) && (( $(date +%s) - EPOCH > 28800 )); then exit 0; fi
fi

PR_STATE=$(gh pr view "$PR" --json state -q .state 2>/dev/null || echo OPEN)
[[ "$PR_STATE" != "OPEN" ]] && exit 0

echo "PR #$PR still OPEN. Stay in watch loop (SKILL.md §6): sleep 60, re-poll check-pr-state.sh, re-review on new HEAD SHA. Hook will allow Stop on merge/close or 8hr cap." >&2
exit 2
