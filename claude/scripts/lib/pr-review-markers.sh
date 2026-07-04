#!/usr/bin/env bash
# pr-review-markers.sh — single source of truth for the /pr-review body sentinels.
#
# Sourced by every site that has to recognize a posted review:
#   - skills/pr-review/hooks/check-post.sh   (enforce a conforming post)
#   - scripts/check-pr-state.sh              (approved_at_head for the runner)
# (spawn-reviewer.sh's reviewed-at-HEAD gate counts ANY review at HEAD via REST
# and does not need the sentinel.)
#
# The literal strings live in the posted templates (approved.md /
# changes-requested.md) — that text IS what lands on GitHub. We read the
# sentinels BACK from those files instead of re-hardcoding them, so editing a
# template can never silently desync detection: there is exactly one physical
# copy of each marker, in the template.
#
# Override PR_REVIEW_TEMPLATES for tests; defaults to the installed location.

PR_REVIEW_TEMPLATES="${PR_REVIEW_TEMPLATES:-$HOME/.claude/skills/pr-review/templates}"

# Shared header — present on BOTH approved.md and changes-requested.md. Proves a
# Claude review was posted; says NOTHING about the verdict. Do not use it to
# detect approval.
pr_review_header() {
  grep -m1 '^# .*Reviewed by Claude' "$PR_REVIEW_TEMPLATES/approved.md" 2>/dev/null
}

# Approval sentinel — the headline that exists ONLY in approved.md
# (`# ✅ APPROVED ✅`). Anchored on the ASCII word APPROVED so the pattern itself
# carries no emoji/locale baggage; the returned line keeps the template's exact
# bytes for a fixed-string (-F / jq contains) match against a posted body.
pr_review_approved_marker() {
  grep -m1 '^# .*APPROVED' "$PR_REVIEW_TEMPLATES/approved.md" 2>/dev/null
}

# True iff $1 (a review body) carries the approval sentinel. Fails safe: if the
# marker can't be read (template missing/renamed), returns false — never treat an
# unrecognizable body as approved.
pr_review_is_approved_body() {
  local marker
  marker=$(pr_review_approved_marker)
  [[ -n "$marker" ]] || return 1
  grep -qF "$marker" <<<"$1"
}
