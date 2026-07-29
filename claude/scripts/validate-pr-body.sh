#!/usr/bin/env bash
# validate-pr-body.sh — Validate a PR description against /pr conventions.
#
# Usage: validate-pr-body.sh "Body content" [ticket-id] [diff-facts-json]
#   ticket-id:       optional. If provided, body must reference it
#                    (Closes / Fixes / Resolves <ID>).
#   diff-facts-json: optional, the output of classify-diff.sh. Drives three
#                    disclosure gates — test-change classification, missing-test
#                    justification, and escape-hatch disclosure. Absent or
#                    malformed → those gates are skipped, never fabricated.
#
# Output: JSON {valid: bool, errors: [string]}.
# Exit 0: valid. Exit 1: invalid.

set -euo pipefail

BODY="${1:-}"
TICKET_ID="${2:-}"
FACTS="${3:-}"

TESTS_CHANGED=$(jq -r '.tests_changed // 0' <<<"$FACTS" 2>/dev/null || echo 0)
SOURCE_CHANGED=$(jq -r '.source_changed // 0' <<<"$FACTS" 2>/dev/null || echo 0)
HATCHES=$(jq -r '.hatches[]? // empty' <<<"$FACTS" 2>/dev/null || true)

ERRORS=()

if [[ -z "$BODY" ]]; then
  echo '{"valid": false, "errors": ["Body is empty"]}'
  exit 1
fi

# Minimum length to discourage one-liners.
CHAR_COUNT=${#BODY}
if (( CHAR_COUNT < 50 )); then
  ERRORS+=("Body too short: $CHAR_COUNT chars (minimum 50)")
fi

# Must contain a Testing section (matches **Testing**, **Testing:**, ## Testing).
if ! grep -qE '(\*\*Testing:?\*\*|^##[[:space:]]+Testing)' <<<"$BODY"; then
  ERRORS+=("Missing Testing section (e.g. **Testing:**)")
fi

# No checklist markers — /pr skill forbids them.
if grep -qE '^[[:space:]]*-[[:space:]]*\[[ xX]\]' <<<"$BODY"; then
  ERRORS+=("Contains checklist markers (- [ ]); /pr forbids checklists")
fi

# Test files changed → the test-integrity.md declaration is mandatory. Fixed
# vocabulary, not prose: a reviewer reads the reason, but only a closed set of
# classifications can be machine-checked. Bold/heading forms allowed since /pr
# bodies use them.
if [[ "$TESTS_CHANGED" == "1" ]]; then
  if ! grep -qiE '(\*\*|##[[:space:]]+)?Test changes:?(\*\*)?[[:space:]]*(contract moved|code fixed|flake fixed|test was wrong|new coverage only)\b' <<<"$BODY"; then
    ERRORS+=("Diff touches tests — body needs 'Test changes: <contract moved|code fixed|flake fixed|test was wrong|new coverage only>' (see ~/.claude/practices/test-integrity.md)")
  fi
fi

# Source changed but no test did → tdd.md's gap, made visible. Not a block on
# shipping untested code, a block on shipping it SILENTLY: say why in one line.
# Free-text reason (unlike the fixed vocabulary above) because the legitimate
# cases — config, pure refactor with existing coverage, generated code — have
# no closed set worth pretending to enumerate.
if [[ "$SOURCE_CHANGED" == "1" && "$TESTS_CHANGED" != "1" ]]; then
  if ! grep -qiE '(\*\*)?No new tests:?(\*\*)?[[:space:]]*.{15,}' <<<"$BODY"; then
    ERRORS+=("Source changed with no test changes — body needs 'No new tests: <why>' in one line (see ~/.claude/practices/tdd.md)")
  fi
fi

# Escape hatches used → name each one in the body. The hatch stays available;
# what it stops being is invisible. A reviewer who never learns a block was
# bypassed cannot review the bypass.
if [[ -n "$HATCHES" ]]; then
  while IFS= read -r TOKEN; do
    [[ -n "$TOKEN" ]] || continue
    if ! grep -qF "$TOKEN" <<<"$BODY"; then
      ERRORS+=("Diff adds escape hatch '$TOKEN' — the body must name it and say why it was needed")
    fi
  done <<<"$HATCHES"
fi

# Ticket reference required when one was inferred from the branch.
if [[ -n "$TICKET_ID" ]]; then
  if ! grep -qiE "(closes|fixes|resolves)[[:space:]]+${TICKET_ID}" <<<"$BODY"; then
    ERRORS+=("Must reference ticket: 'Closes ${TICKET_ID}' (or Fixes/Resolves)")
  fi
fi

if (( ${#ERRORS[@]} == 0 )); then
  echo '{"valid": true, "errors": []}'
  exit 0
fi

JSON_ERRORS="["
FIRST=true
for ERR in "${ERRORS[@]}"; do
  $FIRST || JSON_ERRORS+=","
  ESCAPED=$(printf '%s' "$ERR" | sed 's/\\/\\\\/g; s/"/\\"/g')
  JSON_ERRORS+="\"$ESCAPED\""
  FIRST=false
done
JSON_ERRORS+="]"
echo "{\"valid\": false, \"errors\": $JSON_ERRORS}"
exit 1
