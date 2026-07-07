#!/usr/bin/env bash
# PostToolUse Hook (runner, Bash): auto-spawn the PR reviewer after `gh pr create`.
#
# Structural replacement for the remembered protocol step in runner.md —
# spawn-reviewer.sh is already idempotent (deterministic name + lock +
# reviewed-at-HEAD check + DISPATCH_NO_REVIEWER kill switch), so firing on every
# PR create is safe by construction, and off-book manual spawns become
# unnecessary rather than merely forbidden.
#
# Exit 0 always — a missed auto-spawn just means the runner's own fallback call
# (or the operator) spawns the reviewer; never block the tool result over it.

set -uo pipefail

INPUT=$(cat)
COMMAND=$(echo "$INPUT" | jq -r '.tool_input.command // ""' 2>/dev/null) || exit 0

case "$COMMAND" in
  *gh\ pr\ create*) ;;
  *) exit 0 ;;
esac

CWD=$(echo "$INPUT" | jq -r '.cwd // ""' 2>/dev/null)
if [[ -n "$CWD" && -d "$CWD" ]]; then
  cd "$CWD" 2>/dev/null || exit 0
fi

PR=$(gh pr view --json number -q '.number' 2>/dev/null) || exit 0
[[ -n "$PR" ]] || exit 0

# Per-run opt-out for the `/engineering:pr` path. That skill runs CodeRabbit
# (via `/ar:pr-review`) + Augment PR standards at creation time, so a watcher
# here would just double-review. The runner drops this marker before invoking
# `/engineering:pr` (runner.md step 2). It lives INSIDE the worktree's git dir —
# per-worktree, invisible to `git status`, and resolvable by both sides via
# `git rev-parse --git-dir` from the worktree cwd — because client env does NOT
# survive the `--bg` daemon hop (see scripts/lib/dispatch.sh), so an env var
# couldn't carry the signal here. Consume it (rm) so it can't suppress a later
# genuine spawn if the worktree is reused. The fallback `/pr` path never drops
# it, so that path auto-spawns exactly as before.
GITDIR=$(git rev-parse --git-dir 2>/dev/null) || GITDIR=""
if [[ -n "$GITDIR" && -f "$GITDIR/dispatch-no-auto-reviewer" ]]; then
  rm -f "$GITDIR/dispatch-no-auto-reviewer" 2>/dev/null || true
  echo "reviewer auto-spawn skipped for PR #$PR: /engineering:pr path already ran CodeRabbit at creation." >&2
  exit 0
fi

if OUT=$(bash "$HOME/.claude/skills/dispatch/spawn-reviewer.sh" "$PR" 2>&1); then
  echo "auto-spawned reviewer for PR #$PR:" >&2
else
  echo "reviewer auto-spawn skipped/failed for PR #$PR:" >&2
fi
sed 's/^/  /' <<<"$OUT" >&2
exit 0
