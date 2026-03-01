#!/usr/bin/env bash
# attach.sh — Open tmux window in runner's worktree
#
# Usage: attach.sh <name> <worktree-path>

set -eo pipefail

NAME="$1"
WORKTREE="$2"

if [[ -z "$NAME" || -z "$WORKTREE" ]]; then
    echo "Usage: attach.sh <name> <worktree-path>" >&2
    exit 1
fi

if [[ ! -d "$WORKTREE" ]]; then
    echo "error: worktree not found at $WORKTREE" >&2
    exit 1
fi

tmux new-window -n "deck-$NAME" -c "$WORKTREE" "claude --dangerously-skip-permissions"
tmux split-window -h -t "deck-$NAME" -c "$WORKTREE"
tmux select-pane -t "deck-$NAME.0"
echo "Opened tmux window 'deck-$NAME' in $WORKTREE (claude left, shell right)"
