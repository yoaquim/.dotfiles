# [System Name] Adapter

**System**: [System name, e.g., Jira, GitHub Issues, Notion]
**MCP Tools**: [List MCP tools used, e.g., `mcp__jira__*`]
**Status**: [Active / Placeholder]

This adapter creates tasks in [System] for feature implementation.

---

## Prerequisites

- [MCP server requirement, if any]
- [Authentication/API key requirement]
- [Project/workspace requirement]
- Feature document exists at `.agent/features/NNN-name/README.md`

---

## Implementation

### check_prerequisites()

**Verify system is available:**

```
[Describe how to check connection]
[List MCP tools to call for verification]
```

**If connection fails:**
```
Cannot connect to [System].

Ensure:
1. [Requirement 1]
2. [Requirement 2]
3. [Requirement 3]
```

---

### parse_feature(feature_arg)

**Standard feature parsing** (same for all adapters):

```bash
# Find feature directory
ls -d .agent/features/*/ 2>/dev/null

# Match patterns:
# "001" → .agent/features/001-*/
# "001-sidebar" → .agent/features/001-sidebar*/
# "sidebar" → .agent/features/*-sidebar*/
```

**Extract from feature:**
- Feature number (e.g., `001`)
- Feature name (e.g., `collapsible-sidebar`)
- Full path
- Title from README heading
- Full README.md content
- List of images

---

### plan_tasks(feature)

**[Describe your system's approach]**

[Options:]
- Create tasks directly (like Local adapter)
- Create a planning ticket that spawns subtasks (like VK adapter)
- Create parent issue with sub-issues (like Jira/Linear)

**Task breakdown follows standard rules:**

| Level | Meaning | Execution |
|-------|---------|-----------|
| 0.x | No dependencies | Parallel |
| 1.x | Needs Level 0 | After Level 0 |
| 2.x | Needs Level 1 | After Level 1 |

**Task title format:**
```
[f-{num}] [{level}.{seq}] {Task Title}
```

**Key considerations:**
- [ ] Consolidate all dependencies in [0.1]
- [ ] Tasks at same level must NOT modify same files
- [ ] Evaluate build vs buy for each functional area
- [ ] Include relevant tag content in descriptions

---

### create_tasks(tasks, project_id)

**Create tasks in [System]:**

```javascript
// Pseudocode for task creation
const project = await mcp__[system]__get_project();

for (const task of tasks) {
  await mcp__[system]__create_task({
    project_id: project.id,
    title: task.title,
    description: task.description,
    // [System-specific fields]
  });
}
```

**System-specific considerations:**
- [Order of creation, if matters]
- [Parent-child relationships]
- [Labels/tags to apply]
- [Custom fields]

---

### report_completion(results)

```
[SYSTEM] TASKS CREATED for Feature {num}: {Feature Title}

[System-specific output format]

Level 0 (Start immediately): N tasks
Level 1 (After Level 0): N tasks
...

Total: X tasks ready in [System]

Next steps:
1. [System-specific next step]
2. [System-specific next step]
```

---

## System-Specific Notes

### [Topic 1]
[Any quirks, limitations, or tips for this system]

### [Topic 2]
[Additional notes]

---

## MCP Tools Reference

| Tool | Purpose |
|------|---------|
| `mcp__[system]__list_projects` | List available projects |
| `mcp__[system]__create_task` | Create a new task |
| `mcp__[system]__update_task` | Update existing task |
| [Add more as needed] |

---

## Example Task Description

```markdown
## Overview
{Brief description}

## Requirements
- {Requirement 1}
- {Requirement 2}

## Technical Notes
{Implementation guidance}

## Acceptance Criteria
- [ ] {Criteria 1}
- [ ] {Criteria 2}

## Related
- Feature: `.agent/features/{num}-{name}/README.md`
```
