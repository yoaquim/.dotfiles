#!/bin/bash
# PreToolUse hook: block AI-slop comments in Edit/Write/MultiEdit calls.
#
# Default stance from ~/.claude/practices/no-comments.md: write zero comments.
# This hook catches the worst slop patterns even when the model drifts.
# Blocks on: ticket IDs, references to tickets/Linear/Jira/"as requested",
# TODO/FIXME/XXX, and "this function handles..." restatements.

set -euo pipefail

INPUT=$(cat)
TOOL=$(echo "$INPUT" | jq -r '.tool_name // ""')

case "$TOOL" in
  Edit|Write|MultiEdit) ;;
  *) exit 0 ;;
esac

# Collect the content the tool will write.
case "$TOOL" in
  Edit)
    CONTENT=$(echo "$INPUT" | jq -r '.tool_input.new_string // ""')
    FILE=$(echo "$INPUT" | jq -r '.tool_input.file_path // ""')
    ;;
  Write)
    CONTENT=$(echo "$INPUT" | jq -r '.tool_input.content // ""')
    FILE=$(echo "$INPUT" | jq -r '.tool_input.file_path // ""')
    ;;
  MultiEdit)
    CONTENT=$(echo "$INPUT" | jq -r '[.tool_input.edits[]?.new_string] | join("\n")')
    FILE=$(echo "$INPUT" | jq -r '.tool_input.file_path // ""')
    ;;
esac

[[ -z "$CONTENT" ]] && exit 0

# Skip markdown, text, and config files — comments there are content, not code.
case "$FILE" in
  *.md|*.mdx|*.txt|*.rst|*.adoc) exit 0 ;;
  *.json|*.yaml|*.yml|*.toml) exit 0 ;;
  */CLAUDE.md|*/SKILL.md|*/AGENT.md|*/README*) exit 0 ;;
esac

# Extract candidate comment lines from CONTENT.
# Matches: //, #, /*, *, <!--, """, ''', -- (SQL-style)
# Excludes shebangs (#!) and URL fragments.
COMMENTS=$(echo "$CONTENT" | awk '
  {
    line = $0
    # strip leading whitespace
    sub(/^[ \t]+/, "", line)
    # shebang — not a comment
    if (line ~ /^#!/) next
    # comment styles
    if (line ~ /^\/\//) print line
    else if (line ~ /^#[^!]/) print line
    else if (line ~ /^\/\*/) print line
    else if (line ~ /^\*[^\/]/) print line
    else if (line ~ /^<!--/) print line
    else if (line ~ /^"""/) print line
    else if (line ~ /^'"'"''"'"''"'"'/) print line
    else if (line ~ /^--[^-]/) print line
  }
')

[[ -z "$COMMENTS" ]] && exit 0

VIOLATIONS=()

# Pattern 1: ticket IDs (PER-83, ABC-123, etc.)
if echo "$COMMENTS" | grep -qE '\b[A-Z]{2,}-[0-9]+\b'; then
  HIT=$(echo "$COMMENTS" | grep -oE '\b[A-Z]{2,}-[0-9]+\b' | head -1)
  VIOLATIONS+=("ticket ID '$HIT' in a comment — tickets belong in PR/commit, never in code")
fi

# Pattern 2: ticket-system words
if echo "$COMMENTS" | grep -qiE '\b(ticket|linear|jira)\b'; then
  HIT=$(echo "$COMMENTS" | grep -ioE '\b(ticket|linear|jira)\b' | head -1)
  VIOLATIONS+=("references '$HIT' in a comment — drop it")
fi

# Pattern 3: TODO/FIXME/XXX/HACK
if echo "$COMMENTS" | grep -qE '\b(TODO|FIXME|XXX|HACK)\b'; then
  HIT=$(echo "$COMMENTS" | grep -oE '\b(TODO|FIXME|XXX|HACK)\b' | head -1)
  VIOLATIONS+=("'$HIT' marker in a comment — open an issue or fix it, don't leave breadcrumbs")
fi

# Pattern 4: task-justifying phrases
if echo "$COMMENTS" | grep -qiE '\b(as requested|as per (the )?(ticket|spec|request)|implements the .* feature|for the .* (feature|flow|request))\b'; then
  VIOLATIONS+=("task-justifying phrase in a comment ('as requested' / 'implements the X feature' / etc.) — comments shouldn't reference why the task exists")
fi

# Pattern 5: restatement-of-purpose
if echo "$COMMENTS" | grep -qiE '\bthis (function|method|class|module|component|file) (handles|manages|is responsible|does|performs|processes)\b'; then
  VIOLATIONS+=("restatement of what the code does ('this function handles...') — names already say that")
fi

# Pattern 6: caller references
if echo "$COMMENTS" | grep -qiE '\b(used by|called (from|by))\s+[A-Za-z_]'; then
  VIOLATIONS+=("caller reference in a comment ('used by X' / 'called from Y') — code search finds these")
fi

if (( ${#VIOLATIONS[@]} > 0 )); then
  {
    echo "Blocked: AI-slop comment patterns detected in $FILE"
    echo ""
    for V in "${VIOLATIONS[@]}"; do
      echo "  • $V"
    done
    echo ""
    echo "Rule: default to zero comments. See ~/.claude/practices/no-comments.md."
    echo "Rewrite the change without these comments and retry."
  } >&2
  exit 2
fi

exit 0
