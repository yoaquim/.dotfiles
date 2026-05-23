# No Comments

Default: write **zero** comments. Identifiers do the explaining.

## The rule

If removing a comment wouldn't confuse a future reader, don't write it.

Names carry the meaning. `validateEmailFormat()` doesn't need `// validates email format` above it. A descriptive variable name beats a comment every time.

## The only exception

A non-obvious **why** — a hidden constraint, a subtle invariant, a workaround for a specific bug. One line max. Be terse.

Good: `// Stripe webhook arrives before charge.succeeded; defer until both seen`
Bad: `// This function handles the user authentication flow`

## Never write

- **What** the code does — names already say it
- **References to the task**: ticket IDs (PER-83), Linear, Jira, "as requested", "implements the X feature", "for the Y flow"
- **References to callers**: "used by X", "called from Y" — code search finds these
- **TODO / FIXME / XXX** — open an issue or fix it; don't leave breadcrumbs
- **Section headers / banners**: `// =========== AUTH ===========`
- **Restatements of types**: `// returns a string` above `function f(): string`
- **Multi-line prose blocks** explaining design — that's for the PR description, not the code
- **Commented-out code** — delete it; git has the history

## When in doubt

Don't write the comment. If review asks for it later, add it then with a known reason.
