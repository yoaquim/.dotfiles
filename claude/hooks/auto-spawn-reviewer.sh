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

# No work-machine / engineering:pr special-casing here: spawn-reviewer.sh itself
# stands down on work machines (the augment-risk/engineering plugin gate), so this
# hook can fire unconditionally. The old per-run marker-file opt-out
# (dispatch-no-auto-reviewer) is gone — machine identity, not per-run state,
# decides who reviews.
if OUT=$(bash "$HOME/.claude/skills/dispatch/spawn-reviewer.sh" "$PR" 2>&1); then
  echo "auto-spawned reviewer for PR #$PR:" >&2
else
  echo "reviewer auto-spawn skipped/failed for PR #$PR:" >&2
fi
sed 's/^/  /' <<<"$OUT" >&2
exit 0
