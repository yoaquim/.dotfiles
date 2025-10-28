---
description: Smart VK task orchestration - start ready tasks with dependency awareness
argument-hint: [--watch] [--batch-size=N] [--feature=<name>] [--all]
allowed-tools: Read, Glob, Bash(ls*, git*), AskUserQuestion, mcp__vibe_kanban__*
---

You are orchestrating VK task execution with smart dependency management.

**What this does:**
1. Lists all pending tasks
2. Parses dependencies from task descriptions
3. Identifies tasks with all dependencies met
4. Starts ready tasks (respects batch size if set)
5. Optional: Watch mode - continuously monitors and starts newly-ready tasks

**Default behavior:** Start all dependency-ready tasks in one shot, then exit.

**Modes:**
- **One-shot** (default): Start ready tasks, exit
- **Watch** (`--watch`): Continuous monitoring, auto-start as tasks complete
- **Batch** (`--batch-size=N`): Limit concurrent tasks
- **Feature** (`--feature=<name>`): Only tasks for specific feature
- **All** (`--all`): Ignore dependencies, start everything

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

## Step 0: Parse Arguments

**Check for flags:**

```
--watch         → Enable continuous monitoring mode
--batch-size=N  → Limit to N concurrent tasks (default: 5 if used, unlimited if not)
--feature=<name> → Only start tasks for specific feature
--all           → Ignore dependencies, start all pending tasks
```

**Examples:**
```bash
/vk-start                           # Start all ready tasks, exit
/vk-start --watch                   # Continuous mode
/vk-start --batch-size=10           # Start 10 at a time
/vk-start --feature="user-auth"     # Only user-auth tasks
/vk-start --all                     # Start everything (ignore deps)
/vk-start --watch --batch-size=5    # Watch mode, 5 at a time
```

---

## Step 1: Get All Pending Tasks

**Get VK project:**
```
mcp__vibe_kanban__list_projects
```

Identify `project_id`.

**Get pending tasks:**
```
mcp__vibe_kanban__list_tasks project_id=<project_id> status=todo
```

**If no pending tasks:**
```
✅ No pending tasks to start.

All tasks are either:
- In progress
- In review
- Done
- Cancelled

Run /vk-status to see current state.
```

**Filter by feature if specified:**

If `--feature=<name>` flag present:
- Read each task description
- Check for `**Feature**: <name>`
- Keep only matching tasks

```
📋 Filtered to feature: <name>

Found X tasks for this feature out of Y total pending.
```

---

## Step 2: Build Dependency Graph

**For each pending task:**

1. Get task details:
   ```
   mcp__vibe_kanban__get_task task_id=<task-id>
   ```

2. Parse task description for dependencies:
   ```markdown
   **Depends On**:
   - [Epic] Task name (ID: abc123)
   - [Epic] Another task (ID: def456)
   ```

3. Build dependency map:
   ```
   Task A: depends on []           → No dependencies
   Task B: depends on [Task A]     → Depends on A
   Task C: depends on [Task A]     → Depends on A
   Task D: depends on [Task B, C]  → Depends on B and C
   ```

**Check dependency statuses:**

For each dependency task ID:
```
mcp__vibe_kanban__get_task task_id=<dependency-id>
```

Check status: done, inprogress, todo, inreview, cancelled.

**If `--all` flag:** Skip dependency checking entirely.

---

## Step 3: Identify Ready Tasks

**A task is "ready" if:**
- Status is `todo` (not already running)
- ALL dependencies have status `done` (or no dependencies)
- Passes feature filter (if `--feature` specified)

**Or if `--all` flag:** All pending tasks are "ready" (ignore dependencies).

**Group tasks:**
```
Ready: [Task A, Task B, Task C] (X tasks)
Blocked: [Task D, Task E] (Y tasks)
  - Task D blocked by: Task B (inprogress)
  - Task E blocked by: Task A (todo), Task C (todo)
```

---

## Step 4: Present Execution Plan

**If no ready tasks:**
```
⏸️  NO TASKS READY TO START

All pending tasks are blocked by dependencies.

Currently blocked: Y tasks

Top blockers:
- Task A (blocks 3 other tasks)
- Task B (blocks 2 other tasks)

Options:
A) Wait for running tasks to complete, then run /vk-start again
B) Start blocker tasks manually (/vk-execute <task-id>)
C) Remove dependencies (re-run /vk-prioritize)
D) Force start all tasks (ignores dependencies - may cause failures)

Choose: (a/b/c/d)
```

**If ready tasks found:**

```
🚀 TASK EXECUTION PLAN

Mode: [One-shot / Watch / Batch]
Batch Size: [5 / Unlimited]
Feature Filter: [None / <feature-name>]

---

## Ready to Start: X tasks

All dependencies met, safe to start:

**Wave 1:**
- [User Model] Create User model (ID: abc123)
- [User Model] Create migrations (ID: def456)
- [Another Feature] Setup task (ID: ghi789)

**Currently Blocked: Y tasks**
(Will become ready when dependencies complete)

- [Registration] Build endpoint (ID: jkl012)
  → Blocked by: abc123, def456
- [Registration] Add validation (ID: mno345)
  → Blocked by: jkl012

---

## Execution Details

**What will happen:**
1. Start X ready tasks simultaneously
2. VK creates attempt for each task
3. VK spawns Claude Code instances
4. VK creates isolated git worktrees
5. CC implements each task in parallel
6. Attempts complete (success or failure)
7. VK updates task statuses
8. Blocked tasks become ready as dependencies complete

**Batch size:** [5 / Unlimited]
**Watch mode:** [Enabled - will auto-start next tasks / Disabled - one-shot]

---

Ready to start? (yes/no)
```

---

## Step 5: Start Ready Tasks

**If user confirms:**

**Get current git branch:**
```bash
git branch --show-current
```

Use as base branch (or default to `main`).

### Mode A: One-Shot (Default)

**If batch size specified:**
Start first N tasks.

**If no batch size:**
Start ALL ready tasks.

**For each task to start:**
```
mcp__vibe_kanban__start_task_attempt
  task_id: <task-id>
  executor: "CLAUDE_CODE"
  base_branch: <current-branch>
```

**Track results:**
```
✅ Started: <task-title> (Attempt: <attempt-id>)
✅ Started: <task-title> (Attempt: <attempt-id>)
❌ Failed to start: <task-title> (Error: <error>)
```

**After starting batch:**
```
✅ TASKS STARTED SUCCESSFULLY

Started: X tasks
Failed: Y tasks

---

## Running Attempts

- [User Model] Create User model (Attempt: 12345)
- [User Model] Create migrations (Attempt: 12346)
- [Another Feature] Setup task (Attempt: 12347)

---

## Blocked Tasks: Z tasks

These will become ready when dependencies complete:
- [Registration] Build endpoint
  → Needs: abc123, def456

---

## Next Steps

**Monitor progress:**
```bash
/vk-status         # Check overall progress
```

**When some tasks complete, start next wave:**
```bash
/vk-start          # Start newly-ready tasks
```

**Or switch to watch mode:**
```bash
/vk-start --watch  # Auto-start as tasks complete
```

---

Execution in progress! Check VK UI for real-time logs. 🚀
```

### Mode B: Watch (Continuous)

**If `--watch` flag present:**

```
🔄 WATCH MODE ENABLED

Continuously monitoring task completions and starting ready tasks.

---

## Initial Start

Starting X ready tasks now...

✅ Started: <task-1>
✅ Started: <task-2>
✅ Started: <task-3>

---

## Monitoring

Checking every 30 seconds for:
- Completed tasks
- Newly-ready tasks (dependencies met)
- Failed attempts

Press Ctrl+C to stop watch mode.

---

[Every 30 seconds, check task statuses and start newly-ready tasks]

⏱️  [HH:MM:SS] Checking for updates...
   ✅ Task abc123 completed successfully!
   🔓 2 tasks now unblocked
   🚀 Starting: [Registration] Build endpoint

⏱️  [HH:MM:SS] Checking for updates...
   ⏳ 3 tasks still running...

⏱️  [HH:MM:SS] Checking for updates...
   ✅ Task def456 completed successfully!
   ❌ Task ghi789 failed (see VK UI for details)
   🔓 1 task now unblocked
   🚀 Starting: [Registration] Add validation

---

[Continue until all tasks done or user cancels]

✅ ALL TASKS COMPLETE

Total tasks: X
- Successful: Y
- Failed: Z

Run /vk-status for full report.
```

**Watch mode implementation:**

1. Start initial ready tasks
2. Sleep 30 seconds
3. Check all task statuses:
   ```
   mcp__vibe_kanban__list_tasks project_id=<project_id>
   ```
4. Identify newly-completed tasks
5. Recalculate ready tasks (dependencies now met)
6. Start newly-ready tasks
7. Repeat from step 2

**Exit conditions:**
- User presses Ctrl+C
- All tasks complete (no more pending)
- VK connection lost

---

## Step 6: Handle Failures

### Some Tasks Failed to Start

```
⚠️ PARTIAL START

Successfully started: X tasks
Failed to start: Y tasks

Failed tasks:
- [Epic] Task 1 (Error: VK connection timeout)
- [Epic] Task 2 (Error: Invalid branch)

Successfully running:
- [Epic] Task 3 (Attempt: 12345)
- [Epic] Task 4 (Attempt: 12346)

---

Options:
A) Continue with running tasks
B) Retry failed tasks
C) Stop all attempts and abort

Choose: (a/b/c)
```

### VK Connection Lost (Watch Mode)

```
❌ VK CONNECTION LOST

Watch mode interrupted at [HH:MM:SS]

Status before disconnect:
- Running: X tasks
- Pending: Y tasks
- Completed: Z tasks

---

Reconnect? (yes/no)
```

### All Tasks Blocked

```
⏸️  ALL TASKS BLOCKED

Every pending task has unmet dependencies.

This might indicate:
- Circular dependencies (Task A needs B, B needs A)
- Missing dependency tasks (dependency doesn't exist)
- Failed critical tasks (blocker task failed)

---

Run /vk-prioritize to review and fix dependencies.

Or use --all flag to force-start everything:
/vk-start --all
```

---

## Error Handling

### Batch Size Exceeded Running Tasks

```
⚠️ Batch size: 5
  Currently running: 8 tasks

VK is already running more tasks than your batch size!

Options:
A) Wait for some to complete before starting more
B) Increase batch size
C) Cancel

Choose: (a/b/c)
```

### Invalid Feature Name

```
❌ No tasks found for feature: "<name>"

Available features:
- user-authentication (10 tasks)
- user-profiles (5 tasks)
- blog-posts (15 tasks)

Check feature name or run without --feature flag.
```

---

## Best Practices

### When to Use Each Mode

**One-shot (default):**
✅ Quick start of ready tasks
✅ Manual control over waves
✅ Review between batches

**Watch mode:**
✅ Long-running execution (many tasks)
✅ Fire-and-forget automation
✅ Maximize throughput

**Batch size:**
✅ Limit resource usage (CPU, memory)
✅ Prevent VK overload
✅ Staged rollout (test small batches first)

**Feature filter:**
✅ Focus on specific feature
✅ Parallel feature development
✅ Test one feature before others

**All flag:**
❌ Risky! Tasks may fail due to unmet dependencies
✅ Use only when dependencies are informal/advisory
✅ Use when tasks are truly independent

### Recommended Workflow

```bash
# 1. Prioritize first (set dependencies)
/vk-prioritize

# 2. Start with small batch to test
/vk-start --batch-size=3

# 3. Review results in VK UI

# 4. If good, scale up
/vk-start --watch

# 5. Monitor
/vk-status
```

### Pro Tips

💡 **Start small** - Test with small batches first
💡 **Use watch mode** - For large task lists
💡 **Check /vk-status** - Before and after
💡 **Monitor VK UI** - Real-time logs are valuable
💡 **Don't use --all** - Unless you really know dependencies don't matter

---

## Integration

**Before `/vk-start`:**
- `/vk-plan` - Create tasks
- `/vk-prioritize` - Set dependencies (HIGHLY RECOMMENDED)

**During `/vk-start`:**
- Monitor VK UI (real-time logs)
- Watch mode handles everything automatically
- Or manually trigger waves with repeated `/vk-start` calls

**After `/vk-start`:**
- `/vk-status` - Check progress
- Wait for completions
- Call `/vk-start` again for next wave (if one-shot mode)

---

## Example Sessions

### Example 1: Basic Usage

```bash
/vk-prioritize     # Set dependencies
/vk-start          # Start all ready tasks
# Wait for some to complete...
/vk-start          # Start next wave
# Repeat until done
```

### Example 2: Watch Mode

```bash
/vk-prioritize
/vk-start --watch  # Fire and forget
# Monitor in VK UI
# All tasks execute automatically
```

### Example 3: Feature-Focused

```bash
/vk-start --feature="user-authentication" --watch
# Only user-auth tasks execute
# Other features untouched
```

### Example 4: Conservative Batch

```bash
/vk-start --batch-size=3
# Review in VK UI
# If good:
/vk-start --batch-size=10
```

---

## Flags Summary

```
--watch              Continuous mode (auto-start as dependencies clear)
--batch-size=N       Limit concurrent tasks (default: 5 if flag used, unlimited if not)
--feature=<name>     Only start tasks for specific feature
--all                Ignore dependencies, start everything (risky!)
```

**Can combine:**
```bash
/vk-start --watch --batch-size=5 --feature="user-auth"
```

---

## Notes

**This is the main orchestration command** - Most common way to execute VK tasks.

**Default is smart** - Respects dependencies, maximizes parallelization.

**Watch mode is powerful** - Set it and forget it for large task lists.

**Batch sizes prevent overload** - Use if VK/system resources limited.

**Feature filtering enables focus** - Work on one thing at a time.

**Can be called repeatedly** - Each call starts next wave of ready tasks.

---

**Last Updated**: 2025-10-27
