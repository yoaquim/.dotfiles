# Testing Principles

**Universal SOP** - Core testing principles that apply to all projects.

---

## Testing Philosophy

- **Write tests first** when possible (TDD)
- **Test behavior**, not implementation
- **Aim for high coverage** but prioritize critical paths
- **Keep tests fast** for quick feedback
- **Make tests readable** - they're documentation too

---

## Types of Tests

### Unit Tests
**Purpose**: Test individual functions/methods in isolation

**When to Use**:
- Testing pure functions
- Testing business logic
- Testing edge cases

### Integration Tests
**Purpose**: Test how components work together

**When to Use**:
- Testing API endpoints
- Testing database operations
- Testing service interactions

### End-to-End Tests
**Purpose**: Test complete user workflows

**When to Use**:
- Testing critical user paths
- Testing UI interactions
- Testing multi-step processes

---

## Test Structure

### Naming Convention
- **Test files**: `[name].test.ext` or `[name].spec.ext`
- **Test names**: Descriptive, behavior-focused

**Good Examples**:
```
test("returns 404 when user not found")
test("creates user with valid email")
```

**Bad Examples**:
```
test("test1")
test("userFunction")
```

### Arrange-Act-Assert Pattern
```
test("description", () => {
  // Arrange - Set up test data
  const input = { name: "Test" }

  // Act - Execute the code
  const result = processInput(input)

  // Assert - Verify the result
  expect(result).toBe(expected)
})
```

---

## Coverage Goals

### Target Coverage
- **Overall**: 80%+ recommended
- **Critical Paths**: 95%+ required
- **New Code**: 100% coverage for new features

### What to Cover

**High Priority**:
- Business logic
- Data validation
- API endpoints
- Authentication/authorization
- Data transformations

**Medium Priority**:
- UI components
- Helper functions
- Utilities

**Low Priority**:
- Configuration files
- Simple getters/setters
- Third-party integrations (mock instead)

---

## Best Practices

### Test Independence
- Tests should not depend on each other
- Each test should clean up after itself
- Use fresh data for each test

### Readable Assertions
```
// Good
expect(user.email).toBe("test@example.com")

// Better
expect(user).toMatchObject({
  email: "test@example.com",
  isActive: true
})
```

### Test Edge Cases
- Empty inputs
- Null/undefined
- Maximum values
- Invalid data
- Error conditions

### DRY (Don't Repeat Yourself)
- Extract common setup to `beforeEach`
- Use helper functions
- Share fixtures

---

## Common Patterns

### Testing Async Code
```
test("async operation", async () => {
  const result = await asyncFunction()
  expect(result).toBe(expected)
})
```

### Testing Errors
```
test("throws error for invalid input", () => {
  expect(() => {
    dangerousFunction()
  }).toThrow("Expected error message")
})
```

---

## Continuous Integration

### Pre-commit
Run quick tests locally before committing

### CI Pipeline
Full test suite runs on:
- Pull requests
- Merges to main
- Scheduled (nightly)

### Test Failure Policy
- ❌ Block merge if tests fail
- ❌ Block deployment if tests fail
- ✅ Fix immediately - don't let failures accumulate

---

## Test Smells to Avoid

🚨 **Watch out for**:
- Flaky tests (pass sometimes, fail others)
- Slow tests
- Tests testing implementation details
- Overly complex test setup
- Tests that don't actually test anything

---

**Project-Specific**: See `.agent/sops/testing.md` for:
- Test commands for your tech stack
- Framework-specific patterns
- Local testing setup

---

**Location**: `~/.claude/scaffolds/sops/testing-principles.md`
**Referenced By**: All projects via `.agent/sops/README.md`
**Last Updated**: 2025-10-25
