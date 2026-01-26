---
description: Plan feature implementation across different task management systems
argument-hint: <adapter> <feature-number>
allowed-tools: Read, Glob, Bash(ls*), mcp__vibe_kanban__*, mcp__linear__*, Write, Edit, AskUserQuestion
---

# Unified Plan Command

Plan feature implementation by creating tasks in your chosen task management system.

**Syntax:**
```
/plan vk 001      # Plan feature 001 in Vibe Kanban
/plan local 001   # Create local task documents in .agent/tasks/
/plan linear 001  # Create Linear issues for feature 001 (placeholder)
/plan help        # Show available adapters and usage
```

---

## Step 1: Parse Arguments

**Extract from command arguments:**
1. **Adapter name**: `vk`, `local`, `linear`
2. **Feature identifier**: `001`, `001-sidebar`, `collapsible-sidebar`

**If no arguments or `help`:**
Show usage information with available adapters.

---

## Step 2: Load Adapter

**Read the adapter configuration** from `~/.claude/adapters/`:
- `vk` → `~/.claude/adapters/vk.md`
- `local` → `~/.claude/adapters/local.md`
- `linear` → `~/.claude/adapters/linear.md`

---

## Step 3: Check Prerequisites

**Execute adapter's check_prerequisites():**

### For VK Adapter
Verify VK MCP connection and project exists.

### For Local Adapter
Check `.agent/` and `.agent/tasks/` exist.

### For Linear Adapter
Check for Linear MCP tools or API access. If unavailable, will output issues for manual creation.

---

## Step 4: Parse Feature

**Find and validate the feature:**

```bash
ls -d .agent/features/*/ 2>/dev/null
```

**Match the feature argument:**
- `001` → Find `.agent/features/001-*/`
- `001-sidebar` → Find `.agent/features/001-sidebar*/`
- `sidebar` → Find `.agent/features/*-sidebar*/`

**Read feature document:**
`.agent/features/{num}-{name}/README.md`

---

## Step 5: Execute Adapter Logic

**Based on adapter, follow its specific implementation.**

### VK Adapter Flow
1. Get project ID from VK
2. Read feature document and analyze requirements
3. Read relevant tag templates from `~/.claude/vk-tags/`
4. Evaluate build-vs-buy for each functional area
5. Create task breakdown by levels
6. Create all tasks directly in VK (in reverse order so Level 0 appears at top)

### Local Adapter Flow
1. Analyze feature document
2. Identify functional areas and dependencies
3. Create task breakdown by levels
4. Write task documents to `.agent/tasks/`

### Linear Adapter Flow
1. Analyze feature document
2. Create task breakdown by levels
3. Create Linear issues (or output for manual creation)
4. Also write local task files to `.agent/tasks/` for Claude Code reference
5. Link to parent feature issue if exists

---

## Step 6: Report Completion

**Execute adapter's report_completion():**

### VK Report Format
```
VK TASKS CREATED for Feature {num}: {Feature Title}

Level 0 (Start immediately - can run in parallel):
  - [f-{num}] [0.1] {title}
  - [f-{num}] [0.2] {title}

Level 1 (After Level 0):
  - [f-{num}] [1.1] {title}

Total: {count} tasks created

Next steps:
1. Go to VK and start Level 0 tasks (they can run in parallel)
2. After Level 0 completes, start Level 1 tasks
3. Continue through each level
```

### Local Report Format
```
LOCAL TASKS CREATED for Feature {num}: {Feature Title}

Level 0 (Start immediately):
  - [0.1] {title} → f-{num}-0.1-{slug}.md
  - [0.2] {title} → f-{num}-0.2-{slug}.md

Level 1 (After Level 0):
  - [1.1] {title} → f-{num}-1.1-{slug}.md

WORKFLOW:
1. Read the task document
2. Create feature branch if needed
3. Implement the task
4. Run tests
5. Move to next task
```

### Linear Report Format
```
LINEAR ISSUES CREATED for Feature {num}: {Feature Title}

Parent Issue: [LIN-XXX] (if linked)

Level 0 (Start immediately):
  - [LIN-101] [0.1] {title}
  - [LIN-102] [0.2] {title}

Level 1 (After Level 0):
  - [LIN-103] [1.1] {title}

Local reference files also created in .agent/tasks/

WORKFLOW:
1. Open the Linear issue
2. Start a new Claude Code session
3. Tell Claude: "Work on task f-{num}-{level}.{seq}"
4. Implement, then mark issue Done in Linear
5. Move to next task
```

---

## Task Numbering

All adapters use the same numbering system:

| Level | Meaning | Execution |
|-------|---------|-----------|
| 0.x | No dependencies | Start immediately (parallel) |
| 1.x | Needs Level 0 | After Level 0 complete |
| 2.x | Needs Level 1 | After Level 1 complete |

---

## Adapter Reference

| Adapter | System | Creates | Best For |
|---------|--------|---------|----------|
| `vk` | Vibe Kanban | Numbered tasks directly | Parallel execution via worktrees |
| `local` | Filesystem | Task documents | Solo work, simple orchestration |
| `linear` | Linear | Issues + local files | Team tracking, manual CC execution |
