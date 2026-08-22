#!/usr/bin/env bash
# enforce-worktree.sh — runners must never write the shared main checkout.
#
# Identity comes from the bg job state (tier 1) or the cwd (tier 2) — never
# the CLAUDE_DISPATCH_* env, which daemon leaks turn stale (see the hook
# header). Cases cover both identity tiers, both write vectors (file tools and
# Bash command strings), and the leak: a poisoned env must neither trap an
# unrelated session nor redirect a real runner's enforcement.

set -uo pipefail
# shellcheck source=/dev/null
. "$(dirname "${BASH_SOURCE[0]}")/lib.sh"

# shellcheck disable=SC2153  # HOOKS/SCRIPTS are exported by lib.sh
H="$HOOKS/enforce-worktree.sh"
echo "enforce-worktree.sh"

FIX="$TEST_TMP/worktree"
FAKEHOME="$FIX/home"
mkdir -p "$FAKEHOME/.claude/scripts/lib" "$FAKEHOME/.claude/jobs/beef0001"
cp "$SCRIPTS/lib/dispatch.sh" "$SCRIPTS/lib/hooklog.sh" "$FAKEHOME/.claude/scripts/lib/"

REPO="$FIX/repo"
git init -q "$REPO"
git -C "$REPO" -c user.email=t@t -c user.name=t commit -q --allow-empty -m init
git -C "$REPO" worktree add -q "$REPO/.claude/worktrees/test-run" -b test-branch
WT="$REPO/.claude/worktrees/test-run"
mkdir -p "$REPO/.dispatch/status"
printf -- '- **status**: in_progress\n' > "$REPO/.dispatch/status/test-run.md"

SID="beef0001-1111-2222-3333-444444444444"
jq -n --arg wt "$WT" '{template:"runner", cwd:$wt}' \
  > "$FAKEHOME/.claude/jobs/beef0001/state.json"

# Decoy dispatch for env-poisoning cases.
DECOY="$FIX/decoy"
mkdir -p "$DECOY/.claude/worktrees/decoy" "$DECOY/.dispatch/status"
printf -- '- **status**: in_progress\n' > "$DECOY/.dispatch/status/decoy.md"

# file_json <tool> <path> <cwd> [session_id]
file_json() {
  jq -n --arg t "$1" --arg f "$2" --arg c "$3" --arg s "${4:-$SID}" \
    '{tool_name:$t, session_id:$s, cwd:$c,
      tool_input: (if $t == "NotebookEdit" then {notebook_path:$f} else {file_path:$f} end)}'
}
# bash_json <command> <cwd> [session_id]
bash_json() {
  jq -n --arg cmd "$1" --arg c "$2" --arg s "${3:-$SID}" \
    '{tool_name:"Bash", session_id:$s, cwd:$c, tool_input:{command:$cmd}}'
}

# run_wt <want> <name> <json> [env K=V ...]
run_wt() {
  local want="$1" name="$2" json="$3"; shift 3
  local got out
  out=$(printf '%s' "$json" \
    | env HOME="$FAKEHOME" "$@" bash "$H" 2>&1); got=$?
  if [[ "$got" == "$want" ]]; then
    PASS=$((PASS + 1)); printf '  ok    %s\n' "$name"
  else
    FAIL=$((FAIL + 1)); FAILED_NAMES+=("$name")
    printf '  FAIL  %s (exit %s, want %s)\n' "$name" "$got" "$want"
    printf '%s\n' "$out" | sed -n '1,2p' | sed 's/^/        /'
  fi
}

# ── Tier 1: job-state identity ───────────────────────────────────────────────
run_wt 0 "worktree writes are allowed" \
  "$(file_json Edit "$WT/src/x.ts" "$WT")"
run_wt 0 "status file writes are allowed" \
  "$(file_json Edit "$REPO/.dispatch/status/test-run.md" "$WT")"
run_wt 2 "main-checkout Edit is blocked" \
  "$(file_json Edit "$REPO/src/x.ts" "$WT")"
run_wt 2 "main-checkout Write is blocked" \
  "$(file_json Write "$REPO/README.md" "$WT")"
run_wt 2 "main-checkout NotebookEdit is blocked" \
  "$(file_json NotebookEdit "$REPO/nb.ipynb" "$WT")"
run_wt 2 "Bash naming the main checkout is blocked" \
  "$(bash_json "echo hacked > $REPO/src/x.ts" "$WT")"
run_wt 0 "Bash inside the worktree is allowed" \
  "$(bash_json "sed -i '' s/a/b/ $WT/src/x.ts" "$WT")"
run_wt 0 "Bash outside the checkout entirely is allowed" \
  "$(bash_json "echo scratch > /tmp/scratch.txt" "$WT")"

# ── Tier 2: cwd fallback (no job state for this session) ─────────────────────
NOJOB="ffff9999-1111-2222-3333-444444444444"
run_wt 2 "cwd tier still blocks main-checkout writes" \
  "$(file_json Edit "$REPO/src/x.ts" "$WT" "$NOJOB")"
run_wt 0 "cwd tier allows worktree writes" \
  "$(file_json Edit "$WT/src/x.ts" "$WT" "$NOJOB")"

# A session in a plain repo (no dispatch status file) is not a runner.
PLAIN="$FIX/plain"
git init -q "$PLAIN"
run_wt 0 "non-dispatch session writes freely" \
  "$(file_json Edit "$PLAIN/anything.ts" "$PLAIN" "$NOJOB")"

# ── The leak: CLAUDE_DISPATCH_* env must be inert ────────────────────────────
run_wt 0 "stale env cannot trap an unrelated session" \
  "$(file_json Edit "$DECOY/file.ts" "$PLAIN" "$NOJOB")" \
  CLAUDE_DISPATCH_WORKTREE="$DECOY/.claude/worktrees/decoy" \
  CLAUDE_DISPATCH_ROOT="$DECOY" \
  CLAUDE_DISPATCH_STATUS_FILE="$DECOY/.dispatch/status/decoy.md"
run_wt 2 "stale env cannot redirect a real runner's enforcement" \
  "$(file_json Edit "$REPO/src/x.ts" "$WT")" \
  CLAUDE_DISPATCH_WORKTREE="$DECOY/.claude/worktrees/decoy" \
  CLAUDE_DISPATCH_ROOT="$DECOY" \
  CLAUDE_DISPATCH_STATUS_FILE="$DECOY/.dispatch/status/decoy.md"

summarize
