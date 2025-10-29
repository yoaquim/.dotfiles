# VK Execution Model: Complete Workflow

**Quick Reference for Understanding How VK Works**

---

## The Four Phases

### 1. Planning (You + Claude)

**Commands:** `/vk:plan`, `/vk:kickoff`

**Creates:** Tasks in VK backlog

**Tasks are:**
- Planning artifacts
- Flat structure with `[Epic]` prefixes
- All 1-point (1-2 hours each)
- NOT started yet
- Just sitting in VK backlog
- Dependencies initially empty

**Example:**
```
[User Model] Create User model → VK Task (in backlog)
[User Model] Write tests → VK Task (in backlog)
[Registration] Build endpoint → VK Task (in backlog)
```

---

### 2. Prioritization (You + Claude)

**Command:** `/vk:prioritize`

**What happens:**
- Analyzes all pending tasks
- Identifies logical dependencies
- Asks clarifying questions
- Builds dependency graph
- Updates task descriptions with dependency metadata
- Assigns execution waves

**Example output:**
```
Wave 1 (Ready now):
- [User Model] Create User model
- [User Model] Create migrations

Wave 2 (After Wave 1):
- [User Model] Write tests (needs model)
- [Registration] Build endpoint (needs model + migrations)

Wave 3 (After Wave 2):
- [Registration] Write tests (needs endpoint)
```

---

### 3. Execution (You Trigger via Commands)

**Commands:**
- `/vk:start` - Start all ready tasks (dependency-aware)
- `/vk:start --watch` - Continuous mode (auto-start as tasks complete)
- `/vk:execute <task-id>` - Start specific task manually

**What happens when you run /vk:start:**
```
1. Command reads all tasks
2. Parses dependencies from descriptions
3. Identifies tasks where all dependencies are done
4. Starts Attempts for ready tasks

For each ready task:
  Task: "[User Model] Create User model"
  ↓
  VK starts Attempt (via start_task_attempt)
  ↓
  - Creates isolated git worktree
  - Spawns Claude Code instance
  - Provides full context (task description, .agent/ docs)
  ↓
  CC implements the task
  ↓
  Attempt completes (success or failure)
  ↓
  VK marks task done, merges work
  ↓
  Dependent tasks become ready
```

**Attempt = Execution instance**
- Started via command (not automatic)
- One Attempt per Task
- Isolated git worktree
- CC has full project context
- VK manages lifecycle

**Watch mode:**
- Continuously monitors for completions
- Auto-starts newly-ready tasks
- Runs until all done or cancelled

---

### 4. Monitoring (Throughout Execution)

**Command:** `/vk:status`

**Shows:**
- Tasks ready (can start now)
- Tasks blocked (waiting on dependencies)
- Tasks in progress (active attempts)
- Tasks completed
- Velocity and progress

**After tasks complete:**
- Call `/vk:start` again for next wave
- Or rely on `--watch` mode to auto-continue

---

## Key Points

### You Control

✅ When to prioritize (`/vk:prioritize`)
✅ Dependencies between tasks (set via `/vk:prioritize`)
✅ When to start execution (`/vk:start` or `/vk:execute`)
✅ Execution mode (one-shot vs watch)
✅ Concurrency limits (batch size)

### VK Controls (During Execution)

✅ Spawning Claude Code instances
✅ Creating isolated git worktrees
✅ Merging successful attempts
✅ Marking tasks done
✅ Parallel execution of attempts

### You DO Manually Start Tasks

✅ Use `/vk:start` to start ready tasks
✅ Use `/vk:execute <task-id>` for specific tasks
✅ Use `/vk:start --watch` for continuous execution
❌ VK does NOT auto-start (you trigger via commands)

---

## Complete Flow Example

```
1. Planning:
   /vk:kickoff
   → Identifies features
   → Gathers requirements
   → Creates 20 tasks in VK backlog (all [Epic] prefixed, 1-point)

2. Prioritization:
   /vk:prioritize
   → Analyzes dependencies
   → Sets Wave 1: 5 tasks (no dependencies)
   → Sets Wave 2: 10 tasks (depend on Wave 1)
   → Sets Wave 3: 5 tasks (depend on Wave 2)

3. Execution - Wave 1:
   /vk:start
   → Starts 5 Wave 1 tasks (all ready)
   → VK creates 5 Attempts
   → CC implements in parallel
   → Attempts complete
   → Tasks marked done

4. Monitor:
   /vk:status
   → Wave 1: 5 complete ✅
   → Wave 2: 10 ready (dependencies met)
   → Wave 3: 5 blocked (waiting on Wave 2)

5. Execution - Wave 2:
   /vk:start
   → Starts 10 Wave 2 tasks (now ready)
   → VK creates 10 Attempts
   → CC implements in parallel
   → Attempts complete

6. Execution - Wave 3:
   /vk:start
   → Starts 5 Wave 3 tasks (now ready)
   → Attempts complete

7. Completion:
   /vk:status
   → All 20 tasks complete ✅
   → Feature done!

---

**OR use watch mode:**

```
1-2. Planning + Prioritization (same as above)

3. Execution (continuous):
   /vk:start --watch
   → Starts Wave 1 (5 tasks)
   → Monitors completions
   → Auto-starts Wave 2 when ready (10 tasks)
   → Auto-starts Wave 3 when ready (5 tasks)
   → Runs until all done
   → No manual /vk:start calls needed
```

---

## Task Structure: Flat with Prefixes

**Not hierarchical:**
```
❌ Not this (hierarchy):
Epic
├─ Subtask 1
├─ Subtask 2
└─ Subtask 3
```

**Flat with prefixes:**
```
✅ This (flat):
[Epic] Task 1
[Epic] Task 2
[Epic] Task 3
[Another Epic] Task 4
[Another Epic] Task 5
```

**Why?**
- VK subtasks are tied to Attempts (execution)
- We create Tasks during planning (before execution)
- Flat structure fits VK's model
- Use `[Epic]` prefix for grouping

---

## FAQs

**Q: How do I start tasks?**
A: Use `/vk:start` to start all ready tasks, or `/vk:execute <task-id>` for a specific task.

**Q: How do I know which tasks are ready?**
A: Run `/vk:status` to see which tasks have all dependencies met.

**Q: Can I start tasks automatically?**
A: Yes! Use `/vk:start --watch` for continuous execution that auto-starts as tasks complete.

**Q: What's the difference between Task and Attempt?**
A: Task = planning artifact in backlog. Attempt = execution instance started via command.

**Q: How do dependencies work?**
A: `/vk:prioritize` sets dependencies. `/vk:start` only starts tasks where all dependencies are done.

**Q: Can multiple tasks run at once?**
A: Yes! VK runs multiple Attempts in parallel. Use `--batch-size` to limit if needed.

**Q: How do I know what's running?**
A: `/vk:status` shows ready/blocked/running/done tasks.

**Q: Do I need to prioritize before starting?**
A: Not required, but HIGHLY recommended. Otherwise all tasks run at once (may fail due to unmet dependencies).

---

## Summary

**Four phases:**
1. **Planning:** Create Tasks (`/vk:plan` or `/vk:kickoff`)
2. **Prioritization:** Set dependencies (`/vk:prioritize`)
3. **Execution:** Start Attempts (`/vk:start` or `/vk:execute`)
4. **Monitoring:** Check progress (`/vk:status`)

**You control when tasks start, VK handles how they execute.**

---

**Last Updated**: 2025-10-27
