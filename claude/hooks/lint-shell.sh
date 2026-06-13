#!/usr/bin/env bash
# PostToolUse hook: run shellcheck on edited shell scripts.
# Findings surface as additionalContext — informative, never blocking.

set -uo pipefail
trap 'exit 0' ERR

command -v shellcheck >/dev/null 2>&1 || exit 0

INPUT=$(cat)
TOOL=$(jq -r '.tool_name // ""' <<<"$INPUT")
case "$TOOL" in
  Edit|Write|MultiEdit) ;;
  *) exit 0 ;;
esac

FILE=$(jq -r '.tool_input.file_path // ""' <<<"$INPUT")
[[ -f "$FILE" ]] || exit 0

# Shell files only: .sh extension or a sh/bash shebang.
if [[ "$FILE" != *.sh ]]; then
  head -1 "$FILE" 2>/dev/null | grep -qE '^#!.*\b(bash|sh)\b' || exit 0
fi

RESULTS=$(shellcheck --severity=info --format=gcc "$FILE" 2>/dev/null | head -20 || true)
[[ -z "$RESULTS" ]] && exit 0

jq -n --arg ctx "shellcheck findings for $FILE — fix warnings/errors before finishing:
$RESULTS" '{
  "hookSpecificOutput": {
    "hookEventName": "PostToolUse",
    "additionalContext": $ctx
  }
}'

exit 0
