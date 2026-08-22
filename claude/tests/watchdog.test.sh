#!/usr/bin/env bash
# watchdog.sh — resume exactly the halted runners, and find all of them.
#
# Integration-level: real fixture trees, stubbed `claude` (liveness) and `gh`
# (no PRs), --dry-run so nothing spawns. The discovery regression this suite
# exists for: repos nested one level deeper than <base>/<repo> (client dirs
# like ~/Projects/rimas/<repo>) were invisible to the `find -maxdepth 3`
# discovery — their runners were never resumed and the watchdog log never
# mentioned them (observed 2026-08-21: zero rim-* entries, ever).

set -uo pipefail
# shellcheck source=/dev/null
. "$(dirname "${BASH_SOURCE[0]}")/lib.sh"

WD="$HOME/.claude/skills/dispatch/watchdog.sh"
echo "watchdog.sh"

FIX="$TEST_TMP/watchdog"
FAKEHOME="$FIX/home"
BASE="$FIX/projects"
mkdir -p "$FAKEHOME/.claude/scripts/lib" "$FIX/bin" "$BASE"
# shellcheck disable=SC2153  # SCRIPTS is exported by lib.sh
cp "$SCRIPTS/lib/dispatch.sh" "$SCRIPTS/lib/hooklog.sh" "$FAKEHOME/.claude/scripts/lib/"
cp "$SCRIPTS/validate-status-file.sh" "$FAKEHOME/.claude/scripts/"

# Liveness stub: sessions listed in $FIX/alive.json are alive.
printf '[]' > "$FIX/alive.json"
cat > "$FIX/bin/claude" <<EOF
#!/bin/sh
cat "$FIX/alive.json"
EOF
printf '#!/bin/sh\nexit 1\n' > "$FIX/bin/gh"
chmod +x "$FIX/bin/claude" "$FIX/bin/gh"

# stage_runner <root-rel-path> <name> <status> <updated-iso>
stage_runner() {
  local root="$BASE/$1" name="$2" status="$3" updated="$4"
  mkdir -p "$root/.dispatch/status" "$root/.dispatch/prompts"
  local sf="$root/.dispatch/status/$name.md"
  rm -f "$sf"
  env HOME="$FAKEHOME" bash -c ". '$FAKEHOME/.claude/scripts/lib/dispatch.sh'
    dispatch_init_status_file '$sf' '$name' 'TEST-1' 'Test Title' 'b-$name' '/wt/$name' '$updated'
    dispatch_upsert_status_field status '$status' '$sf'
    dispatch_upsert_status_field updated '$updated' '$sf'"
  echo "prompt" > "$root/.dispatch/prompts/$name.md"
}

# run_wd <name> <expect-substring> [absent-substring]
run_wd() {
  local name="$1" expect="$2" absent="${3:-}" out
  out=$(env HOME="$FAKEHOME" PATH="$FIX/bin:$PATH" \
    DISPATCH_WATCHDOG_ROOTS="$BASE" bash "$WD" --dry-run 2>&1)
  if grep -q "$expect" <<<"$out" && { [[ -z "$absent" ]] || ! grep -q "$absent" <<<"$out"; }; then
    PASS=$((PASS + 1)); printf '  ok    %s\n' "$name"
  else
    FAIL=$((FAIL + 1)); FAILED_NAMES+=("$name")
    printf '  FAIL  %s (expecting %q%s)\n' "$name" "$expect" \
      "${absent:+, without $absent}"
    printf '%s\n' "$out" | sed 's/^/        /'
  fi
}

iso_ago() { date -u -v-"$1" +%Y-%m-%dT%H:%M:%SZ; }

# ── Discovery: direct child AND one level deeper ─────────────────────────────
stage_runner repoA task-a in_progress "$(iso_ago 30M)"
run_wd "halted runner in a direct-child repo would resume" \
  "WOULD resume dispatch-repoA-task-a"
stage_runner client/repoB task-b in_progress "$(iso_ago 30M)"
run_wd "nested client/<repo> is discovered too (maxdepth regression)" \
  "WOULD resume dispatch-repoB-task-b"

# ── Idle windows ─────────────────────────────────────────────────────────────
stage_runner repoA task-a in_progress "$(iso_ago 2M)"
run_wd "fresh halt is left alone (grace window)" \
  "grace window" "WOULD resume dispatch-repoA-task-a"
stage_runner repoA task-a in_progress "$(iso_ago 800M)"
run_wd "long-idle runner is abandoned, not resumed" \
  "abandoned" "WOULD resume dispatch-repoA-task-a"

# ── Status allowlist: only actively-working statuses resume ──────────────────
for s in completed blocked needs_review failed; do
  stage_runner repoA task-a "$s" "$(iso_ago 30M)"
  run_wd "status '$s' is never resumed" \
    "checked" "WOULD resume dispatch-repoA-task-a"
done
stage_runner repoA task-a in_progress "$(iso_ago 30M)"

# ── Liveness: a live session is not re-dispatched ────────────────────────────
jq -n '[{name:"dispatch-repoA-task-a", state:"working"}]' > "$FIX/alive.json"
run_wd "live runner is skipped" \
  "WOULD resume dispatch-repoB-task-b" "WOULD resume dispatch-repoA-task-a"
printf '[]' > "$FIX/alive.json"

# A live runner the agents registry has LOST (2026-08-21, CC 2.1.234) must not
# be double-spawned: its job-state heartbeat is the fallback liveness signal.
mkdir -p "$FAKEHOME/.claude/jobs/lost0001"
jq -n --arg u "$(date -u +%Y-%m-%dT%H:%M:%SZ)" \
  '{name:"dispatch-repoA-task-a", template:"runner", state:"working", updatedAt:$u}' \
  > "$FAKEHOME/.claude/jobs/lost0001/state.json"
run_wd "registry-lost live runner is not double-spawned" \
  "WOULD resume dispatch-repoB-task-b" "WOULD resume dispatch-repoA-task-a"
rm -rf "$FAKEHOME/.claude/jobs/lost0001"

# ── Guardrails on the resume path ────────────────────────────────────────────
rm "$BASE/repoA/.dispatch/prompts/task-a.md"
run_wd "missing prompt file skips with a reason" \
  "missing branch or prompt file" "WOULD resume dispatch-repoA-task-a"

summarize
