# Criterion: `slice-size`

## What it says

A PR that builds new infrastructure (module, manager, resolver, store slice, hook) but doesn't wire it into a call site that the live system actually reaches is too big. Push back on the slice — recommend landing one end-to-end-wired path now and adding breadth in follow-ups.

## Why

Half-wired modules look "covered" in CI (unit tests pass) but the production path never exercises them. They drift, accumulate stale assumptions, and the first integration PR discovers contract mismatches that the original PR could have surfaced. Common shapes of the incident:

- A PR ships a new manager/resolver/handler module plus unit + invariant tests; the orchestration layer (the room/component/controller/service that should call it) shows zero or near-zero lines added.
- A PR ships a resolver enforcing a new rule/threshold; the live path or feature flag never reads that resolver.

In both cases, the regression-guard intent is undermined because nothing in production exercises the new code.

## How to spot

- New module/manager/resolver/extension has unit + invariant tests but the integration file shows zero or near-zero lines added in the same PR.
- PR body or test plan flags wiring as ⏭️ / "follow-up" / "ticket-XX will land the handler".
- A constant or helper is exported from the new module but no production import of it appears in the diff.

## When NOT to apply

- The PR is explicitly scoped as "data only" (e.g. content/config additions) where the runtime already knows how to consume any new entry via an existing registry.
- The new module is a pure refactor extracting an already-wired call site (the wiring is the line deleted from the old location).

## Severity guidance

- **Blocker** when the new module is the *primary value* of the PR and nothing in production reaches it.
- **Concern** when the unwired module is a small auxiliary to a larger, wired change.
