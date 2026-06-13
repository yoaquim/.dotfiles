#!/usr/bin/env bash
# attach.sh — Open tmux window attached to a background runner session
#
# Usage: attach.sh <name> <worktree-path> <session-id> [--remote]
#
# --remote: after attaching, send /remote-control to the session so it
# becomes reachable from claude.ai/code and the Claude mobile app.

set -eo pipefail

NAME="$1"
WORKTREE="$2"
SESSION_ID="$3"
REMOTE="${4:-}"

if [[ -z "$NAME" || -z "$WORKTREE" || -z "$SESSION_ID" ]]; then
    echo "Usage: attach.sh <name> <worktree-path> <session-id> [--remote]" >&2
    exit 1
fi

if [[ ! -d "$WORKTREE" ]]; then
    echo "error: worktree not found at $WORKTREE" >&2
    exit 1
fi

tmux new-window -n "dispatch-$NAME" -c "$WORKTREE" "claude attach $SESSION_ID"
tmux split-window -h -t "dispatch-$NAME" -c "$WORKTREE"
tmux select-pane -t "dispatch-$NAME.0"

if [[ "$REMOTE" == "--remote" ]]; then
    # Best-effort: give the attached TUI a moment to come up, then request
    # remote control. The QR code / URL appears in the attached pane.
    sleep 3
    tmux send-keys -t "dispatch-$NAME.0" "/remote-control" Enter
    echo "Opened tmux window 'dispatch-$NAME' in $WORKTREE (attached session $SESSION_ID left, shell right). Remote control requested — open claude.ai/code or the Claude app; QR/URL is in the attached pane."
else
    echo "Opened tmux window 'dispatch-$NAME' in $WORKTREE (attached session $SESSION_ID left, shell right)"
fi
