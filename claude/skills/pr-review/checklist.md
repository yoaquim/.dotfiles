# PR Review Checklist

Walk these in order. Each step gets one line in your scratch notes before you move on. If a step doesn't apply, mark it `n/a` with a reason.

1. **Scope confirmed.** PR number resolved or branch diff established. Owner/repo known.
2. **PR body read.** Note every concrete claim: counts ("12 tests"), file lists, "all X covered", deferred work flagged. These are the targets for `doc-audit`.
3. **Diff read end-to-end.** Don't review on body alone. If the diff is over ~3k lines, spawn one Explore subagent per logical module and synthesize.
4. **Criteria applied.** For each file in `criteria/`, ask: does this diff give it a target? Mark each as fired / no-target.
5. **Findings drafted.** Each one has: title, severity, criterion slug, file:line, plain-English issue, concrete fix, diff block.
6. **Sort + group.** Blockers → Concerns → Nits. Within tier, group by criterion.
7. **Self-audit.** Re-read your findings. Any duplicates? Any nits that should be silent? Any blockers without a concrete fix? Fix before posting.
8. **Header composed.** Use `header.md` literally. Substitute `{criteria}` with criteria that actually fired or were affirmatively checked — not every file in the dir.
9. **Chat output delivered.** User sees the full review.
10. **Post (if PR number).** Use `gh pr review <n> --comment -b "$(cat <<'EOF' … EOF)"`. If the post-validation hook blocks, fix the gap; do not work around the hook.
