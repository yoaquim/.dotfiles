#!/usr/bin/env bash
# Stop hook for the runner agent.
#
# Blocks the agent from ending until:
#   1. A PR exists for the current branch (forces /pr).
#   2. One bot-review pass on that PR is clean (forces address-then-exit).
#
# Skips entirely when not inside a dispatch session (no status file) or when
# the runner has explicitly marked the work `status: failed`.
#
# Exit 0  → allow stop.
# Exit 2  → block stop; stderr is fed back to the agent as a new instruction.

set -uo pipefail

# Always allow stop if anything in here misbehaves — never trap the agent
# because of a bug in the hook itself.
trap 'exit 0' ERR

# Drain stdin (Stop hook input is JSON we don't need).
cat >/dev/null 2>&1 || true

# --- Identify dispatch session ---
COMMON_GIT_DIR=$(git rev-parse --git-common-dir 2>/dev/null) || exit 0
COMMON_GIT_DIR=$(cd "$COMMON_GIT_DIR" 2>/dev/null && pwd) || exit 0
DISPATCH_ROOT=$(dirname "$COMMON_GIT_DIR")
WORKTREE=$(git rev-parse --show-toplevel 2>/dev/null) || exit 0
NAME=$(basename "$WORKTREE")
STATUS_FILE="$DISPATCH_ROOT/.dispatch/status/$NAME.md"

# Not a dispatch runner — let normal Stop happen.
[[ -f "$STATUS_FILE" ]] || exit 0

# Failed runs are allowed to exit (runner.md already pushes the branch).
if grep -qE '^\s*-\s*\*\*status\*\*:\s*failed' "$STATUS_FILE"; then
  exit 0
fi

STATE_DIR="$DISPATCH_ROOT/.dispatch/state"
mkdir -p "$STATE_DIR"
REVIEW_PASS_MARKER="$STATE_DIR/$NAME.review-pass"
ATTEMPT_FILE="$STATE_DIR/$NAME.attempts"

# --- Escape valve: cap stop attempts to avoid pathological loops ---
ATTEMPTS=$(cat "$ATTEMPT_FILE" 2>/dev/null || echo 0)
ATTEMPTS=$((ATTEMPTS + 1))
echo "$ATTEMPTS" > "$ATTEMPT_FILE"

if [[ $ATTEMPTS -gt 8 ]]; then
  if ! grep -qE '^\s*-\s*\*\*status\*\*:\s*needs_review' "$STATUS_FILE"; then
    sed -i.bak -E 's/^(\s*-\s*\*\*status\*\*:\s*).*/\1needs_review/' "$STATUS_FILE" \
      && rm -f "${STATUS_FILE}.bak"
  fi
  echo "enforce-completion: >8 stop attempts; allowing stop with status=needs_review" >&2
  exit 0
fi

BRANCH=$(git rev-parse --abbrev-ref HEAD 2>/dev/null || echo "<unknown>")

# --- Gate 1: PR must exist ---
PR_NUMBER=$(gh pr view --json number -q '.number' 2>/dev/null || true)
if [[ -z "$PR_NUMBER" ]]; then
  cat >&2 <<EOF
You cannot end this session yet. Complete the ship sequence:

1. Run a final self-review of the diff. Fix anything obvious.
2. Run \`/pr\` to create the pull request for branch \`$BRANCH\`.
3. After the PR is open, wait ~60 seconds for bot reviewers
   (Codex, CodeRabbit, github-actions) to weigh in.
4. Run \`~/.claude/scripts/check-pr-reviews.sh <pr-number>\` and address
   any unresolved bot comments or failing bot checks.

Then try to end again. This Stop hook will re-evaluate.
EOF
  exit 2
fi

# --- Gate 1.5: PR content must conform to /pr conventions ---
# Authoritative gate: re-validate the actual created PR (the PreToolUse hook
# is best-effort on title; heredoc bodies bypass its body check).
PR_CONTENT=$(gh pr view "$PR_NUMBER" --json title,body 2>/dev/null || echo '{}')
PR_TITLE=$(jq -r '.title // ""' <<<"$PR_CONTENT" 2>/dev/null || echo "")
PR_BODY=$(jq -r '.body // ""' <<<"$PR_CONTENT" 2>/dev/null || echo "")

CONTENT_ERRORS=()

if [[ -n "$PR_TITLE" ]]; then
  T_RESULT=$("$HOME/.claude/scripts/validate-title.sh" "$PR_TITLE" 2>/dev/null || true)
  T_VALID=$(jq -r 'if .valid == false then "false" else "true" end' <<<"$T_RESULT" 2>/dev/null || echo true)
  if [[ "$T_VALID" == "false" ]]; then
    while IFS= read -r ERR; do
      [[ -n "$ERR" ]] && CONTENT_ERRORS+=("Title: $ERR")
    done < <(jq -r '.errors[]?' <<<"$T_RESULT" 2>/dev/null)
  fi
fi

TICKET_ID=""
if [[ "$BRANCH" =~ ([A-Za-z]+-[0-9]+) ]]; then
  TICKET_ID=$(echo "${BASH_REMATCH[1]}" | tr '[:lower:]' '[:upper:]')
fi

B_RESULT=$("$HOME/.claude/scripts/validate-pr-body.sh" "$PR_BODY" "$TICKET_ID" 2>/dev/null || true)
B_VALID=$(jq -r 'if .valid == false then "false" else "true" end' <<<"$B_RESULT" 2>/dev/null || echo true)
if [[ "$B_VALID" == "false" ]]; then
  while IFS= read -r ERR; do
    [[ -n "$ERR" ]] && CONTENT_ERRORS+=("Body: $ERR")
  done < <(jq -r '.errors[]?' <<<"$B_RESULT" 2>/dev/null)
fi

if (( ${#CONTENT_ERRORS[@]} > 0 )); then
  {
    echo "You cannot end this session yet. PR #$PR_NUMBER does not conform to /pr conventions."
    echo
    for ERR in "${CONTENT_ERRORS[@]}"; do
      echo "  - $ERR"
    done
    echo
    echo "Fix with: gh pr edit $PR_NUMBER --title \"...\" --body \"...\""
    echo "Or re-run /pr. Rules: ~/.claude/skills/pr/SKILL.md"
  } >&2
  exit 2
fi

# --- Gate 2: one clean review pass must be recorded ---
if [[ -f "$REVIEW_PASS_MARKER" ]]; then
  exit 0
fi

REVIEW_JSON=$(bash "$HOME/.claude/scripts/check-pr-reviews.sh" "$PR_NUMBER" 2>/dev/null || echo '{}')
CLEAN=$(jq -r '.clean // false' <<<"$REVIEW_JSON" 2>/dev/null || echo false)
PENDING=$(jq -r '.pending_checks // 0' <<<"$REVIEW_JSON" 2>/dev/null || echo 0)
UNRESOLVED=$(jq -r '.unresolved_comments // 0' <<<"$REVIEW_JSON" 2>/dev/null || echo 0)
FAILING=$(jq -c '.failing_checks // []' <<<"$REVIEW_JSON" 2>/dev/null || echo '[]')

if [[ "$CLEAN" == "true" ]]; then
  touch "$REVIEW_PASS_MARKER"
  exit 0
fi

{
  echo "You cannot end this session yet. PR #$PR_NUMBER is open but bot reviewers are not satisfied."
  echo
  echo "check-pr-reviews.sh result:"
  echo "  $REVIEW_JSON"
  echo
  if [[ "$PENDING" -gt 0 ]]; then
    echo "- $PENDING bot check(s) still running. Wait ~60s, then try to end again so this hook re-evaluates."
  fi
  if [[ "$UNRESOLVED" -gt 0 ]]; then
    echo "- $UNRESOLVED unresolved bot comment(s). Fetch with:"
    echo "    gh api repos/{owner}/{repo}/pulls/$PR_NUMBER/comments"
    echo "  Address them, commit, push."
  fi
  if [[ "$FAILING" != "[]" ]]; then
    echo "- Failing bot checks: $FAILING. Fix the underlying issues, commit, push."
  fi
  echo
  echo "After acting, try to end again. The hook re-runs the check each turn."
} >&2
exit 2
