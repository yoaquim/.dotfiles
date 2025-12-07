Write unit tests to improve code coverage and ensure reliability.

## Unit Testing Checklist

### 1. Identify What to Test
- [ ] Run coverage report to find untested functions
- [ ] List the specific functions/methods to test
- [ ] Note current coverage percentage

### 2. Write Tests
- [ ] Test the happy path (expected behavior)
- [ ] Test edge cases (empty inputs, boundaries)
- [ ] Test error cases (invalid inputs, exceptions)
- [ ] Mock external dependencies
- [ ] Use descriptive test names

### 3. Test Quality
- [ ] Each test focuses on one behavior
- [ ] Tests can run independently
- [ ] No hardcoded values that might change
- [ ] Clear assertions that verify the behavior

## Examples to Cover:
- Normal inputs → Expected outputs
- Empty/null inputs → Proper handling
- Invalid inputs → Error cases
- Boundary values → Edge case behavior

## Goal
Achieve at least 80% coverage for the target component

## Deliverables
1. New test file(s) with comprehensive unit tests
2. Updated coverage report
3. All tests passing
