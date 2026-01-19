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
```
PLAN COMMAND - Create tasks from feature requirements

Usage: /plan <adapter> <feature>

Adapters:
  vk      Create VK planning ticket (recommended for parallel execution)
  local   Create task documents in .agent/tasks/
  linear  Create Linear issues (placeholder - not yet implemented)

Examples:
  /plan vk 001           # Plan feature 001 in VK
  /plan local 001        # Create local task files
  /plan vk sidebar       # Match feature by name

Feature matching:
  001               → .agent/features/001-*/
  001-sidebar       → .agent/features/001-sidebar*/
  sidebar           → .agent/features/*-sidebar*/

See also:
  ~/.claude/adapters/interface.md   # Adapter contract
  ~/.claude/adapters/vk.md          # VK adapter details
  ~/.claude/adapters/local.md       # Local adapter details
```

**If adapter missing:**
```
Missing adapter. Please specify: vk, local, or linear

Usage: /plan <adapter> <feature>
Example: /plan vk 001
```

**If feature missing:**
```
Missing feature number.

Usage: /plan {adapter} <feature>
Example: /plan {adapter} 001
```

---

## Step 2: Load Adapter

**Read the adapter configuration:**

Based on adapter argument, read the corresponding adapter file:
- `vk` → `~/.claude/adapters/vk.md`
- `local` → `~/.claude/adapters/local.md`
- `linear` → `~/.claude/adapters/linear.md`

**If adapter not found:**
```
Unknown adapter: {adapter}

Available adapters: vk, local, linear

Run /plan help for usage information.
```

**If adapter is placeholder (linear):**
```
The Linear adapter is not yet implemented.

Options:
1. Use /plan local 001 to create local task documents
2. Manually create Linear issues from the task documents

See ~/.claude/adapters/linear.md for implementation status.
```

---

## Step 3: Check Prerequisites

**Execute adapter's check_prerequisites():**

### For VK Adapter

```
Use mcp__vibe_kanban__list_projects to verify:
1. VK MCP connection works
2. Project exists for this repository
```

If fails:
```
Cannot connect to VK.

Ensure:
1. VK is running
2. MCP server is configured in Claude Code
3. Project exists in VK

Run /plan local {feature} to use local task management instead.
```

### For Local Adapter

```bash
# Check .agent/ exists
ls -la .agent/ 2>/dev/null

# Check tasks directory exists
ls -la .agent/tasks/ 2>/dev/null
```

If `.agent/` missing:
```
Project not initialized.

Run /setup first to create the .agent/ structure.
```

If `.agent/tasks/` missing:
```
Local task workflow not configured.

This project may be using VK-only workflow.

To enable local tasks, run:
  mkdir -p .agent/tasks

Or use /plan vk {feature} for VK workflow.
```

---

## Step 4: Parse Feature

**Find and validate the feature:**

```bash
# List available features
ls -d .agent/features/*/ 2>/dev/null
```

**Match the feature argument:**
- `001` → Find `.agent/features/001-*/`
- `001-sidebar` → Find `.agent/features/001-sidebar*/`
- `sidebar` → Find `.agent/features/*-sidebar*/`

**If no match:**
```
Feature not found: {argument}

Available features:
- 001-feature-name
- 002-other-feature
- 003-another-feature

Usage: /plan {adapter} 001
       /plan {adapter} feature-name
```

**If multiple matches:**
```
Multiple features match '{argument}':

1. 001-sidebar-collapsible
2. 002-sidebar-icons

Which feature? (enter number or full name)
```

**Read feature document:**
```
.agent/features/{num}-{name}/README.md
```

**Check for images:**
```bash
ls .agent/features/{num}-{name}/images/ 2>/dev/null
```

**Extract:**
- Feature number
- Feature name
- Feature title (from README heading)
- Full document content
- List of images

---

## Step 5: Execute Adapter Logic

**Based on adapter, follow its specific plan_tasks() and create_tasks() implementation.**

### VK Adapter Flow

1. Get project ID from VK
2. Create planning ticket with comprehensive instructions
3. Planning ticket tells VK how to break down the feature

**See `~/.claude/adapters/vk.md` for full details.**

### Local Adapter Flow

1. Analyze feature document
2. Identify functional areas and dependencies
3. Create task breakdown by levels
4. Write task documents to `.agent/tasks/`

**See `~/.claude/adapters/local.md` for full details.**

---

## Step 6: Report Completion

**Execute adapter's report_completion():**

### VK Report Format

```
VK PLANNING TICKET CREATED

Feature: {num} - {Feature Title}
Ticket: [PLAN] Feature {num}: {Feature Title}

The planning ticket is now in VK.

Next steps:
1. Go to VK and start an attempt on this ticket
2. VK will spawn Claude Code to read the feature and create subtasks
3. Subtasks will be numbered [f-{num}] [0.1], [1.1], etc.

After subtasks are created, start Level 0 tasks (they can run in parallel).
```

### Local Report Format

```
LOCAL TASKS CREATED for Feature {num}: {Feature Title}

Task Directory: .agent/tasks/

Level 0 (Start immediately):
  - [0.1] {title} → f-{num}-0.1-{slug}.md
  - [0.2] {title} → f-{num}-0.2-{slug}.md

Level 1 (After Level 0):
  - [1.1] {title} → f-{num}-1.1-{slug}.md
  - [1.2] {title} → f-{num}-1.2-{slug}.md

Total: X tasks created

WORKFLOW:
Start with Level 0 tasks. For each task:

1. /workflow:implement-task f-{num}-0.1-{slug}
2. (implement the task)
3. /workflow:test-task
4. /workflow:complete-task
5. Move to next task
```

---

## Common Patterns

### Task Numbering

All adapters use the same numbering system:

| Level | Meaning | Execution |
|-------|---------|-----------|
| 0.x | No dependencies | Start immediately (parallel) |
| 1.x | Needs Level 0 | After Level 0 complete |
| 2.x | Needs Level 1 | After Level 1 complete |

### Library Evaluation

Before creating tasks, evaluate build vs buy:

**Use existing libraries when:**
- Problem is solved and battle-tested
- Library has active maintenance
- Significant adoption (stars, downloads)
- Security-sensitive code

**Common libraries to consider:**
- Toast notifications: react-hot-toast, sonner
- Forms: react-hook-form, formik
- Data fetching: tanstack-query, swr
- Validation: zod, yup, pydantic

### Conflict Prevention

**Tasks at the same level must NOT modify the same files.**

For core files:
- Option A: One comprehensive task
- Option B: Sequential levels
- Option C: Separate files by design

---

## Adapter Reference

| Adapter | System | Creates | Best For |
|---------|--------|---------|----------|
| `vk` | Vibe Kanban | Planning ticket | Parallel execution via worktrees |
| `local` | Filesystem | Task documents | Solo work, simple orchestration |
| `linear` | Linear | Issues | Team collaboration (placeholder) |

**Adapter files:**
- `~/.claude/adapters/interface.md` - Contract specification
- `~/.claude/adapters/vk.md` - VK implementation
- `~/.claude/adapters/local.md` - Local implementation
- `~/.claude/adapters/linear.md` - Linear placeholder

---

## Migration from /vk-plan

The `/vk-plan` command is deprecated. Use `/plan vk` instead:

```
OLD: /vk-plan 001
NEW: /plan vk 001
```

The functionality is identical - this is just a naming consolidation.
