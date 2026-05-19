# Criterion: `doc-audit`

## What it says

Every concrete count or "all/every/N of M" claim in the PR body, commit messages, or test-plan/checklist row flips must match what the diff actually contains. Mismatches get surfaced as findings — even small ones.

## Why

When code, tests, and docs are authored together, the doc state is part of the source of truth. A claim of "N of M items covered" with fewer matching test files in the diff makes the doc lie, and future readers trust the doc.

## How to spot

- PR body says "N tests" / "N files" / "all X" / "every Y" → count it.
- A test-plan or checklist row flipped from ❌ → ✅ → confirm a corresponding test file or assertion lands in the diff.
- Commit messages claim a fix → confirm a regression test or behavior assertion exists for it.
- Code comments reference a numbered rule/issue/update → confirm a constant or test locks that reference in.

## Mechanical check

When applicable, run:

```bash
gh pr view <n> --json body --jq '.body'        # extract claims
gh pr diff <n> | grep -c '^+++ b/.*\.test\.'  # count new test files
```

Compare claimed N against grepped N. If they differ, that's a finding.

## When NOT to apply

- PR body has no concrete counts — only qualitative descriptions. Don't invent claims to audit.
- The count drift is +1 in the diff's favor (more tests than claimed) — note it but downgrade to a Nit.

## Severity guidance

- **Concern** when the claimed count exceeds the delivered count (overclaim).
- **Nit** when the claim is vague or under-delivers in the user's favor.
- Never **Blocker** on its own — but combine with other criteria if the mismatch hides a real gap.
