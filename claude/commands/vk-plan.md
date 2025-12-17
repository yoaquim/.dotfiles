---
description: Create a VK planning ticket to break a feature into numbered tasks
argument-hint: <feature-number>
allowed-tools: Read, Glob, Bash(ls*), mcp__vibe_kanban__*
---

You are creating a VK "planning ticket" that will instruct a Claude Code instance to break down a feature into numbered implementation tasks.

**This command creates ONE ticket in VK. VK then executes it and Claude Code breaks down the feature.**

---

## Step 1: Parse Feature Argument

The user provides a feature number or name:
- `001` → Find `.agent/features/001-*/`
- `001-sidebar` → Find `.agent/features/001-sidebar*/`
- `collapsible-sidebar` → Find `.agent/features/*-collapsible-sidebar*/`

**Find the feature:**

```bash
ls -d .agent/features/*/ 2>/dev/null
```

**Match the argument to a feature directory.**

**If no match found:**
```
Feature not found: [argument]

Available features:
[List feature directories]

Usage: /vk-plan 001
       /vk-plan 001-sidebar
```

**Extract feature info:**
- Feature number (e.g., `001`)
- Feature name (e.g., `collapsible-sidebar`)
- Full path (e.g., `.agent/features/001-collapsible-sidebar/`)

---

## Step 2: Read Feature Document

**Read the feature README:**
```
.agent/features/{num}-{name}/README.md
```

**Check for images:**
```bash
ls .agent/features/{num}-{name}/images/ 2>/dev/null
```

**Extract key info for the ticket title:**
- Feature title from the `# Feature:` heading
- Brief description

---

## Step 3: Get VK Project

**List projects to find project_id:**
```
mcp__vibe_kanban__list_projects
```

**Identify the project for the current repository.**

If multiple projects or none found, ask the user to confirm.

---

## Step 4: Create the Planning Ticket

**Create a single VK task with comprehensive instructions.**

**Title format:**
```
[PLAN] Feature {num}: {Feature Title}
```

**Example:**
```
[PLAN] Feature 001: Collapsible Sidebar
```

**Task Description:**

```markdown
## Plan Feature {num}: {Feature Title}

**Feature Directory:** `.agent/features/{num}-{name}/`
**Requirements:** `.agent/features/{num}-{name}/README.md`
**Images:** `.agent/features/{num}-{name}/images/` (if exists)
**Tag Templates:** `~/.claude/vk-tags/` (for task context)

---

## Instructions

1. **Read** the feature document at `.agent/features/{num}-{name}/README.md`
2. **Review** any images/mockups in `.agent/features/{num}-{name}/images/`
3. **Read** relevant tag templates from `~/.claude/vk-tags/` for task context
4. **Analyze** requirements and identify logical task breakdown
5. **Create tasks** via VK MCP with proper numbering, dependencies, and **embedded tag content**

---

## IMPORTANT: Tag Content Embedding

VK tags (`@tag-name`) do NOT auto-expand when creating tasks via MCP.

**You MUST read the tag files and include their content directly in task descriptions.**

Tag files location: `~/.claude/vk-tags/`

Available tags:
- `tdd.md` - Business logic, validation, pure functions (TDD approach)
- `django-patterns.md` - Django code changes
- `tailwind-utilities.md` - UI/CSS work
- `permission-checks.md` - Auth/permissions
- `bug_analysis.md` - Bug fixes
- `code_refactoring.md` - Refactoring
- `plan-feature.md` - Full planning reference (this command uses it)

**Note:** VK handles git workflow automatically through worktrees. Do NOT include git branching instructions in tasks.

**Example:** Read the relevant tag file and include its content in the task description.

---

## Task Numbering System

Number tasks by **dependency level**. Create as many levels and tasks per level as needed—do NOT default to a fixed count (e.g., 3 tasks per level). Let the feature complexity drive the breakdown.

| Level | Meaning | Can Start |
|-------|---------|-----------|
| `0.x` | No dependencies | Immediately (parallel) |
| `1.x` | Needs Level 0 done | After all `0.x` complete |
| `2.x` | Needs Level 1 done | After all `1.x` complete |
| `3.x+` | Continue as needed | After previous level complete |

---

## Task Title Format

```
[f-{num}] [{level}.{seq}] {Task Title}
```

**Examples:**
```
[f-{num}] [0.1] Install all dependencies       # ALWAYS first - ALL packages here
[f-{num}] [0.2] Create database migration
[f-{num}] [0.3] Add environment variables
[f-{num}] [1.1] Implement core functionality
[f-{num}] [1.2] Add event handlers
[f-{num}] [2.1] Add animations and polish
[f-{num}] [3.1] Add comprehensive tests
```

---

## Task Sizing

- **1-2 points** per task (30-120 minutes of work)
- **Prefer many small tasks** over few large ones
- If task feels large, break it down further
- A complex feature may have 15+ tasks; a simple one may have 4
- Do NOT artificially limit task counts—create exactly what's needed

---

## Dependency Levels

### Level 0: Setup & Foundation
No dependencies, can run in parallel:
- **[0.1] ALL dependencies** - Consolidate ALL packages/libraries into ONE ticket (prevents multiple lockfile changes)
- Creating new files/directories
- Adding static assets
- Database migrations
- Configuration changes (env vars, config files)
- Base HTML/template structure

**IMPORTANT: Dependencies Rule**
ALL dependencies for the entire feature MUST be in a single [0.1] ticket titled "Install all dependencies". This includes:
- All packages for any part of the stack (server, client, shared, etc.)
- Any CDN links or external libraries
- System dependencies if needed

Examples by stack:
- Node.js: `npm install` / `yarn add` (one lockfile change)
- Python: `pip install` / `poetry add` (one requirements change)
- Ruby: `bundle add` (one Gemfile.lock change)

Do NOT split dependencies across multiple tickets. One install ticket = one lockfile change.

### Level 1: Core Implementation
Blocked by Level 0:
- Main feature logic
- View functions
- JavaScript functionality
- Core styling

### Level 2: Integration & Polish
Blocked by Level 1:
- Animations and transitions
- Edge case handling
- Permission integration
- Advanced styling

### Level 3+: Testing & Documentation
Blocked by previous levels:
- Unit tests
- Integration tests
- Documentation updates

---

## Task Description Template

```markdown
{Brief description of what to implement}

**Requirements:**
- {Specific requirement from feature doc}
- {Another requirement}

**Design Reference:** (if images exist)
`.agent/features/{num}-{name}/images/{relevant-image}.png`

@tdd (if business logic)
```

---

## Tag Guide

Include relevant tags based on task type:

| Tag | When to Use |
|-----|-------------|
| `@tdd` | Business logic, validation, pure functions |
| `@django-patterns` | Django code changes |
| `@tailwind-utilities` | UI/CSS work |
| `@permission-checks` | Auth/permissions work |
| `@bug_analysis` | Bug fixes |
| `@code_refactoring` | Refactoring work |

**Note:** Git workflow is handled by VK through worktrees. Do NOT add git instructions to tasks.

---

## Creating Tasks via VK MCP

**IMPORTANT: Create tasks in REVERSE order (highest level first, lowest level last).**

VK displays tasks with the most recently created at the top. To have Level 0 tasks appear at the top of the TODO list (so they're worked on first), create tasks starting from the highest level and work backwards:

1. Create Level 3+ tasks first (if any)
2. Then Level 2 tasks
3. Then Level 1 tasks
4. Finally Level 0 tasks (created last = appears at top)

```javascript
// Get project_id
const projects = await mcp__vibe_kanban__list_projects();
const projectId = projects[0].id;

// Create tasks in REVERSE order (3.x → 2.x → 1.x → 0.x)
// This ensures 0.x tasks appear at the top of the VK TODO list

// Level 2 first (if exists)
await mcp__vibe_kanban__create_task({...});

// Level 1 next
await mcp__vibe_kanban__create_task({...});

// Level 0 LAST (so it appears at the top)
await mcp__vibe_kanban__create_task({
  project_id: projectId,
  title: "[f-{num}] [0.1] Task title here",
  description: `Task description...

@django-patterns`
});
```

---

## Output Summary

After creating all tasks, report:

```
✅ Created X tasks for Feature {num}: {Feature Title}

Level 0 (Start immediately): N tasks
Level 1 (After Level 0): N tasks
(continue for all levels created)

Total: X tasks ready in VK
```

---

## Key Principles

1. **One dependency ticket** = ALL packages in [0.1], never split across tickets
2. **Small tasks** = faster completion, easier parallelization
3. **Clear numbering** = know exactly when tasks can start
4. **Proper tagging** = agents have context they need
5. **Image references** = agents see visual requirements
6. **Read the feature doc thoroughly** before creating any tasks
```

---

## Step 5: Report Creation

After creating the VK task:

```
✅ VK PLANNING TICKET CREATED

Feature: {num} - {Feature Title}
Ticket: [PLAN] Feature {num}: {Feature Title}

The planning ticket is now in VK.

Next steps:
1. Go to VK and start an attempt on this ticket
2. VK will spawn Claude Code to read the feature and create subtasks
3. Subtasks will be numbered [f-{num}] [0.1], [1.1], etc.

After subtasks are created, start Level 0 tasks (they can run in parallel).
```

---

## Error Handling

### Feature Not Found
```
Feature not found: [argument]

Check that you've defined the feature with /feature first.
Features are stored in .agent/features/NNN-name/
```

### VK Connection Failed
```
Cannot connect to VK.

Ensure:
1. VK is running
2. MCP server is configured
3. Project exists in VK
```

### No Images
If no images directory exists, the description will note:
```
**Images:** None (no mockups provided)
```
