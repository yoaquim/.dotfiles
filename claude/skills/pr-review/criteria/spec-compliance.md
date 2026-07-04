# Criterion: `spec-compliance`

## What it says

Before bug-checklist, verify the diff matches the spec it claims to implement. Three failure modes: **missing**, **extra**, **misinterpreted**.

## When it applies

Spec context must be resolvable. Try in order:

1. Linear ticket parsed from PR branch/title (same parse as SKILL.md step 0) → fetch via the connected Linear MCP server's get-issue tool (`mcp__linear-<workspace>__*`; pick the workspace matching the ticket prefix). No Linear tools in this session → fall back to the ticket context quoted in the PR body.
2. Sketch file at `.dispatch/sketches/<name>.md` matching the branch name
3. Neither → drop this criterion (don't include in `Criteria applied`)

## Why

Bug-free code that solves the wrong problem is still wrong. PR bodies and commit messages describe *intent*; the diff describes *reality*. Compare reality to spec, not to intent.

## How to spot

For each acceptance criterion / requirement in the spec:

- **Missing** — no diff hunk implements it. Cite the spec line and the absence (`spec: "cancel on overdue fees" — no fee check in handler`).
- **Extra** — diff implements behavior the spec doesn't ask for. Scope creep, premature abstraction, "while I was here" refactors, options nobody requested.
- **Misinterpreted** — diff implements the named feature with wrong semantics. Wrong state machine, wrong default, wrong contract, wrong error path.

## When NOT to apply

- No spec resolvable.
- Pure refactor with no behavior change.
- PR explicitly says "scope reduced from ticket" — judge against the reduced scope, but confirm reduction is acknowledged in the PR body.

## Severity

- **Blocker** — required behavior missing or misinterpreted.
- **Concern** — extras that expand surface area (new abstractions, new options, drive-by refactors).
- **Nit** — extras that are pure cleanup with no surface-area impact.

## Ordering + output

Run **before** `bug-checklist.md`. Blockers from this criterion sort above all bug findings.

"Missing" findings have no code location — fold them into the `## Cross-cutting` section of the review body with a spec reference (`spec doc line N` or `ticket acceptance criterion #2`).
