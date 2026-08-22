#!/usr/bin/env bash
# scripts/lib/dispatch.sh — the shared definitions everything else trusts.
#
# Every enforcement hook, the watchdog, and both spawn scripts source this lib;
# a drift here breaks all of them at once, silently (they fail open). These
# units pin the load-bearing behaviors: the status vocabulary, the status-file
# format spec, offset-honoring time parsing, job-derived identity (the ONLY
# runner-identity channel — see the env-leak note in the lib), and session
# liveness against `claude agents --json`.

set -uo pipefail
# shellcheck source=/dev/null
. "$(dirname "${BASH_SOURCE[0]}")/lib.sh"

LIB="$SCRIPTS/lib/dispatch.sh"
echo "dispatch.sh (lib)"

FIX="$TEST_TMP/lib-fix"
mkdir -p "$FIX"

# lib_do <name> <want-exit> <snippet> [HOME override] — run a snippet with the
# lib sourced, optionally under a fake HOME (job-identity lookups) and the
# fixture bin first in PATH (claude stub).
lib_do() {
  local name="$1" want="$2" snippet="$3" home="${4:-$HOME}" got
  env HOME="$home" PATH="$FIX/bin:$PATH" \
    bash -c ". '$LIB'; $snippet" >/dev/null 2>&1; got=$?
  if [[ "$got" == "$want" ]]; then
    PASS=$((PASS + 1)); printf '  ok    %s\n' "$name"
  else
    FAIL=$((FAIL + 1)); FAILED_NAMES+=("$name")
    printf '  FAIL  %s (exit %s, want %s)\n' "$name" "$got" "$want"
  fi
}

# lib_out <name> <want-stdout> <snippet> [HOME override]
lib_out() {
  local name="$1" want="$2" snippet="$3" home="${4:-$HOME}" got
  got=$(env HOME="$home" PATH="$FIX/bin:$PATH" \
    bash -c ". '$LIB'; $snippet" 2>/dev/null)
  if [[ "$got" == "$want" ]]; then
    PASS=$((PASS + 1)); printf '  ok    %s\n' "$name"
  else
    FAIL=$((FAIL + 1)); FAILED_NAMES+=("$name")
    printf '  FAIL  %s (got %q, want %q)\n' "$name" "$got" "$want"
  fi
}

# ── Status vocabulary ────────────────────────────────────────────────────────
for s in completed needs_review closed-without-merge failed; do
  lib_do "terminal: $s" 0 "dispatch_is_terminal_status '$s'"
done
lib_do "terminal is case-insensitive" 0 "dispatch_is_terminal_status COMPLETED"
lib_do "in_progress is not terminal" 1 "dispatch_is_terminal_status in_progress"
lib_do "blocked is not terminal (parks alive)" 1 "dispatch_is_terminal_status blocked"
lib_do "empty is not terminal" 1 "dispatch_is_terminal_status ''"
lib_do "resumable: in_progress" 0 "dispatch_is_resumable_status in_progress"
lib_do "blocked is not resumable (operator-owned)" 1 "dispatch_is_resumable_status blocked"
lib_do "known: blocked" 0 "dispatch_is_known_status blocked"
lib_do "unknown status rejected" 1 "dispatch_is_known_status merged"

# ── Status-file field access (the regex IS the format spec) ──────────────────
SF="$FIX/status.md"
cat > "$SF" <<'EOF'
# Task

- **ticket**: TEST-1
- **status**: in_progress
- **started**: 2026-08-21T18:00:00Z
EOF
lib_out "field extraction" "in_progress" "dispatch_status_field status '$SF'"
lib_out "missing field is empty, not an error" "" "dispatch_status_field nope '$SF'"
lib_do  "missing field still exits 0" 0 "dispatch_status_field nope '$SF'"
lib_out "missing file is empty" "" "dispatch_status_field status '$FIX/absent.md'"

# Near-miss formats every parser must reject identically (Gate 0 depends on it).
cat > "$FIX/yaml.md" <<'EOF'
status: completed
EOF
lib_out "YAML frontmatter is invisible" "" "dispatch_status_field status '$FIX/yaml.md'"
printf -- '  - **status**: completed\n' > "$FIX/indented.md"
lib_out "indented bullet is invisible" "" "dispatch_status_field status '$FIX/indented.md'"
printf -- '- **status**:completed\n' > "$FIX/nospace.md"
lib_out "missing space after colon is invisible" "" "dispatch_status_field status '$FIX/nospace.md'"

# Duplicate field lines: first wins, and the head-induced SIGPIPE must be
# absorbed — under pipefail+ERR-trap callers it would otherwise fail-open past
# every gate.
cat > "$FIX/dup.md" <<'EOF'
- **status**: first
- **status**: second
EOF
lib_out "duplicate field: first wins" "first" "dispatch_status_field status '$FIX/dup.md'"
lib_do  "duplicate field exits 0 under pipefail" 0 \
  "set -o pipefail; dispatch_status_field status '$FIX/dup.md'"

# ── Status-file writes ───────────────────────────────────────────────────────
cp "$SF" "$FIX/upsert.md"
lib_do "upsert replaces in place" 0 \
  "dispatch_upsert_status_field status completed '$FIX/upsert.md' \
   && [[ \$(dispatch_status_field status '$FIX/upsert.md') == completed ]] \
   && [[ \$(grep -c '\*\*status\*\*' '$FIX/upsert.md') -eq 1 ]]"
lib_do "upsert inserts a missing field inside the header" 0 \
  "dispatch_upsert_status_field model opus '$FIX/upsert.md' \
   && [[ \$(dispatch_status_field model '$FIX/upsert.md') == opus ]]"
lib_do "upsert on a missing file fails" 1 \
  "dispatch_upsert_status_field status x '$FIX/absent.md'"

lib_do "init writes a canonical, parseable file" 0 \
  "dispatch_init_status_file '$FIX/init.md' t TEST-2 Title branch /wt 2026-08-21T00:00:00Z \
   && [[ \$(dispatch_status_field status '$FIX/init.md') == in_progress ]] \
   && [[ \$(dispatch_status_field ticket '$FIX/init.md') == TEST-2 ]]"
lib_do "init never overwrites an existing file" 0 \
  "dispatch_init_status_file '$FIX/init.md' t OTHER-9 X b /w 2026-01-01T00:00:00Z \
   && [[ \$(dispatch_status_field ticket '$FIX/init.md') == TEST-2 ]]"
lib_do "init omits empty ticket/title bullets" 0 \
  "dispatch_init_status_file '$FIX/sketch.md' t '' '' b /w 2026-08-21T00:00:00Z \
   && ! grep -q 'ticket' '$FIX/sketch.md' && ! grep -q 'title' '$FIX/sketch.md'"

# ── Time: offsets must be honored ────────────────────────────────────────────
lib_out "Z suffix parses as UTC" "1767225600" "iso_to_epoch 2026-01-01T00:00:00Z"
lib_out "+02:00 offset is honored" "1767225600" "iso_to_epoch 2026-01-01T02:00:00+02:00"
lib_out "fractional seconds accepted" "1767225600" "iso_to_epoch 2026-01-01T00:00:00.123Z"
lib_out "space separator normalized" "1767225600" "iso_to_epoch '2026-01-01 00:00:00Z'"
lib_out "empty is 0" "0" "iso_to_epoch ''"
lib_out "garbage is 0" "0" "iso_to_epoch not-a-date"

# ── Job-derived runner identity ──────────────────────────────────────────────
FAKEHOME="$FIX/home"
mkdir -p "$FAKEHOME/.claude/jobs/abcd1234" "$FAKEHOME/.claude/jobs/full-uuid-dir"
jq -n '{template:"runner", cwd:"/wt/short"}' > "$FAKEHOME/.claude/jobs/abcd1234/state.json"
jq -n '{template:"runner", cwd:"/wt/full"}' > "$FAKEHOME/.claude/jobs/full-uuid-dir/state.json"

lib_out "job state by short id (bg daemon naming)" "/wt/short" \
  "dispatch_runner_worktree abcd1234-9999-8888-7777-666666666666" "$FAKEHOME"
lib_out "job state by full id (interactive naming)" "/wt/full" \
  "dispatch_runner_worktree full-uuid-dir" "$FAKEHOME"
lib_do "unknown session id fails" 1 \
  "dispatch_runner_worktree deadbeef-0000" "$FAKEHOME"
lib_do "empty session id fails" 1 "dispatch_runner_worktree ''" "$FAKEHOME"

jq -n '{template:"pr-reviewer", cwd:"/wt/rev"}' > "$FAKEHOME/.claude/jobs/abcd1234/state.json"
lib_do "non-runner template is not a runner worktree" 1 \
  "dispatch_runner_worktree abcd1234-9999" "$FAKEHOME"
jq -n '{template:"runner"}' > "$FAKEHOME/.claude/jobs/abcd1234/state.json"
lib_do "runner template without cwd fails" 1 \
  "dispatch_runner_worktree abcd1234-9999" "$FAKEHOME"

# ── Session liveness (stubbed `claude agents --json`) ────────────────────────
mkdir -p "$FIX/bin"
claude_stub() {  # <json>
  printf '#!/bin/sh\ncat <<"JSON"\n%s\nJSON\n' "$1" > "$FIX/bin/claude"
  chmod +x "$FIX/bin/claude"
}

claude_stub '[{"name":"dispatch-r-x","kind":"background","state":"working"}]'
lib_do "working session is alive" 0 "dispatch_name_alive dispatch-r-x"
lib_do "other names are not alive" 1 "dispatch_name_alive dispatch-r-y"

claude_stub '[{"name":"dispatch-r-x","state":"done"}]'
lib_do "done session is not alive" 1 "dispatch_name_alive dispatch-r-x"

# Documented current semantics: idle/blocked sessions count as ALIVE. This is
# what makes a wedged-but-parked runner invisible to the watchdog — if that
# policy changes, this is the assertion to flip.
claude_stub '[{"name":"dispatch-r-x","state":"idle"}]'
lib_do "idle session counts as alive (wedge semantics)" 0 "dispatch_name_alive dispatch-r-x"

claude_stub '[{"name":"dispatch-r-x","status":"stopped"}]'
lib_do "legacy .status field is honored" 1 "dispatch_name_alive dispatch-r-x"
claude_stub 'not json'
lib_do "malformed agents JSON means not alive" 1 "dispatch_name_alive dispatch-r-x"

# The agents registry LOSES live sessions (observed 2026-08-21 on CC 2.1.234:
# a working runner absent from `claude agents --json` while its job state
# heartbeat was seconds old — the watchdog then double-spawned onto the live
# session). The jobs dir is the fallback: a non-terminal state.json with a
# fresh updatedAt means alive, no matter what the registry says.
claude_stub '[]'
mkdir -p "$FAKEHOME/.claude/jobs/lost0001"
jq -n --arg u "$(date -u +%Y-%m-%dT%H:%M:%SZ)" \
  '{name:"dispatch-r-lost", template:"runner", state:"working", updatedAt:$u}' \
  > "$FAKEHOME/.claude/jobs/lost0001/state.json"
lib_do "registry-lost session is alive via its job state" 0 \
  "dispatch_name_alive dispatch-r-lost" "$FAKEHOME"

jq -n --arg u "$(date -u -v-2H +%Y-%m-%dT%H:%M:%SZ)" \
  '{name:"dispatch-r-lost", state:"working", updatedAt:$u}' \
  > "$FAKEHOME/.claude/jobs/lost0001/state.json"
lib_do "stale job-state heartbeat does not count as alive" 1 \
  "dispatch_name_alive dispatch-r-lost" "$FAKEHOME"

jq -n --arg u "$(date -u +%Y-%m-%dT%H:%M:%SZ)" \
  '{name:"dispatch-r-lost", state:"done", updatedAt:$u}' \
  > "$FAKEHOME/.claude/jobs/lost0001/state.json"
lib_do "terminal job state does not count as alive" 1 \
  "dispatch_name_alive dispatch-r-lost" "$FAKEHOME"

# The session ID must also be resolvable from the jobs dir, so spawn guards
# (spawn-reviewer idempotency) don't double-spawn onto a registry-lost session.
jq -n --arg u "$(date -u +%Y-%m-%dT%H:%M:%SZ)" \
  '{name:"dispatch-r-lost", state:"working", updatedAt:$u}' \
  > "$FAKEHOME/.claude/jobs/lost0001/state.json"
lib_out "job session id resolves by name despite lost registry" "lost0001" \
  "dispatch_job_session_by_name dispatch-r-lost" "$FAKEHOME"
lib_do "job session lookup fails for unknown names" 1 \
  "dispatch_job_session_by_name dispatch-r-nope" "$FAKEHOME"

claude_stub '[{"name":"dispatch-r-x","state":"working","id":"aa11bb22"}]'
lib_out "session id resolves by name" "aa11bb22" \
  "dispatch_session_id_by_name dispatch-r-x 1"
lib_do "session id for a dead name fails (1 retry)" 1 \
  "dispatch_session_id_by_name dispatch-r-y 1"

# ── Fail-open trap ───────────────────────────────────────────────────────────
lib_do "fail_open exits 0 (never wedges the agent)" 0 "(dispatch_fail_open t 1)"
lib_do "fail_open names the failure on stderr" 0 \
  "( (dispatch_fail_open label 42) 2>&1 | grep -q 'label.*fail-open.*42' )"

# ── Operator session name (registry lookup by the caller's own session id) ──
OPHOME="$FIX/ophome"
mkdir -p "$OPHOME/.claude/sessions"
printf '{"sessionId":"1111-aaaa","name":"dotfiles-78","kind":"interactive"}' \
  > "$OPHOME/.claude/sessions/100.json"
printf '{"sessionId":"2222-bbbb","kind":"bg"}' > "$OPHOME/.claude/sessions/200.json"
lib_out "operator name resolves from the registry" "dotfiles-78" \
  "CLAUDE_CODE_SESSION_ID=1111-aaaa dispatch_operator_session_name" "$OPHOME"
lib_do "operator name fails outside a Claude session" 1 \
  "CLAUDE_CODE_SESSION_ID= dispatch_operator_session_name" "$OPHOME"
lib_do "operator name fails for an unknown session id" 1 \
  "CLAUDE_CODE_SESSION_ID=9999-zzzz dispatch_operator_session_name" "$OPHOME"
lib_do "operator name fails for a registered session with no name" 1 \
  "CLAUDE_CODE_SESSION_ID=2222-bbbb dispatch_operator_session_name" "$OPHOME"

rm -f "$FIX/bin/claude"

summarize
