#!/usr/bin/env bash
# dispatch.sh — shared definitions for the dispatch machinery.
#
# Source it (never execute):  . "$HOME/.claude/scripts/lib/dispatch.sh"
#
# Single source of truth for the definitions that used to live in per-script
# copies (enforce-completion.sh, enforce-watch.sh, watchdog.sh, spawn.sh,
# spawn-reviewer.sh) and silently broke everything when they drifted:
#   - the status-file status vocabulary
#   - ISO-8601 → epoch parsing (BSD date first, GNU fallback)
#   - status-file field access (the sed regex IS the format spec)
#   - runner liveness / session-id resolution against `claude agents --json`
#   - fail-open trap logging (fail open, but say WHAT failed to stderr)

# ── Status vocabulary ─────────────────────────────────────────────────────────
# Statuses a runner may legally exit on (enforce-completion's gate).
DISPATCH_TERMINAL_STATUSES="completed needs_review closed-without-merge failed"
# Statuses that mean "runner actively working" — the ONLY ones a watchdog/janitor
# may resume (allowlist; the historical vocabulary drifted, blocklists lie).
DISPATCH_RESUMABLE_STATUSES="in_progress"
# Full current vocabulary, for validation. `blocked` is the operator-decision
# PARK: not terminal (the runner resumes once the operator answers) and not
# auto-resumable (operator-owned — the watchdog leaves it alone). enforce-completion
# ALLOWS the Stop on it so the --bg session parks ALIVE and attachable
# (`claude agents`) rather than dying; the runner asks its question via
# SendUserMessage (spawned with `--brief`). Distinct from a terminal exit, which
# yields a `done` session the operator cannot tab into.
DISPATCH_KNOWN_STATUSES="$DISPATCH_RESUMABLE_STATUSES blocked $DISPATCH_TERMINAL_STATUSES"

# Session states in `claude agents --json` that mean "not alive" (jq array).
DISPATCH_TERMINAL_SESSION_STATES='["completed","done","failed","stopped","exited","cancelled","canceled"]'

_dispatch_in_list() {
  local needle
  needle=$(printf '%s' "$1" | tr '[:upper:]' '[:lower:]')
  case " $2 " in
    *" $needle "*) return 0 ;;
    *) return 1 ;;
  esac
}

dispatch_is_terminal_status()  { _dispatch_in_list "${1:-}" "$DISPATCH_TERMINAL_STATUSES"; }
dispatch_is_resumable_status() { _dispatch_in_list "${1:-}" "$DISPATCH_RESUMABLE_STATUSES"; }
dispatch_is_known_status()     { _dispatch_in_list "${1:-}" "$DISPATCH_KNOWN_STATUSES"; }

# ── Status file access ────────────────────────────────────────────────────────
# dispatch_status_field <field> <file> — first value of a `- **field**: value`
# header line. This regex is the de-facto status-file format spec.
dispatch_status_field() {
  sed -n "s/^- \*\*${1}\*\*: //p" "$2" 2>/dev/null | head -1
}

# ── Time ──────────────────────────────────────────────────────────────────────
# ISO-8601 (optional fractional/Z/offset) → epoch seconds; 0 when unparseable.
# The offset MUST be honored: status files and jobs/state.json write UTC (`Z`),
# and truncating the suffix parsed them as local time — skewing every idle
# window and wall-clock cap by the UTC offset. Bare timestamps (no offset)
# parse as local time.
iso_to_epoch() {
  local ts="${1:-}"
  [[ -z "$ts" ]] && { echo 0; return; }
  local norm="${ts/ /T}"
  local re='^([0-9]{4}-[0-9]{2}-[0-9]{2}T[0-9]{2}:[0-9]{2}:[0-9]{2})(\.[0-9]+)?(Z|[+-][0-9]{2}:?[0-9]{2})?$'
  if [[ "$norm" =~ $re ]]; then
    local dt="${BASH_REMATCH[1]}" tz="${BASH_REMATCH[3]}"
    [[ "$tz" == "Z" ]] && tz="+0000"
    tz="${tz/:/}"
    if [[ -n "$tz" ]]; then
      date -j -f '%Y-%m-%dT%H:%M:%S%z' "${dt}${tz}" '+%s' 2>/dev/null && return
    else
      date -j -f '%Y-%m-%dT%H:%M:%S' "$dt" '+%s' 2>/dev/null && return
    fi
  fi
  date -d "$ts" '+%s' 2>/dev/null || echo 0
}

# ── Job-derived runner identity ───────────────────────────────────────────────
# Client env does NOT reach a `claude --bg` daemon worker (verified 2026-07-04:
# two concurrent workers both saw CLAUDE_DISPATCH_WORKTREE unset), so hooks can
# never rely on the CLAUDE_DISPATCH_* vars alone. The channel that DOES survive
# is the job state file: `template` records the --agent, and `cwd` records the
# submission cwd — which spawn.sh guarantees is the runner's worktree.

# dispatch_job_state_file <session_id> — path to the bg job's state.json.
# `claude --bg` names the job dir by the SHORT id (first UUID segment); hooks
# receive the FULL id. Try full, then short. Prints the path or returns 1.
dispatch_job_state_file() {
  local sid="${1:-}"
  [[ -n "$sid" ]] || return 1
  local d="$HOME/.claude/jobs/$sid"
  [[ -f "$d/state.json" ]] || d="$HOME/.claude/jobs/${sid%%-*}"
  [[ -f "$d/state.json" ]] || return 1
  printf '%s\n' "$d/state.json"
}

# dispatch_runner_worktree <session_id> — the worktree of a bg RUNNER session,
# from its job state. Prints the path or returns 1 (not a bg job / not a runner).
dispatch_runner_worktree() {
  local sf wt
  sf=$(dispatch_job_state_file "${1:-}") || return 1
  [[ "$(jq -r '.template // ""' "$sf" 2>/dev/null)" == "runner" ]] || return 1
  wt=$(jq -r '.cwd // ""' "$sf" 2>/dev/null)
  [[ -n "$wt" ]] || return 1
  printf '%s\n' "$wt"
}

# ── Sessions ──────────────────────────────────────────────────────────────────
# dispatch_name_alive <name> — a live (non-terminal) background session with
# this exact --name exists. Liveness by NAME, never by stored session_id, which
# goes stale the moment a runner is re-dispatched.
dispatch_name_alive() {
  claude agents --json 2>/dev/null | jq -e --arg n "$1" \
    --argjson t "$DISPATCH_TERMINAL_SESSION_STATES" '
    any(.[]?;
      ((.name // "") == $n)
      and (((.state // .status // "") | ascii_downcase) as $s | ($t | index($s) | not)))
  ' >/dev/null 2>&1
}

# dispatch_session_id_by_name <name> [retries] — short id of the live session
# with this --name; retries for agent-list latency (default 5 × 1s). Prints the
# id or nothing; callers keep their own stdout-scrape fallbacks.
dispatch_session_id_by_name() {
  local name="$1" retries="${2:-5}" sid=""
  local i
  for ((i = 0; i < retries; i++)); do
    sid=$(claude agents --json 2>/dev/null | jq -r --arg n "$name" \
      --argjson t "$DISPATCH_TERMINAL_SESSION_STATES" '
      [ .[]?
        | select((.name // "") == $n)
        | select(((.state // .status // "") | ascii_downcase) as $s | ($t | index($s) | not))
        | (.id // .sessionId // "")
      ] | first // ""
    ' 2>/dev/null) || sid=""
    [[ -n "$sid" ]] && { printf '%s\n' "$sid"; return 0; }
    sleep 1
  done
  return 1
}

# ── Fail-open trap logging ────────────────────────────────────────────────────
# Hooks fail OPEN by policy (never wedge a runner over a hook bug) — but a
# silent `trap 'exit 0' ERR` hides every failure. Use:
#   trap 'dispatch_fail_open <label> $LINENO' ERR
dispatch_fail_open() {
  echo "[${1:-dispatch}] fail-open: ERR trapped at line ${2:-?} (rc=$?)" >&2
  exit 0
}
