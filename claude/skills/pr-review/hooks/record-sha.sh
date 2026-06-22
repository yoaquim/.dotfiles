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
# Scope to the skill's ONE supported posting surface: the canonical inline-review
# POST (`gh api .../pulls/N/reviews` with -X POST / --input). A bare reviews GET,
# or the legacy `gh pr review|comment` path, is intentionally out of scope — they
# don't return a review object we can confirm, so we'd never stamp them anyway.
grep -qE 'pulls/[0-9]+/reviews' <<<"$COMMAND" || exit 0
grep -qE '(-X[[:space:]=]+["'"'"']?POST|--input)' <<<"$COMMAND" || exit 0

# Flatten the tool response (shape varies: object with stdout/stderr, or a string).
RESP=$(jq -r '
  [ (.tool_response.stdout? // empty),
    (.tool_response.output? // empty),
    (.tool_response.stderr? // empty),
    (if (.tool_response|type) == "string" then .tool_response else empty end) ]
  | join("\n")
' <<<"$INPUT" 2>/dev/null || echo "")

# Confirm success without depending solely on a field name in stdout: prefer the
# Bash tool's exit code if the payload exposes it, else fall back to the presence
# of a posted-review object (pull_request_url). A filtered post (--jq/-q) strips
# the token but still exits 0; a missed stamp would loop the watcher on one HEAD.
EXIT=$(jq -r '.tool_response.exit_code? // .tool_response.exitCode? // .tool_response.code? // empty' <<<"$INPUT" 2>/dev/null || echo "")
[[ "$EXIT" == "0" ]] || grep -q 'pull_request_url' <<<"$RESP" || exit 0

# Resolve PR (from the command, else current branch) and stamp the current HEAD.
PR=$(sed -nE 's#.*/pulls/([0-9]+)/reviews.*#\1#p' <<<"$COMMAND" | head -1)
[[ -z "$PR" ]] && PR=$(gh pr view --json number -q .number 2>/dev/null || echo "")
[[ -z "$PR" ]] && exit 0

SHA=$(gh pr view "$PR" --json headRefOid -q .headRefOid 2>/dev/null || echo "")
[[ -z "$SHA" ]] && exit 0

mkdir -p "$HOME/.claude/jobs/$SID" 2>/dev/null || true
echo "$SHA" > "$HOME/.claude/jobs/$SID/last-reviewed-sha" 2>/dev/null || true

# If this was the clean/approved review (its body carries the approval sentinel
# from templates/approved.md — the same one check-post.sh requires and the runner
# detects), also stamp last-approved-sha. enforce-watch.sh lets the reviewer stop
# once an approved HEAD has green CI, which works even on self-authored PRs where
# GitHub's reviewDecision can never become APPROVED. Source failure fails safe
# (no stamp → reviewer keeps watching rather than exiting on a phantom approval).
# shellcheck disable=SC1091  # installed at runtime; not resolvable at lint time
if source "$HOME/.claude/scripts/lib/pr-review-markers.sh" 2>/dev/null \
   && pr_review_is_approved_body "$RESP"; then
  echo "$SHA" > "$HOME/.claude/jobs/$SID/last-approved-sha" 2>/dev/null || true
fi
exit 0
