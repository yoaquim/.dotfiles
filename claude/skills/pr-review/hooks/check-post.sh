#!/bin/bash
# PreToolUse Hook: Block `gh pr review|comment` posts unless they carry the
# /pr-review skill header AND show real engagement with the diff (at least one
# file:line citation, or an explicit "no bug-class findings" line). Criteria
# citations are encouraged but no longer required — bugs are the primary review,
# and criteria are additive extras that may not fire on a given PR.
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

# Engagement check: the body must either cite specific code (file:line) or
# explicitly declare no findings. A review with neither is a non-review.
#
# file:line pattern: at least one occurrence of <something>.<ext>[:<line>] for
# common source extensions, e.g. Editor.tsx:471, server.ts:380-383, foo.py:12.
FILELINE_RE='[A-Za-z_][A-Za-z0-9_./-]*\.(ts|tsx|js|jsx|mjs|cjs|py|go|rs|rb|java|kt|swift|c|cc|cpp|h|hpp|cs|sh|sql|css|scss|html|md|json|ya?ml|toml|tf|hcl)(:[0-9]+(-[0-9]+)?)?'
NOFINDINGS_RE='_No bug-class findings'

HAS_FILELINE=0
HAS_NOFINDINGS=0
grep -qE "$FILELINE_RE" <<<"$COMMAND" && HAS_FILELINE=1
grep -qF "$NOFINDINGS_RE" <<<"$COMMAND" && HAS_NOFINDINGS=1

if [[ "$HAS_FILELINE" -eq 0 && "$HAS_NOFINDINGS" -eq 0 ]]; then
  ERRORS+=("Post shows no engagement with the diff.")
  ERRORS+=("Required: either at least one file:line citation in a finding,")
  ERRORS+=("OR the explicit line: _No bug-class findings — diff reviewed line by line._")
  ERRORS+=("A review that only counts test files or audits the body is not a review.")
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
