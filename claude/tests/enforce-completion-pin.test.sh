#!/usr/bin/env bash
# enforce-completion.sh — runner identity must come from job state, never env.
#
# The regression this suite exists for: a `claude --bg` call that BIRTHS the
# daemon bakes its CLAUDE_DISPATCH_* env into the daemon, and every later bg
# session inherits it. The hook trusted the env tier first, so every runner's
# Stop evaluated the daemon-founding runner's status file; once that founder
# completed, every Stop was waved through in ~40ms and runners quit mid-review
# loop (observed 2026-08-21: rim-64 released nul-537/539/540). Fixtures below
# poison the env with a decoy dispatch and assert the hook resolves the
# session's OWN identity — or, for a non-dispatch session, no identity at all.

set -uo pipefail
# shellcheck source=/dev/null
. "$(dirname "${BASH_SOURCE[0]}")/lib.sh"

# shellcheck disable=SC2153  # HOOKS is exported by lib.sh
H="$HOOKS/enforce-completion.sh"
echo "enforce-completion.sh (identity pin)"

FIX="$TEST_TMP/completion-pin"
mkdir -p "$FIX"

# Fake HOME so the jobs dir is ours; the hook sources its libs from there too.
FAKEHOME="$FIX/home"
mkdir -p "$FAKEHOME/.claude/scripts/lib" "$FAKEHOME/.claude/jobs"
cp "$SCRIPTS/lib/dispatch.sh" "$SCRIPTS/lib/hooklog.sh" "$FAKEHOME/.claude/scripts/lib/"
cp "$H" "$FAKEHOME/.claude/enforce-completion.sh"
HOOK="$FAKEHOME/.claude/enforce-completion.sh"

# `gh` stub: no PR exists for anything. Keeps Gate 1 deterministic and offline.
STUBBIN="$FIX/bin"
mkdir -p "$STUBBIN"
printf '#!/bin/sh\nexit 1\n' > "$STUBBIN/gh"
chmod +x "$STUBBIN/gh"

# The session's real dispatch: repo + worktree + status file, as spawn.sh lays
# them out. NAME derives from the worktree basename.
REPO="$FIX/repo"
git init -q "$REPO"
git -C "$REPO" -c user.email=t@t -c user.name=t commit -q --allow-empty -m init
git -C "$REPO" worktree add -q "$REPO/.claude/worktrees/test-run" -b test-branch
WT="$REPO/.claude/worktrees/test-run"
mkdir -p "$REPO/.dispatch/status"

own_status() {  # <status value>
  cat > "$REPO/.dispatch/status/test-run.md" <<EOF
# Task: test

- **ticket**: TEST-1
- **status**: $1
- **started**: $(date -u +%Y-%m-%dT%H:%M:%SZ)
- **branch**: test-branch
EOF
}

# Job state for the session id the hook will receive on stdin. Short-id dir,
# as `claude --bg` names it.
SID="abcd1234-1111-2222-3333-444444444444"
mkdir -p "$FAKEHOME/.claude/jobs/abcd1234"
jq -n --arg wt "$WT" '{template:"runner", cwd:$wt}' \
  > "$FAKEHOME/.claude/jobs/abcd1234/state.json"

# Decoy dispatches the poisoned env points at — one terminal, one live.
for D in decoy-done decoy-live; do
  mkdir -p "$FIX/$D/.claude/worktrees/$D" "$FIX/$D/.dispatch/status"
done
printf -- '- **status**: completed\n'   > "$FIX/decoy-done/.dispatch/status/decoy-done.md"
printf -- '- **status**: in_progress\n' > "$FIX/decoy-live/.dispatch/status/decoy-live.md"

# run_pin <want> <name> <cwd> <decoy|-> — feed the runner's session id on
# stdin, optionally poison the env with a decoy's identity, and run the hook
# from <cwd>. Neutral cwd proves the job-state pin does the work.
run_pin() {
  local want="$1" name="$2" dir="$3" decoy="$4" got out
  local -a poison=()
  if [[ "$decoy" != "-" ]]; then
    poison=(
      "CLAUDE_DISPATCH_WORKTREE=$FIX/$decoy/.claude/worktrees/$decoy"
      "CLAUDE_DISPATCH_ROOT=$FIX/$decoy"
      "CLAUDE_DISPATCH_STATUS_FILE=$FIX/$decoy/.dispatch/status/$decoy.md"
    )
  fi
  out=$(cd "$dir" && printf '{"session_id":"%s"}' "$SID" \
    | env HOME="$FAKEHOME" PATH="$STUBBIN:$PATH" "${poison[@]+"${poison[@]}"}" \
      bash "$HOOK" 2>&1); got=$?
  if [[ "$got" == "$want" ]]; then
    PASS=$((PASS + 1))
    printf '  ok    %s\n' "$name"
  else
    FAIL=$((FAIL + 1))
    FAILED_NAMES+=("$name")
    printf '  FAIL  %s (exit %s, want %s)\n' "$name" "$got" "$want"
    printf '%s\n' "$out" | sed -n '1,3p' | sed 's/^/        /'
  fi
}

# Baseline: own status non-terminal, no PR → the ship-sequence block.
own_status in_progress
run_pin 2 "own in_progress blocks (no env)" "$TEST_TMP" "-"

# THE regression: a terminal decoy in the env must not release a live runner.
own_status in_progress
run_pin 2 "stale terminal env cannot release a live runner" "$TEST_TMP" "decoy-done"

# Inverse: a live decoy in the env must not trap a finished runner.
own_status completed
run_pin 0 "stale live env cannot trap a finished runner" "$TEST_TMP" "decoy-live"

# A session with no job state and a non-dispatch cwd is not a dispatch session,
# no matter what the leaked env claims.
rm "$FAKEHOME/.claude/jobs/abcd1234/state.json"
PLAIN="$FIX/plain-repo"
git init -q "$PLAIN"
run_pin 0 "stale env cannot drag a non-dispatch session into the gates" "$PLAIN" "decoy-live"

summarize
