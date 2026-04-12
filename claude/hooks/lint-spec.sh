#!/usr/bin/env bash
set -e

INPUT=$(cat)
TOOL=$(echo "$INPUT" | jq -r '.tool_name')

# Get file path from tool input
if [ "$TOOL" = "Write" ]; then
  FILE=$(echo "$INPUT" | jq -r '.tool_input.file_path')
elif [ "$TOOL" = "Edit" ]; then
  FILE=$(echo "$INPUT" | jq -r '.tool_input.file_path')
else
  exit 0
fi

# Only lint .deck/specs/ files
case "$FILE" in
  */.deck/specs/*.md) ;;
  *) exit 0 ;;
esac

[ ! -f "$FILE" ] && exit 0

# Count steps (numbered lines in ## Steps section)
STEPS=$(sed -n '/^## Steps/,/^## /p' "$FILE" | grep -c '^[0-9]')

# Count files (list items in ## Files section)
FILES=$(sed -n '/^## Files/,/^## /p' "$FILE" | grep -c '^ *- ')

WARNINGS=""

if [ "$STEPS" -gt 8 ]; then
  WARNINGS="${WARNINGS}\n  - ${STEPS} steps (threshold: 8). Consider splitting."
fi

if [ "$FILES" -gt 10 ]; then
  WARNINGS="${WARNINGS}\n  - ${FILES} files touched (threshold: 10). Likely too broad."
fi

if [ -n "$WARNINGS" ]; then
  MSG=$(printf "Spec scope warning for $(basename "$FILE"):${WARNINGS}\nRunners perform best with narrow, focused specs.")
  jq -n --arg ctx "$MSG" '{
    "hookSpecificOutput": {
      "hookEventName": "PostToolUse",
      "additionalContext": $ctx
    }
  }'
fi

exit 0
