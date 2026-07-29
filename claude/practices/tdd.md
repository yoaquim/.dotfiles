# TDD

Write tests FIRST, then implement code to pass them. Mandatory for all implementation tasks.

## Workflow (Red-Green-Refactor)

1. **RED**: Write a failing test for the expected behavior
2. **Run**: Confirm test fails — *and that it fails for the expected reason* (missing behavior), not a typo, import error, or malformed assertion. A test that fails for the wrong reason isn't evidence of anything.
3. **GREEN**: Write minimal code to make it pass
4. **Run**: Confirm test passes — because the behavior is correct, not because the assertion is trivially satisfied
5. **REFACTOR**: Clean up while keeping tests green
6. **Repeat**

## Shipping without tests

Sometimes legitimate — config, a pure rename, generated code. It is never legitimate *silently*. A PR that changes source and touches no test file must carry one line saying why:

```
No new tests: <reason>
```

`validate-pr-body.sh` requires it. The line is the point: it turns an omission nobody would notice into a claim someone can disagree with.

## On Violation

Wrote production code without a failing test first? **Delete it. All of it.** Don't keep it as scratch, in a comment, or in a side file — it biases the test you write next. Restart from RED.

## Test Quality

- One behavior per test
- Descriptive names: `test_parseDate_withTimezone_returnsUTC`
- Arrange-Act-Assert pattern
- Tests run independently — no shared mutable state
- Mock external dependencies (APIs, databases, file system)
- Cover: happy path, edge cases (empty, null, boundaries), error cases

## Coverage

- 80%+ overall on new code
- 95%+ on critical paths (auth, payments, data mutations)
- Don't chase 100% — diminishing returns on simple getters/config

## File Placement

Follow the framework/repo convention first — Rails uses `spec/`, Django puts tests in-app, an existing repo's layout always wins. Absent a convention, default to a `tests/` directory mirroring `src/` (`src/utils/jwt.ts` → `tests/utils/jwt.test.ts`).

## When TDD is Optional

- Pure setup tasks (installing deps, config changes)
- Prototyping/exploration
- E2E tasks — they ARE the tests, and they run as separate work after implementation
