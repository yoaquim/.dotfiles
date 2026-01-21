---
description: Test a completed task implementation with automated and manual verification
argument-hint: [task-number]
allowed-tools: Read, Bash(docker*), Bash(pytest*), Bash(npm*), Bash(git*), Bash(ls*), Grep, Glob
---

You are testing a completed task implementation.

**Parameter**: Task number (optional)
- If provided, test that specific task
- If not provided, test the most recently implemented task

---

## CRITICAL: Read These First

1. The task document (`.agent/tasks/XXX-*.md`) - Review success criteria
2. `.agent/sops/testing.md` - Testing guidelines (if exists)
3. The task's testing strategy section

---

## Testing Checklist

### 1. Automated Tests
```bash
# Run full test suite
docker compose exec web pytest

# Check coverage
docker compose exec web pytest --cov=apps --cov-report=term
```
- Check pass/fail counts
- Note coverage percentage
- All new code should have tests

### 2. Success Criteria Verification
- Review each item in task's Success Criteria section
- Test each criterion manually if needed
- Mark each as PASS or FAIL
- Document any failures

### 3. Files Verification
- Check that all files mentioned in "Files to Create/Modify" were handled
- Verify files exist and contain expected changes

### 4. Manual Testing
- Follow any manual testing steps from task
- Test the feature from user perspective
- Try edge cases and error conditions
- Verify UI/UX if applicable

### 5. Code Quality
- Check for console errors (if web feature)
- Verify logs look correct
- Test error handling

### 6. Git Workflow
- Verify feature branch exists
- Check commits are descriptive
- Ensure no stray files committed
- Confirm branch is up to date

### 7. Documentation
- Check if code has comments where needed
- Verify new functions/classes have docstrings

---

## Generate Test Report

```
TEST REPORT

Tests Passing: X/Y tests
Coverage: X%

Success Criteria:
- [PASS/FAIL] Criterion 1
- [PASS/FAIL] Criterion 2
- [PASS/FAIL] Criterion 3

Files: All expected files present? [Yes/No]

Manual Testing: Feature works as expected? [Yes/No]

Issues Found:
- [List any problems]

Notes:
- [Observations or recommendations]
```

---

## STOP HERE - DO NOT CONTINUE

**CRITICAL**: After testing is complete, you MUST:
1. **STOP** - Do not merge branches
2. **STOP** - Do not complete the task
3. **STOP** - Do not update final documentation
4. **STOP** - Do not mark task as complete
5. **WAIT** for the user to run `/workflow:complete-task` command

The user will explicitly run `/workflow:complete-task` when ready to finalize.

---

## If Issues Are Found

- Report issues clearly
- Provide specific commands for fixes
- WAIT for user decision on how to proceed

---

## Common Test Commands

```bash
# Run all tests
docker compose exec web pytest

# Run specific test file
docker compose exec web pytest apps/assets/tests/test_models.py

# Run with coverage
docker compose exec web pytest --cov=apps --cov-report=html

# Run single test
docker compose exec web pytest apps/assets/tests/test_models.py::TestModel::test_creation
```
