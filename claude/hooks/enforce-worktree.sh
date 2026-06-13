#!/usr/bin/env bash
# PreToolUse hook for the runner agent: block file writes outside the worktree.
#
# Dispatch runners work in <repo>/.claude/worktrees/<name> but receive absolute
# paths into the main checkout from discovery. The spawn prompt instructs them
# to stay in the worktree; this hook enforces it deterministically.
#
# Runner identity comes from the CLAUDE_DISPATCH_* env vars that spawn.sh injects
# into the runner process. These are IMMUTABLE — a runner that `cd`s into the
# main checkout cannot change them, so enforcement holds regardless of cwd.
# Sessions launched without those vars fall back to cwd-derived detection (best
# effort: it cannot see a runner that has cd'd away from its worktree).
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
[[ -z "$FILE" ]] && exit 0

if [[ -n "${CLAUDE_DISPATCH_WORKTREE:-}" ]]; then
    # Immutable identity from spawn.sh — cannot be subverted by cd.
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

# Absolutize relative paths against the session cwd (worktree if cwd unknown).
[[ "$FILE" != /* ]] && FILE="${CWD:-$WORKTREE}/$FILE"

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
STATUS_FILE=$(canon "$STATUS_FILE")

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
