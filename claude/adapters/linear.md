# Linear Adapter

**System**: Linear
**MCP Tools**: `mcp__linear__*` (if available)
**Execution**: Vanilla Claude Code (manual spin-up per task)

This adapter creates issues in Linear for feature task breakdown. Each sub-task becomes a Linear issue that you work on in a separate Claude Code session.

---

## Prerequisites

- Linear account with API access
- Feature document exists at `.agent/features/NNN-name/README.md`
- Parent feature issue in Linear (optional, created by `/feature --linear`)

---

## Implementation

### check_prerequisites()

**Check for Linear access:**

1. Check if Linear MCP tools are available
2. If not, check for `LINEAR_API_KEY` environment variable
3. If neither, inform user they'll need to create issues manually

```
If no Linear access:
  "Linear API not configured. I'll generate the issue details for you to create manually."
```

---

### parse_feature(feature_arg)

**Standard feature parsing** (same as other adapters):

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
- Parent Linear issue ID if exists (from `## Tracking` section)

---

### plan_tasks(feature)

**Analyze feature and create task breakdown.**

#### Task Analysis Process

1. **Read feature document** thoroughly
2. **Identify functional areas** from requirements
3. **Evaluate build vs buy** for each area
4. **Determine dependencies** between components
5. **Group into levels** based on dependencies
6. **Size tasks** at 1-2 points each (30-120 min of work)

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
      id: "0.1",
      title: "Install dependencies and configure base",
      description: "...",
      files: ["package.json", "tsconfig.json"],
      estimate: "Small",
    },
    {
      level: 1,
      sequence: 1,
      id: "1.1",
      title: "Implement user service",
      description: "...",
      files: ["src/services/user.ts"],
      estimate: "Medium",
    }
  ]
}
```

---

### create_tasks(tasks, feature)

**Create Linear issues for each task.**

#### Issue Format

For each task, create a Linear issue with:

**Title**: `[f-{feature_num}] [{level}.{seq}] {Task Title}`

Example: `[f-001] [0.1] Install dependencies and configure base`

**Description**:
```markdown
## Task

{Task description}

## Context

**Feature**: {Feature number} - {Feature name}
**Level**: {level}.{sequence}
**Depends on**: {list of dependency task IDs or "None"}
**Blocks**: {list of tasks this blocks or "None"}

## Files to Modify

{List of files this task will touch}

## Acceptance Criteria

- [ ] {Criteria 1}
- [ ] {Criteria 2}
- [ ] Tests pass
- [ ] No linting errors

## Implementation Notes

{Any specific guidance}

---

📄 **Feature doc**: .agent/features/{num}-{name}/README.md
🏷️ **Task ID**: f-{num}-{level}.{seq}
```

**Labels**:
- `feature-{num}` (e.g., `feature-001`)
- `level-{level}` (e.g., `level-0`, `level-1`)

**Priority** (based on level):
- Level 0: Urgent
- Level 1: High
- Level 2+: Medium

**Parent Issue**: Link to feature issue if it exists in Linear

#### If Linear MCP Available

Use MCP tools to create issues:
```
mcp__linear__create_issue(title, description, labels, priority, parent_id)
```

#### If No Linear Access

Output the issues in a format for manual creation:

```
LINEAR ISSUES TO CREATE

Copy each issue below into Linear:

---
ISSUE 1 of N
Title: [f-001] [0.1] Install dependencies and configure base
Labels: feature-001, level-0
Priority: Urgent
Parent: [Feature issue ID if exists]

Description:
[Full markdown description]

---
ISSUE 2 of N
...
```

---

### Also Create Local Task Files

**Important**: In addition to Linear issues, also create local task files in `.agent/tasks/` for reference.

This allows Claude Code to read task details locally without needing Linear API access.

File naming: `f-{feature_num}-{level}.{seq}-{slug}.md`

Example: `f-001-0.1-install-dependencies.md`

---

### report_completion(results)

```
LINEAR ISSUES CREATED for Feature {num}: {Feature Title}

Parent Issue: [LIN-XXX] (if exists)

Level 0 (Start immediately - no dependencies):
  - [LIN-101] [0.1] {Task title}
  - [LIN-102] [0.2] {Task title}

Level 1 (After Level 0 complete):
  - [LIN-103] [1.1] {Task title}
  - [LIN-104] [1.2] {Task title}

Level 2 (After Level 1 complete):
  - [LIN-105] [2.1] {Task title}

Total: X issues created

LOCAL REFERENCE FILES:
  .agent/tasks/f-{num}-0.1-*.md
  .agent/tasks/f-{num}-0.2-*.md
  ...

WORKFLOW:
For each task (start with Level 0):

1. Open the Linear issue
2. Start a new Claude Code session
3. Tell Claude: "Work on Linear issue LIN-XXX" or "Work on task f-{num}-{level}.{seq}"
4. Claude reads the local task file and implements
5. Mark issue as Done in Linear
6. Move to next task

Level 0 tasks can be worked in parallel (different Claude sessions).
After all Level 0 complete, start Level 1, etc.
```

---

## Linear-Specific Features

### Issue Relationships

- **Parent/Child**: Feature issue → Task issues
- **Blocking**: Level N tasks block Level N+1 tasks
- **Related**: Tasks at same level are related

### Labels Strategy

Required labels (create if missing):
- `feature-NNN` for each feature
- `level-0`, `level-1`, `level-2`, etc.
- `claude-code` to identify AI-assisted work

### Workflow States

Map to Linear workflow:
- **Backlog**: Planned task
- **Todo**: Ready to start (dependencies met)
- **In Progress**: Being worked on
- **In Review**: Implementation complete, testing
- **Done**: Complete

---

## When to Use Linear vs Other Adapters

**Use Linear Adapter when:**
- Team needs visibility into work
- Want to track time/progress in Linear
- Multiple people working on same feature
- Need to link to other Linear projects/issues

**Use Local Adapter when:**
- Solo work, no team tracking needed
- Quick prototyping
- Don't want Linear overhead

**Use VK Adapter when:**
- Want automated parallel execution
- VK handles orchestration
- Complex multi-worktree scenarios
