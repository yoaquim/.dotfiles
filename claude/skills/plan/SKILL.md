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
2. Create planning ticket with comprehensive instructions
3. Planning ticket tells VK how to break down the feature

### Local Adapter Flow
1. Analyze feature document
2. Identify functional areas and dependencies
3. Create task breakdown by levels
4. Write task documents to `.agent/tasks/`

---

## Step 6: Report Completion

**Execute adapter's report_completion():**

### VK Report Format
```
VK PLANNING TICKET CREATED

Feature: {num} - {Feature Title}
Ticket: [PLAN] Feature {num}: {Feature Title}

Next steps:
1. Go to VK and start an attempt on this ticket
2. VK will spawn Claude Code to read the feature and create subtasks
```

### Local Report Format
```
LOCAL TASKS CREATED for Feature {num}: {Feature Title}

Level 0 (Start immediately):
  - [0.1] {title}
  - [0.2] {title}

Level 1 (After Level 0):
  - [1.1] {title}

WORKFLOW:
/workflow:implement-task f-{num}-0.1-{slug}
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
| `vk` | Vibe Kanban | Planning ticket | Parallel execution via worktrees |
| `local` | Filesystem | Task documents | Solo work, simple orchestration |
| `linear` | Linear | Issues | Team collaboration (placeholder) |
