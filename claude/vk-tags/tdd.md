# TDD - Test-Driven Development

## Core Principle
Write tests FIRST, then implement code to pass them.

## TDD Workflow (Red-Green-Refactor)
1. **RED**: Write a failing test for the expected behavior
2. **Run**: Confirm the test fails (validates test is meaningful)
3. **GREEN**: Write minimal code to make the test pass
4. **Run**: Confirm the test passes
5. **REFACTOR**: Clean up code while keeping tests green
6. **Repeat**: Next behavior

## When to TDD
- Pure functions (calculations, transformations)
- Business logic and validation rules
- API endpoints
- State machines
- Any code with clear input/output expectations

## When TDD is Optional
- UI components (unless complex logic)
- Simple CRUD operations
- Prototyping/exploration
- One-off scripts

## Test Quality Checklist
- [ ] Happy path: Expected inputs produce expected outputs
- [ ] Edge cases: Empty inputs, boundaries, nulls
- [ ] Error cases: Invalid inputs, exceptions
- [ ] Each test focuses on ONE behavior
- [ ] Descriptive test names explain what's being tested
- [ ] Tests can run independently (no shared state)
- [ ] No hardcoded values that might change

## Best Practices
- Use the project's existing test framework (check package.json, pytest.ini, etc.)
- Follow existing test patterns in the codebase
- Mock external dependencies (APIs, databases, file system)
- Aim for 80%+ coverage on new code
- Keep tests fast—slow tests get skipped

## Test Naming Convention
```
test_<function>_<scenario>_<expected_result>
```
Example: `test_calculateDamage_withModifiers_returnsSumOfBaseAndModifiers`
