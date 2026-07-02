#!/usr/bin/env bash
# spawn.sh — Create worktree (if needed) and spawn runner agent
#
# Usage: spawn.sh <name> <branch> <project-root> <prompt-file> [target-repo]
#
# If target-repo is provided and differs from project-root, the worktree is
# created in the target repo instead (for cross-repo dispatch).
#
# Output (key:value on stdout):
#   worktree_status:reused|created-existing-branch|created-new-branch
#   worktree:<path>
#   session_id:<id>

set -eo pipefail

NAME="$1"
BRANCH="$2"
ROOT="$3"
PROMPT_FILE="$4"
TARGET_REPO="${5:-$ROOT}"

if [[ -z "$NAME" || -z "$BRANCH" || -z "$ROOT" || -z "$PROMPT_FILE" ]]; then
    echo "Usage: spawn.sh <name> <branch> <project-root> <prompt-file> [target-repo]" >&2
    exit 1
fi

# Resolve target repo to absolute path
if [[ "$TARGET_REPO" != /* ]]; then
    TARGET_REPO="$(cd "$TARGET_REPO" && pwd)"
fi

# Verify target repo is a git repo
if ! git -C "$TARGET_REPO" rev-parse --git-dir >/dev/null 2>&1; then
    echo "error: target-repo is not a git repository: $TARGET_REPO" >&2
    exit 1
fi

# Resolve relative prompt path against project root
if [[ "$PROMPT_FILE" != /* ]]; then
    PROMPT_FILE="$ROOT/$PROMPT_FILE"
fi

if [[ ! -f "$PROMPT_FILE" ]]; then
    echo "error: prompt file not found: $PROMPT_FILE" >&2
    exit 1
fi

# Worktree and dispatch artifacts live in the target repo
WORKTREE="$TARGET_REPO/.claude/worktrees/$NAME"
LOG_DIR="$TARGET_REPO/.dispatch/logs"

mkdir -p "$LOG_DIR" "$TARGET_REPO/.dispatch/status"

# Reset the Stop-hook attempt counter from any prior run of this name —
# a stale count >8 would let a re-dispatched runner exit immediately.
rm -f "$TARGET_REPO/.dispatch/state/$NAME.attempts"

# --- Worktree ---
if [[ -d "$WORKTREE/.git" || -f "$WORKTREE/.git" ]]; then
    echo "worktree_status:reused"
else
    WT_ERR="$(mktemp)"
    trap 'rm -f "$WT_ERR"' EXIT

    if git -C "$TARGET_REPO" rev-parse --verify "$BRANCH" >/dev/null 2>&1; then
        if ! git -C "$TARGET_REPO" worktree add "$WORKTREE" "$BRANCH" 2>"$WT_ERR"; then
            if grep -q "already checked out" "$WT_ERR"; then
                echo "error: branch '$BRANCH' is already checked out in another worktree" >&2
                exit 1
            fi
            cat "$WT_ERR" >&2
            exit 1
        fi
        echo "worktree_status:created-existing-branch"
    else
        if ! git -C "$TARGET_REPO" worktree add "$WORKTREE" -b "$BRANCH" 2>"$WT_ERR"; then
            cat "$WT_ERR" >&2
            exit 1
        fi
        echo "worktree_status:created-new-branch"
    fi
fi

echo "worktree:$WORKTREE"

# --- Spawn ---
# Prepend a hard worktree-isolation guard so the runner never edits or commits in
# the shared main checkout. The runner is given absolute paths into the main repo
# (from discovery); without this it can edit/commit there instead of its worktree.
STATUS_FILE="$TARGET_REPO/.dispatch/status/$NAME.md"
RUNTIME_PROMPT="$TARGET_REPO/.dispatch/prompts/$NAME.runtime.md"
# shellcheck disable=SC2016  # backticked code spans in prose, not expansions
{
    printf '## WORKTREE ISOLATION — read first, non-negotiable\n\n'
    printf 'Your working directory is this git worktree:\n  %s\n(branch `%s`). Do ALL work inside it.\n\n' "$WORKTREE" "$BRANCH"
    printf -- '- Every file edit happens inside `%s`.\n' "$WORKTREE"
    printf -- '- Run every git command (status/add/commit/push) from this worktree; commits belong on branch `%s`.\n' "$BRANCH"
    printf -- '- NEVER edit files, `cd`, or run git in the main checkout at `%s` — it is shared across runners and must not be modified.\n' "$TARGET_REPO"
    printf -- '- If the task or discovery cites an absolute path under `%s` (e.g. `%s/packages/...`), treat it as the SAME relative path inside your worktree (`%s/packages/...`) and edit it THERE.\n' "$TARGET_REPO" "$TARGET_REPO" "$WORKTREE"
    printf -- '- The ONLY path you may write outside the worktree is your status file: `%s`.\n' "$STATUS_FILE"
    printf -- '- Do NOT create Linear issues/tickets (no `save_issue`, no `/issue`). If you discover follow-up work, document it in your status file + PR description as a proposed follow-up; the operator files it via `/issue`. Reference it as "proposed follow-up", never a created ticket id.\n'
    printf -- '- Before every commit run `git rev-parse --show-toplevel` and confirm it prints `%s`; if it prints anything else, STOP and cd into the worktree first.\n\n' "$WORKTREE"
    printf -- '---\n\n'
    cat "$PROMPT_FILE"
} > "$RUNTIME_PROMPT"

# Pass prompt via file to avoid shell argument length limits.
# The CLAUDE_DISPATCH_* vars give the worktree-isolation hook an IMMUTABLE
# runner identity — it enforces against these, not the session cwd, so a runner
# that cd's into the main checkout still can't write there.
PROJECT_NAME="$(basename "$TARGET_REPO")"
RUNNER_NAME="dispatch-$PROJECT_NAME-$NAME"
SESSION_OUTPUT=$(cd "$WORKTREE" && \
    CLAUDE_DISPATCH_WORKTREE="$WORKTREE" \
    CLAUDE_DISPATCH_ROOT="$TARGET_REPO" \
    CLAUDE_DISPATCH_STATUS_FILE="$STATUS_FILE" \
    claude --bg \
    --agent runner \
    --model default \
    --name "$RUNNER_NAME" \
    --permission-mode bypassPermissions \
    --append-system-prompt-file "$RUNTIME_PROMPT" \
    "Execute the task described in the system prompt." 2>&1)

# Resolve the session id by the --name we set — robust to --bg stdout wording,
# which is the one fragile coupling to CLI output. Retry briefly for agent-list
# latency, then fall back to scraping stdout ("backgrounded · <8-hex>").
resolve_id_by_name() {
    claude agents --json 2>/dev/null | jq -r --arg n "$RUNNER_NAME" '
      ["completed","done","failed","stopped","exited","cancelled","canceled"] as $terminal
      | [ .[]
          | select((.name // "") == $n)
          | select(((.state // .status // "") | ascii_downcase) as $s | ($terminal | index($s) | not))
          | (.id // .sessionId // "")
        ] | first // ""
    ' 2>/dev/null || echo ""
}
SESSION_ID=""
for _ in 1 2 3 4 5; do
    SESSION_ID=$(resolve_id_by_name)
    if [[ -n "$SESSION_ID" ]]; then break; fi
    sleep 1
done
if [[ -z "$SESSION_ID" ]]; then
    SESSION_ID=$(echo "$SESSION_OUTPUT" | grep 'backgrounded' | grep -oE '[a-f0-9]{8}' | head -1)
fi

if [[ -z "$SESSION_ID" ]]; then
    echo "error: failed to spawn background session" >&2
    echo "$SESSION_OUTPUT" >&2
    exit 1
fi

echo "session_id:$SESSION_ID"
