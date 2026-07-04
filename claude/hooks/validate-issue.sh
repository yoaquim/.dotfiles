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

# Nothing recognizable came back (failed call, unexpected shape) → nothing to
# validate; a bare "no estimate" warning against a non-issue is just noise.
[[ -z "$TITLE" && -z "$ISSUE_ID" ]] && exit 0

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

# Sub-issues (parentId set) are dispatch-ready implementation slices: /spec
# deliberately puts discovered code paths in their ## Context, so the
# no-implementation-details rules apply only to top-level issues.
PARENT_ID=$(echo "$INPUT" | jq -r '.tool_input.parentId // ""' 2>/dev/null || echo "")
[[ -z "$PARENT_ID" ]] && PARENT_ID=$(echo "$ISSUE" | jq -r '.parentId // .parent.id // ""' 2>/dev/null || echo "")

# Description: no code references (top-level issues only)
if [[ -n "$DESCRIPTION" && -z "$PARENT_ID" ]]; then
  # Check for common code patterns (file paths, class references, backtick code blocks)
  if echo "$DESCRIPTION" | grep -qE '\.(rb|py|ts|tsx|js|jsx|go|rs|java|sh)[:)]?'; then
    WARNINGS+=("Description may contain file path references — implementation details belong in PRs, not issues")
  fi
  if echo "$DESCRIPTION" | grep -qE '```'; then
    WARNINGS+=("Description contains code blocks — implementation details belong in PRs, not issues")
  fi
fi
if [[ -n "$DESCRIPTION" ]]; then
  # Check for checklist items
  if echo "$DESCRIPTION" | grep -qE '^\s*-\s*\[[ x]\]'; then
    WARNINGS+=("Description contains checklists — use sub-issues instead")
  fi
fi

# Estimate: should exist
if [[ -z "$ESTIMATE" ]]; then
  WARNINGS+=("No estimate set — consider adding a fibonacci estimate (1, 2, 3, 5, 8)")
fi

# Plain stdout on exit-0 PostToolUse goes to transcript mode only — the model
# never sees it. hookSpecificOutput.additionalContext is the visible channel.
if (( ${#WARNINGS[@]} > 0 )); then
  TEXT="Issue $ISSUE_ID created with style warnings:"
  for W in "${WARNINGS[@]}"; do
    TEXT+=$'\n'"  - $W"
  done
  TEXT+=$'\n'"Fix via the Linear MCP update tool (or leave if deliberate)."
  jq -n --arg ctx "$TEXT" \
    '{hookSpecificOutput: {hookEventName: "PostToolUse", additionalContext: $ctx}}'
fi

# Always exit 0 — warnings only, never block
exit 0
