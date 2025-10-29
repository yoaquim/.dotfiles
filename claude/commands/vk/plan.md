---
description: Create agile plan and VK tasks (flat structure with epic prefixes, all 1-point)
argument-hint: [feature description]
allowed-tools: Read, Write, Grep, Glob, AskUserQuestion, mcp__vibe_kanban__*
---

You are in PLAN MODE for VK-Claude Code workflow. Generate detailed implementation plan, break into 1-point tasks with epic prefixes, create in Vibe Kanban.

**VK Model (Flat Structure):**
- All tasks are VK Tasks (flat, independent)
- Use `[Epic Name]` prefix for grouping
- Each task is 1 point (1-2 hours)
- VK orchestrates execution (starts attempts when ready)

**CRITICAL RULES:**
1. **Every task MUST be 1 point** (1-2 hours of work)
2. **Auto-generate documentation tasks per epic**
3. **Auto-generate test tasks (TDD approach)**
4. **Use [Epic] prefix** for grouping related tasks

---

## Prerequisites

**Check VK workflow enabled:**

```bash
ls .agent/.vk-enabled 2>/dev/null
```

If not exists:
```
⚠️ VK workflow not enabled.

Run /vk:init first, or use /plan-task for standard workflow.
```

**Check VK connection:**
```
mcp__vibe_kanban__list_projects
```

If fails:
```
❌ Cannot connect to Vibe Kanban.

Please ensure:
1. VK MCP server is configured
2. VK is running
3. Connection is active
```

---

## Step 0: Determine Feature to Plan

**If user provided argument:**
- Use that as feature to plan
- Check for matching feature requirements in `.agent/features/`

**If NO argument:**
- Check `.agent/.last-feature` file
- Confirm with user

**Check for feature requirements:**
```bash
ls -la .agent/features/ 2>/dev/null
```

**If matching feature requirements found:**
- Read `.agent/features/<feature-name>.md` FIRST
- Use requirements as guide
- Ensure plan addresses all acceptance criteria

**If no feature requirements:**
```
⚠️ No feature requirements found for: [feature-name]

Would you like to:
A) Run /vk:feature first to define requirements
B) Continue with planning anyway (less structured)
C) Cancel

Choose: (A/B/C)
```

---

## Step 1: Read Context

**MUST read:**
1. `.agent/features/<feature-name>.md` - Feature requirements
2. `CLAUDE.md` - Core project instructions
3. `.agent/system/overview.md` - Current project state
4. `.agent/system/architecture.md` - Technical architecture
5. `~/.claude/workflow/sops/vk-integration.md` - VK workflow rules

**Get current VK project:**
```
mcp__vibe_kanban__list_projects
```

Identify `project_id` for current repo.

**Check existing tasks:**
```
mcp__vibe_kanban__list_tasks project_id=<project_id>
```

---

## Step 2: Generate Implementation Plan

### 2.1 Epic Identification

Break feature into **Epics** (logical functional areas):

**Example:**
```
Feature: "User Authentication"

Epics:
1. User Model & Database - Backend foundation
2. Registration API - User signup
3. Login & JWT Auth - Auth flow
4. Password Reset - Security feature
5. User Profile API - Profile management
```

### 2.2 Task Breakdown (1-POINT RULE)

For EACH epic, break into **1-point tasks**:

**A 1-point task:**
- Completable in 1-2 hours
- Single, focused objective
- Modifies 2-3 files max
- Testable independently
- No complex dependencies

**Task Naming: `[Epic Name] Task description`**

**Example:**
```
Epic: "User Model & Database"

Tasks (all 1-point):
- [User Model] Create User model with email/password fields
- [User Model] Create database migrations for User
- [User Model] Write User model unit tests
- [User Model] Update database schema docs
```

### 2.3 Pattern: Setup → Test → Implement → Test → Document

**For each epic:**

```
Epic: "Registration API"

Tasks (1-point each):
- [Registration] Build POST /register endpoint [1pt]
- [Registration] Add email validation logic [1pt]
- [Registration] Write registration endpoint tests [1pt]
- [Registration] Add password hashing (bcrypt) [1pt]
- [Registration] Write password security tests [1pt]
- [Registration] Update API documentation [1pt]
```

### 2.4 Auto-Generated Tasks

**For EVERY epic, automatically add:**

1. **Documentation Task** (last):
   - `[Epic Name] Update documentation`
   - Updates `.agent/system/*` based on epic work
   - Always 1 point

2. **Test Tasks** (throughout):
   - One test task per major implementation task
   - TDD-friendly (can come before or after)
   - Always 1 point each

### 2.5 Validation: 1-Point Check

**For each task, verify:**
- [ ] Completable in 1-2 hours?
- [ ] Single, clear objective?
- [ ] 2-3 files max?
- [ ] Testable independently?

**If NO to any, break down further.**

---

## Step 3: Present Plan

```
📋 VK TASK PLAN: [Feature Name]

Feature Requirements: .agent/features/[name].md
Complexity: [Simple/Medium/Complex]

---

## Epic 1: [Epic Name]
Value: [What this delivers]
Tasks: [N] tasks (all 1pt)

Tasks:
1. [Epic 1] Task description [1pt]
2. [Epic 1] Another task [1pt]
3. [Epic 1] Test task [1pt]
4. [Epic 1] Update documentation [1pt]

## Epic 2: [Epic Name]
Value: [What this delivers]
Tasks: [M] tasks (all 1pt)

Tasks:
1. [Epic 2] Task description [1pt]
2. [Epic 2] Another task [1pt]
...

---

## Summary

Total Epics: X
Total Tasks: Y (all 1-point, flat structure)
Estimated: Y * 1.5 hours = Z hours

**Task Structure:**
✅ Flat (all independent VK Tasks)
✅ Grouped by [Epic] prefix
✅ All 1-point (1-2 hours each)
✅ VK will orchestrate execution

---

Would you like to:
✅ CREATE - Create these tasks in Vibe Kanban
🔄 REVISE - Modify the plan
❌ CANCEL - Don't create tasks

Choose: (create/revise/cancel)
```

---

## Step 4: Handle User Response

### If REVISE:
Ask for feedback, regenerate, show updated plan.

### If CANCEL:
Exit.

### If CREATE:
Proceed to create VK tasks.

---

## Step 5: Create VK Tasks (Flat Structure)

**Get project_id:**
```
mcp__vibe_kanban__list_projects
```

**For each 1-point task:**

```
mcp__vibe_kanban__create_task
  project_id: <project_id>
  title: "[Epic Name] Task description"
  description: "[Detailed task description]"
```

**Task Description Template:**

```markdown
**Feature**: [feature-name] (.agent/features/[feature-name].md)
**Epic**: [Epic Name]
**Points**: 1
**Wave**: (Set by /vk:prioritize)
**Depends On**:
(Set by /vk:prioritize - initially empty)

---

# [Epic Name] Task description

## Objective

[Clear, focused objective - single responsibility]

---

## Context

**From Feature Requirements:**
[Relevant context from feature doc]

**Related User Story:**
"As a [role], I want to [action], so that [benefit]"

---

## Implementation Details

**What to create/modify:**
- File 1: [path] - [What changes]
- File 2: [path] - [What changes]

**Specific actions:**
1. [Action 1]
2. [Action 2]

---

## Success Criteria (EARS format)

WHEN [event]:
- THEN [expected behavior]

[From feature requirements]

---

## Related Tasks

**Same Epic:**
- [Epic Name] Other task 1
- [Epic Name] Other task 2

[Link related tasks for context]

---

## Resources

- Feature Requirements: .agent/features/[name].md
- Architecture: .agent/system/architecture.md
- Available commands: ~/.claude/commands/
- SOPs: ~/.claude/workflow/sops/

---

## Notes

**Type**: [Implementation/Testing/Documentation]
**Epic Context:** [What epic this belongs to]
**Estimated Time:** 1-2 hours

This task will be started via /vk:execute or /vk:start.
During execution, VK spawns CC instance with full project context.
```

**Create all tasks:**

For each task in plan:
1. Format title with `[Epic]` prefix
2. Generate detailed description
3. Call `mcp__vibe_kanban__create_task`
4. Track created task IDs

---

## Step 6: Report Creation

```
✅ VK TASKS CREATED SUCCESSFULLY

🎯 Feature: [Feature Name]
📊 Task Structure: Flat (all independent)

---

## Created Tasks by Epic

### Epic 1: [Epic Name]
✅ [Epic 1] Task 1 (Task ID: xxx)
✅ [Epic 1] Task 2 (Task ID: xxx)
✅ [Epic 1] Task 3 (Task ID: xxx)
✅ [Epic 1] Update documentation (Task ID: xxx)

### Epic 2: [Epic Name]
✅ [Epic 2] Task 1 (Task ID: xxx)
✅ [Epic 2] Task 2 (Task ID: xxx)
...

---

## Summary

✅ Total Tasks Created: Y
✅ All tasks are 1-point (1-2 hours each)
✅ Grouped by [Epic] prefix for organization
✅ All tasks in VK backlog (not started yet)

---

## Task Structure

**Flat Model:**
- All Y tasks are independent VK Tasks
- No hierarchy (VK's model)
- Grouped by naming: [Epic] prefix
- VK can execute in any order (respecting dependencies you set in VK)

**1-Point Rule:**
✅ Every task validated as 1-point
✅ Focused, completable work units
✅ Parallel execution ready

---

## Next Steps

### 1. Review in Vibe Kanban
- Open VK interface
- See all Y tasks in backlog
- Review task descriptions

### 2. Prioritize Tasks (RECOMMENDED)

**Set dependencies and execution order:**
```bash
/vk:prioritize
```

This will:
- Analyze logical dependencies
- Build execution waves
- Update task descriptions with dependency metadata
- Prepare for execution

### 3. Start Execution

**Option A: Start all ready tasks**
```bash
/vk:start              # One-shot: start ready tasks, exit
/vk:start --watch      # Continuous: auto-start as tasks complete
```

**Option B: Start specific task**
```bash
/vk:execute <task-id>  # Manual single-task execution
```

**Option C: Limit concurrency**
```bash
/vk:start --batch-size=5      # Start 5 at a time
/vk:start --feature="name"    # Only start specific feature
```

### 4. Monitor Progress

```bash
/vk:status
```

Shows:
- Tasks ready (can start now)
- Tasks blocked (waiting on dependencies)
- Tasks in progress (Attempts running)
- Tasks completed
- Overall progress

---

## Understanding VK Execution Model

**Planning (this command):**
- Creates **Tasks** in VK backlog
- Tasks are not started yet
- Just planning artifacts

**Prioritization (/vk:prioritize):**
- Analyzes dependencies
- Sets execution order
- Updates task metadata

**Execution (/vk:start or /vk:execute):**
- You trigger execution via commands
- VK starts **Attempt** for each Task
- Attempt = Execution instance (spawns CC, creates git worktree)
- CC implements the task
- Attempt completes or fails
- VK marks task done, unblocks dependent tasks

**You control when tasks start** - via /vk:start or /vk:execute.

**VK handles execution** - spawning instances, worktrees, parallelization.

---

## Pro Tips

💡 **Use VK UI** to:
- Prioritize tasks
- Set dependencies
- Track progress
- Review results

💡 **[Epic] Prefixes** help:
- Group related work visually
- Filter tasks by epic
- Understand context

💡 **1-Point Tasks** enable:
- True parallelization
- Faster completion
- Clear progress visibility

---

## Files Updated

- `.agent/.last-feature` - Tracked for this feature
- VK Project - Y tasks created (all in backlog)

---

**Ready to execute!**

Next: /vk:prioritize (set dependencies) then /vk:start (begin execution)
```

---

## Error Handling

### VK Connection Failed

```
❌ Cannot connect to Vibe Kanban

Cannot proceed without VK connection.
Check VK is running and MCP configured.
```

### Task Creation Failed

```
⚠️ Task creation failed for: [task name]

Error: [error message]

Partial tasks may have been created.
Check VK to see what exists.

Retry? (yes/no)
```

---

## Best Practices

### Epic Design
✅ 3-8 epics per feature
✅ Each epic delivers specific value
✅ Logical grouping of related work

### Task Design (1-Point Rule)
✅ Always 1 point
✅ Single responsibility
✅ Clear `[Epic]` prefix
✅ Testable independently

### Naming Convention
✅ `[Epic Name] Task description`
✅ Descriptive, clear
✅ Use same epic name consistently

### Task Descriptions
✅ Link to feature requirements
✅ Include success criteria (EARS format)
✅ Reference available tools
✅ List related tasks (same epic)

---

## The 1-Point Rule

**Benefits:**
1. **VK Execution**: Each task = one Attempt, completable
2. **Parallelization**: VK can run multiple tasks simultaneously
3. **Progress**: Clear, granular tracking
4. **Isolation**: Each task in own git worktree

**If task estimates >1 point, break it down.**

---

## Integration

**Before `/vk:plan`:**
- `/vk:feature` - Define requirements

**After `/vk:plan`:**
- `/vk:prioritize` - Set dependencies and execution order (recommended)
- `/vk:start` - Begin task execution
- `/vk:execute` - Execute specific tasks manually
- `/vk:status` - Monitor progress
- `/vk:sync-docs` - Sync docs if needed

---

## Advanced: Complex Features

If feature generates 50+ tasks:

```
⚠️ This feature appears very complex.

Estimated: X epics, Y tasks

Recommendation: Break into phases.

Options:
B) Break into Feature Phase 1, Phase 2, etc.

Choose: (continue/phase/cancel)
```

If phase chosen, help user break into manageable chunks.
