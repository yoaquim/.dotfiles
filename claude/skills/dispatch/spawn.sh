#!/usr/bin/env bash
# spawn.sh — Create worktree (if needed) and spawn runner agent
#
# Usage: spawn.sh <name> <branch> <project-root> <prompt-file>
#
# Cross-repo dispatch passes the resolved target repo AS project-root
# (the /dispatch skill resolves --repo before calling).
#
# DISPATCH_MODEL (env, optional): model for the runner session (e.g. opus,
# sonnet, claude-opus-4-8). Defaults to the CLI default — the only other lever,
# since ANTHROPIC_MODEL does not propagate to a --bg daemon's worker.
#
# Output (key:value on stdout):
#   worktree_status:reused|created-existing-branch|created-new-branch
#   worktree:<path>
#   session_id:<id>

set -eo pipefail

# Shared dispatch definitions (session-id resolution). Not a hook — a missing
# lib is a hard error (set -e), never fail-open.
# shellcheck disable=SC1091
. "$HOME/.claude/scripts/lib/dispatch.sh"

NAME="$1"
BRANCH="$2"
ROOT="$3"
PROMPT_FILE="$4"
TARGET_REPO="$ROOT"
MODEL="${DISPATCH_MODEL:-default}"

if [[ -z "$NAME" || -z "$BRANCH" || -z "$ROOT" || -z "$PROMPT_FILE" ]]; then
    echo "Usage: spawn.sh <name> <branch> <project-root> <prompt-file>" >&2
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

mkdir -p "$TARGET_REPO/.dispatch/status"

# Reset the Stop-hook attempt counter from any prior run of this name —
# a stale count >8 would let a re-dispatched runner exit immediately.
rm -f "$TARGET_REPO/.dispatch/state/$NAME.attempts"

# --- Worktree ---
if [[ -d "$WORKTREE/.git" || -f "$WORKTREE/.git" ]]; then
    # Never reuse a worktree that sits on a different branch — the runner would
    # silently commit its work to the wrong branch.
    WT_BRANCH=$(git -C "$WORKTREE" rev-parse --abbrev-ref HEAD 2>/dev/null || echo "")
    if [[ -n "$WT_BRANCH" && "$WT_BRANCH" != "$BRANCH" ]]; then
        echo "error: worktree $WORKTREE is on branch '$WT_BRANCH', expected '$BRANCH' — remove it or dispatch under a different name" >&2
        exit 1
    fi
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
        # Base new branches on the remote default branch, never on whatever the
        # main checkout happens to have checked out — an operator sitting on a
        # feature branch would otherwise silently become the runner's base.
        BASE_REF=$(git -C "$TARGET_REPO" symbolic-ref --quiet --short refs/remotes/origin/HEAD 2>/dev/null || echo "")
        if [[ -z "$BASE_REF" ]]; then
            for CAND in origin/main origin/master; do
                if git -C "$TARGET_REPO" rev-parse --verify --quiet "$CAND" >/dev/null 2>&1; then
                    BASE_REF="$CAND"
                    break
                fi
            done
        fi
        if ! git -C "$TARGET_REPO" worktree add "$WORKTREE" -b "$BRANCH" ${BASE_REF:+"$BASE_REF"} 2>"$WT_ERR"; then
            cat "$WT_ERR" >&2
            exit 1
        fi
        echo "worktree_status:created-new-branch"
        [[ -n "$BASE_REF" ]] && echo "base_ref:$BASE_REF"
    fi
fi

echo "worktree:$WORKTREE"

# --- Spawn ---
# Prepend a hard worktree-isolation guard so the runner never edits or commits in
# the shared main checkout. The runner is given absolute paths into the main repo
# (from discovery); without this it can edit/commit there instead of its worktree.
STATUS_FILE="$TARGET_REPO/.dispatch/status/$NAME.md"
RUNTIME_PROMPT="$TARGET_REPO/.dispatch/prompts/$NAME.runtime.md"

# Resume path (watchdog / manual re-dispatch) doesn't set DISPATCH_MODEL — fall
# back to the model the status file recorded at first dispatch, so an
# `--model opus` runner doesn't silently resume on the default model.
if [[ "$MODEL" == "default" ]]; then
    RECORDED_MODEL=$(dispatch_status_field model "$STATUS_FILE" || true)
    if [[ -n "$RECORDED_MODEL" && "$RECORDED_MODEL" != "default" ]]; then
        MODEL="$RECORDED_MODEL"
    fi
fi
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
# `--brief` enables the SendUserMessage tool: the ONLY way a --bg runner can hand
# an operator-decision back and PARK alive. Without it a runner that hits a gate it
# can't resolve (a ruling, a visual ratification) has no way to ask — it writes a
# terminal status and exits, leaving a `done` session the operator can't tab into.
# With it, the runner asks and parks in `blocked` (attachable via `claude agents`).
PROJECT_NAME="$(basename "$TARGET_REPO")"
RUNNER_NAME="dispatch-$PROJECT_NAME-$NAME"
SESSION_OUTPUT=$(cd "$WORKTREE" && \
    CLAUDE_DISPATCH_WORKTREE="$WORKTREE" \
    CLAUDE_DISPATCH_ROOT="$TARGET_REPO" \
    CLAUDE_DISPATCH_STATUS_FILE="$STATUS_FILE" \
    claude --bg \
    --agent runner \
    --model "$MODEL" \
    --name "$RUNNER_NAME" \
    --permission-mode bypassPermissions \
    --brief \
    --append-system-prompt-file "$RUNTIME_PROMPT" \
    "Execute the task described in the system prompt." 2>&1)

# Resolve the session id by the --name we set — robust to --bg stdout wording,
# which is the one fragile coupling to CLI output. dispatch_session_id_by_name
# (scripts/lib/dispatch.sh) retries for agent-list latency; then fall back to
# scraping stdout ("backgrounded · <8-hex>").
SESSION_ID=$(dispatch_session_id_by_name "$RUNNER_NAME" 5) || SESSION_ID=""
if [[ -z "$SESSION_ID" ]]; then
    SESSION_ID=$(echo "$SESSION_OUTPUT" | grep 'backgrounded' | grep -oE '[a-f0-9]{8}' | head -1)
fi

if [[ -z "$SESSION_ID" ]]; then
    echo "error: failed to spawn background session" >&2
    echo "$SESSION_OUTPUT" >&2
    exit 1
fi

echo "session_id:$SESSION_ID"
