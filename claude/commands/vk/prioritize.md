---
description: Prioritize VK tasks and build dependency graph for execution
allowed-tools: Read, Glob, Bash(ls*), AskUserQuestion, mcp__vibe_kanban__*
---

You are setting up task prioritization and dependencies for VK-Claude workflow.

**What this does:**
1. Lists all pending VK tasks
2. Analyzes logical dependencies (database before API, tests after implementation)
3. Semi-interactive: proposes priorities, asks clarifying questions
4. Builds dependency graph
5. Updates task descriptions with dependency metadata
6. Outputs clear execution plan (Wave 1, Wave 2, Wave 3...)

**VK Limitation:** VK tasks have no native dependency fields. We store dependencies in task description metadata.

---

## Prerequisites

**Check VK enabled:**
```bash
ls .agent/.vk-enabled 2>/dev/null
```

If not exists:
```
⚠️ VK workflow not enabled.

Run /vk:init first.
```

**Check VK connection:**
```
mcp__vibe_kanban__list_projects
```

If fails:
```
❌ Cannot connect to Vibe Kanban.

Ensure VK is running and MCP server configured.
```

---

## Step 1: Get All Pending Tasks

**Get current VK project:**
```
mcp__vibe_kanban__list_projects
```

Identify `project_id` for current repo.

**Get all pending tasks:**
```
mcp__vibe_kanban__list_tasks project_id=<project_id> status=todo
```

**If no tasks:**
```
✅ No pending tasks to prioritize.

All tasks are either in progress or completed.

Run /vk:status to see current state.
```

---

## Step 2: Group and Analyze Tasks

**Read feature documents:**
```bash
ls -la .agent/features/ 2>/dev/null
```

For each feature, read `.agent/features/<name>.md` to understand context.

**Group tasks by:**
1. **Feature** (extract from task description if present)
2. **Epic** (extract from `[Epic Name]` prefix)
3. **Type** (implementation, testing, documentation)

**Analyze logical dependencies:**

Common patterns:
- **Database tasks** → Must come before API tasks
- **Model creation** → Before endpoints using that model
- **Implementation** → Before tests for that implementation
- **Core features** → Before dependent features
- **Setup/config** → Before usage

**Build initial dependency graph.**

---

## Step 3: Present Initial Analysis

```
📋 TASK PRIORITIZATION ANALYSIS

Total pending tasks: X
Features: Y
Epics: Z

---

## Grouped by Feature

### Feature: User Authentication
(.agent/features/user-authentication.md)

Epic: User Model & Database
- [User Model] Create User model with email/password fields
- [User Model] Create database migrations for User
- [User Model] Write User model unit tests
- [User Model] Update documentation

Epic: Registration API
- [Registration] Build POST /register endpoint
- [Registration] Add email validation logic
- [Registration] Write registration tests
- [Registration] Update API documentation

### Feature: [Another Feature]
...

---

## Proposed Dependency Order

**Wave 1: Foundation** (No dependencies)
- [User Model] Create User model with email/password fields
- [User Model] Create database migrations for User
- [Another Feature] Setup task

**Wave 2: Core Implementation** (Depends on Wave 1)
- [User Model] Write User model unit tests
- [Registration] Build POST /register endpoint

**Wave 3: Advanced Features** (Depends on Wave 2)
- [Registration] Add email validation logic
- [Registration] Write registration tests

**Wave 4: Documentation** (Depends on Wave 3)
- [User Model] Update documentation
- [Registration] Update API documentation

---

This is my proposed order based on:
- Database/models before APIs
- Implementation before tests
- Tests before documentation
- Logical feature dependencies

Does this order make sense? (yes/no/adjust)
```

---

## Step 4: Semi-Interactive Refinement

**If user says "adjust" or has questions:**

Ask targeted questions:
```
🔍 Let's refine the execution order.

Q1: Should all database tasks complete before ANY API tasks start?
   A) Yes - safer, sequential (Wave 1: DB, Wave 2: API)
   B) No - can overlap (parallel where possible)

Q2: Should tests run immediately after each implementation?
   A) Yes - TDD approach (implementation → test → next)
   B) No - all implementation first, then tests

Q3: Any specific tasks that MUST go first?
   (Enter task numbers or "none")

Q4: Any tasks that can only run after specific others complete?
   (e.g., "Task 5 needs Task 2" or "none")
```

**Process user responses and rebuild dependency graph.**

---

## Step 5: Build Dependency Graph

**For each task, determine:**
- **Dependencies**: Which tasks must complete first
- **Wave number**: Execution priority level
- **Rationale**: Why this order

**Dependency resolution:**
```
Task A has no dependencies → Wave 1
Task B depends on Task A → Wave 2
Task C depends on Task B → Wave 3
Task D depends on Task A (not B) → Wave 2
```

**Topological sort** to ensure:
- No circular dependencies
- Optimal parallelization within waves
- Clear execution path

---

## Step 6: Update Task Descriptions

**For each task:**

Read current description:
```
mcp__vibe_kanban__get_task task_id=<task_id>
```

**Update with dependency metadata:**

```
mcp__vibe_kanban__update_task
  task_id: <task_id>
  description: [Enhanced description with metadata]
```

**Enhanced description template:**

```markdown
**Feature**: user-authentication (.agent/features/user-authentication.md)
**Epic**: User Model & Database
**Points**: 1
**Wave**: 1
**Depends On**:
- [User Model] Create User model (ID: abc123) - Must complete first
- [Database] Run migrations (ID: def456) - Must complete first

---

## Objective

[Original task objective]

---

## Context

[Original context]

---

## Success Criteria

[Original criteria]

---

## Dependency Rationale

This task depends on:
1. User model creation (need model definition)
2. Database migrations (need schema in place)

This task unblocks:
- [Registration] Build POST /register endpoint
- [User Model] Write User model unit tests
```

**Update ALL tasks with:**
- Feature link
- Wave number
- Dependencies (task IDs)
- Rationale

---

## Step 7: Output Final Execution Plan

```
✅ TASK PRIORITIZATION COMPLETE

---

## Execution Plan

**Total Tasks**: X
**Total Waves**: Y
**Estimated Sequential Time**: Z hours
**Parallel Execution**: Much faster! (VK handles concurrency)

---

## Wave 1: Foundation (N tasks)
**Can start immediately** - No dependencies

- [User Model] Create User model with email/password fields (ID: abc123)
- [User Model] Create database migrations for User (ID: def456)
- [Another Feature] Setup task (ID: ghi789)

**Rationale**: Database foundation must exist before API development

---

## Wave 2: Core Implementation (M tasks)
**Starts when Wave 1 completes**

Depends on: Wave 1 tasks

- [User Model] Write User model unit tests (ID: jkl012)
  → Needs: abc123 (User model must exist)
- [Registration] Build POST /register endpoint (ID: mno345)
  → Needs: abc123, def456 (Model + migrations)

**Rationale**: Implementation builds on foundation

---

## Wave 3: Advanced Features (P tasks)
**Starts when Wave 2 completes**

Depends on: Wave 2 tasks

- [Registration] Add email validation logic (ID: pqr678)
  → Needs: mno345 (Endpoint must exist)
- [Registration] Write registration tests (ID: stu901)
  → Needs: mno345, pqr678 (Implementation complete)

**Rationale**: Advanced features build on core implementation

---

## Wave 4: Documentation (Q tasks)
**Starts when Wave 3 completes**

Depends on: All implementation complete

- [User Model] Update documentation (ID: vwx234)
- [Registration] Update API documentation (ID: yzab567)

**Rationale**: Document final implementation

---

## Dependency Summary

**Tasks with NO dependencies**: N (can start immediately)
**Tasks with dependencies**: M
**Maximum parallel tasks per wave**:
- Wave 1: N tasks
- Wave 2: M tasks
- Wave 3: P tasks
- Wave 4: Q tasks

---

## Next Steps

**To start execution:**

```bash
# Option 1: Start all ready tasks, then call again for next wave
/vk:start

# Option 2: Continuous - auto-start as tasks complete
/vk:start --watch

# Option 3: Start specific feature only
/vk:start --feature="user-authentication"

# Option 4: Limit concurrency (5 tasks at a time)
/vk:start --batch-size=5

# Option 5: Start single task manually
/vk:execute <task-id>
```

**To monitor:**
```bash
/vk:status
```

---

## Files Updated

All X task descriptions updated with:
- Feature links
- Wave assignments
- Dependency metadata
- Execution rationale

Ready to execute! 🚀
```

---

## Error Handling

### Circular Dependencies Detected

```
❌ CIRCULAR DEPENDENCY DETECTED

Task A → depends on → Task B
Task B → depends on → Task C
Task C → depends on → Task A

This creates an infinite loop!

Please review these tasks and adjust dependencies:
- [Epic A] Task description (ID: xxx)
- [Epic B] Task description (ID: yyy)
- [Epic C] Task description (ID: zzz)

Which dependency should be removed? (a→b / b→c / c→a)
```

### VK Connection Lost

```
❌ Lost connection while updating tasks.

Progress: X/Y tasks updated

You can:
- Retry from where it stopped (yes/no)
- Review already-updated tasks in VK
```

### No Logical Dependencies

```
✅ All tasks appear independent (no obvious dependencies).

Options:
A) Assign waves by feature (group related work)
B) Assign waves by type (all DB, then API, then tests)
C) Leave all at same priority (start everything)
D) Manual: I'll ask you about specific task order

Choose: (a/b/c/d)
```

---

## Best Practices

### Good Dependencies
✅ Database migrations before API endpoints
✅ Model creation before model tests
✅ Implementation before testing
✅ Core features before dependent features
✅ Setup before usage

### Avoid Over-Constraining
❌ Don't make everything sequential if tasks can run parallel
❌ Don't create dependencies for unrelated features
❌ Don't block documentation on ALL tasks (can document per epic)

### Balance
- **Too many dependencies**: Kills parallelization, slow execution
- **Too few dependencies**: Risk of failures (running tests before code exists)
- **Just right**: Logical dependencies only, max parallelization

---

## Notes

**This command doesn't start tasks** - it only sets up the execution order.

After prioritization, use `/vk:start` to begin execution.

**Dependencies are stored in task descriptions** - VK has no native dependency support via MCP.

**Can re-run anytime** to adjust priorities or dependencies.

---

**Last Updated**: 2025-10-27
