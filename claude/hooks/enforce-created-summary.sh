#!/usr/bin/env bash
# Stop hook: enforce the standardized closing block after a Linear create.
#
# When the agent finishes a turn in which it SUCCESSFULLY CREATED a Linear issue
# or spec document (a save_issue / save_document call with no `id` in its input —
# i.e. a create, not an update), the agent's final message must close with the
# standardized summary contract:
#
#     **What it does** — plain-English, 3–5 lines
#     **What was issued** / **What was specced** — the artifacts
#
# (Contract: ~/.claude/skills/issue/created-summary.md.)
#
# If that block is missing, exit 2 and feed the agent an instruction to append it.
# Otherwise — or in any turn with no successful create — allow the stop.
#
# Self-gating: runs in every session but does nothing unless a create happened
# this turn, so it's inert outside /issue and /spec.
#
# Exit 0  → allow stop.
# Exit 2  → block stop; stderr is fed back to the agent as a new instruction.
#
# Fail-open: any error or unexpected shape allows the stop. Never trap the agent
# because of a bug in the hook itself.

set -uo pipefail
trap 'exit 0' ERR

# Skip dispatch runner sessions. A runner has its own Stop hook
# (enforce-completion.sh) and its own completion summary — two blocking Stop
# hooks must not fight — and a runner that files an incidental follow-up ticket
# via /issue shouldn't be forced into the created-summary format. Env vars when
# present, else the bg job's template (env doesn't survive the --bg daemon hop).
[[ -n "${CLAUDE_DISPATCH_WORKTREE:-}${CLAUDE_DISPATCH_STATUS_FILE:-}" ]] && exit 0

INPUT=$(cat)

# shellcheck disable=SC1091
. "$HOME/.claude/scripts/lib/dispatch.sh" 2>/dev/null || true
if command -v dispatch_runner_worktree >/dev/null 2>&1; then
  SESSION_ID=$(jq -r '.session_id // ""' <<<"$INPUT" 2>/dev/null) || SESSION_ID=""
  dispatch_runner_worktree "$SESSION_ID" >/dev/null 2>&1 && exit 0
fi

TRANSCRIPT=$(jq -r '.transcript_path // ""' <<<"$INPUT" 2>/dev/null) || exit 0
[[ -n "$TRANSCRIPT" && -f "$TRANSCRIPT" ]] || exit 0

# Single slurp pass over the transcript. Real Claude Code transcripts write one
# content block per JSONL line, so a logical assistant message is split across
# several lines — we work at block granularity, not line granularity.
#
#   - drop sidechain (subagent) lines — /spec's Task subagents log inline here,
#     and only the MAIN agent's creates + closing prose are ours to police
#   - scope to the turn after the last real human message (a `user` event whose
#     content has no tool_result block)
#   - $ok   = successful creates this turn (save_issue/save_document, no
#             .input.id → a create not an update, not answered by an is_error)
#   - $text = the closing prose: text blocks AFTER the turn's last tool_use,
#             which is where the summary lands (after the create + the `open`)
# Bound the slurp: only the current turn matters, and it lives at the end of
# the transcript. 2000 JSONL lines is far more than any /issue//spec turn; on a
# very long session this keeps the most expensive always-on hook cheap.
RESULT=$(tail -n 2000 "$TRANSCRIPT" 2>/dev/null | jq -s '
  [ .[] | select(.isSidechain != true) ] as $main
  | ( [ range(0; ($main | length)) as $i
        | select(
            ($main[$i].type == "user")
            and ( [ ($main[$i].message.content // empty)
                    | if type == "array" then .[] else empty end
                    | select(.type == "tool_result") ] | length ) == 0
          ) | $i ] | last ) as $h
  | ( if $h == null then 0 else $h + 1 end ) as $start
  | $main[$start:] as $turn
  | [ $turn[] | select(.type == "assistant") | .message.content[]? ] as $ablocks
  | ( [ range(0; ($ablocks | length)) | select($ablocks[.].type == "tool_use") ] | last ) as $lastTU
  | ( [ $ablocks[] | select(.type == "tool_use")
        | select(.name | test("save_issue$|save_document$"))
        | select(.input.id == null) | .id ] ) as $created
  | ( [ $turn[] | select(.type == "user") | .message.content[]?
        | select(.type == "tool_result") | select(.is_error == true)
        | .tool_use_id ] ) as $errs
  | ( [ $created[] | select( ($errs | index(.)) | not ) ] | length ) as $ok
  | ( if $lastTU == null
      then [ $ablocks[] | select(.type == "text") | .text ]
      else [ $ablocks[ ($lastTU + 1): ][] | select(.type == "text") | .text ]
      end ) as $tail
  | { ok: $ok, start: $start, text: ( $tail | join("\n") ) }
' 2>/dev/null) || exit 0

OK=$(jq -r '.ok // 0' <<<"$RESULT" 2>/dev/null) || exit 0
TEXT=$(jq -r '.text // ""' <<<"$RESULT" 2>/dev/null) || exit 0
START=$(jq -r '.start // 0' <<<"$RESULT" 2>/dev/null) || exit 0

# Nothing created this turn → not our business.
[[ "$OK" =~ ^[0-9]+$ ]] || exit 0
(( OK > 0 )) || exit 0

# Closing block already present → allow stop.
if grep -qiE 'what it does' <<<"$TEXT" \
   && grep -qiE 'what was (issued|specced|created)' <<<"$TEXT"; then
  exit 0
fi

# One-shot per turn: block at most once per turn, then let the stop through. A
# transcript flush/rotation race can hide the just-written summary from the copy
# we read here; without this the agent re-appends a summary that is already there
# and the hook re-blocks forever. Stamp on transcript + turn boundary so a
# genuine miss still gets ONE reminder, but a stuck read can't loop. Cheaper and
# more turn-precise than the session cap below, which stays as the hard backstop.
STAMP="${TMPDIR:-/tmp}/created-summary.$(printf '%s' "${TRANSCRIPT}:${START}" | cksum | tr -d ' ')"
[[ -f "$STAMP" ]] && exit 0
touch "$STAMP" 2>/dev/null || true

# Bounded blocking: convergence otherwise relies entirely on the model
# complying — cap at 3 blocks per session, then let the stop through.
SID=$(jq -r '.session_id // ""' <<<"$INPUT" 2>/dev/null) || SID=""
if [[ -n "$SID" ]]; then
  CAP_FILE="${TMPDIR:-/tmp}/created-summary.$SID.attempts"
  N=$(( $(cat "$CAP_FILE" 2>/dev/null || echo 0) + 1 ))
  echo "$N" > "$CAP_FILE" 2>/dev/null || true
  (( N > 3 )) && exit 0
fi

# Created something but didn't close with the contract → block and instruct.
cat >&2 <<'EOF'
You created a Linear issue/spec this turn but didn't close with the standardized
summary. Append it now, then end again — this hook will re-evaluate.

Contract: ~/.claude/skills/issue/created-summary.md

**What it does** — plain English, 3–5 lines, what the work actually does for a
user. No jargon, no ticket IDs, no file paths.

**What was issued** (or **What was specced** for /spec) — the artifacts:
issue/ticket ID + URL; for a spec also the sub-issue count, total points, and
next step (/dispatch <id>).

Keep those two bold headers verbatim.
EOF
exit 2
