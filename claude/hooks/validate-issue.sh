#!/bin/bash
# PostToolUse Hook: Validate a Linear issue after creation.
# Fires after mcp__claude_ai_Linear__save_issue.
# Flags violations as warnings — does not block.

set -euo pipefail

INPUT=$(cat)

# Extract the tool response (the created issue data)
TOOL_RESPONSE=$(echo "$INPUT" | jq -r '.tool_response // ""')

# If no response or it's an error, skip validation
if [[ -z "$TOOL_RESPONSE" ]] || echo "$TOOL_RESPONSE" | jq -e '.error' &>/dev/null; then
  exit 0
fi

TITLE=$(echo "$TOOL_RESPONSE" | jq -r '.title // ""')
DESCRIPTION=$(echo "$TOOL_RESPONSE" | jq -r '.description // ""')
ISSUE_ID=$(echo "$TOOL_RESPONSE" | jq -r '.id // ""')
ESTIMATE=$(echo "$TOOL_RESPONSE" | jq -r '.estimate // empty')

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
