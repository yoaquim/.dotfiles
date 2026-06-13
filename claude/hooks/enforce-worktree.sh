#!/usr/bin/env bash
# PreToolUse hook for the runner agent: keep the runner inside its worktree.
#
# Dispatch runners work in <repo>/.claude/worktrees/<name> but receive absolute
# paths into the main checkout from discovery. The spawn prompt instructs them
# to stay in the worktree; this hook enforces it for BOTH vectors:
#   - Edit|Write|MultiEdit — block a file_path inside the main checkout
#   - Bash                  — block a command that references the main checkout
#                             (covers sed -i, cat >, tee, git -C <main>, etc.,
#                             which never reach the Edit/Write tools)
#
# Runner identity comes from the CLAUDE_DISPATCH_* env vars that spawn.sh injects
# into the runner process. These are IMMUTABLE — a runner that `cd`s into the
# main checkout cannot change them, so enforcement holds regardless of cwd.
# Sessions launched without those vars fall back to cwd-derived detection (best
# effort: it cannot see a runner that has cd'd away from its worktree).
#
# The Bash check is best-effort: it catches references to the main checkout's
# absolute path (what discovery hands the runner). It cannot see writes reached
# purely by relative traversal (e.g. `cd ../../.. && sed -i x`), which the spawn
# prompt forbids. Treat it as defense-in-depth layered on that prompt.
#
# Exit 0 → allow. Exit 2 → block; stderr is fed back to the agent.

set -uo pipefail

# Fail open on hook bugs — never trap the agent because of us.
trap 'exit 0' ERR

INPUT=$(cat)
TOOL=$(jq -r '.tool_name // ""' <<<"$INPUT")
CWD=$(jq -r '.cwd // ""' <<<"$INPUT")

# --- Resolve runner identity (immutable env, else cwd fallback) ---
if [[ -n "${CLAUDE_DISPATCH_WORKTREE:-}" ]]; then
    WORKTREE="$CLAUDE_DISPATCH_WORKTREE"
    DISPATCH_ROOT="${CLAUDE_DISPATCH_ROOT:-$(dirname "$(dirname "$(dirname "$WORKTREE")")")}"
    STATUS_FILE="${CLAUDE_DISPATCH_STATUS_FILE:-$DISPATCH_ROOT/.dispatch/status/$(basename "$WORKTREE").md}"
else
    # Legacy fallback: derive from cwd (same detection as enforce-completion.sh).
    [[ -z "$CWD" ]] && exit 0
    cd "$CWD" 2>/dev/null || exit 0
    WORKTREE=$(git rev-parse --show-toplevel 2>/dev/null) || exit 0
    COMMON_GIT_DIR=$(git rev-parse --git-common-dir 2>/dev/null) || exit 0
    COMMON_GIT_DIR=$(cd "$COMMON_GIT_DIR" 2>/dev/null && pwd) || exit 0
    DISPATCH_ROOT=$(dirname "$COMMON_GIT_DIR")
    STATUS_FILE="$DISPATCH_ROOT/.dispatch/status/$(basename "$WORKTREE").md"

    # Not a dispatch runner, or the worktree IS the main checkout → nothing to enforce.
    [[ -f "$STATUS_FILE" ]] || exit 0
    [[ "$WORKTREE" == "$DISPATCH_ROOT" ]] && exit 0
fi

[[ -z "$DISPATCH_ROOT" ]] && exit 0

# Resolve symlinks (e.g. /tmp → /private/tmp) so prefix checks compare
# physical paths. Walks up past not-yet-created components.
canon() {
    local p="$1" suffix=""
    [[ -z "$p" ]] && return
    while [[ ! -d "$p" && "$p" != "/" ]]; do
        suffix="/$(basename "$p")$suffix"
        p=$(dirname "$p")
    done
    p=$(cd "$p" 2>/dev/null && pwd -P) || { printf '%s' "$1"; return; }
    printf '%s%s' "$p" "$suffix"
}

block_msg() {
    {
      echo "Blocked: $1"
      echo
      echo "Your worktree is: $WORKTREE"
      echo "Use the SAME relative path inside the worktree instead. The only path"
      echo "you may touch outside it is your status file: $STATUS_FILE"
    } >&2
}

case "$TOOL" in
  Edit|Write|MultiEdit)
    FILE=$(jq -r '.tool_input.file_path // ""' <<<"$INPUT")
    [[ -z "$FILE" ]] && exit 0
    [[ "$FILE" != /* ]] && FILE="${CWD:-$WORKTREE}/$FILE"
    FILE=$(canon "$FILE")
    C_WORKTREE=$(canon "$WORKTREE")
    C_ROOT=$(canon "$DISPATCH_ROOT")
    C_STATUS=$(canon "$STATUS_FILE")
    case "$FILE" in
      "$C_WORKTREE"/*) exit 0 ;;
      "$C_STATUS") exit 0 ;;
      "$C_ROOT"/*)
        block_msg "'$FILE' is in the main checkout, not your worktree."
        exit 2
        ;;
    esac
    ;;
  Bash)
    CMD=$(jq -r '.tool_input.command // ""' <<<"$INPUT")
    [[ -z "$CMD" ]] && exit 0
    # Mask legitimate references (the worktree and the status file) so only
    # main-checkout references remain. The worktree path contains DISPATCH_ROOT
    # as a prefix, so masking it first prevents false positives.
    MASKED=${CMD//"$WORKTREE"/}
    MASKED=${MASKED//"$STATUS_FILE"/}
    if [[ "$MASKED" == *"$DISPATCH_ROOT"* ]]; then
      block_msg "this command references the shared main checkout at '$DISPATCH_ROOT'."
      exit 2
    fi
    ;;
esac

exit 0
