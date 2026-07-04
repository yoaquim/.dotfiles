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

# Don't parse the message out of the command string — the default heredoc form
# (`git commit -m "$(cat <<'EOF' ...)"`) is unextractable. This is PostToolUse:
# the commit exists, so read the real subject line from git.
CWD=$(echo "$INPUT" | jq -r '.cwd // ""')
[[ -n "$CWD" ]] || exit 0
MSG=$(git -C "$CWD" log -1 --format='%s' 2>/dev/null) || exit 0
[[ -n "$MSG" ]] || exit 0

# Only validate a commit this call actually created — if the command failed,
# HEAD is an older commit that was already validated when it was made.
C_TIME=$(git -C "$CWD" log -1 --format='%ct' 2>/dev/null || echo 0)
(( $(date +%s) - C_TIME < 60 )) || exit 0

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
if [[ "$MSG" =~ \.$ ]]; then
  WARNINGS+=("Ends with period")
fi

# Imperative mood check — common past tense patterns
FIRST_WORD=$(echo "$MSG" | awk '{print $1}')
case "$FIRST_WORD" in
  Added|Fixed|Updated|Removed|Changed|Implemented|Refactored|Migrated|Deleted|Created)
    WARNINGS+=("'$FIRST_WORD' is past tense — use imperative ('${FIRST_WORD%ed}', '${FIRST_WORD%d}')")
    ;;
esac

# Plain stdout on exit-0 PostToolUse goes to transcript mode only — the model
# never sees it. hookSpecificOutput.additionalContext is the visible channel.
if (( ${#WARNINGS[@]} > 0 )); then
  TEXT="Commit message warnings for \"$MSG\":"
  for W in "${WARNINGS[@]}"; do
    TEXT+=$'\n'"  - $W"
  done
  TEXT+=$'\n'"Fix with: git commit --amend -m \"...\" (style: 50-75 chars, imperative, capitalized, no period)"
  jq -n --arg ctx "$TEXT" \
    '{hookSpecificOutput: {hookEventName: "PostToolUse", additionalContext: $ctx}}'
fi

exit 0
