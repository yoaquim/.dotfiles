#!/usr/bin/env bash
# PostToolUse hook for /pr-review. Stamps the reviewed HEAD SHA into this job's
# state dir (jobs/<sid>/last-reviewed-sha) so the Stop hook (enforce-watch.sh)
# can tell "new commit, re-review" from "same SHA, just wait."
#
# Stamps ONLY after a CONFIRMED-successful review post. Recording in the
# PreToolUse allow-path (before `gh api .../reviews` runs) would stamp an
# unreviewed HEAD if the post then failed — the watcher would then idle on a
# review that never landed. Success signal: GitHub returns the created
# review/comment object, which carries "pull_request_url"; gh errors don't.
#
# Exit 0 always (recording is best-effort; never wedge the agent).

set -uo pipefail
trap 'exit 0' ERR

INPUT=$(cat 2>/dev/null || echo '{}')
SID=$(jq -r '.session_id // ""' <<<"$INPUT")
[[ -z "$SID" ]] && exit 0

COMMAND=$(jq -r '.tool_input.command // ""' <<<"$INPUT" 2>/dev/null || echo "")
# Only the inline-review POST path or the legacy gh pr review/comment path.
grep -qE 'pulls/[0-9]+/reviews|gh[[:space:]]+pr[[:space:]]+(review|comment)' <<<"$COMMAND" || exit 0

# Flatten the tool response (shape varies: object with stdout/stderr, or a string)
# and require a posted-review signature so a failed post does not stamp.
RESP=$(jq -r '
  [ (.tool_response.stdout? // empty),
    (.tool_response.output? // empty),
    (.tool_response.stderr? // empty),
    (if (.tool_response|type) == "string" then .tool_response else empty end) ]
  | join("\n")
' <<<"$INPUT" 2>/dev/null || echo "")
grep -q 'pull_request_url' <<<"$RESP" || exit 0   # no success object → don't stamp

# Resolve PR (from the command, else current branch) and stamp the current HEAD.
PR=$(sed -nE 's#.*/pulls/([0-9]+)/reviews.*#\1#p' <<<"$COMMAND" | head -1)
[[ -z "$PR" ]] && PR=$(gh pr view --json number -q .number 2>/dev/null || echo "")
[[ -z "$PR" ]] && exit 0

SHA=$(gh pr view "$PR" --json headRefOid -q .headRefOid 2>/dev/null || echo "")
[[ -z "$SHA" ]] && exit 0

mkdir -p "$HOME/.claude/jobs/$SID" 2>/dev/null || true
echo "$SHA" > "$HOME/.claude/jobs/$SID/last-reviewed-sha" 2>/dev/null || true
exit 0
