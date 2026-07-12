#!/usr/bin/env bash
# Stop hook for the pr-reviewer watch loop. Allows Stop only when:
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
#
# REGISTRATION: this is registered GLOBALLY in settings.json Stop, NOT in the
# pr-reviewer agent's frontmatter — as defense in depth. Frontmatter hooks DO
# fire for --bg agent sessions (canary-verified 2026-07-04, CC 2.1.170; the old
# "cached at startup" claim was wrong), but this hook's whole job is to never
# silently not-fire, and the global registration is the one an agent-file edit
# can't drop. The template gate below scopes it to pr-reviewer sessions only.

set -uo pipefail

# --- Identification phase ---
# Until we've confirmed this is a live reviewer for an open PR, an error means
# "I can't tell whose session this is" → let the stop happen (fail-open).
trap 'exit 0' ERR

# Shared dispatch definitions: iso_to_epoch, fail-open logging. This hook fires
# for EVERY session's Stop (global registration), so a missing lib must fail
# open — but say so.
# shellcheck disable=SC1091
. "$HOME/.claude/scripts/lib/dispatch.sh" 2>/dev/null \
  || { echo "enforce-watch: fail-open: cannot source scripts/lib/dispatch.sh" >&2; exit 0; }
trap 'dispatch_fail_open enforce-watch $LINENO' ERR

INPUT=$(cat 2>/dev/null || echo '{}')
SID=$(jq -r '.session_id // ""' <<<"$INPUT")
[[ -z "$SID" ]] && exit 0

# Resolve the job dir. `claude --bg` names the dir by the SHORT session id (the
# first UUID segment, e.g. 3aa6edb5), but a Stop hook receives the FULL session id
# (3aa6edb5-a8e7-…). Interactive sessions use the full-uuid dir; bg reviewers use
# the short one. Try full first, then fall back to ${SID%%-*}. This was THE bug:
# the hook built the path from the full id, never found the bg reviewer's state
# file, and bailed fail-open at the check below — before it could ever watch, so
# watch.attempts stayed unwritten and every reviewer ended after one review.
JOBDIR="$HOME/.claude/jobs/$SID"
[[ -d "$JOBDIR" ]] || JOBDIR="$HOME/.claude/jobs/${SID%%-*}"
STATE="$JOBDIR/state.json"
[[ -f "$STATE" ]] || exit 0

# GATE: act ONLY on a pr-reviewer agent session. The harness records the agent in
# state.json as `template`. Since this hook is registered globally, every other
# session (interactive, runners, other agents) MUST exit 0 here — we can never
# trap a non-reviewer in the watch loop.
[[ "$(jq -r '.template // ""' "$STATE" 2>/dev/null)" == "pr-reviewer" ]] || exit 0

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
# (JOBDIR was resolved during identification — don't rebuild it from $SID here,
# which would re-break the short/full id lookup the identification phase fixed.)
trap 'echo "enforce-watch: transient error — staying in the watch loop. sleep 60, then try to end again." >&2; exit 2' ERR

# Runaway-spin backstop, incremented FIRST so the loop is bounded even if anything
# below errors. A healthy watch Stops ~once/60s → ~480 times over 8hr, so the cap
# sits well above legitimate use.
ATTEMPT_FILE="$JOBDIR/watch.attempts"
ATTEMPTS=$(( $(cat "$ATTEMPT_FILE" 2>/dev/null || echo 0) + 1 ))
echo "$ATTEMPTS" > "$ATTEMPT_FILE" 2>/dev/null || true

# Durable audit trail. watch.attempts (above) lives in the job dir, which the
# daemon deletes the instant the session is killed — so it can't prove the hook
# fired after the fact. Append one line per fire to a log OUTSIDE the job dir, via
# an EXIT trap so every exit path is recorded with the decision it reached. Set
# here, past the gates, so only confirmed reviewer fires are logged.
WATCH_LOG="$HOME/.claude/pr-review-watch.log"
# Bound the log (~480 lines per reviewer per 8h, no other rotation).
if [[ -f "$WATCH_LOG" ]] && (( $(wc -l < "$WATCH_LOG") > 5000 )); then
  tail -1000 "$WATCH_LOG" > "$WATCH_LOG.tmp" 2>/dev/null && mv "$WATCH_LOG.tmp" "$WATCH_LOG" 2>/dev/null || true
fi
DECISION="keep-watching(transient-err)"
trap 'echo "$(date "+%Y-%m-%dT%H:%M:%S%z") sid=${SID%%-*} pr=$PR attempt=$ATTEMPTS decision=$DECISION" >> "$WATCH_LOG" 2>/dev/null' EXIT

if (( ATTEMPTS > 1000 )); then
  DECISION="allow-stop(runaway-guard)"
  echo "enforce-watch: >1000 stop attempts on PR #$PR; allowing stop (runaway-spin guard). Re-run /pr-review to resume watching." >&2
  exit 0
fi

# 8hr wall-clock cap.
CREATED=$(jq -r '.createdAt // ""' "$STATE")
if [[ -n "$CREATED" ]]; then
  EPOCH=$(iso_to_epoch "$CREATED")
  if (( EPOCH > 0 )) && (( $(date +%s) - EPOCH > 28800 )); then DECISION="allow-stop(8hr-cap)"; exit 0; fi
fi

# --- Poll backoff: bound how often we spend a GitHub GraphQL point ---
# The keep-watching messages below tell the model to `sleep 60` between Stop
# attempts, but that's advisory — a reviewer that retries Stop immediately re-runs
# check-pr-state.sh (a GraphQL call) every few seconds and can drain the graphql
# rate-limit bucket in minutes. Gate the poll on a timestamp so we hit GitHub at
# most once per POLL_INTERVAL no matter how fast Stop is retried; inside the window
# we keep watching WITHOUT polling. This is a FLOOR below the model's own ~60s
# cadence, so a well-behaved reviewer never notices it — only a spinning one gets
# throttled. The stamp lives in the job dir (daemon-cleaned on kill), so a fresh
# reviewer always polls immediately.
POLL_INTERVAL=30
POLL_STAMP="$JOBDIR/watch.last-poll"
NOW=$(date +%s)
LAST_POLL=$(cat "$POLL_STAMP" 2>/dev/null || echo 0)
if (( NOW - LAST_POLL < POLL_INTERVAL )); then
  DECISION="keep-watching(backoff)"
  # The "sleep 60" instruction below is advisory and observed reviewers retry
  # every ~3s — sleep here too, so the hook itself enforces a floor and each
  # blocked attempt costs one model turn less often.
  sleep 5
  {
    if (( LAST_POLL > NOW )); then
      # The rate-limited branch below parks the stamp in the FUTURE (quota
      # reset time) — "polled -540s ago" would only confuse the reviewer.
      echo "Do NOT stop — GitHub polling for PR #$PR is deferred until the rate-limit quota resets (~$((LAST_POLL - NOW + POLL_INTERVAL))s from now)."
      echo "sleep 300, then try to end again. Do not run gh commands in the meantime."
    else
      echo "Do NOT stop — PR #$PR was polled $((NOW - LAST_POLL))s ago; backing off to spare the GitHub API rate limit."
      echo "sleep 60, then try to end again. The next state poll runs once ${POLL_INTERVAL}s have elapsed."
    fi
  } >&2
  exit 2
fi
echo "$NOW" > "$POLL_STAMP" 2>/dev/null || true

# One authoritative snapshot — pr_state, review_decision, ci_green, head_sha,
# reviewed/approved_at_head — all from check-pr-state.sh (repo resolved explicitly
# from the PR URL), so the reviewer's exit test uses the SAME definitions as the
# runner's "completed" test.
STATE_JSON=$(bash "$HOME/.claude/scripts/check-pr-state.sh" "$PR" "$REPO_SLUG" 2>/dev/null || echo '{}')

# A snapshot with an error (or no head_sha — every real PR has one) is a
# transient GitHub failure, not PR state. Acting on it would either stop the
# watch (pr_state UNKNOWN) or kick a duplicate review (reviewed_at_head false).
STATE_ERR=$(jq -r '.error // ""' <<<"$STATE_JSON")
STATE_SHA=$(jq -r '.head_sha // ""' <<<"$STATE_JSON")

# Rate-limit exhaustion is NOT a transient blip: check-pr-state only reports it
# when the graphql bucket is dry AND its REST fallback failed too. Re-polling
# before the reset is pure waste — ~100 failed polls and model turns over a
# 49-minute window, each saying only "transient error". Advance the poll stamp
# to the reset time so the poll gate above enforces zero GitHub calls until the
# bucket refills (clamped to 90min against a garbage reset), and say exactly
# what is happening and when it ends.
if [[ "$STATE_ERR" == "rate_limited" ]]; then
  RESET_EPOCH=$(jq -r '.rate_reset_epoch // 0' <<<"$STATE_JSON")
  [[ "$RESET_EPOCH" =~ ^[0-9]+$ ]] || RESET_EPOCH=0
  NOW=$(date +%s)
  RESET_HUMAN="soon"
  if (( RESET_EPOCH > NOW )); then
    (( RESET_EPOCH > NOW + 5400 )) && RESET_EPOCH=$(( NOW + 5400 ))
    echo $(( RESET_EPOCH - POLL_INTERVAL )) > "$POLL_STAMP" 2>/dev/null || true
    RESET_HUMAN=$(date -r "$RESET_EPOCH" "+%H:%M:%S" 2>/dev/null \
      || date -d "@$RESET_EPOCH" "+%H:%M:%S" 2>/dev/null || echo "epoch $RESET_EPOCH")
  fi
  DECISION="keep-watching(rate-limited)"
  {
    echo "Do NOT stop — the GitHub API rate limit is exhausted; PR #$PR state cannot be polled."
    echo "The quota resets at $RESET_HUMAN. This hook blocks further GitHub polls until then —"
    echo "do not run check-pr-state.sh or any gh command yourself. sleep 300, then try to end again."
  } >&2
  exit 2
fi

if [[ -n "$STATE_ERR" || -z "$STATE_SHA" ]]; then
  DECISION="keep-watching(state-fetch-failed)"
  {
    echo "Do NOT stop — could not fetch PR #$PR state (transient GitHub error)."
    echo "sleep 60, then try to end again; the next attempt re-polls."
  } >&2
  exit 2
fi

PR_STATE=$(jq -r '.pr_state // "OPEN"' <<<"$STATE_JSON")
[[ "$PR_STATE" != "OPEN" ]] && { DECISION="allow-stop(pr-$PR_STATE)"; exit 0; }

REVIEW_DECISION=$(jq -r '.review_decision // ""' <<<"$STATE_JSON")
CI_GREEN=$(jq -r 'if .ci_green == true then "true" else "false" end' <<<"$STATE_JSON")
CUR_SHA=$(jq -r '.head_sha // ""' <<<"$STATE_JSON")
REVIEWED_AT_HEAD=$(jq -r 'if .reviewed_at_head == true then "true" else "false" end' <<<"$STATE_JSON")
APPROVED_AT_HEAD=$(jq -r 'if .approved_at_head == true then "true" else "false" end' <<<"$STATE_JSON")

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
if [[ "$APPROVED_HEAD" == "yes" && "$CI_GREEN" == "true" ]]; then DECISION="allow-stop(approved+ci-green)"; exit 0; fi

# Approved this exact HEAD, but CI isn't green yet → wait specifically on CI.
if [[ "$APPROVED_HEAD" == "yes" ]]; then
  DECISION="keep-watching(approved,ci-pending)"
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
  DECISION="keep-watching(review-new-head)"
  {
    echo "Do NOT stop — PR #$PR HEAD ($CUR_SHA) has not been reviewed yet."
    echo
    echo "Review the diff now (SKILL.md steps 1-6):"
    echo "  1. bash ~/.claude/skills/pr-review/ensure-review-checkout.sh $PR   — sync review checkout to the new HEAD"
    echo "     gh pr diff $PR                     — read the diff end to end, then Read the real files around each hunk"
    echo "  2. Apply bug-checklist.md + detected criteria (resolve-criteria.sh <checkout>)"
    echo "  3. Verify each candidate finding against the checkout — try to refute it; drop what doesn't survive"
    echo "  4. Fill templates/ (approved.md or changes-requested.md) + finding.md per finding"
    echo "  5. Post: gh api .../pulls/$PR/reviews --input <payload.json>"
    echo "           (APPROVE if zero findings, else REQUEST_CHANGES; on a self-authored 422, re-post as COMMENT)"
    echo
    echo "Then try to end again — this hook re-evaluates every turn."
  } >&2
  exit 2
fi

# HEAD already reviewed → nothing new. Idle one beat; do NOT re-review same SHA.
DECISION="keep-watching(idle,head-reviewed)"
sleep 5
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
