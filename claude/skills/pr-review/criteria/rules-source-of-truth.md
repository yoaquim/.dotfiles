# Criterion: `rules-source-of-truth`

## What it says

For projects with an explicit rules/spec/design document, the data files, runtime code, and tests must all agree with the doc — and the doc must agree with what landed. When they drift, flag the drift, not just "a bug".

## Why

When a repo treats a spec doc as load-bearing — a written spec that drives encoded data, runtime code that enforces the spec, and tests that assert against the spec — a change in one of these layers must reach the others or behavior silently diverges from intent. Typical incident pattern: a data file encodes the wrong shape (e.g., a duration value treated as a stack count, a single entry vs. repeated entries) while tests pass because they assert something downstream of the encoding rather than the encoded shape itself.

## How to spot

- Diff touches a spec/rules doc → confirm a matching code/data/test change in the same PR.
- Diff touches data files that the runtime consumes → confirm the doc still describes what the data encodes.
- A test asserts a magic constant → confirm the doc cites the same value and the source-of-change reference (e.g., an "updates" doc, an ADR, a changelog entry).
- A handler/resolver branch encodes a rule-specific calculation → confirm a comment or test references the rules section it implements.

## Mechanical check

For repos with a known spec-doc location, surface doc + code drift in one PR. Substitute the project's actual spec-doc path(s) and data-dir path(s):

```bash
gh pr diff <n> --name-only | grep -E '<spec-doc-filename>\.md'
gh pr diff <n> --name-only | grep -E '<data-dir-path>'
# If one lights up but the other doesn't, ask why.
```

If the repo doesn't have a designated source-of-truth doc, this criterion doesn't apply — say so explicitly and omit it from the `Criteria applied` header.

## When NOT to apply

- The repo doesn't have a designated source-of-truth doc. Don't manufacture one.
- The PR is a pure mechanical refactor (rename, extract function) with no rule semantics in scope.

## Severity guidance

- **Blocker** when data and doc disagree about a value a user or downstream system will see.
- **Concern** when the rule is encoded correctly but the doc isn't updated to reflect the change.
- **Nit** when only comments are stale (no behavior or doc drift).
