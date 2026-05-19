# Criterion: `slice-size`

## What it says

A PR that builds new infrastructure (module, manager, resolver, store slice, hook) but doesn't wire it into a call site that the live system actually reaches is too big. Push back on the slice — recommend landing one end-to-end-wired path now and adding breadth in follow-ups.

## Why

Half-wired modules look "covered" in CI (unit tests pass) but the production path never exercises them. They drift, accumulate stale assumptions, and the first integration PR discovers contract mismatches that the original PR could have surfaced. Two incidents from 2026-05-19:

- nullbreaker#20 shipped `SubroutineManager` + 7 resolvers + invariant tests; `EncounterRoom` never called any of them.
- nullbreaker#18 shipped `resolveMomentumCloak` enforcing the new threshold; the play layer ignored the resolver entirely.

In both cases, the regression-guard intent was undermined because nothing in production read the new code.

## How to spot

- New module/manager/resolver/extension has unit + invariant tests but the integration file (`EncounterRoom.ts`, `Editor.tsx`, the room/component/handler that orchestrates) shows zero or near-zero lines added in the same PR.
- PR body or TEST_PLAN flags wiring as ⏭️ / "follow-up" / "PER-XX will land the handler".
- A constant or helper is exported from the new module but no production import of it appears in the diff.

## When NOT to apply

- The PR is explicitly scoped as "data only" (e.g. card definitions, content) where the runtime already knows how to consume any new entry via an existing registry.
- The new module is a pure refactor extracting an already-wired call site (the wiring is the line you deleted from the old location).

## Severity guidance

- **Blocker** when the new module is the *primary value* of the PR and nothing in production reaches it.
- **Concern** when the unwired module is a small auxiliary to a larger, wired change.
