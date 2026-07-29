#!/usr/bin/env bash
# hooklog.sh — opt-in breadcrumbs for hook decisions.
#
# These hooks all fail open by design: any unexpected shape allows the action
# rather than trapping the agent. The cost is that a hook which silently bailed
# and a hook which deliberately allowed look identical from outside — nothing
# happens either way. enforce-created-summary.sh blocked wrongly 13 times before
# anyone noticed, and only transcript archaeology found it.
#
# Usage — one line near the top of a hook, after its name is known:
#
#   . "$HOME/.claude/scripts/lib/hooklog.sh" 2>/dev/null || true
#   hook_log_init "guard-test-edits"
#
# Then optionally, wherever the decision becomes known:
#
#   hook_reason "not a test file"
#
# An EXIT trap records the real exit code, so every path is logged including
# the fail-open ones nobody wrote a log line for.
#
# Off unless CLAUDE_HOOK_DEBUG is set. Writes to $CLAUDE_HOOK_LOG, default
# ${TMPDIR}/claude-hooks.log. Never writes to stdout — hooks use stdout for
# structured JSON the harness parses.

HOOK_NAME="${HOOK_NAME:-unknown}"
HOOK_REASON="${HOOK_REASON:-}"

hook_reason() { HOOK_REASON="$*"; }

hook_log_write() {
  [[ -n "${CLAUDE_HOOK_DEBUG:-}" ]] || return 0
  local logfile="${CLAUDE_HOOK_LOG:-${TMPDIR:-/tmp}/claude-hooks.log}"
  local code="$1" verdict
  case "$code" in
    0) verdict="allow" ;;
    2) verdict="BLOCK" ;;
    *) verdict="exit$code" ;;
  esac
  printf '%s  %-26s %-6s %s\n' \
    "$(date '+%Y-%m-%d %H:%M:%S')" "$HOOK_NAME" "$verdict" "${HOOK_REASON:-—}" \
    >>"$logfile" 2>/dev/null || true
}

hook_log_init() {
  HOOK_NAME="$1"
  [[ -n "${CLAUDE_HOOK_DEBUG:-}" ]] || return 0
  trap 'hook_log_write "$?"' EXIT
}
