# DRY — Reuse Before Build

One system per thing. A second implementation of an existing interaction, animation, validation family, data shape, or wire contract is a defect, not a style choice — parallel systems drift, and drift becomes player-visible bugs (operator ruling, Nullbreaker 2026-07-25, after an audit found four dice implementations, four reward-grant paths, and three error taxonomies in one repo).

## Before implementing anything

Before writing a system, subsystem, component, hook, helper, validator, or type, **search for an existing implementation first** — this is a mandatory step, not a suggestion:

- Search by the *interaction or concept*, not just the name you'd give it (grep for the behavior: "roll", "modal", "picker", "grant", "guard" — synonyms included). Check the project's kit/shared/helpers directories and the nearest sibling feature.
- Found one that fits → **use it.**
- Found one that almost fits → **extend it** (variant prop, parameter, optional field). Extending a shared thing beats forking it, even when extending is more work today.
- Found one that can't be extended → say so explicitly in the PR/status notes: name the existing implementation, why it can't absorb this case, and what the unification would take. Building parallel WITHOUT this written justification is the failure mode this practice exists to prevent.
- Found nothing → build it **where the second consumer will find it** (shared module, kit, helpers dir per the repo's conventions), not inline where only you know it exists.

## While implementing

- Declare every data shape ONCE. If a stack forces a mirror (sync schema / wire DTO / client view), derive both sides from one source, or ship a conformance test binding them **in the same PR** — one that fails naming the drifted field the moment either side changes alone. The gate must be exact (bijection, derived-equals-source), never "subset" or "assignable"; a permissive gate is how synced-but-forgotten hides. Can't gate it? The mirror doesn't ship — restructure so the single declaration can be imported.
- Copying a block to a second site is the signal to extract, at the moment of the second copy — not the third, not "later."
- Constants, predicates, and message/error vocabularies are systems too: one taxonomy, one lookup, no inline literals of things that have a home. A bare literal that happens to equal a named constant elsewhere IS a second declaration — worst when the unnamed site is the authoritative one. A value that genuinely can't cross a boundary is a mirror: gate it.
- Cross-boundary twins (client preview vs server validation of the same rule) compute from literally the same shared function wherever the runtime allows it.

## Replacing a system

Superseding something means it dies in the same PR — code, exports, and its tests. DRY's other rules stop you building a second system; this one stops you *leaving* one behind.

- **A test suite is not a consumer.** "Its tests still pass" is not a reason to keep dead code — it is the mechanism by which dead code survives. Tests guarding an uncalled implementation burn CI, inflate coverage, and keep the thing warm enough that someone imports it by accident.
- Prove death before burial: grep for consumers, paste the evidence in the PR. Zero production consumers → delete. One surprise consumer → stop. You found a live dependency the design missed, not a reason to keep two systems.
- Genuinely staged migration? Say so in the PR, name what still consumes the old system, and file the deletion as tracked work. "Clean it up later" with no record is how a codebase accretes a second engine for a job it already did.
- Never leave old and new exporting the same symbol name from different paths. An import-path typo must not be able to silently swap implementations.

## When you FIND duplication you didn't create

Don't silently add a third copy, and don't silently refactor unrelated code mid-task. Note the duplication (status file, PR description, or a proposed follow-up) so it becomes a tracked finding. If your change must touch one of the copies, prefer touching it in a way that converges them.

## The test

Before the PR: "if someone deletes my new code and greps for what it does, would they find an older thing that already did it?" If yes, the PR isn't done.
