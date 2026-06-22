#!/usr/bin/env bash
# Stop hook for /pr-review. Allows Stop only when:
#   - the current HEAD is approved (a review at HEAD carries the approved.md
#     sentinel, or an external reviewDecision==APPROVED) AND CI is green
#   - PR is MERGED or CLOSED
#   - 8hr cap reached (state.json .createdAt)
#   - --once was in args
#   - no PR identifier in args (branch mode)
# Otherwise blocks: Claude reviews the HEAD if it's unreviewed, else idles. All
# coverage/approval signals come from GitHub (check-pr-state.sh), NOT local stamp
# files — the stamps proved fragile (silently unwritten), which made reviewers
# re-review the same SHA and let duplicate reviewers spawn.

set -uo pipefail

# --- Identification phase ---
# Until we've confirmed this is a live reviewer for an open PR, an error means
# "I can't tell whose session this is" → let the stop happen (fail-open).
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

# Resolve owner/repo from the reviewer's PR URL in its intent, so the state check
# is cwd-independent — the reviewer's worktree can be cleaned up out from under it
# once the runner exits, which would otherwise resolve the wrong repo. Best-effort;
# empty is fine (check-pr-state falls back to cwd).
PR_URL=$(grep -oE 'https?://[^ ]+/pull/[0-9]+' <<<"$INTENT" | head -1)
REPO_SLUG=""
if [[ -n "$PR_URL" ]]; then
  _t=${PR_URL%/pull/*}; _t=${_t#*://}; REPO_SLUG=${_t#*/}
fi

# --- Watch phase ---
# From here we KNOW this is a live reviewer for open PR #PR. Fail CLOSED now: any
# unexpected error KEEPS the reviewer watching (exit 2), never a silent stop. This
# is the fix for reviewers dying after a single review — a transient hiccup in the
# hook used to fail open (exit 0) and let the session end, so the runner re-spawned
# a fresh reviewer per commit. The guards below still bound the loop.
JOBDIR="$HOME/.claude/jobs/$SID"
trap 'echo "enforce-watch: transient error — staying in the watch loop. sleep 60, then try to end again." >&2; exit 2' ERR

# Runaway-spin backstop, incremented FIRST so the loop is bounded even if anything
# below errors. A healthy watch Stops ~once/60s → ~480 times over 8hr, so the cap
# sits well above legitimate use.
ATTEMPT_FILE="$JOBDIR/watch.attempts"
ATTEMPTS=$(( $(cat "$ATTEMPT_FILE" 2>/dev/null || echo 0) + 1 ))
echo "$ATTEMPTS" > "$ATTEMPT_FILE" 2>/dev/null || true
if (( ATTEMPTS > 1000 )); then
  echo "enforce-watch: >1000 stop attempts on PR #$PR; allowing stop (runaway-spin guard). Re-run /pr-review to resume watching." >&2
  exit 0
fi

# 8hr wall-clock cap.
CREATED=$(jq -r '.createdAt // ""' "$STATE")
if [[ -n "$CREATED" ]]; then
  EPOCH=$(date -j -f '%Y-%m-%dT%H:%M:%S' "${CREATED%.*}" '+%s' 2>/dev/null \
       || date -d "$CREATED" +%s 2>/dev/null || echo 0)
  if (( EPOCH > 0 )) && (( $(date +%s) - EPOCH > 28800 )); then exit 0; fi
fi

# One authoritative snapshot — pr_state, review_decision, ci_green, head_sha,
# reviewed/approved_at_head — all from check-pr-state.sh (repo resolved explicitly
# from the PR URL), so the reviewer's exit test uses the SAME definitions as the
# runner's "completed" test.
STATE_JSON=$(bash "$HOME/.claude/scripts/check-pr-state.sh" "$PR" "$REPO_SLUG" 2>/dev/null || echo '{}')

PR_STATE=$(jq -r '.pr_state // "OPEN"' <<<"$STATE_JSON")
[[ "$PR_STATE" != "OPEN" ]] && exit 0

REVIEW_DECISION=$(jq -r '.review_decision // ""' <<<"$STATE_JSON")
CI_GREEN=$(jq -r 'if .ci_green == true then "true" else "false" end' <<<"$STATE_JSON")
CUR_SHA=$(jq -r '.head_sha // ""' <<<"$STATE_JSON")
REVIEWED_AT_HEAD=$(jq -r 'if .reviewed_at_head == true then "true" else "false" end' <<<"$STATE_JSON")
APPROVED_AT_HEAD=$(jq -r 'if .approved_at_head == true then "true" else "false" end' <<<"$STATE_JSON")

JOBDIR="$HOME/.claude/jobs/$SID"

# The reviewer's job is done once it has signed off on THIS HEAD AND CI is green —
# then there's nothing left to review and nothing left to fail. "Signed off" is
# read from GitHub (check-pr-state: a review at the current HEAD carrying the
# approved.md sentinel), NOT a local stamp. Self-authored PRs can't move GitHub's
# reviewDecision, so the sentinel is the signal; a real reviewDecision==APPROVED
# (external/bot reviewer) counts too. CI is the gate: approved but CI pending/red
# → keep watching (ci_green counts running/queued checks as not-green; a failing
# check may push a fix to re-review).
APPROVED_HEAD=no
[[ "$APPROVED_AT_HEAD" == "true" ]] && APPROVED_HEAD=yes
[[ "$REVIEW_DECISION" == "APPROVED" ]] && APPROVED_HEAD=yes
if [[ "$APPROVED_HEAD" == "yes" && "$CI_GREEN" == "true" ]]; then exit 0; fi

# Approved this exact HEAD, but CI isn't green yet → wait specifically on CI.
if [[ "$APPROVED_HEAD" == "yes" ]]; then
  {
    echo "Do NOT stop — you've approved PR #$PR HEAD ($CUR_SHA) but CI is not green yet."
    echo "Wait on the checks: sleep 60, then re-poll ~/.claude/scripts/check-pr-state.sh $PR."
    echo "You'll be allowed to stop once ci_green is true. If a new commit lands, re-review it."
  } >&2
  exit 2
fi

# --- Coverage check: is THIS HEAD already reviewed? (GitHub, not a local stamp) ---
# reviewed_at_head (check-pr-state) is true iff a review exists whose commit_id ==
# current HEAD. Unreviewed → review it. Already reviewed → idle (don't re-review
# the same SHA). This replaces the fragile last-reviewed-sha stamp, whose silent
# failures made the reviewer re-review one SHA repeatedly.
if [[ "$REVIEWED_AT_HEAD" != "true" ]]; then
  {
    echo "Do NOT stop — PR #$PR HEAD ($CUR_SHA) has not been reviewed yet."
    echo
    echo "Review the diff now (SKILL.md steps 1-5):"
    echo "  1. gh pr diff $PR                     — read the diff end to end"
    echo "  2. Apply bug-checklist.md + criteria/"
    echo "  3. Fill templates/ (approved.md or changes-requested.md) + finding.md per finding"
    echo "  4. Post: gh api .../pulls/$PR/reviews --input <payload.json>"
    echo "           (APPROVE if zero findings, else REQUEST_CHANGES; on a self-authored 422, re-post as COMMENT)"
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
