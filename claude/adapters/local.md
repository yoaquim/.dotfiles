# Local Adapter

**System**: Local filesystem (`.agent/tasks/`)
**MCP Tools**: None (uses file operations only)

This adapter creates task documents in `.agent/tasks/`.

---

## Prerequisites

- `.agent/` directory exists (project initialized with `/setup`)
- `.agent/tasks/` directory exists
- Feature document exists at `.agent/features/NNN-name/README.md`

---

## Implementation

### check_prerequisites()

**Verify local setup:**

```bash
# Check .agent/ exists
ls -la .agent/ 2>/dev/null

# Check tasks directory exists
ls -la .agent/tasks/ 2>/dev/null
```

**If `.agent/` doesn't exist:**
```
Project not initialized.

Run /setup first to create the .agent/ structure.
```

**If `.agent/tasks/` doesn't exist:**
```
Local task workflow not configured.

This project may be using VK-only workflow.

To enable local tasks:
  mkdir -p .agent/tasks

Or reinitialize with /setup and select "Local Tasks" or "Both".
```

---

### parse_feature(feature_arg)

**Standard feature parsing** (same as interface.md):

```bash
# Find feature directory
ls -d .agent/features/*/ 2>/dev/null

# Match patterns:
# "001" → .agent/features/001-*/
# "001-sidebar" → .agent/features/001-sidebar*/
# "collapsible-sidebar" → .agent/features/*-collapsible-sidebar*/
```

**Extract from feature:**
- Feature number (e.g., `001`)
- Feature name (e.g., `collapsible-sidebar`)
- Full path (e.g., `.agent/features/001-collapsible-sidebar/`)
- Title from `# Feature:` heading
- Full README.md content
- List of images in images/ directory

**If no match found:**
```
Feature not found: [argument]

Available features:
[List feature directories]

Usage: /plan local 001
       /plan local 001-sidebar
```

---

### plan_tasks(feature)

**Analyze feature and create task breakdown.**

Unlike VK (which creates a planning ticket for deferred execution), the local adapter analyzes the feature immediately and creates task documents directly.

#### Task Analysis Process

1. **Read feature document** thoroughly
2. **Identify functional areas** from requirements
3. **Evaluate build vs buy** for each area
4. **Determine dependencies** between components
5. **Group into levels** based on dependencies
6. **Size tasks** at 1-2 points each (30-120 min)

#### Level Assignment

| Level | Type | Examples |
|-------|------|----------|
| 0.x | Setup/Foundation | Dependencies, migrations, config, base structures |
| 1.x | Core Implementation | Main features, services, components |
| 2.x | Integration | Wiring components, advanced features |
| 3.x | Polish | Animations, error handling, edge cases |
| 4.x | Testing | Unit tests, integration tests, e2e tests |
| 5.x | Documentation | README updates, API docs, comments |

#### Conflict Prevention

**Tasks at the same level must NOT modify the same files.**

For core files touched by multiple features:
- **Option A**: One comprehensive task covering all changes to that file
- **Option B**: Sequential levels for same-file changes
- **Option C**: Design architecture with separate files

#### Output Format

```
{
  tasks: [
    {
      level: 0,
      sequence: 1,
      title: "Install all dependencies",
      description: "...",
      files: ["package.json"],  // Files this task modifies
      tags: ["dependencies"],
    },
    {
      level: 1,
      sequence: 1,
      title: "Implement user service",
      description: "...",
      files: ["src/services/user.ts"],
      tags: ["tdd"],
    }
  ]
}
```

---

### create_tasks(tasks, project_id?)

**Create task documents in `.agent/tasks/`**

#### Determine Task Numbering

```bash
# Find existing feature tasks
ls .agent/tasks/f-{feature_num}-*.md 2>/dev/null

# Or find highest task number overall
ls .agent/tasks/*.md 2>/dev/null | sort -V | tail -1
```

**Task file naming**: `f-{feature_num}-{level}.{seq}-{brief-title}.md`

Example: `f-001-0.1-install-dependencies.md`

#### Task Document Template

For each task, create a document following the task-template.md format:

```markdown
# Task f-{num} [{level}.{seq}]: {Title}

**Status**: Planned
**Branch**: `feature/{num}-{brief-name}`
**Priority**: {Based on level - Level 0 is High}
**Planned**: {Today's date}
**Feature**: {num}-{feature-name}
**Level**: {level}.{seq}

---

## Problem

{Description of what this task accomplishes}

**Current State:**
{What exists before this task}

**Target State:**
{What should exist after this task}

---

## Solution

### Approach

{High-level approach for this task}

### Files to Modify/Create

| File | Action | Purpose |
|------|--------|---------|
| `path/to/file.ts` | Create/Modify | {Why} |

### Implementation Notes

{Specific implementation guidance}

{Embedded tag content if applicable}

---

## Dependencies

**Depends on:**
- {List tasks this depends on, e.g., "[0.1] Install dependencies"}

**Blocks:**
- {List tasks that depend on this one}

---

## Acceptance Criteria

- [ ] {Specific testable criteria}
- [ ] {Another criteria}
- [ ] Tests pass
- [ ] No linting errors

---

## Related

- Feature: [.agent/features/{num}-{name}/README.md](../features/{num}-{name}/README.md)
- Task template: [.agent/task-template.md](../task-template.md)
```

#### Create All Tasks

Write each task document to `.agent/tasks/`.

#### Update Feature Status

After creating tasks, optionally update the feature README.md status:
- From "Defined" to "Planned"
- Add link to task documents

---

### report_completion(results)

```
LOCAL TASKS CREATED for Feature {num}: {Feature Title}

Task Directory: .agent/tasks/

Level 0 (Start immediately):
  - [0.1] {Task title} → f-{num}-0.1-{title}.md
  - [0.2] {Task title} → f-{num}-0.2-{title}.md

Level 1 (After Level 0):
  - [1.1] {Task title} → f-{num}-1.1-{title}.md
  - [1.2] {Task title} → f-{num}-1.2-{title}.md

Level 2 (After Level 1):
  - [2.1] {Task title} → f-{num}-2.1-{title}.md

Total: X tasks created

WORKFLOW:
Start with Level 0 tasks. For each task:

1. Read the task document
2. Create feature branch if needed
3. Implement the task
4. Run tests
5. Move to next task

Level 0 tasks can be worked in any order.
After all Level 0 complete, start Level 1, etc.
```

---

## System-Specific Notes

### Git Workflow

Unlike VK (which uses worktrees), local workflow uses standard git branching:

1. Create feature branch: `git checkout -b feature/{num}-{name}`
2. Implement task
3. Commit changes
4. Move to next task (same branch)
5. When feature complete, create PR

### Task Dependencies

Local tasks use explicit documentation of dependencies rather than enforced ordering. The developer is responsible for completing dependencies before dependent tasks.

### When to Use Local vs VK

**Use Local Adapter when:**
- Working solo without VK
- Quick prototyping
- Projects that don't need parallel execution
- Simpler orchestration needs

**Use VK Adapter when:**
- Need parallel task execution via worktrees
- Team collaboration through VK
- Complex features with many dependencies
- Want automated task orchestration
