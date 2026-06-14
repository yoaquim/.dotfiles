#!/bin/bash
# PreToolUse Hook: Block /pr-review posts unless they carry the skill header
# AND show real engagement with the diff (at least one inline comment, OR an
# explicit "no bug-class findings" line for an APPROVE).
#
# Gates two posting paths:
#   1. New (v3+):  gh api repos/<owner>/<repo>/pulls/<n>/reviews -X POST --input <file>
#   2. Legacy:    gh pr review|comment ... -b/-F ...
#
# Exit 0 → allow the tool call.
# Exit 2 → block; stderr is shown to the agent.

set -uo pipefail

INPUT=$(cat)
# Malformed JSON or missing field → allow (fail-open: a parse error is not the
# user's fault, and we'd rather miss a check than wedge unrelated bash calls).
COMMAND=$(jq -r '.tool_input.command // ""' <<<"$INPUT" 2>/dev/null || echo "")
[[ -z "$COMMAND" ]] && exit 0

# shellcheck disable=SC2016  # backticked code span in prose
HEADER='# 👾 Reviewed by Claude via the `/pr-review` skill 👾'
NOFINDINGS_RE='_No bug-class findings'
FILELINE_RE='[A-Za-z_][A-Za-z0-9_./-]*\.(ts|tsx|js|jsx|mjs|cjs|py|go|rs|rb|java|kt|swift|c|cc|cpp|h|hpp|cs|sh|sql|css|scss|html|md|json|ya?ml|toml|tf|hcl)(:[0-9]+(-[0-9]+)?)?'

# -------- Path 1: new inline-review API --------
# Match: gh api repos/.../pulls/<n>/reviews ... (POST is default for --input)
if grep -qE '(^|[[:space:]]|;|&&|\|\||\||\(|`|\$\()gh[[:space:]]+api[[:space:]]+["'"'"']?repos/[^[:space:]]+/pulls/[0-9]+/reviews' <<<"$COMMAND"; then
  # Extract --input <file> argument
  PAYLOAD_FILE=$(sed -nE 's/.*--input[[:space:]=]+["'"'"']?([^"'"'"' ]+)["'"'"']?.*/\1/p' <<<"$COMMAND" | head -1)

  if [[ -z "$PAYLOAD_FILE" || ! -f "$PAYLOAD_FILE" ]]; then
    {
      echo "❌ /pr-review post blocked:"
      echo "  - Could not locate payload file via --input."
      echo "  - The skill must write the review JSON to a tempfile and pass --input <file>."
    } >&2
    exit 2
  fi

  BODY=$(jq -r '.body // ""' "$PAYLOAD_FILE" 2>/dev/null || echo "")
  COMMENTS_LEN=$(jq -r '(.comments // []) | length' "$PAYLOAD_FILE" 2>/dev/null || echo 0)
  EVENT=$(jq -r '.event // ""' "$PAYLOAD_FILE" 2>/dev/null || echo "")

  ERRORS=()

  # Header required in body
  if ! grep -qF "$HEADER" <<<"$BODY"; then
    ERRORS+=("Payload .body is missing the required /pr-review header line:")
    ERRORS+=("    $HEADER")
    ERRORS+=("Prepend header.md to the body before posting.")
  fi

  # Engagement: at least one inline comment OR explicit no-findings line in body.
  HAS_NOFINDINGS=0
  grep -qF "$NOFINDINGS_RE" <<<"$BODY" && HAS_NOFINDINGS=1

  if [[ "$COMMENTS_LEN" -eq 0 && "$HAS_NOFINDINGS" -eq 0 ]]; then
    ERRORS+=("Post shows no engagement with the diff.")
    ERRORS+=("Required: at least one inline comment in .comments[],")
    ERRORS+=("OR the explicit body line: _No bug-class findings — diff reviewed line by line._")
  fi

  # APPROVE with findings or REQUEST_CHANGES with zero findings is inconsistent.
  if [[ "$EVENT" == "APPROVE" && "$COMMENTS_LEN" -gt 0 ]]; then
    ERRORS+=("Event is APPROVE but comments[] has $COMMENTS_LEN inline comments.")
    ERRORS+=("APPROVE means zero findings. Use REQUEST_CHANGES when posting comments.")
  fi
  if [[ "$EVENT" == "REQUEST_CHANGES" && "$COMMENTS_LEN" -eq 0 && "$HAS_NOFINDINGS" -eq 1 ]]; then
    ERRORS+=("Event is REQUEST_CHANGES but body declares no findings.")
    ERRORS+=("Use APPROVE when there are no findings.")
  fi

  if [[ "${#ERRORS[@]}" -gt 0 ]]; then
    {
      echo "❌ /pr-review post blocked:"
      echo ""
      for e in "${ERRORS[@]}"; do
        echo "  - $e"
      done
      echo ""
      echo "Fix the payload and retry. Do not bypass this hook."
    } >&2
    exit 2
  fi

  exit 0
fi

# -------- Path 2: legacy `gh pr review|comment` --------
# Only intercept when actually being invoked (not mentioned in echo/grep/etc).
if ! grep -qE '(^|[[:space:]]|;|&&|\|\||\||\(|`|\$\()gh[[:space:]]+pr[[:space:]]+(review|comment)([[:space:]]|$)' <<<"$COMMAND"; then
  exit 0
fi

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
if ! grep -qE '(-b[[:space:]]|--body[[:space:]]|--body=|-F[[:space:]]|--body-file[[:space:]]|--body-file=)' <<<"$COMMAND"; then
  exit 0
fi

BODY_FILE=$(sed -nE 's/.*(-F|--body-file)[[:space:]=]+["'"'"']?([^"'"'"' ]+)["'"'"']?.*/\2/p' <<<"$COMMAND" | head -1)
if [[ -n "$BODY_FILE" && -f "$BODY_FILE" ]]; then
  COMMAND="$COMMAND
$(cat "$BODY_FILE")"
fi

ERRORS=()

if ! grep -qF "$HEADER" <<<"$COMMAND"; then
  ERRORS+=("Post is missing the required /pr-review header line:")
  ERRORS+=("    $HEADER")
  ERRORS+=("Cat the skill's header.md into the body before posting.")
fi

HAS_FILELINE=0
HAS_NOFINDINGS=0
grep -qE "$FILELINE_RE" <<<"$COMMAND" && HAS_FILELINE=1
grep -qF "$NOFINDINGS_RE" <<<"$COMMAND" && HAS_NOFINDINGS=1

if [[ "$HAS_FILELINE" -eq 0 && "$HAS_NOFINDINGS" -eq 0 ]]; then
  ERRORS+=("Post shows no engagement with the diff.")
  ERRORS+=("Required: either at least one file:line citation in a finding,")
  ERRORS+=("OR the explicit line: _No bug-class findings — diff reviewed line by line._")
fi

if [[ "${#ERRORS[@]}" -gt 0 ]]; then
  {
    echo "❌ /pr-review post blocked (legacy path):"
    echo ""
    for e in "${ERRORS[@]}"; do
      echo "  - $e"
    done
    echo ""
    echo "Prefer the new inline-review path: gh api .../reviews --input <payload.json>"
  } >&2
  exit 2
fi

exit 0
