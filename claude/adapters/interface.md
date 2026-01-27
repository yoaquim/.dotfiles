# Adapter Interface Specification

This document defines the contract all orchestration tool adapters must implement.

---

## Overview

Adapters allow the `/plan` command to work with different task management systems (VK, Linear, local files) through a unified interface. Each adapter handles the specifics of its target system while following a consistent contract.

---

## Adapter Contract

Every adapter must implement these phases:

### 1. check_prerequisites()

**Purpose**: Verify the target system is available and properly configured.

**Returns**: `{ available: boolean, error?: string }`

**Checks**:
- MCP server connection (if applicable)
- Required permissions/credentials
- Project exists in target system

**Example outputs**:
```
VK: Check mcp__vibe_kanban__list_projects works
Linear: Check mcp__linear__* endpoints work
Local: Check .agent/ directory exists
```

### 2. parse_feature(feature_arg)

**Purpose**: Read and parse the feature document.

**Input**: Feature identifier (e.g., "001", "001-sidebar", "collapsible-sidebar")

**Returns**:
```
{
  number: string,      // "001"
  name: string,        // "collapsible-sidebar"
  path: string,        // ".agent/features/001-collapsible-sidebar/"
  title: string,       // From README.md heading
  document: string,    // Full README.md content
  images: string[],    // List of image files
}
```

**Behavior**:
- Match argument to `.agent/features/*/` directories
- Read README.md from feature directory
- List images in images/ subdirectory

### 3. plan_tasks(feature)

**Purpose**: Analyze feature and create task breakdown.

**Input**: Parsed feature object from parse_feature()

**Returns**:
```
{
  tasks: [
    {
      level: number,     // 0, 1, 2, etc.
      sequence: number,  // 1, 2, 3 within level
      title: string,
      description: string,
      practices: string[], // Relevant practices to inline (from ~/.claude/practices/)
    }
  ],
  summary: {
    total: number,
    byLevel: { [level: number]: number }
  }
}
```

**Behavior**:
- Follow task numbering system (0.x, 1.x, 2.x)
- Consolidate dependencies in [0.1]
- Identify core files and prevent parallel conflicts
- Apply library evaluation (build vs buy)
- Include embedded tag content in descriptions

### 4. create_tasks(tasks, project_id?)

**Purpose**: Execute task creation in target system.

**Input**:
- Task list from plan_tasks()
- Project ID (for external systems)

**Returns**:
```
{
  created: [
    { id: string, title: string, level: string }
  ],
  errors: string[]
}
```

**Behavior**:
- Create tasks in REVERSE order (highest level first)
- Handle rate limits and retries
- Report errors without failing entire batch

### 5. report_completion(results)

**Purpose**: Generate human-readable summary.

**Input**: Results from create_tasks()

**Returns**: Formatted string for display

**Format**:
```
TASKS CREATED for Feature {num}: {Title}

Level 0 (Start immediately): N tasks
Level 1 (After Level 0): N tasks
...

Total: X tasks ready in [system]
```

---

## Adapter File Structure

Each adapter file should contain:

```markdown
# [Adapter Name] Adapter

**System**: [VK / Linear / Local]
**MCP Tools**: [List of MCP tools used, if any]

---

## Prerequisites

[What this adapter needs to work]

---

## Implementation

### check_prerequisites()
[Step-by-step instructions]

### parse_feature(feature_arg)
[Uses common pattern - can reference interface.md]

### plan_tasks(feature)
[System-specific task planning logic]

### create_tasks(tasks, project_id?)
[System-specific creation logic]

### report_completion(results)
[Standard or custom reporting format]

---

## System-Specific Notes

[Quirks, limitations, tips for this system]
```

---

## Common Patterns

### Feature Parsing (All Adapters)

```bash
# Find feature directory
ls -d .agent/features/*/ 2>/dev/null

# Match patterns:
# "001" → .agent/features/001-*/
# "001-sidebar" → .agent/features/001-sidebar*/
# "sidebar" → .agent/features/*-sidebar*/
```

### Tag Embedding (All Adapters)

Tags (`@tag-name`) do NOT auto-expand. Read `~/.claude/practices/INDEX.md` to select relevant practices, then read those files and inline content directly in task descriptions.

### Task Numbering (All Adapters)

| Level | Meaning | Execution |
|-------|---------|-----------|
| 0.x | No dependencies | Parallel |
| 1.x | Needs Level 0 | Parallel after 0 |
| 2.x | Needs Level 1 | Parallel after 1 |

**Critical**: Tasks at same level must NOT modify same files.

### Library Evaluation (All Adapters)

Before creating tasks, evaluate build vs buy for each functional area. If a well-established library exists, specify it in the task description.

---

## Available Adapters

| Adapter | File | Status |
|---------|------|--------|
| VK (Vibe Kanban) | `vk.md` | Active |
| Local | `local.md` | Active |
| Linear | `linear.md` | Placeholder |

---

## Extending with New Adapters

To add support for a new task management system:

1. Create `~/.claude/adapters/[name].md`
2. Implement all 5 contract phases
3. Document MCP tools required
4. Add to the Available Adapters table above
5. Update `/plan` command's adapter detection

**Example new adapter targets**:
- GitHub Issues
- Jira
- Notion
- Asana
- Trello
