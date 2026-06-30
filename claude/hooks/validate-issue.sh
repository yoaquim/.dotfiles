#!/bin/bash
# PostToolUse Hook: Validate a Linear issue after creation.
# Fires after any Linear MCP save_issue call (matcher: mcp__.*__save_issue).
# Flags violations as warnings — does not block.

set -euo pipefail

INPUT=$(cat)

# Extract the tool response and normalize it to an issue object.
# Linear MCP variants return tool_response as a plain object, an array of
# content blocks, or content blocks with the issue JSON embedded as text.
RAW=$(echo "$INPUT" | jq -c '.tool_response // {}' 2>/dev/null || echo '{}')

ISSUE=$(jq -n --argjson r "$RAW" '
  def parse: (try fromjson catch {});
  if   (($r|type) == "object") then $r
  elif (($r|type) == "array")  then
    ( [ $r[]
        | if   (type=="object" and (has("title") or has("id"))) then .
          elif (type=="object" and has("text")) then (.text|parse)
          else (tostring|parse) end ]
      | map(select((type=="object") and (has("title") or has("id"))))
      | (.[0] // {}) )
  else ($r|tostring|parse) end' 2>/dev/null || echo '{}')

# If it's an error response, skip validation
if echo "$ISSUE" | jq -e '.error' &>/dev/null; then
  exit 0
fi

TITLE=$(echo "$ISSUE" | jq -r '.title // ""')
DESCRIPTION=$(echo "$ISSUE" | jq -r '.description // ""')
ISSUE_ID=$(echo "$ISSUE" | jq -r '.id // ""')
ESTIMATE=$(echo "$ISSUE" | jq -r '.estimate // empty')

WARNINGS=()

# Title: word count 2-7
if [[ -n "$TITLE" ]]; then
  WORD_COUNT=$(echo "$TITLE" | wc -w | tr -d ' ')
  if (( WORD_COUNT < 2 || WORD_COUNT > 7 )); then
    WARNINGS+=("Title '$TITLE' has $WORD_COUNT words (expected 2-7)")
  fi

  # Title: no verb prefixes
  FIRST_WORD=$(echo "$TITLE" | awk '{print $1}' | sed 's/:$//')
  case "$FIRST_WORD" in
    Add|Fix|Update|Implement|Create|Remove|Delete|Refactor|Migrate|Move|Change)
      WARNINGS+=("Title starts with verb '$FIRST_WORD' — should be a noun phrase")
      ;;
  esac
fi

# Description: no code references
if [[ -n "$DESCRIPTION" ]]; then
  # Check for common code patterns (file paths, class references, backtick code blocks)
  if echo "$DESCRIPTION" | grep -qE '\.(rb|py|ts|tsx|js|jsx|go|rs|java|sh)[:)]?'; then
    WARNINGS+=("Description may contain file path references — implementation details belong in PRs, not issues")
  fi
  if echo "$DESCRIPTION" | grep -qE '```'; then
    WARNINGS+=("Description contains code blocks — implementation details belong in PRs, not issues")
  fi
  # Check for checklist items
  if echo "$DESCRIPTION" | grep -qE '^\s*-\s*\[[ x]\]'; then
    WARNINGS+=("Description contains checklists — use sub-issues instead")
  fi
fi

# Estimate: should exist
if [[ -z "$ESTIMATE" ]]; then
  WARNINGS+=("No estimate set — consider adding a fibonacci estimate (1, 2, 3, 5, 8)")
fi

# Output warnings
if (( ${#WARNINGS[@]} > 0 )); then
  echo "Issue $ISSUE_ID created with style warnings:"
  for W in "${WARNINGS[@]}"; do
    echo "  - $W"
  done
  echo ""
  echo "Correct directly in Linear if needed."
fi

# Always exit 0 — warnings only, never block
exit 0
