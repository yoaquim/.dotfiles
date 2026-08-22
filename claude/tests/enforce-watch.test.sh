#!/usr/bin/env bash
# enforce-watch.sh — the reviewer watch loop, gate by gate.
#
# Registered globally on Stop, so the identification phase must wave through
# every session that is NOT a live pr-reviewer watching a numbered PR — and
# once identified, the watch phase must HOLD the reviewer until approved+green
# +codex-settled, merge/close, or a safety cap. check-pr-state.sh is stubbed;
# each case pins one decision branch (the DECISION strings in the hook).

set -uo pipefail
# shellcheck source=/dev/null
. "$(dirname "${BASH_SOURCE[0]}")/lib.sh"

H="$HOME/.claude/skills/pr-review/hooks/enforce-watch.sh"
echo "enforce-watch.sh"

FIX="$TEST_TMP/watch"
FAKEHOME="$FIX/home"
JOBS="$FAKEHOME/.claude/jobs"
mkdir -p "$FAKEHOME/.claude/scripts/lib" "$JOBS"
# shellcheck disable=SC2153  # SCRIPTS is exported by lib.sh
cp "$SCRIPTS/lib/dispatch.sh" "$SCRIPTS/lib/hooklog.sh" "$FAKEHOME/.claude/scripts/lib/"

# check-pr-state.sh stub: prints whatever the case staged.
PR_STATE_FILE="$FIX/pr-state.json"
cat > "$FAKEHOME/.claude/scripts/check-pr-state.sh" <<EOF
#!/bin/sh
cat "$PR_STATE_FILE"
EOF
chmod +x "$FAKEHOME/.claude/scripts/check-pr-state.sh"

SID="cafe0001-1111-2222-3333-444444444444"
JOBDIR="$JOBS/cafe0001"

# stage_job <template> <intent> [createdAt]
stage_job() {
  rm -rf "$JOBDIR"; mkdir -p "$JOBDIR"
  jq -n --arg t "$1" --arg i "$2" --arg c "${3:-}" \
    '{template:$t, intent:$i} + (if $c != "" then {createdAt:$c} else {} end)' \
    > "$JOBDIR/state.json"
}

# stage_pr <json> — next check-pr-state poll returns this; also reset the poll
# stamp (each hook run advances it, which would trip the backoff branch).
stage_pr() { printf '%s' "$1" > "$PR_STATE_FILE"; rm -f "$JOBDIR/watch.last-poll"; }

# run_watch <want> <name> [stderr-substring]
run_watch() {
  local want="$1" name="$2" grepfor="${3:-}" got out
  out=$(printf '{"session_id":"%s"}' "$SID" \
    | env HOME="$FAKEHOME" bash "$H" 2>&1); got=$?
  if [[ "$got" == "$want" ]] && { [[ -z "$grepfor" ]] || grep -q "$grepfor" <<<"$out"; }; then
    PASS=$((PASS + 1)); printf '  ok    %s\n' "$name"
  else
    FAIL=$((FAIL + 1)); FAILED_NAMES+=("$name")
    printf '  FAIL  %s (exit %s, want %s%s)\n' "$name" "$got" "$want" \
      "${grepfor:+, expecting \"$grepfor\" in output}"
    printf '%s\n' "$out" | sed -n '1,3p' | sed 's/^/        /'
  fi
}

OPEN_BASE='{"pr_state":"OPEN","head_sha":"abc123","review_decision":null'

# ── Identification: everyone who is NOT a watching reviewer walks free ───────
run_watch 0 "no matching job state waves through"
stage_job runner "whatever 42"
run_watch 0 "runner sessions are never trapped"
stage_job claude "review PR 42"
run_watch 0 "other bg templates are never trapped"
stage_job pr-reviewer "review PR 42 --once"
run_watch 0 "--once reviewer may stop"
stage_job pr-reviewer "review the current branch"
run_watch 0 "branch mode (no PR number) may stop"

# ── Watch phase: safety caps ─────────────────────────────────────────────────
stage_job pr-reviewer "watch https://github.com/o/r/pull/42"
echo 1001 > "$JOBDIR/watch.attempts"
run_watch 0 "runaway-spin guard releases" "runaway-spin"

stage_job pr-reviewer "watch https://github.com/o/r/pull/42" "2026-08-01T00:00:00Z"
stage_pr "$OPEN_BASE}"
run_watch 0 "8hr cap releases"

# ── Watch phase: PR state decisions ──────────────────────────────────────────
watch_job() { stage_job pr-reviewer "watch https://github.com/o/r/pull/42" \
  "$(date -u +%Y-%m-%dT%H:%M:%SZ)"; }

watch_job; stage_pr '{"pr_state":"MERGED","head_sha":"abc123"}'
run_watch 0 "merged PR releases"
watch_job; stage_pr '{"pr_state":"CLOSED","head_sha":"abc123"}'
run_watch 0 "closed PR releases"

watch_job; stage_pr "$OPEN_BASE,\"ci_green\":true,\"approved_at_head\":true,\"codex_state\":\"clean\"}"
run_watch 0 "approved + green + codex clean releases"
watch_job; stage_pr "$OPEN_BASE,\"ci_green\":true,\"approved_at_head\":true,\"codex_state\":\"absent\"}"
run_watch 0 "approved + green + codex absent releases"

watch_job; stage_pr "$OPEN_BASE,\"ci_green\":true,\"approved_at_head\":true,\"codex_state\":\"pending\"}"
run_watch 2 "codex pending holds the reviewer" "Codex is still engaged"
watch_job; stage_pr "$OPEN_BASE,\"ci_green\":false,\"approved_at_head\":true,\"codex_state\":\"clean\"}"
run_watch 2 "approved but CI not green holds" "CI is not green"
watch_job; stage_pr "$OPEN_BASE,\"ci_green\":true,\"reviewed_at_head\":false,\"codex_state\":\"waiting\"}"
run_watch 2 "unreviewed HEAD demands a review" "has not been reviewed yet"
watch_job; stage_pr "$OPEN_BASE,\"ci_green\":false,\"reviewed_at_head\":true,\"codex_state\":\"waiting\"}"
run_watch 2 "reviewed HEAD idles without re-reviewing" "do NOT re-review"

# Transient GitHub failure: fail CLOSED, keep watching.
watch_job; stage_pr '{}'
run_watch 2 "state fetch failure keeps watching" "transient GitHub error"

# Poll backoff: a second Stop within the window blocks WITHOUT re-polling.
watch_job; stage_pr "$OPEN_BASE,\"ci_green\":false,\"reviewed_at_head\":true,\"codex_state\":\"waiting\"}"
run_watch 2 "first poll goes through" "do NOT re-review"
stage_pr '{"pr_state":"MERGED","head_sha":"abc123"}'
date +%s > "$JOBDIR/watch.last-poll"
run_watch 2 "inside the backoff window no re-poll happens" "backing off"

summarize
