#!/usr/bin/env bash
# enforce-completion.sh — the full Stop gauntlet, gate by gate.
#
# This hook owns the runner review loop: it must HOLD a session whose work
# isn't finished (non-terminal status, missing/malformed PR) and RELEASE one
# that is (terminal status, operator park, safety caps). Each case below pins
# one gate, with `gh` stubbed so the suite is deterministic and offline.
# Identity-channel cases (env poisoning) live in enforce-completion-pin.test.sh.

set -uo pipefail
# shellcheck source=/dev/null
. "$(dirname "${BASH_SOURCE[0]}")/lib.sh"

# shellcheck disable=SC2153  # HOOKS/SCRIPTS are exported by lib.sh
H="$HOOKS/enforce-completion.sh"
echo "enforce-completion.sh (gates)"

FIX="$TEST_TMP/completion-gates"
FAKEHOME="$FIX/home"
STUB="$FIX/stub"
mkdir -p "$FAKEHOME/.claude/scripts/lib" "$FAKEHOME/.claude/jobs/abcd1234" \
  "$STUB" "$FIX/bin"
cp "$SCRIPTS/lib/dispatch.sh" "$SCRIPTS/lib/hooklog.sh" "$FAKEHOME/.claude/scripts/lib/"
for s in validate-title.sh validate-pr-body.sh classify-diff.sh is-test-path.sh; do
  cp "$SCRIPTS/$s" "$FAKEHOME/.claude/scripts/"
done
cp "$H" "$FAKEHOME/.claude/enforce-completion.sh"
HOOK="$FAKEHOME/.claude/enforce-completion.sh"

# gh stub: answers exactly the three calls the hook makes, from fixture files.
# No pr-number file → "no PR exists" (Gate 1).
cat > "$FIX/bin/gh" <<EOF
#!/bin/sh
case "\$*" in
  "pr view --json number -q .number") cat "$STUB/pr-number" 2>/dev/null || exit 1 ;;
  "pr view 42 --json title,body")     cat "$STUB/pr-content" 2>/dev/null || exit 1 ;;
  "pr diff 42")                       cat "$STUB/pr-diff" 2>/dev/null ;;
  *) exit 1 ;;
esac
EOF
chmod +x "$FIX/bin/gh"

# The dispatch fixture: repo, worktree, job state — as spawn.sh lays them out.
REPO="$FIX/repo"
git init -q "$REPO"
git -C "$REPO" -c user.email=t@t -c user.name=t commit -q --allow-empty -m init
git -C "$REPO" worktree add -q "$REPO/.claude/worktrees/test-run" -b test-branch
WT="$REPO/.claude/worktrees/test-run"
mkdir -p "$REPO/.dispatch/status" "$REPO/.dispatch/state"
SID="abcd1234-1111-2222-3333-444444444444"
jq -n --arg wt "$WT" '{template:"runner", cwd:$wt}' \
  > "$FAKEHOME/.claude/jobs/abcd1234/state.json"

STATUS_MD="$REPO/.dispatch/status/test-run.md"
ATTEMPTS="$REPO/.dispatch/state/test-run.attempts"

own_status() {  # <status> [started-iso]
  cat > "$STATUS_MD" <<EOF
# Task: test

- **ticket**: TEST-1
- **status**: $1
- **started**: ${2:-$(date -u +%Y-%m-%dT%H:%M:%SZ)}
- **branch**: test-branch
EOF
}

# assert_status_md <want-status> <name> — the caps must FINALIZE, not just release.
assert_status_md() {
  local want="$1" name="$2" got
  got=$(sed -n 's/^- \*\*status\*\*: //p' "$STATUS_MD")
  if [[ "$got" == "$want" ]]; then
    PASS=$((PASS + 1)); printf '  ok    %s\n' "$name"
  else
    FAIL=$((FAIL + 1)); FAILED_NAMES+=("$name")
    printf '  FAIL  %s (status %q, want %q)\n' "$name" "$got" "$want"
  fi
}

# run_gate <want> <name> [stderr-substring]
run_gate() {
  local want="$1" name="$2" grepfor="${3:-}" got out
  out=$(printf '{"session_id":"%s"}' "$SID" \
    | env HOME="$FAKEHOME" PATH="$FIX/bin:$PATH" bash "$HOOK" 2>&1); got=$?
  if [[ "$got" == "$want" ]] && { [[ -z "$grepfor" ]] || grep -q "$grepfor" <<<"$out"; }; then
    PASS=$((PASS + 1)); printf '  ok    %s\n' "$name"
  else
    FAIL=$((FAIL + 1)); FAILED_NAMES+=("$name")
    printf '  FAIL  %s (exit %s, want %s%s)\n' "$name" "$got" "$want" \
      "${grepfor:+, expecting \"$grepfor\" in output}"
    printf '%s\n' "$out" | sed -n '1,3p' | sed 's/^/        /'
  fi
}

# ── Release: terminal statuses and the operator park ─────────────────────────
for s in completed needs_review closed-without-merge failed; do
  own_status "$s"
  run_gate 0 "terminal status releases: $s"
done
NUDGE="$REPO/.dispatch/state/test-run.operator-nudged"
own_status blocked; rm -f "$NUDGE"
run_gate 2 "blocked without an operator push is nudged" "Operator notified"
run_gate 0 "blocked parks after the single nudge (no loop)" "parking session alive"
own_status blocked; rm -f "$NUDGE"
printf '\n## Notes\nAwaiting operator: which colour?\nOperator notified: sent 06f78118\n' >> "$STATUS_MD"
run_gate 0 "blocked with an operator push parks immediately" "parking session alive"
own_status blocked; rm -f "$NUDGE"
printf '\n## Notes\nOperator notified: skipped (no operator session)\n' >> "$STATUS_MD"
run_gate 0 "blocked with a skipped push parks immediately" "parking session alive"
rm -f "$NUDGE"

# ── Release: safety caps, which must also finalize the status ────────────────
own_status in_progress "$(date -u -v-9H +%Y-%m-%dT%H:%M:%SZ)"
run_gate 0 "8hr wall-clock cap releases" "8hr cap"
assert_status_md needs_review "8hr cap finalizes status to needs_review"

own_status in_progress
echo 1001 > "$ATTEMPTS"
run_gate 0 "spin guard releases after >1000 attempts" "runaway-spin"
assert_status_md needs_review "spin guard finalizes status to needs_review"
rm -f "$ATTEMPTS"

# ── Gate 0: only the canonical bullet format is a status ─────────────────────
printf 'status: completed\n' > "$STATUS_MD"
run_gate 2 "YAML frontmatter cannot exit — corrective message" "YAML frontmatter is NOT parsed"
rm -f "$ATTEMPTS"

# ── Gate 1: no PR → the ship sequence ────────────────────────────────────────
own_status in_progress
run_gate 2 "non-terminal without a PR demands /pr" "no PR exists yet"
expect_cmd 0 "stop attempt is counted" grep -qx 1 "$ATTEMPTS"

# ── Gate 1.5: the PR must conform to /pr conventions ─────────────────────────
echo 42 > "$STUB/pr-number"
: > "$STUB/pr-diff"
jq -n '{title:"Fix stuff", body:"whatever"}' > "$STUB/pr-content"
run_gate 2 "malformed PR content blocks" "does not conform"

# ── Gate 2: conforming PR, non-terminal status → the review loop ─────────────
BODY=$(printf '**What:** adds retry\n\n**Why:** flaky\n\n**Testing:** ran the suite\n\nCloses TEST-1')
jq -n --arg b "$BODY" '{title:"Loader Retry Backoff", body:$b}' > "$STUB/pr-content"
run_gate 2 "conforming PR still holds until terminal" "unified review loop"
run_gate 2 "loop message names the codex gate" "codex_state"

own_status completed
run_gate 0 "terminal status releases even with the PR gates armed"

summarize
