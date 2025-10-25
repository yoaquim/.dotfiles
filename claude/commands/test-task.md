You are testing a completed task implementation.

**Parameter**: Task number (optional)
- If provided, test that specific task
- If not provided, test the most recently implemented task

**CRITICAL: Read these first:**
1. The task document (`.agent/tasks/XX-*.md`) - Review success criteria
2. `.agent/sops/testing.md` - Testing guidelines (if exists)
3. The task's testing strategy section

**Testing checklist:**

1. **Automated Tests**
   - Run the full test suite: `docker compose exec web pytest`
   - Check test results (pass/fail counts)
   - Verify coverage: `docker compose exec web pytest --cov=apps --cov-report=term`
   - Note coverage percentage
   - All new code should have tests

2. **Success Criteria Verification**
   - Review each item in task's Success Criteria section
   - Test each criterion manually if needed
   - Mark each as ✅ or ❌
   - Document any failures

3. **Files Verification**
   - Check that all files mentioned in "Files to Create/Modify" were handled
   - Verify files exist and contain expected changes
   - Check for any missing files

4. **Manual Testing**
   - Follow any manual testing steps from task
   - Test the feature from user perspective
   - Try edge cases and error conditions
   - Verify UI/UX if applicable

5. **Code Quality**
   - Check for console errors (if web feature)
   - Verify logs look correct
   - Test error handling
   - Check responsive design (if UI feature)

6. **Git Workflow**
   - Verify feature branch exists
   - Check commits are descriptive
   - Ensure no stray files committed
   - Confirm branch is up to date

7. **Documentation**
   - Check if code has comments where needed
   - Verify any new functions/classes have docstrings
   - Ensure complex logic is explained

**Generate test report with:**
- ✅ **Tests Passing**: X/Y tests
- 📊 **Coverage**: X%
- ✅/❌ **Success Criteria**: List each criterion with status
- ✅/❌ **Files**: All expected files present?
- ✅/❌ **Manual Testing**: Feature works as expected?
- ⚠️ **Issues Found**: List any problems
- 📝 **Notes**: Any observations or recommendations

**After testing:**
- If all tests pass and criteria met → Report test results
- If issues found → Report issues and list specific problems

**🛑 STOP HERE - DO NOT CONTINUE 🛑**

**CRITICAL**: After testing is complete, you MUST:
1. **STOP** - Do not merge branches
2. **STOP** - Do not complete the task
3. **STOP** - Do not update final documentation
4. **STOP** - Do not mark task as complete
5. **WAIT** for the user to run `/complete-task XXX` command

The user will explicitly run `/complete-task XXX` when they are ready to finalize.

**If issues are found:**
- Report issues clearly
- Provide specific commands for fixes
- WAIT for user decision on how to proceed

**Common test commands:**
```bash
# Run all tests
docker compose exec web pytest

# Run specific test file
docker compose exec web pytest apps/assets/tests/test_models.py

# Run with coverage
docker compose exec web pytest --cov=apps --cov-report=html

# Run single test
docker compose exec web pytest apps/assets/tests/test_models.py::TestArtistModel::test_creation
```