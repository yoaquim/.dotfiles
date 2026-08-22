#!/usr/bin/env bash
# notify-done.sh — one notification per real finish of an interactive session.
#
# The regression this suite exists for: the hook gated on the leaked
# CLAUDE_DISPATCH_* env marker, and once a dispatch-born daemon served that
# marker to every session, notifications went silent globally (2026-08-21).
# The gates must come from per-session signals only: the stop_hook_active
# retry flag and the bg job's template.

set -uo pipefail
# shellcheck source=/dev/null
. "$(dirname "${BASH_SOURCE[0]}")/lib.sh"

# shellcheck disable=SC2153  # HOOKS is exported by lib.sh
H="$HOOKS/notify-done.sh"
echo "notify-done.sh"

FIX="$TEST_TMP/notify"
FAKEHOME="$FIX/home"
mkdir -p "$FAKEHOME/.claude/jobs" "$FIX/bin"

# osascript stub records each invocation; the marker file is the assertion.
MARK="$FIX/notified"
printf '#!/bin/sh\necho x >> "%s"\n' "$MARK" > "$FIX/bin/osascript"
chmod +x "$FIX/bin/osascript"

# run_notify <want> <name> <json> <expect-notified: yes|no>
run_notify() {
  local want="$1" name="$2" json="$3" notified="$4" got
  rm -f "$MARK"
  printf '%s' "$json" \
    | env HOME="$FAKEHOME" PATH="$FIX/bin:$PATH" "$H" >/dev/null 2>&1; got=$?
  local sent=no
  [[ -f "$MARK" ]] && sent=yes
  if [[ "$got" == "$want" && "$sent" == "$notified" ]]; then
    PASS=$((PASS + 1)); printf '  ok    %s\n' "$name"
  else
    FAIL=$((FAIL + 1)); FAILED_NAMES+=("$name")
    printf '  FAIL  %s (exit %s want %s, notified %s want %s)\n' \
      "$name" "$got" "$want" "$sent" "$notified"
  fi
}

# A retry after another Stop hook blocked → silent (already notified once).
run_notify 0 "blocked-stop retry is silent" \
  '{"stop_hook_active":true,"session_id":"s1","cwd":"/tmp"}' no

# Background runner / reviewer sessions → silent (loop machinery, not a finish).
mkdir -p "$FAKEHOME/.claude/jobs/aaaa1111"
jq -n '{template:"runner"}' > "$FAKEHOME/.claude/jobs/aaaa1111/state.json"
run_notify 0 "runner session is silent" \
  '{"stop_hook_active":false,"session_id":"aaaa1111-2222-3333-4444-555555555555","cwd":"/tmp"}' no

jq -n '{template:"pr-reviewer"}' > "$FAKEHOME/.claude/jobs/aaaa1111/state.json"
run_notify 0 "pr-reviewer session is silent" \
  '{"stop_hook_active":false,"session_id":"aaaa1111-2222-3333-4444-555555555555","cwd":"/tmp"}' no

# Other bg templates are not loop machinery → notify.
jq -n '{template:"claude"}' > "$FAKEHOME/.claude/jobs/aaaa1111/state.json"
run_notify 0 "non-loop bg template notifies" \
  '{"stop_hook_active":false,"session_id":"aaaa1111-2222-3333-4444-555555555555","cwd":"/tmp"}' yes

# A plain interactive session (no job state at all) → notify. This is the case
# the leaked env marker silenced.
run_notify 0 "interactive session notifies" \
  '{"stop_hook_active":false,"session_id":"bbbb2222-3333-4444-5555-666666666666","cwd":"/tmp"}' yes

# The leaked marker must be IGNORED — even when set, an interactive finish rings.
rm -f "$MARK"
printf '{"stop_hook_active":false,"session_id":"bbbb2222-0000","cwd":"/tmp"}' \
  | env HOME="$FAKEHOME" PATH="$FIX/bin:$PATH" \
    CLAUDE_DISPATCH_WORKTREE=/stale/leak "$H" >/dev/null 2>&1
if [[ $? -eq 0 && -f "$MARK" ]]; then
  PASS=$((PASS + 1)); echo "  ok    stale env marker cannot mute notifications"
else
  FAIL=$((FAIL + 1)); FAILED_NAMES+=("stale env mute")
  echo "  FAIL  stale env marker cannot mute notifications"
fi

summarize
