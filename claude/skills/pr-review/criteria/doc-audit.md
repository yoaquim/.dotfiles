# Criterion: `doc-audit`

## What it says

Every concrete count or "all/every/N of M" claim in the PR body, commit messages, or TEST_PLAN row flips must match what the diff actually contains. Mismatches get surfaced as findings — even small ones.

## Why

Yoaquim writes code, tests, and docs together; the doc state is part of the source of truth. A claim of "12 of 15 spec scripts covered" with 10 test files in the diff makes the doc lie, and future readers (including future-Yoaquim) trust the doc. Caught on nullbreaker#18 on 2026-05-19.

## How to spot

- PR body says "N tests" / "N files" / "all X" / "every Y" → count it.
- TEST_PLAN.md (or equivalent) row flipped from ❌ → ✅ → confirm a corresponding test file or assertion lands in the diff.
- Commit messages claim a fix → confirm a regression test or behavior assertion exists for it.
- Code comments reference `RULES_UPDATES.md #N` thresholds → confirm a constant or test locks the threshold in.

## Mechanical check

When applicable, run:

```bash
gh pr view <n> --json body --jq '.body'  # extract claims
gh pr diff <n> | grep -c '^+++ b/.*\.test\.'  # count new test files
```

Compare claimed N against grepped N. If they differ, that's a finding.

## When NOT to apply

- PR body has no concrete counts — only qualitative descriptions. Don't invent claims to audit.
- The count drift is +1 in the diff's favor (more tests than claimed) — note it but downgrade to a Nit.

## Severity guidance

- **Concern** when the claimed count exceeds the delivered count (overclaim).
- **Nit** when the claim is vague or under-delivers in the user's favor.
- Never **Blocker** on its own — but combine with other criteria if the mismatch hides a real gap (e.g., the missing 2 of 12 spec scripts are the 2 with the trickiest RNG).
