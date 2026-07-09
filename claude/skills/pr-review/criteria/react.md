# Criterion: `react`

## What it says

React diffs get checked for hook and render-lifecycle failure modes: stale closures, effect misuse, state-update races, and identity churn.

## How to spot

**Hooks**
- `useEffect` / `useCallback` / `useMemo` dependency arrays missing a value the body reads → stale closure. Check every captured variable against the array.
- Dependency array with an object/array/function literal recreated every render → effect fires every render (or memo never holds).
- Hook called conditionally or in a loop — order changes between renders.
- Effect without a cleanup that subscribes, sets a timer, or adds a listener.

**State**
- `setState` after an await with no cancellation/mounted guard — races and out-of-order responses (fast typing, tab switches).
- Derived state copied into `useState` from props and never re-synced — two sources of truth.
- Multiple `setState` calls computing from stale `state` instead of the functional form.
- State that should be a ref (doesn't drive render) causing render loops or effect churn.

**Rendering**
- `key={index}` on a reorderable/deletable list — state sticks to the wrong row.
- Context value created inline in the provider (`value={{...}}`) — every consumer re-renders every render.
- Component defined inside another component's body — remounts on every parent render, loses state.
- Controlled input flipping to uncontrolled (`value` sometimes undefined).

**Data fetching**
- Fetch in an effect without abort/ignore handling for unmount or param change.
- Response of an earlier request overwriting a later one (no request-id / abort check).

## When NOT to apply

- Diff touches no `.jsx`/`.tsx`/component files.
- The "missing dependency" is deliberately omitted with an eslint-disable and a comment explaining why — verify the reason, don't auto-flag.

## Severity guidance

- **Blocker** — stale-closure bugs on user-visible state; out-of-order fetch overwrites; conditional hooks.
- **Concern** — missing effect cleanup; index keys on mutable lists; derived-state divergence.
- **Nit** — inline context values / unstable deps with only performance impact.
