#!/usr/bin/env bash
# spawn.sh — Create worktree (if needed) and spawn deck-runner agent
#
# Usage: spawn.sh <name> <branch> <project-root> <spec-path> [--resume]
#
# --resume: append to log file and add continuation note to prompt
#
# Output (key:value on stdout):
#   worktree_status:reused|created-existing-branch|created-new-branch
#   worktree:<path>
#   pid:<number>
#   pid_start:<lstart string>

set -eo pipefail

NAME="$1"
BRANCH="$2"
ROOT="$3"
SPEC_PATH="$4"
RESUME=""

# Check for --resume flag
shift 4 2>/dev/null || true
for arg in "$@"; do
    [[ "$arg" == "--resume" ]] && RESUME=1
done

if [[ -z "$NAME" || -z "$BRANCH" || -z "$ROOT" || -z "$SPEC_PATH" ]]; then
    echo "Usage: spawn.sh <name> <branch> <project-root> <spec-path> [--resume]" >&2
    exit 1
fi

WORKTREE="$ROOT/.claude/worktrees/$NAME"
LOG_DIR="$ROOT/.deck/logs"

mkdir -p "$LOG_DIR" "$ROOT/.deck/status"

# --- Worktree ---
if [[ -d "$WORKTREE/.git" || -f "$WORKTREE/.git" ]]; then
    echo "worktree_status:reused"
else
    WT_ERR="$(mktemp)"
    trap 'rm -f "$WT_ERR"' EXIT

    if git -C "$ROOT" rev-parse --verify "$BRANCH" >/dev/null 2>&1; then
        if ! git -C "$ROOT" worktree add "$WORKTREE" "$BRANCH" 2>"$WT_ERR"; then
            if grep -q "already checked out" "$WT_ERR"; then
                echo "error: branch '$BRANCH' is already checked out in another worktree" >&2
                exit 1
            fi
            cat "$WT_ERR" >&2
            exit 1
        fi
        echo "worktree_status:created-existing-branch"
    else
        if ! git -C "$ROOT" worktree add "$WORKTREE" -b "$BRANCH" 2>"$WT_ERR"; then
            cat "$WT_ERR" >&2
            exit 1
        fi
        echo "worktree_status:created-new-branch"
    fi
fi

echo "worktree:$WORKTREE"

# --- Build prompt ---
PROMPT="Spec name: $NAME
Spec file: $SPEC_PATH
Status file: $ROOT/.deck/status/$NAME.md"

if [[ -n "$RESUME" ]]; then
    PROMPT="$PROMPT
A previous runner worked on this spec. Check the status file and git log for what's done. Continue from where it left off."
fi

# --- Spawn ---
cd "$WORKTREE"
if [[ -n "$RESUME" ]]; then
    nohup env -u CLAUDECODE claude --agent deck-runner -p "$PROMPT" --dangerously-skip-permissions \
        >> "$LOG_DIR/$NAME.log" 2>&1 &
else
    nohup env -u CLAUDECODE claude --agent deck-runner -p "$PROMPT" --dangerously-skip-permissions \
        > "$LOG_DIR/$NAME.log" 2>&1 &
fi
PID=$!

# Retry PID start time capture — process tree may need a moment to initialize
PID_START="unknown"
for i in 1 2 3; do
    sleep 1
    PID_START="$(ps -p "$PID" -o lstart= 2>/dev/null | xargs)" && [[ -n "$PID_START" ]] && break
    PID_START="unknown"
done

echo "pid:$PID"
echo "pid_start:$PID_START"
