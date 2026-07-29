#!/usr/bin/env bash
# Test helpers for the hook suite.
#
# Hooks communicate through exit codes: 0 allows, 2 blocks. Every assertion
# here is therefore "feed this JSON on stdin, expect this exit code" — the same
# contract the harness uses, so a passing test means the harness would see the
# same thing.

PASS=0
FAIL=0
FAILED_NAMES=()

# Each test gets its own TMPDIR: enforce-created-summary.sh writes one-shot
# stamps and per-session attempt counters there, and a leaked stamp from an
# earlier case would silently turn a real block into an allow.
TEST_TMP=$(mktemp -d "${TMPDIR:-/tmp}/claude-hook-tests.XXXXXX")
export TMPDIR="$TEST_TMP"
trap 'rm -rf "$TEST_TMP"' EXIT

# Consumed by the sourcing test files, which shellcheck can't see from here.
export HOOKS="$HOME/.claude/hooks"
export SCRIPTS="$HOME/.claude/scripts"

# expect_exit <want> <name> <hook-path> <json-stdin>
expect_exit() {
  local want="$1" name="$2" hook="$3" json="$4" got out
  out=$(printf '%s' "$json" | "$hook" 2>&1); got=$?
  if [[ "$got" == "$want" ]]; then
    PASS=$((PASS + 1))
    printf '  ok    %s\n' "$name"
  else
    FAIL=$((FAIL + 1))
    FAILED_NAMES+=("$name")
    printf '  FAIL  %s (exit %s, want %s)\n' "$name" "$got" "$want"
    printf '%s\n' "$out" | sed -n '1,3p' | sed 's/^/        /'
  fi
}

# expect_cmd <want-exit> <name> <cmd...>
expect_cmd() {
  local want="$1" name="$2"; shift 2
  local got
  "$@" >/dev/null 2>&1; got=$?
  if [[ "$got" == "$want" ]]; then
    PASS=$((PASS + 1))
    printf '  ok    %s\n' "$name"
  else
    FAIL=$((FAIL + 1))
    FAILED_NAMES+=("$name")
    printf '  FAIL  %s (exit %s, want %s)\n' "$name" "$got" "$want"
  fi
}

# edit_json <file> <old> <new> — a PreToolUse Edit payload.
edit_json() {
  jq -n --arg f "$1" --arg o "$2" --arg n "$3" \
    '{tool_name:"Edit",tool_input:{file_path:$f,old_string:$o,new_string:$n}}'
}

summarize() {
  echo
  if (( FAIL == 0 )); then
    echo "$PASS passed, 0 failed"
    exit 0
  fi
  echo "$PASS passed, $FAIL FAILED:"
  printf '  - %s\n' "${FAILED_NAMES[@]}"
  exit 1
}
