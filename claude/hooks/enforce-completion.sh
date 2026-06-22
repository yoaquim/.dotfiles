#!/usr/bin/env bash
# Stop hook for the runner agent.
#
# Blocks the agent from ending until:
#   1. A PR exists for the current branch (forces /pr).
#   2. The PR title + body conform to /pr conventions.
#   3. The runner's status file reports a terminal state.
#
# Terminal statuses (allow exit):
#   - completed             — APPROVED + CI green, or PR merged
#   - needs_review          — loop cap / timeout reached
#   - closed-without-merge  — PR was closed without merging
#   - failed                — runner gave up on the work itself
#
# Anything else (in_progress, addressing_reviews, etc.) → exit 2, runner
# re-engages and continues the unified review loop in runner.md.
#
# Skips entirely when not inside a dispatch session (no status file).
#
# Exit 0  → allow stop.
# Exit 2  → block stop; stderr is fed back to the agent as a new instruction.

set -uo pipefail

# Always allow stop if anything in here misbehaves — never trap the agent
# because of a bug in the hook itself.
trap 'exit 0' ERR

# Drain stdin (Stop hook input is JSON we don't need).
cat >/dev/null 2>&1 || true

# Pin to the runner's worktree via the immutable identity spawn.sh injects, so a
# cwd that has drifted into the shared checkout can't make this look like a
# non-dispatch session and skip the completion gates. All git/gh checks below
# then run against the worktree regardless of where the runner's cwd ended up.
if [[ -n "${CLAUDE_DISPATCH_WORKTREE:-}" ]]; then
  cd "$CLAUDE_DISPATCH_WORKTREE" 2>/dev/null || true
fi

# --- Identify dispatch session ---
COMMON_GIT_DIR=$(git rev-parse --git-common-dir 2>/dev/null) || exit 0
COMMON_GIT_DIR=$(cd "$COMMON_GIT_DIR" 2>/dev/null && pwd) || exit 0
DISPATCH_ROOT=$(dirname "$COMMON_GIT_DIR")
WORKTREE=$(git rev-parse --show-toplevel 2>/dev/null) || exit 0
NAME=$(basename "$WORKTREE")
STATUS_FILE="$DISPATCH_ROOT/.dispatch/status/$NAME.md"

# Not a dispatch runner — let normal Stop happen.
[[ -f "$STATUS_FILE" ]] || exit 0

# Helper: extract current status value from the status file.
# Status file format: `- **status**: <value>`. Returns lowercase value, trimmed.
read_status() {
  awk -F':' '
    tolower($0) ~ /^[[:space:]]*-[[:space:]]*\*\*status\*\*[[:space:]]*:/ {
      # Everything after the first colon
      sub(/^[^:]*:/, "", $0)
      # Trim
      gsub(/^[[:space:]]+|[[:space:]]+$/, "", $0)
      print tolower($0)
      exit
    }
  ' "$STATUS_FILE"
}

is_terminal() {
  case "$1" in
    completed|needs_review|closed-without-merge|failed) return 0 ;;
    *) return 1 ;;
  esac
}

# Start timestamp from the status file header (`- **started**: <ISO>`).
read_started() {
  sed -n 's/^- \*\*started\*\*: //p' "$STATUS_FILE" | head -1
}

# Flip the status line to needs_review in place (macOS sed lacks /I, so awk).
finalize_needs_review() {
  awk '
    !done && tolower($0) ~ /^[[:space:]]*-[[:space:]]*\*\*status\*\*[[:space:]]*:/ {
      sub(/:.*/, ": needs_review")
      done = 1
    }
    { print }
  ' "$STATUS_FILE" > "${STATUS_FILE}.tmp" && mv "${STATUS_FILE}.tmp" "$STATUS_FILE"
}

STATUS=$(read_status)

# Terminal → allow exit immediately. The runner has finalized its work.
if is_terminal "$STATUS"; then
  exit 0
fi

# --- Wall-clock cap: 8hr from start → stop with needs_review ---
# This is the real give-up bound (mirrors the reviewer's enforce-watch cap). The
# runner no longer counts its own iterations; the hook owns the limit.
STARTED=$(read_started)
if [[ -n "$STARTED" ]]; then
  # First 19 chars are YYYY-MM-DDTHH:MM:SS regardless of fractional/Z/offset suffix;
  # normalize a space separator to 'T' so a `2026-06-20 19:57:00` status value parses.
  STARTED_NORM="${STARTED:0:19}"; STARTED_NORM="${STARTED_NORM/ /T}"
  # BSD date first, GNU `date -d` fallback (mirrors enforce-watch.sh) so the cap
  # survives both implementations and minor format drift in the status file.
  S_EPOCH=$(date -j -f '%Y-%m-%dT%H:%M:%S' "$STARTED_NORM" '+%s' 2>/dev/null \
         || date -d "$STARTED" +%s 2>/dev/null || echo 0)
  if [[ "$S_EPOCH" -gt 0 ]] && (( $(date +%s) - S_EPOCH > 28800 )); then
    finalize_needs_review
    echo "enforce-completion: 8hr cap reached; allowing stop with status=needs_review" >&2
    exit 0
  fi
fi

STATE_DIR="$DISPATCH_ROOT/.dispatch/state"
mkdir -p "$STATE_DIR"
ATTEMPT_FILE="$STATE_DIR/$NAME.attempts"

# --- Runaway-spin backstop: cap stop attempts well above legitimate use ---
# A healthy review loop Stops ~once/60s → ~480 times over 8hr, so this sits above
# real use and only catches a session that ignores the sleep and spins.
ATTEMPTS=$(cat "$ATTEMPT_FILE" 2>/dev/null || echo 0)
ATTEMPTS=$((ATTEMPTS + 1))
echo "$ATTEMPTS" > "$ATTEMPT_FILE"

if [[ $ATTEMPTS -gt 1000 ]]; then
  finalize_needs_review
  echo "enforce-completion: >1000 stop attempts; allowing stop with status=needs_review (runaway-spin guard)" >&2
  exit 0
fi

BRANCH=$(git rev-parse --abbrev-ref HEAD 2>/dev/null || echo "<unknown>")

# --- Gate 1: PR must exist ---
PR_NUMBER=$(gh pr view --json number -q '.number' 2>/dev/null || true)
if [[ -z "$PR_NUMBER" ]]; then
  cat >&2 <<EOF
You cannot end this session yet. Status is "$STATUS" (non-terminal) and no PR exists yet.

Complete the ship sequence:

1. Run a final self-review of the diff. Fix anything obvious.
2. Run \`/pr\` to create the pull request for branch \`$BRANCH\`.
3. After the PR is open, spawn the reviewer and enter the unified review loop
   per runner.md "Completion". The runner is responsible for writing a terminal
   status when the loop ends.

Then try to end again. This hook will re-evaluate.
EOF
  exit 2
fi

# --- Gate 1.5: PR content must conform to /pr conventions ---
# Re-validate the actual created PR (the PreToolUse hook is best-effort on
# title; heredoc bodies bypass its body check).
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

# --- Gate 2: status must be terminal ---
# Get fresh state to include in the message.
STATE_JSON=$(bash "$HOME/.claude/scripts/check-pr-state.sh" "$PR_NUMBER" 2>/dev/null || echo '{}')

{
  echo "You cannot end this session yet. Status is \"$STATUS\" (non-terminal)."
  echo
  echo "PR #$PR_NUMBER state:"
  echo "  $STATE_JSON"
  echo
  echo "Re-enter the unified review loop in runner.md \"Completion\":"
  echo "  - Run: ~/.claude/scripts/check-pr-state.sh $PR_NUMBER"
  echo "  - Unresolved threads → fix → commit → push → ~/.claude/skills/dispatch/resolve-thread.sh <id>"
  echo "  - ci_green==false → fix the failing check (gh pr checks $PR_NUMBER; gh run view <run-id> --log-failed) → commit → push. In scope; don't wait for a human."
  echo "  - Every turn, ensure a reviewer is watching: ~/.claude/skills/dispatch/spawn-reviewer.sh \"$PR_NUMBER\" (idempotent — reuses live / already-reviewed / spawns). Never hand-roll a claude --bg review agent."
  echo "  - Terminal when approved_at_head==true AND ci_green (self-authored PRs never reach reviewDecision==APPROVED), or on merge/close."
  echo "  - Sleep 60s if idle, then re-check"
  echo
  echo "Write a terminal status (completed | needs_review | closed-without-merge | failed)"
  echo "in the status file when the loop ends. The hook re-runs the check each turn."
} >&2
exit 2
