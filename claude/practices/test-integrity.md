# Test Suite Integrity

TDD covers writing a test. This covers editing one later — refactors, contract changes, bug fixes.

## The core rule

**Never edit a test because it is failing. Edit it because the behavior it describes intentionally changed.** In a diff those look identical, so the reason must be stated every time — in the commit body or PR description, never a code comment (`no-comments.md`).

## Classify before touching

Name the primary cause. If two apply, split the change.

| Cause | Action |
|---|---|
| Contract changed — a ticket or spec says so | Rewrite the test to the new contract |
| Code is wrong | Fix the code, don't touch the test |
| Non-deterministic — order, clock, race, shared fixture, network | Fix the determinism; never the assertion, never the timeout |
| Test was always wrong — rare, needs evidence | Fix the test, write down why |

Can't classify it? Stop. That means you don't understand the change yet — investigate or ask, don't sand the assertion until it's green.

## Declare it

Every PR touching tests carries this line verbatim. `validate-pr-body.sh` requires it and only these five values pass:

```
Test changes: <contract moved | code fixed | flake fixed | test was wrong | new coverage only>
```

Then the reason in prose. A test diff with no stated reason is production code with no test.

## Weakening is deleting

Each of these keeps the suite green while cutting what it can catch, and carries a delete's burden of justification. `guard-test-edits.sh` blocks the first three:

- Skipping, marking pending/xfail, or commenting a test out
- Removing assertions — including trading a behavioral one for not-null, doesn't-throw, or truthy
- Raising a timeout instead of fixing the race
- Loosening an exact assertion to a range or tolerance
- Dropping a case from a table-driven or parameterized test
- Swapping a pinned value for a type- or shape-only matcher
- Accepting a snapshot update unread
- Reducing iterations, seeds, or sample sizes
- Mocking out the unit under test
- Swallowing the failure in a try/catch

Deleting needs a reason too: "obsolete" is a claim, "failing" is not. Prefer rewriting — changed behavior is still behavior. A live code path losing its test needs replacement coverage.

Genuinely justified? `test-weakening-ok` in the edited chunk clears the hook; say why in the commit.

## Prove the edit can still fail

Revert the production change or mutate the code, watch the test go red for the right reason, and paste that run into the PR (`verification.md`). An edited test inherits the original's credibility while possibly guarding nothing.

## Mass rewrites

One bounded commit, no drive-by cleanups, old and new contract named once, count honest. Reviewers pattern-match after the tenth identical diff — that is where a weakened assertion hides.

## What this can't catch

Green-and-wrong: a test asserting against the same drifted fixture or duplicated definition as the code, so both agree and both are wrong. That needs a conformance check against ground truth (`dry.md`), not editing discipline. Periodically ask of a suspicious test — *what code change would make this fail?* If nothing would, it isn't testing anything.

## On violation

Edited an assertion to make it pass without being able to say which case you were in? Revert the test edit and classify first. The shortcut's output is not evidence, and keeping it biases what you do next.
