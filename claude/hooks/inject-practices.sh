#!/usr/bin/env bash
set -e

INPUT=$(cat)
CWD=$(echo "$INPUT" | jq -r '.cwd // empty')
[ -z "$CWD" ] && CWD="."

PRACTICES_DIR="$HOME/.claude/practices"
INDEX="$PRACTICES_DIR/INDEX.md"

[ ! -f "$INDEX" ] && exit 0

INJECTED=""
FALLBACK=""

# Parse the markdown table: skip header and separator lines, read rows
while IFS='|' read -r _ practice file _ detect _; do
  # Trim whitespace
  practice=$(echo "$practice" | xargs)
  file=$(echo "$file" | xargs | tr -d '`')
  detect=$(echo "$detect" | xargs)

  [ -z "$file" ] && continue
  [ ! -f "$PRACTICES_DIR/$file" ] && continue

  matched=false

  if [ "$detect" = "always" ]; then
    matched=true

  elif [ -z "$detect" ]; then
    # No detect rule — add to fallback list
    FALLBACK="${FALLBACK}\n- ${practice} (${file})"
    continue

  else
    # Handle comma-separated rules (any match wins)
    IFS=',' read -ra RULES <<< "$detect"
    for rule in "${RULES[@]}"; do
      rule=$(echo "$rule" | xargs)

      if [[ "$rule" == *:* ]]; then
        # file:string — check file exists and contains string
        CHECK_FILE="${rule%%:*}"
        CHECK_STRING="${rule#*:}"
        if [ -f "$CWD/$CHECK_FILE" ] && grep -q "$CHECK_STRING" "$CWD/$CHECK_FILE" 2>/dev/null; then
          matched=true
          break
        fi

      elif [[ "$rule" == *\** ]]; then
        # glob pattern
        if compgen -G "$CWD/$rule" > /dev/null 2>&1; then
          matched=true
          break
        fi

      else
        # plain filename
        if [ -f "$CWD/$rule" ]; then
          matched=true
          break
        fi
      fi
    done
  fi

  if [ "$matched" = true ]; then
    INJECTED="$INJECTED
---
$(cat "$PRACTICES_DIR/$file")"
  fi

done < <(grep '^|' "$INDEX" | tail -n +3)

# Build output
CONTENT=""

if [ -n "$INJECTED" ]; then
  CONTENT="ACTIVE PRACTICES (auto-detected):
$INJECTED"
fi

if [ -n "$FALLBACK" ]; then
  CONTENT="$CONTENT

Additional practices available if relevant (not auto-detected):$(echo -e "$FALLBACK")
Review and apply if they match this project."
fi

if [ -n "$CONTENT" ]; then
  jq -n --arg ctx "$CONTENT" '{"additionalContext": $ctx}'
fi

exit 0
