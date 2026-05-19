#!/bin/bash
# PreToolUse Hook: Block `gh pr review|comment` posts unless they carry the
# /pr-review skill header and cite at least one criterion file.
#
# Exit 0 → allow the tool call.
# Exit 2 → block; stderr is shown to the agent.

set -uo pipefail

INPUT=$(cat)
# Malformed JSON or missing field → allow (fail-open: a parse error is not the
# user's fault, and we'd rather miss a check than wedge unrelated bash calls).
COMMAND=$(jq -r '.tool_input.command // ""' <<<"$INPUT" 2>/dev/null || echo "")
[[ -z "$COMMAND" ]] && exit 0

# Only intercept when gh pr review|comment is actually being invoked — i.e.,
# at the start of the command, or after a shell separator. Mentioning the
# string inside an echo/comment/heredoc must NOT trigger the hook.
if ! grep -qE '(^|[[:space:]]|;|&&|\|\||\||\(|`|\$\()gh[[:space:]]+pr[[:space:]]+(review|comment)([[:space:]]|$)' <<<"$COMMAND"; then
  exit 0
fi

# Extra guard: if the gh pr review/comment substring is only preceded by
# echo/printf/cat/grep-style tokens (i.e. mentioned, not invoked), pass through.
# Practical heuristic: the first non-whitespace token on its line must be one
# of gh, env-var assignments, or a known shell builtin that invokes commands.
FIRST_TOK=$(awk '{
  for (i=1; i<=NF; i++) {
    if ($i ~ /=/) continue
    print $i
    exit
  }
}' <<<"$COMMAND")
case "$FIRST_TOK" in
  echo|printf|cat|grep|sed|awk|comm) exit 0 ;;
esac

# Pure --approve / --request-changes with no body → not a comment, skip.
# Only enforce when there's actually a body to validate (-b/--body/-F/--body-file).
if ! grep -qE '(-b[[:space:]]|--body[[:space:]]|--body=|-F[[:space:]]|--body-file[[:space:]]|--body-file=)' <<<"$COMMAND"; then
  exit 0
fi

# If body comes from a file (-F or --body-file), resolve and inline it so the
# checks below can see the content. Quote stripping is best-effort.
BODY_FILE=$(sed -nE 's/.*(-F|--body-file)[[:space:]=]+["'"'"']?([^"'"'"' ]+)["'"'"']?.*/\2/p' <<<"$COMMAND" | head -1)
if [[ -n "$BODY_FILE" && -f "$BODY_FILE" ]]; then
  COMMAND="$COMMAND
$(cat "$BODY_FILE")"
fi

ERRORS=()

# Required header (literal match on the first line of the skill's header.md).
HEADER='# 👾 Reviewed by Claude via the `/pr-review` skill 👾'
if ! grep -qF "$HEADER" <<<"$COMMAND"; then
  ERRORS+=("Post is missing the required /pr-review header line:")
  ERRORS+=("    $HEADER")
  ERRORS+=("Cat the skill's header.md into the body before posting.")
fi

# Must cite at least one criterion. Accept either a slug in backticks or a
# criteria/<slug> path reference.
CRITERIA_DIR="$HOME/.claude/skills/pr-review/criteria"
CITED=0
if [[ -d "$CRITERIA_DIR" ]]; then
  while IFS= read -r -d '' file; do
    slug=$(basename "$file" .md)
    if grep -qE "(\`$slug\`|criteria/$slug)" <<<"$COMMAND"; then
      CITED=$((CITED + 1))
    fi
  done < <(find "$CRITERIA_DIR" -name '*.md' -print0)
fi

if [[ "$CITED" -eq 0 ]]; then
  ERRORS+=("Post does not cite any criterion from criteria/.")
  ERRORS+=("Every finding must name the criterion that fired,")
  ERRORS+=("either as a backticked slug (e.g. \`slice-size\`) or a criteria/<slug> path.")
fi

if [[ "${#ERRORS[@]}" -gt 0 ]]; then
  {
    echo "❌ /pr-review post blocked:"
    echo ""
    for e in "${ERRORS[@]}"; do
      echo "  - $e"
    done
    echo ""
    echo "Fix the body and retry. Do not bypass this hook."
  } >&2
  exit 2
fi

exit 0
