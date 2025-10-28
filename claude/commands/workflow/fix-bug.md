---
description: Intelligently fix bugs with quick hotfix or full bug task workflow
argument-hint: <bug description>
allowed-tools: Read, Edit, Write, Bash(git*), Bash(docker*), Bash(pytest*), Bash(npm*), Bash(find*), Bash(ls*), Grep, Glob
---

You are fixing a bug. This command intelligently routes between quick hotfixes and full bug task workflow based on complexity.

**How this command works:**

**Quick Hotfix (Simple bugs):**
- Analyzes → Confirms → **Fixes it completely in one execution**
- No separate commands needed
- Fast turnaround (minutes)

**Bug Task (Complex bugs):**
- Analyzes → Confirms → Creates task document
- Then offers: **A)** Fix it now (executes full workflow) **B)** Let user use `/implement-task XX` **C)** Document only
- If user chooses A, executes the entire bug fix workflow
- If user chooses B, hands off to other slash commands

**User provides:**
- Bug description (what's wrong, where it is, any error messages)
- Location (file, function, line number if known)
- Context (when discovered, impact, urgency)

## Step 1: Read Current State

**Read these first:**
1. `CLAUDE.md` (project root) - Core instructions
2. `.agent/README.md` - Documentation index
3. `.agent/tasks/` - Check most recent tasks (especially just completed ones)
4. Git status - What branch are we on? Any uncommitted changes?

## Step 1.5: Search for Similar Issues

**Search known-issues across ALL projects** to see if this bug has been encountered before using relevant keywords from the bug description (e.g., "timezone", "upload", "database").

**If similar issue found:**
- Read the documented solution
- Check if it applies to current bug
- Adapt the fix if needed
- Reference the original issue in your documentation

**Report findings:**
```
🔍 CROSS-PROJECT SEARCH RESULTS

Found [N] similar issues in other projects:
- [Project name]: .agent/known-issues/NN-issue-name.md
  - Similar problem: [brief description]
  - Solution: [what worked]
  - Applicable: Yes/No/Partially

[Or]
No similar issues found in other projects.
```

## Step 2: Analyze Bug Complexity

Based on the bug description, assess:

**Simple Bug Indicators:**
- Typo or minor text issue
- Missing import or small syntax error
- Simple logic error with clear fix
- UI styling issue
- Broken link or reference
- Small configuration error
- Can be fixed in < 30 minutes
- Doesn't require investigation
- Fix is obvious from description

**Complex Bug Indicators:**
- Data integrity issues
- Multiple files/components affected
- Requires debugging/investigation
- Performance problem
- Security vulnerability
- Race condition or timing issue
- Unclear root cause
- Affects multiple features
- Needs testing across scenarios
- Will take > 30 minutes

## Step 3: Suggest Approach

After analyzing, present assessment:

```
🔍 BUG ANALYSIS

Description: [Summarize what user described]
Location: [File/function if provided]
Impact: [Low/Medium/High based on description]

COMPLEXITY ASSESSMENT: [Simple/Complex]

Reasoning:
- [Why you think it's simple or complex]
- [Key factors from description]

RECOMMENDED APPROACH: [Quick Hotfix / Bug Task]

[If Simple]
This looks like a quick fix. I'll:
1. Create hotfix branch (fix/bug-name)
2. Fix the issue
3. Test the fix
4. Update relevant docs if needed
5. Merge and cleanup

[If Complex]
This requires investigation. I'll:
1. Create bug task document
2. Follow full task workflow
3. Investigate root cause
4. Implement comprehensive fix
5. Test thoroughly
6. Document findings

Proceed with [approach]? (yes/no/switch)
```

## Step 4A: Quick Hotfix Workflow

**If user confirms simple/quick approach:**

**IMPORTANT: Execute this entire workflow in one go. Do NOT stop and ask for other slash commands.**

This is a shortcut - fix it directly without breaking into separate commands.

### 1. Check Recent Task Context

Check if bug is related to recently completed task:
```bash
# Look at last 3 tasks
ls -lt .agent/tasks/*.md | head -3
```

If related to task completed < 1 week ago, note it.

### 2. Create Hotfix Branch

```bash
git checkout main
git pull origin main
git checkout -b fix/brief-bug-name
```

Branch naming:
- `fix/typo-in-header`
- `fix/broken-asset-link`
- `fix/missing-import`

### 3. Implement Fix

- Read the file(s) mentioned
- Understand the issue
- Implement the fix
- Keep changes minimal and focused
- Add comments if fix isn't obvious

### 4. Test the Fix

**Automated tests:**
```bash
# Run relevant tests
docker compose exec web pytest [relevant-test-path]

# Or run all tests if uncertain
docker compose exec web pytest
```

**Manual verification:**
- Test the specific functionality
- Verify no regressions
- Check error is resolved

### 5. Commit Fix

```bash
git add [files]
git commit -m "Fix: [brief description of bug and solution]"
```

Example commit messages:
- "Fix: Typo in navigation header text"
- "Fix: Missing import causing asset upload failure"
- "Fix: Broken link in documentation"

### 6. Update Documentation (If Needed)

**If bug was in recently completed task:**
- Add note to task's Implementation Summary
- Document the fix and when it was applied
- Note commit hash

**If bug is in older code:**
- Usually no doc updates needed for simple fixes
- Unless it affects architecture or system docs

**If bug was encountered elsewhere:**
- Reference similar known-issues from cross-project search
- Note if applying solution from another project

### 7. Merge and Cleanup

```bash
git checkout main
git merge fix/brief-bug-name
git push origin main
git branch -d fix/brief-bug-name
```

### 8. Report Results

```
✅ BUG FIXED (Quick Hotfix)

Bug: [description]
Fix: [what was changed]
Location: [files modified]
Branch: fix/brief-bug-name
Commit: [hash]

Tests: [X/Y passing]
Manual verification: ✅

[If related to recent task]
Updated task documentation: .agent/tasks/XXX-task-name.md

[If similar issue found in other projects]
Referenced solution from: [project-name]/.agent/known-issues/NN-issue.md

The fix is now merged to main and the hotfix branch has been cleaned up.

Next: Continue with your work, or check /status
```

**The bug is completely fixed. No further commands needed.**

## Step 4B: Bug Task Workflow

**If user confirms complex approach:**

### 1. Create Bug Task Document

Find next task number and create:
`.agent/tasks/XXX-fix-bug-name.md`

**Note**: Tasks use 3-digit numbering (000-999)

Use this structure:

```markdown
# Task XXX: Fix [Bug Name]

**Status**: 🔄 In Progress
**Branch**: `fix/bug-name`
**Priority**: [High/Medium/Low based on impact]
**Type**: Bug Fix
**Reported**: [Today's date]

## Cross-Project Search Results

**Similar issues found**: [Y/N]
[If yes, list similar issues from other projects with brief summary]

## Problem

**Bug Description:**
[User's description]

**Location:**
[Files/functions affected]

**Error/Symptoms:**
[Error messages, incorrect behavior]

**Impact:**
[Who/what is affected]

**When Discovered:**
[Context of discovery]

## Investigation Needed

- [ ] Reproduce the bug consistently
- [ ] Identify root cause
- [ ] Determine scope of impact
- [ ] Check for related issues
- [ ] Review relevant code/tests

## Solution

[To be filled after investigation]

## Implementation Plan

### Phase 1: Investigation
1. Reproduce bug in development
2. Add test case that fails (demonstrates bug)
3. Debug and identify root cause
4. Document findings

### Phase 2: Fix Implementation
1. Implement fix based on root cause
2. Ensure test case now passes
3. Check for edge cases
4. Verify no regressions

### Phase 3: Testing
1. Run full test suite
2. Manual testing of affected features
3. Test edge cases
4. Verify fix in different scenarios

### Phase 4: Documentation
1. Update task with solution details
2. Update relevant System docs if needed
3. Add comments explaining fix
4. Update README if user-facing

## Success Criteria

- [ ] Bug reproduced and understood
- [ ] Root cause identified
- [ ] Fix implemented
- [ ] Test case added/updated
- [ ] All tests passing
- [ ] No regressions introduced
- [ ] Code reviewed (if applicable)
- [ ] Documentation updated

## Technical Details

**Files Affected:**
[List]

**Root Cause:**
[To be determined]

**Fix Approach:**
[To be determined]

## Testing Strategy

**Test Cases:**
- [ ] Test case that reproduces bug
- [ ] Edge case tests
- [ ] Regression tests for related functionality

**Manual Testing:**
- [ ] [Scenario 1]
- [ ] [Scenario 2]

## Related Issues

[Any related bugs or features]

## Git Workflow

```bash
git checkout -b fix/bug-name
# Investigation and implementation
git commit -m "Fix: [description]"
git checkout main
git merge fix/bug-name
git branch -d fix/bug-name
```
```

### 2. Update Documentation Index

Add to `.agent/README.md`:
```markdown
- [XXX - Fix Bug Name](./tasks/XXX-fix-bug-name.md) - 🔄 Bug fix (In Progress)
```

### 3. Start Investigation

```
✅ BUG TASK CREATED: Task XXX

📄 Task Document: .agent/tasks/XXX-fix-bug-name.md
📋 Status: In Progress

[If similar issues found]
🔍 Found similar issues in other projects - solutions referenced in task doc

Ready to begin investigation and implementation.

Would you like me to:
A) Start now (I'll follow the task plan and fix it)
B) You'll handle it with /implement-task XXX (manual control)
C) Just document for now, fix later

Choose: (A/B/C)
```

### 4. If User Chooses A - Proceed with Implementation

**Execute the bug task workflow directly:**
- Create fix branch
- Follow the task's investigation and implementation plan
- Fix the bug
- Test thoroughly
- Commit and merge
- Update task documentation to ✅ Complete
- Update .agent/README.md
- Report completion

**This is the full workflow, done in one command execution.**

After completion, report:
```
✅ BUG FIXED (Bug Task)

Task: XXX - Fix [bug name]
Status: Complete ✅

Investigation findings: [summary]
Root cause: [what caused it]
Fix: [what was implemented]
Tests: [X/Y passing]
Coverage: [X%]

Files modified: [list]
Branch: fix/bug-name (merged and deleted)
Documentation updated: ✅

Task file: .agent/tasks/XXX-fix-bug-name.md

[If similar issue found]
Referenced solution from: [project-name]/.agent/known-issues/NN-issue.md

The bug is completely fixed and documented.
```

**The bug is fixed. No further commands needed.**

### 4. If User Chooses B - Hand Off to Slash Commands

```
Task documented. Run these commands when ready:

/implement-task XXX  # To investigate and fix
/test-task XXX       # To test the fix
/complete-task XXX   # To finalize

Task file: .agent/tasks/XXX-fix-bug-name.md
```

**User takes control from here.**

## Step 5: Handle User Override

If user says "no" or "switch":

```
Would you like to:
A) Switch to [other approach]
B) Provide more details about the bug
C) Cancel and handle manually
```

## Special Cases

### Bug During Task Implementation

If user is currently implementing a task (status 🔄):

```
⚠️ NOTE: You're currently implementing Task XXX.

Options:
A) Fix bug now as part of current task (recommended)
B) Create separate hotfix branch
C) Note bug and fix after completing task

Which approach? (A/B/C)
```

### Critical/Urgent Bug

If description indicates urgency (production down, data loss, security):

```
🚨 CRITICAL BUG DETECTED

This appears urgent based on: [reason]

Fast-track approach:
1. Immediate hotfix branch
2. Fix bug
3. Test critical path only
4. Emergency merge
5. Full testing after

Proceed with fast-track? (yes/no)
```

### Bug in Recent Task

If bug found in task completed < 1 week ago:

```
📌 Related to recent task: Task XXX - [name]

I'll:
1. Fix bug with hotfix branch
2. Update Task XXX documentation with fix details
3. Note the bug and resolution in Implementation Summary

This keeps documentation accurate and helps track issues.
```

## Documentation Updates

### For Quick Hotfixes:

**If related to recent task:**
Add to task's Implementation Summary:
```markdown
### Post-Completion Fix

**Date**: [date]
**Bug**: [description]
**Fix**: [what was changed]
**Commit**: [hash]
```

**If not related to recent task:**
- Usually no doc updates needed
- Unless it affects architecture or configuration

### For Bug Tasks:

- Full task documentation with investigation findings
- Update System docs if bug revealed architectural issues
- Update SOPs if bug indicated process improvement needed

## Command Variations

User can provide varying levels of detail:

**Minimal:**
```
/fix-bug The upload button doesn't work
```

**Detailed:**
```
/fix-bug
File: apps/assets/views.py, line 45
Bug: Asset upload fails with 500 error when file > 10MB
Error: "Max upload size exceeded"
Context: Just noticed after completing Task 05
Impact: Users can't upload large files
Urgency: Medium (affects some users)
```

Adapt your analysis to the information provided. Ask for more details if needed.

## Best Practices

1. **Always test before merging** - Even "simple" fixes
2. **Keep fixes focused** - Don't bundle multiple changes
3. **Update docs for related tasks** - Maintain accuracy
4. **Use descriptive commit messages** - "Fix: [specific issue]"
5. **Don't skip investigation** - Even if fix seems obvious
6. **Test for regressions** - Bug fixes can break other things
7. **Document root cause** - Helps prevent similar bugs

## After Bug Fix

**For Quick Hotfixes and completed Bug Tasks:**

The bug is fixed and everything is done. Ask if user wants to:

```
Bug fixed successfully! ✅

Would you like to:
A) Check project status (/status)
B) Review documentation (/review-docs)
C) Plan next feature (/plan-task)
D) Continue with current work

Choose: (A/B/C/D) or just continue working
```

**For Bug Tasks where user chose option B (manual):**

The task is documented. They'll use other commands to complete it:
```
Task documented. Use these when ready:
/implement-task XX
/test-task XX
/complete-task XX
```

## Error Handling

If fix attempt fails:
```
⚠️ Fix attempt unsuccessful

Issue: [what went wrong]

Options:
A) Try different approach
B) Escalate to bug task (needs investigation)
C) Provide more context
D) Manual intervention needed

What would you like to do? (A/B/C/D)
```