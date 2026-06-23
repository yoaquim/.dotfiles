# Created Summary — shared closing contract

The standardized block that `/issue` and `/spec` emit once they finish creating
in Linear. Lives here because `/issue` is the style primitive `/spec` composes.

A `Stop` hook (`~/.claude/hooks/enforce-created-summary.sh`) re-prompts if this
block is missing after a Linear issue or spec is created — so always emit it.

Two parts, in order, with the bold headers **verbatim** (the hook looks for them):

## 1. What it does

Plain-English explanation of what the created work actually does — the feature or
fix from a user's point of view, **not** the tickets. Succinct: under a paragraph,
3–5 lines, more only if truly needed. No jargon, no ticket IDs, no file paths.

## 2. What was issued / What was specced

A terse summary of the artifacts created:

- `/issue` → header **What was issued**: issue ID + URL.
- `/spec`  → header **What was specced**: master ticket ID + URL, sub-issue count,
  total points, next step (`/dispatch <ticket-id>`).

Use the matching header literally: `What it does`, and `What was issued` or
`What was specced`.
