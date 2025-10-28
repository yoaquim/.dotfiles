---
description: Execute a single VK task by starting an attempt
argument-hint: <task-id>
allowed-tools: Read, Glob, Bash(ls*), AskUserQuestion, mcp__vibe_kanban__*
---

You are starting execution for a single VK task.

**What this does:**
1. Validates task exists and is ready
2. Checks dependencies (warns if blockers not done)
3. Starts task attempt via VK
4. Shows attempt details and status

**Use cases:**
- Test single task execution
- Manual control over specific tasks
- Execute high-priority task immediately
- Debug/troubleshoot specific task

---

## Prerequisites

**Check VK enabled:**
```bash
ls .agent/.vk-enabled 2>/dev/null
```

If not exists:
```
⚠️ VK workflow not enabled.

Run /vk-init first.
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

## Step 0: Get Task ID

**If user provided task ID:**
Use that.

**If NO task ID provided:**
```
❌ Task ID required.

Usage: /vk-execute <task-id>

To find task IDs:
- Run /vk-status (shows all tasks with IDs)
- Check VK UI
- Run /vk-start (shows ready tasks with IDs)

Example: /vk-execute abc123-def456-789
```

---

## Step 1: Validate Task

**Get VK project:**
```
mcp__vibe_kanban__list_projects
```

Identify `project_id`.

**Get task details:**
```
mcp__vibe_kanban__get_task task_id=<task-id>
```

**If task not found:**
```
❌ Task not found: <task-id>

Possible reasons:
- Task ID incorrect
- Task from different project
- Task was deleted

Run /vk-status to see all available tasks.
```

**Check task status:**

If status is `done`:
```
⚠️ Task already completed: <task-title>

Status: done

Run /vk-status to see pending tasks.
```

If status is `inprogress`:
```
⚠️ Task already running: <task-title>

Status: in progress
Attempt may be active.

Check VK UI for attempt details.

Continue anyway? (yes/no)
```

If status is `cancelled`:
```
⚠️ Task is cancelled: <task-title>

Status: cancelled

This task won't execute. Reactivate in VK UI if needed.
```

---

## Step 2: Check Dependencies

**Parse task description** for dependency metadata:

Look for:
```markdown
**Depends On**:
- [Epic Name] Task description (ID: xxx)
- [Epic Name] Another task (ID: yyy)
```

**If dependencies found:**

For each dependency task ID:
```
mcp__vibe_kanban__get_task task_id=<dependency-id>
```

Check status of each dependency.

**If any dependency NOT done:**
```
⚠️ DEPENDENCY WARNING

Task: <task-title>

This task depends on:
✅ [Epic A] Task 1 (done)
❌ [Epic B] Task 2 (todo) - NOT COMPLETE
❌ [Epic C] Task 3 (inprogress) - NOT COMPLETE

Starting this task may fail or have issues because dependencies aren't complete.

Options:
A) Start anyway (I know what I'm doing)
B) Wait for dependencies
C) Start dependencies first (run /vk-start for dependency tasks)
D) Cancel

Choose: (a/b/c/d)
```

Handle user choice.

**If all dependencies done:**
```
✅ All dependencies complete. Safe to start!
```

---

## Step 3: Show Task Details

```
📋 TASK EXECUTION

Task ID: <task-id>
Title: <task-title>
Feature: <feature-name>
Epic: <epic-name>
Status: todo
Points: 1

Dependencies: <N> tasks
✅ [Dependency 1] (done)
✅ [Dependency 2] (done)

---

## Task Objective

[From task description]

---

## What Will Happen

1. VK creates task attempt
2. VK spawns Claude Code instance
3. VK creates isolated git worktree
4. CC implements the task with full context
5. Attempt completes (success or failure)
6. VK merges or handles failure

---

Ready to start? (yes/no)
```

---

## Step 4: Start Task Attempt

**If user confirms:**

**Get git branch info:**
```bash
git branch --show-current
```

Use current branch as base (or default to `main`/`master`).

**Start the attempt:**

```
mcp__vibe_kanban__start_task_attempt
  task_id: <task-id>
  executor: "CLAUDE_CODE"
  base_branch: <current-branch-or-main>
```

**If successful:**
```
✅ TASK ATTEMPT STARTED

Task: <task-title>
Attempt ID: <attempt-id>
Executor: Claude Code
Base Branch: <branch>
Worktree: <worktree-path>

---

## Attempt Details

VK has:
- Created isolated git worktree
- Spawned Claude Code instance
- Provided full project context

CC is now implementing the task.

---

## Monitor Progress

Check VK UI for:
- Real-time logs
- CC actions
- Attempt status

Or run:
```bash
/vk-status
```

---

## When Complete

VK will:
- Mark task as done (if successful)
- Merge changes (if successful)
- Update task status
- Unblock dependent tasks

Then you can:
- Start next tasks (/vk-start)
- Check status (/vk-status)
- Review changes in VK UI
```

**If failed:**
```
❌ FAILED TO START ATTEMPT

Task: <task-title>
Error: <error-message>

Possible reasons:
- VK connection lost
- Invalid executor
- Git branch issues
- VK orchestration busy

Check:
1. VK is running
2. MCP connection active
3. Git repository healthy

Retry? (yes/no)
```

---

## Step 5: Report Completion

```
🚀 Task execution started successfully!

Task: <task-title>
Attempt: Running

Next steps:
1. Monitor in VK UI (see real-time progress)
2. Run /vk-status (check overall progress)
3. Wait for completion, then start more tasks

When this task completes:
- Run /vk-start to start newly-unblocked tasks
- Or /vk-execute <next-task-id> for specific task
```

---

## Error Handling

### Invalid Task ID Format

```
❌ Invalid task ID format: <input>

Task IDs are UUIDs like: abc123-def456-789012

Get task IDs from:
- /vk-status
- /vk-start (shows ready tasks)
- VK UI
```

### Multiple Attempts Warning

```
⚠️ This task already has attempt history.

Previous attempts:
- Attempt 1: Failed (2024-01-15)
- Attempt 2: Failed (2024-01-16)

This will create Attempt 3.

Review previous failures in VK UI before retrying.

Continue? (yes/no)
```

### Git Branch Mismatch

```
⚠️ Current branch: feature-x
  Base branch for task: main

This task was planned for 'main' branch, but you're on 'feature-x'.

Options:
A) Use 'feature-x' as base (may have conflicts)
B) Switch to 'main' first
C) Cancel

Choose: (a/b/c)
```

---

## Best Practices

### When to Use `/vk-execute`

✅ Testing single task execution
✅ High-priority urgent task
✅ Debugging specific task issues
✅ Manual control over execution order
✅ Running tasks with resolved dependencies

### When NOT to Use

❌ Starting many tasks (use `/vk-start` instead)
❌ Starting tasks with unmet dependencies (will likely fail)
❌ Batch execution (use `/vk-start --batch-size` instead)

### Pro Tips

💡 **Check dependencies first** - Saves failed attempts
💡 **Use /vk-status** - See all task IDs and statuses
💡 **Monitor in VK UI** - Real-time logs and progress
💡 **Let VK orchestrate** - /vk-start is usually better for multiple tasks

---

## Integration

**Before `/vk-execute`:**
- `/vk-plan` - Create tasks
- `/vk-prioritize` - Set dependencies (optional)

**After `/vk-execute`:**
- Monitor in VK UI or `/vk-status`
- Wait for completion
- Start next tasks with `/vk-start` or `/vk-execute`

**Alternative:**
Use `/vk-start` for automated batch execution instead of manual task-by-task.

---

## Example Session

```bash
# See all tasks
/vk-status

# Output shows:
# Ready: 5 tasks
# - [User Model] Create User model (ID: abc123)
# - [User Model] Create migrations (ID: def456)
# ...

# Execute specific task
/vk-execute abc123

# Claude validates, checks dependencies, starts attempt
# Monitor progress in VK UI

# When done, start next task
/vk-execute def456

# Or start all ready tasks
/vk-start
```

---

## Notes

**This starts ONE task only** - for batch execution, use `/vk-start`.

**VK manages the attempt** - Claude Code instance, worktree, execution all handled by VK.

**You just trigger it** - Everything else is automatic.

**Can be called repeatedly** - Start tasks one by one if you prefer manual control.

---

**Last Updated**: 2025-10-27
