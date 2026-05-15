#!/bin/bash
# PostToolUse Hook: Validate git commit messages.
# Fires after Bash commands matching git commit.
# Warns on style violations — does not block.

set -euo pipefail

INPUT=$(cat)

# Extract the command that was run
COMMAND=$(echo "$INPUT" | jq -r '.tool_input.command // ""')

# Only check git commit commands
case "$COMMAND" in
  *git\ commit*) ;;
  *) exit 0 ;;
esac

# Extract commit message from -m flag
MSG=$(echo "$COMMAND" | sed -n 's/.*-m[[:space:]]*["'"'"']\([^"'"'"']*\)["'"'"'].*/\1/p')
[[ -z "$MSG" ]] && exit 0

# If heredoc/cat style, grab first line
MSG=$(echo "$MSG" | head -1)

WARNINGS=()

# Max 75 chars
LEN=${#MSG}
if (( LEN > 75 )); then
  WARNINGS+=("$LEN chars (max 75)")
fi

# Capitalized first word
FIRST_CHAR="${MSG:0:1}"
if [[ "$FIRST_CHAR" != "$(echo "$FIRST_CHAR" | tr '[:lower:]' '[:upper:]')" ]]; then
  WARNINGS+=("First word not capitalized")
fi

# No trailing period
if [[ "$MSG" =~ \\.$ ]]; then
  WARNINGS+=("Ends with period")
fi

# Imperative mood check — common past tense patterns
FIRST_WORD=$(echo "$MSG" | awk '{print $1}')
case "$FIRST_WORD" in
  Added|Fixed|Updated|Removed|Changed|Implemented|Refactored|Migrated|Deleted|Created)
    WARNINGS+=("'$FIRST_WORD' is past tense — use imperative ('${FIRST_WORD%ed}', '${FIRST_WORD%d}')")
    ;;
esac

if (( ${#WARNINGS[@]} > 0 )); then
  echo "Commit message warnings:"
  for W in "${WARNINGS[@]}"; do
    echo "  - $W"
  done
fi

exit 0
