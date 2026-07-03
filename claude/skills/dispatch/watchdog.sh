#!/usr/bin/env bash
# watchdog.sh — Resume dispatch runners that halted mid-loop.
#
# The dispatch loop is driven by Stop hooks (enforce-completion / enforce-watch):
# they keep a LIVE runner from quitting, but they cannot wake one that has already
# halted — machine sleep/lock, a crash, or a transient error tripping a hook's
# `trap 'exit 0' ERR` fail-open can leave a runner stopped with a non-terminal
# status and nothing to restart it. status.sh already DETECTS this; spawn.sh
# already RESUMES (reuses the worktree; runner.md "Re-dispatched sessions" reads
# the status file + git and continues only the remaining work). This script is the
# missing trigger between the two — run it on a timer (cron, ~10 min).
#
# Conservative + idempotent, so it can run unattended without spawning duplicates:
#   - ALLOWLIST, not blocklist: resumes only statuses that mean "runner actively
#     working" (RESUMABLE_STATUSES, default just `in_progress`). The status
#     vocabulary has drifted over time — merged/done/in_review/review/
#     ready_for_review all appear in old files — so a blocklist of known-terminals
#     can't be trusted; we only ever touch the current "working" status;
#   - WINDOWED on idle time: the status file must be quiet for >= STALE_MIN minutes
#     (grace window — don't race a just-halted/just-resumed runner) AND <= MAX_AGE_MIN
#     (a real halt is recent; something idle for days is abandoned, not halted —
#     leave it for the operator);
#   - liveness is by RUNNER NAME (dispatch-<repo>-<name>, deterministic), NOT the
#     status file's session_id — which goes stale the moment we re-dispatch, and
#     would otherwise make a freshly-resumed runner look dead and get double-spawned;
#   - a per-host lock means overlapping cron ticks can't both resume the same runner.
# A resumed runner reloads runner.md fresh, so this also upgrades old-code runners.
#
# Usage: watchdog.sh [--dry-run] [root ...]
#   With no roots, discovers every dir under ~/Projects holding a .dispatch/status.
#   --dry-run reports what it WOULD resume without spawning anything.
#
# Env: DISPATCH_WATCHDOG_STALE_MIN  (default 10)    — lower idle bound (grace)
#      DISPATCH_WATCHDOG_MAX_AGE_MIN (default 720)   — upper idle bound (abandon)
#      DISPATCH_WATCHDOG_STATUSES    (default "in_progress")
#      DISPATCH_WATCHDOG_ROOTS_GLOB  (default "$HOME/Projects")
#
# Exit 0 always — a watchdog must never wedge its scheduler.

set -uo pipefail

DRY_RUN=0
ROOTS=()
for a in "$@"; do
  case "$a" in
    --dry-run) DRY_RUN=1 ;;
    *) ROOTS+=("$a") ;;
  esac
done

# shellcheck disable=SC1091
. "$HOME/.claude/scripts/lib/dispatch.sh"

STALE_MIN="${DISPATCH_WATCHDOG_STALE_MIN:-10}"
MAX_AGE_MIN="${DISPATCH_WATCHDOG_MAX_AGE_MIN:-720}"
RESUMABLE_STATUSES="${DISPATCH_WATCHDOG_STATUSES:-$DISPATCH_RESUMABLE_STATUSES}"
ROOTS_BASE="${DISPATCH_WATCHDOG_ROOTS_GLOB:-$HOME/Projects}"
DISPATCH="$HOME/.claude/skills/dispatch"

now_epoch=$(date +%s)

# Single-flight: don't let an overlapping tick resume the same runner twice.
if [[ "$DRY_RUN" -eq 0 ]]; then
  LOCK_DIR="${TMPDIR:-/tmp}/dispatch-watchdog.lock"
  if ! mkdir "$LOCK_DIR" 2>/dev/null; then
    echo "watchdog: another run holds the lock; skipping this tick"
    exit 0
  fi
  trap 'rmdir "$LOCK_DIR" 2>/dev/null' EXIT
fi

# get_field / iso_to_epoch / name_alive come from scripts/lib/dispatch.sh —
# the shared single source of truth (they used to be per-script copies).
get_field() { dispatch_status_field "$@"; }
name_alive() { dispatch_name_alive "$@"; }

# Write the new short session id back into the status file (so /dispatch status
# and `claude attach` resolve the resumed session, not the dead one).
stamp_session_id() {
  local file="$1" sid="$2"
  [[ -n "$sid" ]] || return 0
  awk -v sid="$sid" '
    !done && /^- \*\*session_id\*\*:/ { sub(/:.*/, ": " sid); done=1 }
    { print }
  ' "$file" > "$file.wd.tmp" 2>/dev/null && mv "$file.wd.tmp" "$file" 2>/dev/null || true
}

discover_roots() {
  if [[ ${#ROOTS[@]} -gt 0 ]]; then printf '%s\n' "${ROOTS[@]}"; return; fi
  find "$ROOTS_BASE" -maxdepth 3 -type d -path '*/.dispatch/status' 2>/dev/null \
    | sed 's#/.dispatch/status$##'
}

checked=0; resumed=0; skipped=0
while IFS= read -r ROOT; do
  [[ -d "$ROOT/.dispatch/status" ]] || continue
  PROJECT=$(basename "$ROOT")
  shopt -s nullglob
  for FILE in "$ROOT"/.dispatch/status/*.md; do
    NAME=$(basename "$FILE" .md)
    checked=$((checked + 1))

    STATUS=$(get_field status "$FILE" | tr '[:upper:]' '[:lower:]')
    case " $RESUMABLE_STATUSES " in
      *" $STATUS "*) ;;             # an actively-working status → candidate
      *) continue ;;                # terminal/legacy/paused → leave alone
    esac

    RUNNER_NAME="dispatch-$PROJECT-$NAME"
    if name_alive "$RUNNER_NAME"; then
      continue                      # still running → nothing to do
    fi

    # Halted (resumable status, no live session). Window the idle time: past the
    # grace floor, under the abandonment ceiling.
    UPDATED=$(get_field updated "$FILE")
    U_EPOCH=$(iso_to_epoch "$UPDATED")
    IDLE_S=$(( now_epoch - U_EPOCH ))
    if [[ "$U_EPOCH" -gt 0 ]] && (( IDLE_S < STALE_MIN * 60 )); then
      echo "skip  $RUNNER_NAME — halted but updated $UPDATED (< ${STALE_MIN}m ago); grace window"
      skipped=$((skipped + 1))
      continue
    fi
    if [[ "$U_EPOCH" -gt 0 ]] && (( IDLE_S > MAX_AGE_MIN * 60 )); then
      echo "skip  $RUNNER_NAME — idle since $UPDATED (> ${MAX_AGE_MIN}m); abandoned, not a fresh halt — resume manually if wanted"
      skipped=$((skipped + 1))
      continue
    fi

    BRANCH=$(get_field branch "$FILE")
    PROMPT="$ROOT/.dispatch/prompts/$NAME.md"
    if [[ -z "$BRANCH" || ! -f "$PROMPT" ]]; then
      echo "skip  $RUNNER_NAME — missing branch or prompt file ($PROMPT)"
      skipped=$((skipped + 1))
      continue
    fi

    # Never resume against a mangled status file — surface it instead.
    if ! VERDICT=$(bash "$HOME/.claude/scripts/validate-status-file.sh" "$FILE" 2>/dev/null); then
      echo "skip  $RUNNER_NAME — status file failed validation: $VERDICT"
      skipped=$((skipped + 1))
      continue
    fi

    if [[ "$DRY_RUN" -eq 1 ]]; then
      echo "WOULD resume $RUNNER_NAME (status=$STATUS, idle since $UPDATED, branch=$BRANCH)"
      resumed=$((resumed + 1))
      continue
    fi

    echo "resume $RUNNER_NAME (status=$STATUS, idle since $UPDATED) — re-dispatching"
    if OUT=$(bash "$DISPATCH/spawn.sh" "$NAME" "$BRANCH" "$ROOT" "$PROMPT" 2>&1); then
      SID=$(sed -n 's/^session_id://p' <<<"$OUT" | head -1)
      stamp_session_id "$FILE" "$SID"
      echo "  resumed $RUNNER_NAME → session ${SID:-?}"
      resumed=$((resumed + 1))
    else
      echo "  FAILED to resume $RUNNER_NAME:"; sed 's/^/    /' <<<"$OUT"
    fi
  done
  shopt -u nullglob
done < <(discover_roots)

VERB="resumed"; [[ "$DRY_RUN" -eq 1 ]] && VERB="would-resume"
echo "watchdog: checked $checked runner(s), $VERB $resumed, skipped $skipped"
exit 0
