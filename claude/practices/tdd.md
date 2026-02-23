# TDD

Write tests FIRST, then implement code to pass them. Mandatory for all implementation tasks.

## Workflow (Red-Green-Refactor)

1. **RED**: Write a failing test for the expected behavior
2. **Run**: Confirm test fails (validates test is meaningful)
3. **GREEN**: Write minimal code to make it pass
4. **Run**: Confirm test passes
5. **REFACTOR**: Clean up while keeping tests green
6. **Repeat**

## Test Types

- **Unit**: Individual functions/methods in isolation. Pure functions, business logic, edge cases.
- **Integration**: How components work together. API endpoints, database operations, service interactions.
- **E2E**: Complete user workflows. Critical paths, multi-step processes. Separate task, runs after implementation.

## Test Quality

- One behavior per test
- Descriptive names: `test_calculateDamage_withModifiers_returnsSumOfBaseAndModifiers`
- Arrange-Act-Assert pattern
- Tests run independently — no shared mutable state
- Mock external dependencies (APIs, databases, file system)
- Cover: happy path, edge cases (empty, null, boundaries), error cases

## Coverage

- 80%+ overall on new code
- 95%+ on critical paths (auth, payments, data mutations)
- Don't chase 100% — diminishing returns on simple getters/config

## File Placement

Tests in dedicated `tests/` directory, mirroring `src/` structure:

```
src/utils/jwt.ts      →  tests/utils/jwt.test.ts
src/hooks/useAuth.ts  →  tests/hooks/useAuth.test.ts
```

## When TDD is Optional

- Pure setup tasks (installing deps, config changes)
- Prototyping/exploration
- E2E test tasks (they ARE the tests)
