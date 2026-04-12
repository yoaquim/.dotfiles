#!/usr/bin/env bash
set -e

INPUT=$(cat)
CWD=$(echo "$INPUT" | jq -r '.cwd // empty')
[ -z "$CWD" ] && CWD="."

PRACTICES_DIR="$HOME/.claude/practices"
SELECTED="$PRACTICES_DIR/tdd.md" # Always include TDD

# Detect stack and append matching practices
[ -f "$CWD/manage.py" ] && SELECTED="$SELECTED $PRACTICES_DIR/django.md"
[ -f "$CWD/package.json" ] && {
  grep -q '"react"' "$CWD/package.json" 2>/dev/null && SELECTED="$SELECTED $PRACTICES_DIR/react.md"
}
[ -f "$CWD/tailwind.config.js" ] || [ -f "$CWD/tailwind.config.ts" ] && SELECTED="$SELECTED $PRACTICES_DIR/tailwind.md"
[ -f "$CWD/Dockerfile" ] || [ -f "$CWD/compose.yml" ] && SELECTED="$SELECTED $PRACTICES_DIR/docker.md"

# Build output from matching practice files
CONTENT=""
for f in $SELECTED; do
  [ -f "$f" ] && CONTENT="$CONTENT
---
$(cat "$f")"
done

if [ -n "$CONTENT" ]; then
  MSG=$(printf "ACTIVE PRACTICES (auto-detected from project stack):\n%s" "$CONTENT")
  jq -n --arg ctx "$MSG" '{"additionalContext": $ctx}'
fi

exit 0
