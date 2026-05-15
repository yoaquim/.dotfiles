#!/bin/bash
# PostToolUse Hook: Validate PR title after creation.
# Fires after Bash commands matching gh pr create.
# Reuses validate-title.sh logic. Warns — does not block.

set -euo pipefail

INPUT=$(cat)

COMMAND=$(echo "$INPUT" | jq -r '.tool_input.command // ""')

# Only check gh pr create commands
case "$COMMAND" in
  *gh\ pr\ create*) ;;
  *) exit 0 ;;
esac

# Extract title from --title flag
TITLE=$(echo "$COMMAND" | sed -n 's/.*--title[[:space:]]*["'"'"']\([^"'"'"']*\)["'"'"'].*/\1/p')
[[ -z "$TITLE" ]] && exit 0

# Run validate-title.sh
RESULT=$("$HOME/.claude/scripts/validate-title.sh" "$TITLE" 2>/dev/null) || true
VALID=$(echo "$RESULT" | jq -r '.valid // true')

if [[ "$VALID" == "false" ]]; then
  ERRORS=$(echo "$RESULT" | jq -r '.errors[]' 2>/dev/null)
  echo "PR title warnings:"
  while IFS= read -r ERR; do
    echo "  - $ERR"
  done <<< "$ERRORS"
fi

exit 0
