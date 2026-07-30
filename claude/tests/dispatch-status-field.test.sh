#!/usr/bin/env bash
# dispatch_upsert_status_field — records the resolved model/effort so a watchdog
# resume reproduces the session instead of falling back to the fleet default.
#
# It edits a live status file that enforce-completion.sh, watchdog.sh and
# /dispatch status all parse, so the bullet must land INSIDE the header block —
# an append past the prose is invisible to dispatch_status_field.

set -uo pipefail
# shellcheck source=/dev/null
. "$(dirname "${BASH_SOURCE[0]}")/lib.sh"
# shellcheck source=/dev/null
. "$HOME/.claude/scripts/lib/dispatch.sh"

echo "dispatch_upsert_status_field"

FIX="$TEST_TMP/status"
mkdir -p "$FIX"

make_status() {
  cat > "$1" <<'MD'
# runner-name

- **ticket**: ENG-142
- **session_id**: pending
- **branch**: feat/thing
- **worktree**: /tmp/wt
- **status**: in_progress
- **started**: 2026-07-29T10:00:00Z
- **updated**: 2026-07-29T10:00:00Z

## Progress
Runner starting...

## Commits
MD
}

# --- insert when absent ---
F="$FIX/insert.md"; make_status "$F"
dispatch_upsert_status_field model claude-opus-5 "$F"
expect_cmd 0 "inserts a missing field" \
  bash -c "[ \"\$(. \$HOME/.claude/scripts/lib/dispatch.sh; dispatch_status_field model '$F')\" = 'claude-opus-5' ]"
expect_cmd 0 "insert lands inside the header block, not after the prose" \
  bash -c "[ \"\$(grep -n 'model' '$F' | cut -d: -f1)\" -lt \"\$(grep -n '## Progress' '$F' | cut -d: -f1)\" ]"
expect_cmd 0 "existing fields survive the insert" \
  bash -c "[ \"\$(. \$HOME/.claude/scripts/lib/dispatch.sh; dispatch_status_field status '$F')\" = 'in_progress' ]"

# --- replace when present ---
F="$FIX/replace.md"; make_status "$F"
dispatch_upsert_status_field model claude-fable-5 "$F"
dispatch_upsert_status_field model claude-opus-5 "$F"
expect_cmd 0 "replaces rather than duplicating" \
  bash -c "[ \"\$(grep -c '^- \*\*model\*\*:' '$F')\" = 1 ]"
expect_cmd 0 "replacement wins" \
  bash -c "[ \"\$(. \$HOME/.claude/scripts/lib/dispatch.sh; dispatch_status_field model '$F')\" = 'claude-opus-5' ]"

# --- both fields coexist ---
F="$FIX/pair.md"; make_status "$F"
dispatch_upsert_status_field model claude-opus-5 "$F"
dispatch_upsert_status_field effort high "$F"
expect_cmd 0 "model and effort coexist" \
  bash -c "[ \"\$(. \$HOME/.claude/scripts/lib/dispatch.sh; dispatch_status_field effort '$F')\" = 'high' ] && [ \"\$(. \$HOME/.claude/scripts/lib/dispatch.sh; dispatch_status_field model '$F')\" = 'claude-opus-5' ]"

# --- the file stays valid for every other consumer ---
expect_cmd 0 "status file still passes validate-status-file.sh" \
  "$SCRIPTS/validate-status-file.sh" "$F"

# --- degenerate inputs fail closed, never corrupt ---
expect_cmd 1 "missing file returns non-zero" \
  dispatch_upsert_status_field model x "$FIX/nope.md"

F="$FIX/noheader.md"; printf '# just a title\n\nprose only\n' > "$F"
dispatch_upsert_status_field effort medium "$F"
expect_cmd 0 "a file with no header bullets still gets the field" \
  bash -c "[ \"\$(. \$HOME/.claude/scripts/lib/dispatch.sh; dispatch_status_field effort '$F')\" = 'medium' ]"

# --- no temp files left behind ---
expect_cmd 1 "leaves no .tmp files" bash -c "ls '$FIX'/*.tmp.* 2>/dev/null"

# --- first dispatch must ignore a model the skill agent invented ---
# A /dispatch agent sometimes writes its own model/effort into the status file
# before spawn.sh runs. Honoring that guess pinned real runners to a model
# nobody chose, then wrote it back out as though spawn.sh had resolved it.
# session_id is the discriminator: the template writes it as not-yet-resolved,
# and spawn.sh replaces it with the real id after a successful spawn.
# Mirrors spawn.sh's resolution block.
UNRESOLVED=pend'ing'   # split so the skip-marker guard can't misread the literal
resolve() { # $1=status file → "<model> / <effort>"
  local M="" E="" sid rec_m rec_e
  sid=$(dispatch_status_field session_id "$1")
  if [[ -n "$sid" && "$sid" != "$UNRESOLVED" ]]; then
    rec_m=$(dispatch_status_field model "$1")
    [[ -n "$rec_m" && "$rec_m" != "default" ]] && M="$rec_m"
    rec_e=$(dispatch_status_field effort "$1")
    [[ -n "$rec_e" ]] && E="$rec_e"
  fi
  echo "${M:-FLEET_MODEL} / ${E:-FLEET_EFFORT}"
}

expect_resolve() { # <want> <name> <status-file>
  local got; got=$(resolve "$3")
  if [[ "$got" == "$1" ]]; then
    PASS=$((PASS + 1)); printf '  ok    %s\n' "$2"
  else
    FAIL=$((FAIL + 1)); FAILED_NAMES+=("$2")
    printf '  FAIL  %s (got %s, want %s)\n' "$2" "$got" "$1"
  fi
}

F="$FIX/guessed.md"; make_status "$F"
dispatch_upsert_status_field model claude-opus-5 "$F"   # the agent's invention
dispatch_upsert_status_field effort medium "$F"
expect_resolve "FLEET_MODEL / FLEET_EFFORT" \
  "unresolved session_id → fleet default beats the agent's guess" "$F"

# --- a real resume DOES inherit what spawn.sh recorded ---
F="$FIX/resumed.md"; make_status "$F"
dispatch_upsert_status_field session_id c38f3fc0 "$F"
dispatch_upsert_status_field model claude-fable-5 "$F"
dispatch_upsert_status_field effort high "$F"
expect_resolve "claude-fable-5 / high" \
  "resolved session_id → recorded pair is honored" "$F"

# --- dispatch_init_status_file: code owns the shape ---
NOW=2026-07-30T18:00:00Z
G="$FIX/gen.md"
dispatch_init_status_file "$G" nul-999 NUL-999 "One Response Shape" feat/x /w/nul-999 "$NOW"
expect_cmd 0 "generated file passes the validator" "$SCRIPTS/validate-status-file.sh" "$G"
expect_cmd 0 "generates exactly the 8 canonical header bullets" \
  bash -c "[ \"\$(grep -cE '^- \*\*' '$G')\" = 8 ]"
expect_cmd 0 "carries the ticket and title it was given" \
  bash -c "grep -q '^- \*\*ticket\*\*: NUL-999$' '$G' && grep -q '^- \*\*title\*\*: One Response Shape$' '$G'"
expect_cmd 1 "adds no section the template doesn't define" \
  bash -c "grep -E '^## ' '$G' | grep -qvE '^## (Progress|Commits)$'"

# Sketch dispatches have neither ticket nor title — those bullets drop out and
# the file is still valid, since the validator treats both as optional.
K="$FIX/sketch.md"
dispatch_init_status_file "$K" sk "" "" sketch-x /w/sk "$NOW"
expect_cmd 0 "sketch form (no ticket/title) still validates" "$SCRIPTS/validate-status-file.sh" "$K"
expect_cmd 1 "omits the ticket bullet when empty" bash -c "grep -q 'ticket' '$K'"

# A live runner's prose lives in this file — regenerating over it would erase
# the Progress and Commits it has been writing.
printf 'RUNNER WROTE THIS\n' >> "$G"
dispatch_init_status_file "$G" nul-999 OTHER "Other" other /w/other "$NOW"
expect_cmd 0 "never clobbers an existing file" bash -c "grep -q 'RUNNER WROTE THIS' '$G'"
expect_cmd 0 "and leaves its original fields intact" \
  bash -c "[ \"\$(sed -n 's/^- \*\*branch\*\*: //p' '$G' | head -1)\" = 'feat/x' ]"

# --- a fabricated `started` is corrected on first dispatch, kept on resume ---
# The 8hr wall-clock cap is measured from `started`, so an invented value moves
# a real deadline. spawn.sh overwrites it while session_id is unresolved, then
# must leave it alone forever after — otherwise the cap restarts every resume.
T="$FIX/fabricated.md"; make_status "$T"
dispatch_upsert_status_field started 2026-07-30T23:59:00Z "$T"   # agent's invention
REAL=2026-07-30T18:00:00Z
sid=$(dispatch_status_field session_id "$T")
[[ "$sid" == "$UNRESOLVED" ]] && dispatch_upsert_status_field started "$REAL" "$T"
expect_cmd 0 "first dispatch overwrites a fabricated started" \
  bash -c "[ \"\$(sed -n 's/^- \*\*started\*\*: //p' '$T' | head -1)\" = '$REAL' ]"

dispatch_upsert_status_field session_id c38f3fc0 "$T"
sid=$(dispatch_status_field session_id "$T")
[[ "$sid" == "$UNRESOLVED" ]] && dispatch_upsert_status_field started 2026-07-31T06:00:00Z "$T"
expect_cmd 0 "resume preserves started (cap does not restart)" \
  bash -c "[ \"\$(sed -n 's/^- \*\*started\*\*: //p' '$T' | head -1)\" = '$REAL' ]"

summarize
