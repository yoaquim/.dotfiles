#!/usr/bin/env bash
# validate-pr-body.sh — Validate a PR description against /pr conventions.
#
# Usage: validate-pr-body.sh "Body content" [ticket-id]
#   ticket-id: optional. If provided, body must reference it
#              (Closes / Fixes / Resolves <ID>).
#
# Output: JSON {valid: bool, errors: [string]}.
# Exit 0: valid. Exit 1: invalid.

set -euo pipefail

BODY="${1:-}"
TICKET_ID="${2:-}"

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
