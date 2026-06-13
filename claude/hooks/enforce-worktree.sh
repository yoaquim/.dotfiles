#!/usr/bin/env bash
# PreToolUse hook for the runner agent: block file writes outside the worktree.
#
# Dispatch runners work in <repo>/.claude/worktrees/<name> but receive absolute
# paths into the main checkout from discovery. The spawn prompt instructs them
# to stay in the worktree; this hook enforces it deterministically.
#
# Allowed:
#   - any path inside the worktree
#   - the runner's own status file in the main repo's .dispatch/status/
#   - anything outside the main checkout entirely (/tmp, caches, ...)
# Blocked:
#   - any other path inside the main checkout (shared across runners)
#
# Exit 0 → allow. Exit 2 → block; stderr is fed back to the agent.

set -uo pipefail

# Fail open on hook bugs — never trap the agent because of us.
trap 'exit 0' ERR

INPUT=$(cat)
FILE=$(jq -r '.tool_input.file_path // ""' <<<"$INPUT")
CWD=$(jq -r '.cwd // ""' <<<"$INPUT")
[[ -z "$FILE" || -z "$CWD" ]] && exit 0

# Identify dispatch session (same detection as enforce-completion.sh).
cd "$CWD" 2>/dev/null || exit 0
WORKTREE=$(git rev-parse --show-toplevel 2>/dev/null) || exit 0
COMMON_GIT_DIR=$(git rev-parse --git-common-dir 2>/dev/null) || exit 0
COMMON_GIT_DIR=$(cd "$COMMON_GIT_DIR" 2>/dev/null && pwd) || exit 0
DISPATCH_ROOT=$(dirname "$COMMON_GIT_DIR")
NAME=$(basename "$WORKTREE")
STATUS_FILE="$DISPATCH_ROOT/.dispatch/status/$NAME.md"

# Not a dispatch runner, or the worktree IS the main checkout → nothing to enforce.
[[ -f "$STATUS_FILE" ]] || exit 0
[[ "$WORKTREE" == "$DISPATCH_ROOT" ]] && exit 0

# Absolutize relative paths against the session cwd.
[[ "$FILE" != /* ]] && FILE="$CWD/$FILE"

# Resolve symlinks (e.g. /tmp → /private/tmp) so prefix checks compare
# physical paths. Walks up past not-yet-created components.
canon() {
    local p="$1" suffix=""
    while [[ ! -d "$p" && "$p" != "/" ]]; do
        suffix="/$(basename "$p")$suffix"
        p=$(dirname "$p")
    done
    p=$(cd "$p" 2>/dev/null && pwd -P) || { printf '%s' "$1"; return; }
    printf '%s%s' "$p" "$suffix"
}

FILE=$(canon "$FILE")
WORKTREE=$(canon "$WORKTREE")
DISPATCH_ROOT=$(canon "$DISPATCH_ROOT")
STATUS_FILE="$DISPATCH_ROOT/.dispatch/status/$NAME.md"

case "$FILE" in
  "$WORKTREE"/*) exit 0 ;;
  "$STATUS_FILE") exit 0 ;;
  "$DISPATCH_ROOT"/*)
    {
      echo "Blocked: '$FILE' is in the main checkout, not your worktree."
      echo
      echo "Your worktree is: $WORKTREE"
      echo "Write the same relative path there instead. The only file you may"
      echo "write outside the worktree is your status file: $STATUS_FILE"
    } >&2
    exit 2
    ;;
esac

exit 0
