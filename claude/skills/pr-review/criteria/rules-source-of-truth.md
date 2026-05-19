# Criterion: `rules-source-of-truth`

## What it says

For projects with an explicit rules/spec document (game rules, protocol spec, design system tokens), the data files, runtime code, and tests must all agree with the doc — and the doc must agree with what landed. When they drift, flag the drift, not just "a bug".

## Why

Yoaquim's repos treat docs as load-bearing. `docs/GAME_RULES.md` and `RULES_UPDATES.md` are the spec; `shared/gameData/cards/*.ts` is the encoded data; resolver logic enforces the spec; tests assert against the spec. A change in one of the four must reach the other three or behavior silently diverges from intent. This is the substrate behind the Neural Scorch and Amp Surge incidents (nullbreaker#18, 2026-05-19) — the data encoded the wrong shape (`duration: 2` instead of two `apply_status` entries) and tests papered over it.

## How to spot

- Diff touches `docs/GAME_RULES.md` or `RULES_UPDATES.md` → confirm a matching code/data/test change in the same PR.
- Diff touches card/spec/data files (`shared/gameData/`, `shared/types/`) → confirm the doc still describes what the data encodes.
- A test asserts a constant (e.g., `MOMENTUM_CLOAK_THRESHOLD = 3`) → confirm the doc cites the same number and the source incident (`RULES_UPDATES.md #001`).
- A handler/resolver branch encodes a rule-specific calculation → confirm a comment or test references the rules section it implements.

## Mechanical check (partial)

```bash
# Surface any doc + code drift in one PR
gh pr diff <n> --name-only | grep -E '(GAME_RULES|RULES_UPDATES)\.md'
gh pr diff <n> --name-only | grep -E '(gameData/|/scripts/|/subroutines/)'
# If one lights up but the other doesn't, ask why.
```

## When NOT to apply

- The repo doesn't have a designated source-of-truth doc. Don't manufacture one.
- The PR is a pure mechanical refactor (rename, extract function) with no rule semantics in scope.

## Severity guidance

- **Blocker** when data and doc disagree about a number a player or downstream system will see.
- **Concern** when the rule is encoded correctly but the doc isn't updated to reflect a nerf/buff that landed (`RULES_UPDATES.md` gap).
- **Nit** when only comments are stale (no behavior or doc drift).
