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

# One authoritative snapshot — pr_state, review_decision, ci_green, head_sha all
# from check-pr-state.sh, so the reviewer's exit test uses the SAME green
# definition as the runner's "completed" test.
STATE_JSON=$(bash "$HOME/.claude/scripts/check-pr-state.sh" "$PR" 2>/dev/null || echo '{}')

PR_STATE=$(jq -r '.pr_state // "OPEN"' <<<"$STATE_JSON")
[[ "$PR_STATE" != "OPEN" ]] && exit 0

# The reviewer's job is done once it has APPROVED AND all GitHub checks are green
# — then there's nothing left to review and nothing left to fail. Let it exit
# instead of watching until a human merges (which left an orphaned session burning
# until the 8hr cap). Approved but CI still pending/red → stay alive: a failing
# check may push a fix it should re-review. ci_green counts running/queued checks
# as not-green.
REVIEW_DECISION=$(jq -r '.review_decision // ""' <<<"$STATE_JSON")
CI_GREEN=$(jq -r 'if .ci_green == true then "true" else "false" end' <<<"$STATE_JSON")
if [[ "$REVIEW_DECISION" == "APPROVED" && "$CI_GREEN" == "true" ]]; then exit 0; fi

JOBDIR="$HOME/.claude/jobs/$SID"

# --- Runaway-spin backstop ---
# The 8hr cap bounds wall-clock; this bounds a session that ignores the sleep
# and Stops in a tight loop. A healthy watch Stops ~once/60s → ~480 times over
# 8hr, so the cap sits well above legitimate use.
ATTEMPT_FILE="$JOBDIR/watch.attempts"
ATTEMPTS=$(cat "$ATTEMPT_FILE" 2>/dev/null || echo 0)
ATTEMPTS=$((ATTEMPTS + 1))
echo "$ATTEMPTS" > "$ATTEMPT_FILE" 2>/dev/null || true
if (( ATTEMPTS > 1000 )); then
  echo "enforce-watch: >1000 stop attempts on PR #$PR; allowing stop (runaway-spin guard). Re-run /pr-review to resume watching." >&2
  exit 0
fi

# --- SHA compare: hand the agent one concrete next action ---
# last-reviewed-sha is stamped by check-post.sh when a review is posted; CUR_SHA
# reuses the snapshot above.
CUR_SHA=$(jq -r '.head_sha // ""' <<<"$STATE_JSON")
LAST_SHA=$(cat "$JOBDIR/last-reviewed-sha" 2>/dev/null || echo "")

if [[ -n "$CUR_SHA" && "$CUR_SHA" != "$LAST_SHA" ]]; then
  {
    echo "Do NOT stop — PR #$PR has an unreviewed HEAD."
    echo
    echo "  last reviewed: ${LAST_SHA:-<none>}"
    echo "  current HEAD:  $CUR_SHA"
    echo
    echo "Re-review the fresh diff now (SKILL.md steps 1-5):"
    echo "  1. gh pr diff $PR                     — read the new diff end to end"
    echo "  2. Apply bug-checklist.md + criteria/"
    echo "  3. Fill templates/ (approved.md or changes-requested.md) + finding.md per finding"
    echo "  4. Post: gh api .../pulls/$PR/reviews --input <payload.json>"
    echo "           (APPROVE if zero findings, else REQUEST_CHANGES)"
    echo
    echo "Then try to end again — this hook re-evaluates every turn."
  } >&2
  exit 2
fi

# HEAD already reviewed → nothing new. Idle one beat; do NOT re-review same SHA.
{
  echo "Do NOT stop, and do NOT re-review — PR #$PR HEAD (${CUR_SHA:-unknown}) is already reviewed."
  echo
  echo "Wait for the author, then re-check:"
  echo "  sleep 60"
  echo "  ~/.claude/scripts/check-pr-state.sh $PR    — re-poll HEAD"
  echo
  echo "Then try to end again. The hook releases Stop on merge/close or the 8hr cap,"
  echo "and kicks you straight into a fresh review the moment HEAD changes."
} >&2
exit 2
