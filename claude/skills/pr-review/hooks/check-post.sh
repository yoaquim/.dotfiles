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

# NOTE: this PreToolUse hook only VALIDATES the post. HEAD coverage/approval is
# read straight from GitHub by enforce-watch.sh (via check-pr-state.sh) — there is
# no local SHA stamp anymore (the old record-sha.sh stamps proved fragile and
# nothing read them, so that hook was removed).

# Header + approval sentinel come from the single source of truth (read back from
# the posted templates) so this gate and the approval detectors can never
# disagree. If the lib is somehow missing, fall back to inline literals and keep
# failing OPEN (this gate's documented stance) rather than wedge the reviewer.
# shellcheck disable=SC1091  # installed at runtime; not resolvable at lint time
if ! source "$HOME/.claude/scripts/lib/pr-review-markers.sh" 2>/dev/null; then
  # shellcheck disable=SC2016,SC2329  # literal fallbacks, invoked indirectly below
  pr_review_header() { printf '%s' '# 👾 Reviewed by Claude via the `/pr-review` skill 👾'; }
  # shellcheck disable=SC2329
  pr_review_is_approved_body() { grep -qF '# ✅ APPROVED ✅' <<<"$1"; }
fi
HEADER=$(pr_review_header)
FILELINE_RE='[A-Za-z_][A-Za-z0-9_./-]*\.(ts|tsx|js|jsx|mjs|cjs|py|go|rs|rb|java|kt|swift|c|cc|cpp|h|hpp|cs|sh|sql|css|scss|html|md|json|ya?ml|toml|tf|hcl)(:[0-9]+(-[0-9]+)?)?'

# -------- Path 1: new inline-review API --------
# Match: gh api repos/.../pulls/<n>/reviews ... (POST is default for --input)
if grep -qE '(^|[[:space:]]|;|&&|\|\||\||\(|`|\$\()gh[[:space:]]+api[[:space:]]+["'"'"']?repos/[^[:space:]]+/pulls/[0-9]+/reviews' <<<"$COMMAND"; then
  # Extract --input <file> argument
  PAYLOAD_FILE=$(sed -nE 's/.*--input[[:space:]=]+["'"'"']?([^"'"'"' ]+)["'"'"']?.*/\1/p' <<<"$COMMAND" | head -1)

  if [[ -z "$PAYLOAD_FILE" || ! -f "$PAYLOAD_FILE" ]]; then
    {
      echo "❌ /pr-review post blocked:"
      echo "  - Could not read the payload file named by --input (got: '${PAYLOAD_FILE:-none}')."
      echo "  - The payload must be written in a PREVIOUS Bash call, and --input must be a"
      echo "    literal path (e.g. /tmp/pr-review-payload-<pr>.json) — this hook validates the"
      echo "    file at call time and cannot expand \$VARIABLES or see files created in the"
      echo "    same call. Split it: call 1 writes the JSON, call 2 posts it."
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
    ERRORS+=("Use templates/approved.md or templates/changes-requested.md — they carry it.")
  fi

  # Engagement: at least one inline comment OR an approved body (the approved.md
  # sentinel). Post templates/approved.md verbatim for a clean approve.
  HAS_APPROVED=0
  pr_review_is_approved_body "$BODY" && HAS_APPROVED=1

  if [[ "$COMMENTS_LEN" -eq 0 && "$HAS_APPROVED" -eq 0 ]]; then
    ERRORS+=("Post shows no engagement with the diff.")
    ERRORS+=("Required: at least one inline comment in .comments[],")
    ERRORS+=("OR an approve posted verbatim from templates/approved.md.")
  fi

  # APPROVE with findings or REQUEST_CHANGES with zero findings is inconsistent.
  if [[ "$EVENT" == "APPROVE" && "$COMMENTS_LEN" -gt 0 ]]; then
    ERRORS+=("Event is APPROVE but comments[] has $COMMENTS_LEN inline comments.")
    ERRORS+=("APPROVE means zero findings. Use REQUEST_CHANGES when posting comments.")
  fi
  if [[ "$EVENT" == "REQUEST_CHANGES" && "$COMMENTS_LEN" -eq 0 && "$HAS_APPROVED" -eq 1 ]]; then
    ERRORS+=("Event is REQUEST_CHANGES but body is an approval.")
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
  ERRORS+=("Cat templates/approved.md or templates/changes-requested.md into the body.")
fi

HAS_FILELINE=0
HAS_APPROVED=0
grep -qE "$FILELINE_RE" <<<"$COMMAND" && HAS_FILELINE=1
pr_review_is_approved_body "$COMMAND" && HAS_APPROVED=1

if [[ "$HAS_FILELINE" -eq 0 && "$HAS_APPROVED" -eq 0 ]]; then
  ERRORS+=("Post shows no engagement with the diff.")
  ERRORS+=("Required: either at least one file:line citation in a finding,")
  ERRORS+=("OR an approve posted verbatim from templates/approved.md.")
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
