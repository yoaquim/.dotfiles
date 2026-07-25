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

- Declare every data shape ONCE. If a stack forces mirrors (sync schema / wire DTO / client view), derive them from one source or bind them with a conformance test — never hand-maintain parallel declarations.
- Copying a block to a second site is the signal to extract, at the moment of the second copy — not the third, not "later."
- Constants, predicates, and message/error vocabularies are systems too: one taxonomy, one lookup, no inline literals of things that have a home.
- Cross-boundary twins (client preview vs server validation of the same rule) compute from literally the same shared function wherever the runtime allows it.

## When you FIND duplication you didn't create

Don't silently add a third copy, and don't silently refactor unrelated code mid-task. Note the duplication (status file, PR description, or a proposed follow-up) so it becomes a tracked finding. If your change must touch one of the copies, prefer touching it in a way that converges them.

## The test

Before the PR: "if someone deletes my new code and greps for what it does, would they find an older thing that already did it?" If yes, the PR isn't done.
