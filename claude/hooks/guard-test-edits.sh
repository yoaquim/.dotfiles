#!/usr/bin/env bash
# PreToolUse hook (Edit|Write|MultiEdit): block mechanical weakening of an
# existing test.
#
# ~/.claude/practices/test-integrity.md — "weakening counts as deleting". Most
# of that practice needs judgment and can only be enforced at review. Three of
# its items are mechanical facts about the edit itself, so they're enforced
# here instead of asked for politely:
#
#   1. a test switched off (skip/pending/xfail/ignore) — or focused with
#      `.only`, which switches off every sibling
#   2. assertions removed — the chunk checks less after the edit than before
#   3. a timeout raised — the standard way to make a race stop flaking
#
# Known gap: dropping a case from a table-driven test is invisible here, since
# the rows carry no assertions of their own. That one stays a review question.
#
# Only ever compares an edit against what was already there: new test files and
# added assertions are never touched. PreToolUse (not Post) so the weakening
# never lands on disk.
#
# Escape hatch: `test-weakening-ok` anywhere in the edited chunk allows it, for
# the genuinely justified case (deleting a feature, extracting assertions to a
# helper). Chunk-scoped, not line-scoped — same reasoning as
# check-playwright-routes.sh: these constructs legitimately span lines.
#
# Exit 0 → allow the edit. Exit 2 → block; stderr is fed back to the model.

set -uo pipefail

# shellcheck disable=SC1091
. "$HOME/.claude/scripts/lib/hooklog.sh" 2>/dev/null || true
hook_log_init "guard-test-edits"

# Never break editing because of a bug in this hook.
trap 'exit 0' ERR

INPUT=$(cat 2>/dev/null || echo '{}')
TOOL=$(jq -r '.tool_name // ""' <<<"$INPUT")
FILE=$(jq -r '.tool_input.file_path // ""' <<<"$INPUT")

[[ -n "$FILE" ]] || exit 0

# Shared with the PR-body gate — one definition of "test file", per dry.md.
BASE=${FILE##*/}
hook_reason "not a test file: $BASE"
"$HOME/.claude/scripts/is-test-path.sh" "$FILE" >/dev/null 2>&1 || exit 0

# Fixtures and factories are support code, not assertions — editing them down
# is not a coverage claim.
case "$BASE" in
  conftest.py|factories.*|fixtures.*|*.fixture.*|setup.*|helpers.*) hook_reason "support file, exempt"; exit 0 ;;
esac

# Write carries `content`, Edit `old_string`/`new_string`, MultiEdit an
# `edits[]` array. For Write the file on disk is still the pre-edit version —
# PreToolUse runs before the write — so it is the `old` side.
case "$TOOL" in
  Edit)
    OLD=$(jq -r '.tool_input.old_string // ""' <<<"$INPUT")
    NEW=$(jq -r '.tool_input.new_string // ""' <<<"$INPUT")
    ;;
  MultiEdit)
    OLD=$(jq -r '[.tool_input.edits[]?.old_string] | join("\n")' <<<"$INPUT")
    NEW=$(jq -r '[.tool_input.edits[]?.new_string] | join("\n")' <<<"$INPUT")
    ;;
  Write)
    NEW=$(jq -r '.tool_input.content // ""' <<<"$INPUT")
    # No file yet → a brand new test file. Nothing to weaken.
    [[ -f "$FILE" ]] || exit 0
    OLD=$(cat "$FILE" 2>/dev/null || echo "")
    ;;
  *) exit 0 ;;
esac

[[ -n "${NEW//[[:space:]]/}" ]] || exit 0

if grep -q 'test-weakening-ok' <<<"$NEW"; then
  hook_reason "escape hatch used in $BASE"
  exit 0
fi

# Drop commented-out lines before counting. Commenting a test out is itself a
# way to silence it — leaving the text in place would keep its assertions in
# the tally and hide the removal. Runs after the escape-hatch check above,
# which deliberately reads the raw text (the hatch lives in a comment).
strip_comments() {
  sed -E 's@^[[:space:]]*(//|#|--|\*|/\*|<!--).*$@@' <<<"$1"
}

# grep is line-oriented and these constructs wrap across lines.
OLD_FLAT=$(tr '\n\t' '  ' <<<"$(strip_comments "$OLD")")
NEW_FLAT=$(tr '\n\t' '  ' <<<"$(strip_comments "$NEW")")

# grep exits 1 on no-match, which under `set -o pipefail` would fail the whole
# pipeline and trip the fail-open ERR trap — absorb it, 0 matches is an answer.
count() {
  local n
  n=$( { grep -oE "$2" <<<"$1" 2>/dev/null || true; } | wc -l | tr -d ' ')
  printf '%s' "${n:-0}"
}

VIOLATIONS=()

# --- 1. Test switched off ------------------------------------------------
# `pending` and `.only` are matched in call/marker position only — bare words
# appear in ordinary identifiers ("pendingWrites", "onlyDigits") and this hook
# blocks, so a false positive costs a real edit.
# RSpec's `pending` is a statement: `pending(` or `pending "reason"`. A quote
# IMMEDIATELY after it with no space is a string-literal boundary — `'pending'`
# in a test's own assertions is data, not a marker. Requiring the paren, or a
# space before the quote, keeps the marker and drops that false positive.
SKIP_RE='\.skip\b|\.todo\b|\bxit\(|\bxdescribe\(|\bxcontext\(|@pytest\.mark\.(skip|xfail)|@unittest\.(skip|expectedFailure)|\bt\.Skip\(|@Ignore\b|#\[ignore\]|\bpending\(|\bpending[[:space:]]+["'"'"']|\.only\b|\bfit\(|\bfdescribe\('
OLD_SKIP=$(count "$OLD_FLAT" "$SKIP_RE")
NEW_SKIP=$(count "$NEW_FLAT" "$SKIP_RE")
if (( NEW_SKIP > OLD_SKIP )); then
  ADDED=$( { grep -oE "$SKIP_RE" <<<"$NEW_FLAT" || true; } | sort -u | tr '\n' ' ')
  VIOLATIONS+=("Test disabled — this edit adds: $ADDED")
fi

# --- 2. Assertions removed ------------------------------------------------
ASSERT_RE='\bassert[A-Za-z_]*[[:space:]]*\(|\bassert\b|\bexpect[[:space:]]*\(|\.should\b|\brequire\.[A-Z]|\bt\.Error|\bt\.Fatal|XCTAssert'
OLD_ASSERT=$(count "$OLD_FLAT" "$ASSERT_RE")
NEW_ASSERT=$(count "$NEW_FLAT" "$ASSERT_RE")
if (( OLD_ASSERT > 0 && NEW_ASSERT < OLD_ASSERT )); then
  VIOLATIONS+=("Assertions removed — $OLD_ASSERT before, $NEW_ASSERT after")
fi

# --- 3. Timeout raised ----------------------------------------------------
# Largest number sitting next to a timeout/wait knob, before vs after.
max_timeout() {
  { grep -oiE '(timeout|wait_?for|retries|max_?wait)[^0-9]{0,12}[0-9]+' <<<"$1" 2>/dev/null || true; } \
    | { grep -oE '[0-9]+$' || true; } | sort -n | tail -1
}
OLD_TO=$(max_timeout "$OLD_FLAT"); OLD_TO=${OLD_TO:-0}
NEW_TO=$(max_timeout "$NEW_FLAT"); NEW_TO=${NEW_TO:-0}
if (( OLD_TO > 0 && NEW_TO > OLD_TO )); then
  VIOLATIONS+=("Timeout raised — $OLD_TO to $NEW_TO")
fi

if (( ${#VIOLATIONS[@]} == 0 )); then
  hook_reason "clean: $BASE"
  exit 0
fi

hook_reason "$BASE — ${VIOLATIONS[*]}"

{
  echo "Blocked: this edit weakens an existing test in $BASE"
  echo
  for V in "${VIOLATIONS[@]}"; do
    echo "  - $V"
  done
  echo
  echo "Weakening a test removes coverage as surely as deleting it, and stays"
  echo "green while doing so. Before editing the test, classify why it is red:"
  echo "the contract changed, the code is wrong, the test is non-deterministic,"
  echo "or the test was always wrong. Then fix THAT."
  echo
  echo "A flaky test is fixed by removing the nondeterminism — pin the clock,"
  echo "isolate the fixture, await the condition — never by raising a timeout."
  echo
  echo "If this weakening is genuinely correct (feature deleted, assertions"
  echo "moved to a helper), put test-weakening-ok in the edited chunk and say"
  echo "why in the commit body."
  echo
  echo "Practice: ~/.claude/practices/test-integrity.md"
} >&2
exit 2
