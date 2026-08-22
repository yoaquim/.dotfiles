#!/usr/bin/env bash
# spawn.sh flag parsing — flags are the only override channel.
#
# The DISPATCH_MODEL/DISPATCH_EFFORT env vars used to be the override lever,
# which meant any stale export — a long-lived orchestrator session, a
# settings.local.json `env` block — silently pinned runners to a model nobody
# chose, and no restart flushed it. These tests run the REAL spawn.sh against a
# stubbed `claude` binary (poisoned env always set) and assert the poison stays
# inert, flags win, and an explicit override is logged to stderr.

set -uo pipefail
# shellcheck source=/dev/null
. "$(dirname "${BASH_SOURCE[0]}")/lib.sh"
# shellcheck source=/dev/null
. "$HOME/.claude/scripts/lib/dispatch.sh"

echo "spawn.sh flags"

SPAWN="$HOME/.claude/skills/dispatch/spawn.sh"
FIX="$TEST_TMP/spawn"
mkdir -p "$FIX/bin"

# Stub claude: records the runner invocation's args, and answers `agents --json`
# with the name the test expects so session-id resolution returns on the first
# try instead of burning its retry budget.
cat > "$FIX/bin/claude" <<'STUB'
#!/usr/bin/env bash
if [[ "${1:-}" == "agents" ]]; then
  printf '[{"name":"%s","state":"running","id":"deadbeef"}]\n' "${STUB_AGENT_NAME:-}"
  exit 0
fi
printf '%s\n' "$*" > "$STUB_ARGS_FILE"
echo "backgrounded · deadbeef"
STUB
chmod +x "$FIX/bin/claude"

REPO="$FIX/repo"
git init -q -b main "$REPO"
git -C "$REPO" -c user.name=t -c user.email=t@t commit -q --allow-empty -m init

# The /dispatch skill writes the prompt under .dispatch/prompts/ before calling
# spawn.sh, which is also where spawn.sh writes its runtime prompt — the dir
# must exist, as it does in every real dispatch.
mkdir -p "$REPO/.dispatch/prompts"
PROMPT="$REPO/.dispatch/prompts/task.md"
echo "do the thing" > "$PROMPT"

ARGS="$FIX/args.txt"
ERR="$FIX/err.txt"

run_spawn() { # <name> [spawn flags...] — the poisoned env is ALWAYS set
  local name="$1"; shift
  PATH="$FIX/bin:$PATH" \
  STUB_AGENT_NAME="dispatch-repo-$name" STUB_ARGS_FILE="$ARGS" \
  DISPATCH_MODEL=poison-model DISPATCH_EFFORT=poison-effort \
  DISPATCH_TICKET=POISON-1 DISPATCH_TITLE="Poison Title" \
  bash "$SPAWN" "$name" "dispatch/$name" "$REPO" "$PROMPT" "$@" >/dev/null 2>"$ERR"
}

# --- env poison is inert ---
expect_cmd 0 "spawn succeeds with poisoned env" run_spawn nb-env
expect_cmd 0 "a model is still resolved for the runner" grep -q -- "--model" "$ARGS"
expect_cmd 1 "poisoned DISPATCH_MODEL never reaches the runner" grep -q poison-model "$ARGS"
expect_cmd 1 "poisoned DISPATCH_EFFORT never reaches the runner" grep -q poison-effort "$ARGS"
expect_cmd 1 "poisoned DISPATCH_TICKET never reaches the status file" \
  grep -q POISON-1 "$REPO/.dispatch/status/nb-env.md"
expect_cmd 1 "no override is logged when no flag was given" grep -q override "$ERR"

# --- flags win, even with the env still poisoned ---
expect_cmd 0 "spawn accepts --model/--effort/--ticket/--title" \
  run_spawn nb-flags --model claude-fable-5 --effort high --ticket NUL-9 --title "Real Title"
S="$REPO/.dispatch/status/nb-flags.md"
expect_cmd 0 "--model reaches the runner invocation" grep -q -- "--model claude-fable-5" "$ARGS"
expect_cmd 0 "--effort reaches the runner invocation" grep -q -- "--effort high" "$ARGS"
expect_cmd 0 "status file records the flag model" \
  bash -c "[ \"\$(. \$HOME/.claude/scripts/lib/dispatch.sh; dispatch_status_field model '$S')\" = 'claude-fable-5' ]"
expect_cmd 0 "status file records the flag effort" \
  bash -c "[ \"\$(. \$HOME/.claude/scripts/lib/dispatch.sh; dispatch_status_field effort '$S')\" = 'high' ]"
expect_cmd 0 "--ticket lands in the status file" grep -q '^- \*\*ticket\*\*: NUL-9$' "$S"
expect_cmd 0 "--title lands in the status file" grep -q '^- \*\*title\*\*: Real Title$' "$S"
expect_cmd 0 "model override is logged to stderr" grep -q 'model override: claude-fable-5' "$ERR"
expect_cmd 0 "effort override is logged to stderr" grep -q 'effort override: high' "$ERR"

# --- a resume (resolved session_id) inherits the recorded pair without flags ---
dispatch_upsert_status_field session_id deadbeef "$S"
expect_cmd 0 "re-spawn without flags (resume path)" run_spawn nb-flags
expect_cmd 0 "resume reuses the recorded model" grep -q -- "--model claude-fable-5" "$ARGS"
expect_cmd 0 "resume reuses the recorded effort" grep -q -- "--effort high" "$ARGS"
expect_cmd 1 "an inherited pair is not logged as an override" grep -q override "$ERR"

# --- operator session reaches the runtime prompt via the FILE, never env ---
RUNTIME="$REPO/.dispatch/prompts/op-none.runtime.md"
CLAUDE_CODE_SESSION_ID= run_spawn op-none
expect_cmd 0 "no operator session → prompt says none" \
  grep -q '^Operator session: none' "$RUNTIME"
expect_cmd 1 "runner is not spawned with an operator env var" \
  grep -q 'OPERATOR' "$ARGS"

# --- bad invocations fail fast ---
expect_cmd 1 "unknown flag is rejected" run_spawn nb-bad --frobnicate yes
expect_cmd 1 "--model without a value is rejected" run_spawn nb-bad --model

summarize
