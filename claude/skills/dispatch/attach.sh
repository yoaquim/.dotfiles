#!/usr/bin/env bash
# attach.sh — Open tmux window attached to a background runner session
#
# Usage: attach.sh <name> <worktree-path> <session-id>

set -eo pipefail

NAME="$1"
WORKTREE="$2"
SESSION_ID="$3"

if [[ -z "$NAME" || -z "$WORKTREE" || -z "$SESSION_ID" ]]; then
    echo "Usage: attach.sh <name> <worktree-path> <session-id>" >&2
    exit 1
fi

if [[ ! -d "$WORKTREE" ]]; then
    echo "error: worktree not found at $WORKTREE" >&2
    exit 1
fi

tmux new-window -n "dispatch-$NAME" -c "$WORKTREE" "claude attach $SESSION_ID"
tmux split-window -h -t "dispatch-$NAME" -c "$WORKTREE"
tmux select-pane -t "dispatch-$NAME.0"
echo "Opened tmux window 'dispatch-$NAME' in $WORKTREE (attached session $SESSION_ID left, shell right)"
