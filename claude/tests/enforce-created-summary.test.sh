#!/usr/bin/env bash
# enforce-created-summary.sh — requires the closing summary after a Linear create.
#
# The regression this suite exists for: the hook read the transcript before the
# final assistant text block had been flushed, saw a turn ending in a tool_use
# with no prose, and blocked — re-prompting for a summary the user had already
# seen. Fixtures below reproduce both the unflushed state and a genuine miss,
# which are indistinguishable except for the presence of ANY closing text.

set -uo pipefail
# shellcheck source=/dev/null
. "$(dirname "${BASH_SOURCE[0]}")/lib.sh"

H="$HOOKS/enforce-created-summary.sh"
echo "enforce-created-summary.sh"

FIX="$TEST_TMP/fixtures"
mkdir -p "$FIX"

# Build a transcript: human turn → assistant save_issue → tool_result → [text].
# Claude Code writes one content block per JSONL line, which is what the hook's
# block-granularity parsing assumes.
make_transcript() {
  local out="$1" closing="${2:-}"
  {
    jq -c -n '{type:"user",isSidechain:false,message:{content:[{type:"text",text:"file an issue for this"}]}}'
    jq -c -n '{type:"assistant",isSidechain:false,message:{content:[{type:"tool_use",id:"tu_1",name:"mcp__linear__save_issue",input:{title:"X"}}]}}'
    jq -c -n '{type:"user",isSidechain:false,message:{content:[{type:"tool_result",tool_use_id:"tu_1",is_error:false}]}}'
    [[ -n "$closing" ]] && jq -c -n --arg t "$closing" '{type:"assistant",isSidechain:false,message:{content:[{type:"text",text:$t}]}}'
  } > "$out"
}

hook_input() { jq -n --arg p "$1" --arg s "$2" '{session_id:$s,transcript_path:$p}'; }

SUMMARY='**What it does**

Adds a retry with backoff so a 429 no longer fails the request.

**What was issued**

- RIM-9 — Retry on 429'

# Transcript still missing the final text block → unflushed, not a violation.
make_transcript "$FIX/unflushed.jsonl"
expect_exit 0 "unflushed transcript is not a missing summary" "$H" \
  "$(hook_input "$FIX/unflushed.jsonl" "s-unflushed")"

# Summary present → allow.
make_transcript "$FIX/good.jsonl" "$SUMMARY"
expect_exit 0 "conforming summary allows stop" "$H" \
  "$(hook_input "$FIX/good.jsonl" "s-good")"

# Closing prose present but not the contract → genuine miss, block.
make_transcript "$FIX/miss.jsonl" "All three items are done and pushed."
expect_exit 2 "closing prose without the headers blocks" "$H" \
  "$(hook_input "$FIX/miss.jsonl" "s-miss")"

# Second call on the same turn must not block again — the one-shot stamp.
expect_exit 0 "one-shot: same turn does not block twice" "$H" \
  "$(hook_input "$FIX/miss.jsonl" "s-miss")"

# Only half the contract is still a miss.
make_transcript "$FIX/half.jsonl" "**What it does**

Adds a retry with backoff."
expect_exit 2 "half the contract still blocks" "$H" \
  "$(hook_input "$FIX/half.jsonl" "s-half")"

# No create this turn → not this hook's business, whatever the prose says.
{
  jq -c -n '{type:"user",isSidechain:false,message:{content:[{type:"text",text:"whats the weather"}]}}'
  jq -c -n '{type:"assistant",isSidechain:false,message:{content:[{type:"text",text:"Sunny."}]}}'
} > "$FIX/nocreate.jsonl"
expect_exit 0 "no create this turn is ignored" "$H" \
  "$(hook_input "$FIX/nocreate.jsonl" "s-nocreate")"

# An update (save_issue WITH an id) is not a create.
{
  jq -c -n '{type:"user",isSidechain:false,message:{content:[{type:"text",text:"retitle it"}]}}'
  jq -c -n '{type:"assistant",isSidechain:false,message:{content:[{type:"tool_use",id:"tu_2",name:"mcp__linear__save_issue",input:{id:"RIM-9",title:"Y"}}]}}'
  jq -c -n '{type:"user",isSidechain:false,message:{content:[{type:"tool_result",tool_use_id:"tu_2",is_error:false}]}}'
  jq -c -n '{type:"assistant",isSidechain:false,message:{content:[{type:"text",text:"Retitled."}]}}'
} > "$FIX/update.jsonl"
expect_exit 0 "an update is not a create" "$H" \
  "$(hook_input "$FIX/update.jsonl" "s-update")"

# A failed create must not demand a summary for something that does not exist.
{
  jq -c -n '{type:"user",isSidechain:false,message:{content:[{type:"text",text:"file it"}]}}'
  jq -c -n '{type:"assistant",isSidechain:false,message:{content:[{type:"tool_use",id:"tu_3",name:"mcp__linear__save_issue",input:{title:"Z"}}]}}'
  jq -c -n '{type:"user",isSidechain:false,message:{content:[{type:"tool_result",tool_use_id:"tu_3",is_error:true}]}}'
  jq -c -n '{type:"assistant",isSidechain:false,message:{content:[{type:"text",text:"Linear rejected that."}]}}'
} > "$FIX/failed.jsonl"
expect_exit 0 "a failed create needs no summary" "$H" \
  "$(hook_input "$FIX/failed.jsonl" "s-failed")"

summarize
