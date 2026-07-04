#!/bin/bash
# PreToolUse Hook: Block `gh pr create` unless the title (and body, when
# extractable) match /pr conventions. Heredoc-substituted bodies are skipped
# here — the Stop hook (enforce-completion.sh) re-validates the actual PR
# content via `gh pr view`, which is the authoritative gate.
#
# Exit 0 → allow the tool call.
# Exit 2 → block; stderr is shown to the agent.

set -euo pipefail

INPUT=$(cat)
COMMAND=$(echo "$INPUT" | jq -r '.tool_input.command // ""')

case "$COMMAND" in
  *gh\ pr\ create*) ;;
  *) exit 0 ;;
esac

ERRORS=()

# --- Title (best effort) ---
# Extract only the double-quoted form — the old character-class sed stopped at
# the first apostrophe ("Don't reorder" → "Don") and hard-blocked valid titles.
# Present-but-unextractable titles defer to the Stop hook's authoritative
# re-validation via `gh pr view`.
if ! grep -qE -- '--title' <<<"$COMMAND"; then
  ERRORS+=("Missing --title")
else
  TITLE=$(perl -0777 -ne 'if (/--title\s+"((?:[^"\\]|\\.)*)"/s) { print $1; exit }' <<<"$COMMAND")
  if [[ -n "$TITLE" ]]; then
    TITLE_RESULT=$("$HOME/.claude/scripts/validate-title.sh" "$TITLE" 2>/dev/null || true)
    TITLE_VALID=$(jq -r 'if .valid == false then "false" else "true" end' <<<"$TITLE_RESULT" 2>/dev/null || echo true)
    if [[ "$TITLE_VALID" == "false" ]]; then
      while IFS= read -r ERR; do
        [[ -n "$ERR" ]] && ERRORS+=("Title: $ERR")
      done < <(jq -r '.errors[]?' <<<"$TITLE_RESULT" 2>/dev/null)
    fi
  fi
fi

# --- Body (best effort) ---
# Extraction is hard for heredocs and bodies containing special characters.
# When --body is present but we cannot reliably extract it, defer to the
# Stop hook (enforce-completion.sh), which re-validates via `gh pr view`.
if grep -qE -- '--body' <<<"$COMMAND"; then
  BODY=""
  if ! grep -qE -- '--body[[:space:]]+"\$\(' <<<"$COMMAND"; then
    BODY=$(perl -0777 -ne 'if (/--body\s+"((?:[^"\\]|\\.)*)"/s) { print $1; exit }' <<<"$COMMAND")
  fi

  if [[ -n "$BODY" ]]; then
    TICKET_ID=""
    BRANCH=$(git rev-parse --abbrev-ref HEAD 2>/dev/null || true)
    # Never infer a ticket from sketch branches — `sketch-jwt-auth-2` would
    # "match" AUTH-2 and demand a bogus Closes line.
    if [[ "$BRANCH" != sketch-* && "$BRANCH" =~ ([A-Za-z]+-[0-9]+) ]]; then
      TICKET_ID=$(echo "${BASH_REMATCH[1]}" | tr '[:lower:]' '[:upper:]')
    fi

    BODY_RESULT=$("$HOME/.claude/scripts/validate-pr-body.sh" "$BODY" "$TICKET_ID" 2>/dev/null || true)
    BODY_VALID=$(jq -r 'if .valid == false then "false" else "true" end' <<<"$BODY_RESULT" 2>/dev/null || echo true)
    if [[ "$BODY_VALID" == "false" ]]; then
      while IFS= read -r ERR; do
        [[ -n "$ERR" ]] && ERRORS+=("Body: $ERR")
      done < <(jq -r '.errors[]?' <<<"$BODY_RESULT" 2>/dev/null)
    fi
  fi
else
  ERRORS+=("Missing --body")
fi

if (( ${#ERRORS[@]} == 0 )); then
  exit 0
fi

{
  echo "Blocked: \`gh pr create\` violates /pr conventions."
  echo
  for ERR in "${ERRORS[@]}"; do
    echo "  - $ERR"
  done
  echo
  echo "Fix the command and retry, or run /pr to generate it correctly."
  echo "Rules: ~/.claude/skills/pr/SKILL.md"
} >&2
exit 2
