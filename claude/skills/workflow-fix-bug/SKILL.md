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
- Fast turnaround

**Bug Task (Complex bugs):**
- Analyzes → Confirms → Creates task document
- Then offers: **A)** Fix it now **B)** Let user use `/workflow:implement-task` **C)** Document only

---

## Step 1: Read Current State

**Read these first:**
1. `CLAUDE.md` (project root) - Core instructions
2. `.agent/README.md` - Documentation index
3. `.agent/tasks/` - Check most recent tasks
4. Git status - What branch are we on?

---

## Step 1.5: Search for Similar Issues

**Search known-issues across ALL projects** to see if this bug has been encountered before.

```
CROSS-PROJECT SEARCH RESULTS

Found [N] similar issues in other projects:
- [Project name]: .agent/known-issues/NN-issue-name.md
  - Similar problem: [brief description]
  - Solution: [what worked]
  - Applicable: Yes/No/Partially

[Or]
No similar issues found in other projects.
```

---

## Step 2: Analyze Bug Complexity

**Simple Bug Indicators:**
- Typo or minor text issue
- Missing import or syntax error
- Simple logic error with clear fix
- UI styling issue
- Can be fixed in < 30 minutes
- Fix is obvious from description

**Complex Bug Indicators:**
- Data integrity issues
- Multiple files/components affected
- Requires debugging/investigation
- Performance problem
- Security vulnerability
- Race condition
- Unclear root cause
- Will take > 30 minutes

---

## Step 3: Suggest Approach

```
BUG ANALYSIS

Description: [Summarize]
Location: [File/function if provided]
Impact: [Low/Medium/High]

COMPLEXITY ASSESSMENT: [Simple/Complex]

Reasoning:
- [Why simple or complex]

RECOMMENDED APPROACH: [Quick Hotfix / Bug Task]

Proceed? (yes/no/switch)
```

---

## Step 4A: Quick Hotfix Workflow

**Execute this entire workflow in one go:**

### 1. Check Recent Task Context
Check if bug is related to recently completed task.

### 2. Create Hotfix Branch
```bash
git checkout main
git pull origin main
git checkout -b fix/brief-bug-name
```

### 3. Implement Fix
- Read the file(s)
- Understand the issue
- Implement the fix
- Keep changes minimal

### 4. Test the Fix
```bash
docker compose exec web pytest [relevant-test-path]
```

### 5. Commit Fix
```bash
git add [files]
git commit -m "Fix: [description]"
```

### 6. Update Documentation (If Needed)
If bug was in recently completed task, add note to task's Implementation Summary.

### 7. Merge and Cleanup
```bash
git checkout main
git merge fix/brief-bug-name
git push origin main
git branch -d fix/brief-bug-name
```

### 8. Report Results
```
BUG FIXED (Quick Hotfix)

Bug: [description]
Fix: [what was changed]
Location: [files modified]
Branch: fix/brief-bug-name
Commit: [hash]

Tests: [X/Y passing]
Manual verification: [Yes]

The fix is now merged to main.
```

**The bug is completely fixed. No further commands needed.**

---

## Step 4B: Bug Task Workflow

### 1. Create Bug Task Document
`.agent/tasks/XXX-fix-bug-name.md`

### 2. Update Documentation Index
Add to `.agent/README.md`.

### 3. Offer Options
```
BUG TASK CREATED: Task XXX

Would you like me to:
A) Start now (I'll follow the task plan and fix it)
B) You'll handle it with /workflow:implement-task XXX
C) Just document for now, fix later

Choose: (A/B/C)
```

### 4. If User Chooses A
Execute the full bug task workflow directly - fix, test, commit, merge, update docs.

### 5. If User Chooses B
Hand off to slash commands:
```
/workflow:implement-task XXX
/workflow:test-task XXX
/workflow:complete-task XXX
```

---

## Special Cases

### Bug During Task Implementation
If currently implementing a task, ask whether to:
- Fix as part of current task
- Create separate hotfix branch
- Note bug and fix after completing task

### Critical/Urgent Bug
Fast-track approach:
1. Immediate hotfix branch
2. Fix bug
3. Test critical path only
4. Emergency merge
5. Full testing after

---

## Best Practices

1. **Always test before merging**
2. **Keep fixes focused** - Don't bundle changes
3. **Update docs for related tasks**
4. **Use descriptive commit messages** - "Fix: [specific issue]"
5. **Don't skip investigation**
6. **Test for regressions**
7. **Document root cause**
