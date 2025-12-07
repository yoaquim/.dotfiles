# VK Tag: plan_feature

**Tag Name:** `plan_feature`

**How to add:** VK Settings → General → Task Tags → Add Tag

**Copy everything below the line into VK:**

---

## Instructions

1. **Read** the feature document specified in the task title
2. **Review** any images/mockups in the feature's `images/` directory
3. **Analyze** requirements and identify logical task breakdown
4. **Create tasks** via VK MCP with proper numbering and dependencies

## Task Numbering System

Number tasks by **dependency level**:

| Level | Meaning | Can Start |
|-------|---------|-----------|
| `0.x` | No dependencies | Immediately (parallel) |
| `1.x` | Needs Level 0 done | After all `0.x` complete |
| `2.x` | Needs Level 1 done | After all `1.x` complete |
| `3.x` | Needs Level 2 done | After all `2.x` complete |

## Task Title Format

```
[f-{feature-num}] [{level}.{seq}] {Task Title}
```

**Examples:**
```
[f-001] [0.1] Add required dependencies
[f-001] [1.1] Implement core functionality
[f-001] [2.1] Add animations
[f-001] [3.1] Add tests
```

## Task Sizing

- **1-2 points** per task (30-120 minutes)
- **Prefer many small tasks** over few large ones

## Dependency Levels

**Level 0 - Setup:** Dependencies, assets, migrations, base structure
**Level 1 - Core:** Main logic, views, JavaScript, core styling
**Level 2 - Polish:** Animations, edge cases, permissions, advanced styling
**Level 3+ - Testing:** Unit tests, integration tests, documentation

## Task Description Template

```
{Brief description}

**Requirements:**
- {Requirement 1}
- {Requirement 2}

**Design Reference:** (if images exist)
`.agent/features/{num}-{name}/images/{image}.png`

@git-workflow {other-tags}
```

## Tag Guide

- `@git-workflow` - All tasks
- `@django-patterns` - Django code
- `@tailwind-utilities` - UI/CSS
- `@permission-checks` - Auth work
- `@testing-requirements` - Code needing tests
- `@add_unit_tests` - Test-only tasks

## Output

After creating tasks, report:
```
✅ Created X tasks for Feature NNN

Level 0: N tasks (start immediately)
Level 1: N tasks (after Level 0)
Level 2: N tasks (after Level 1)
Level 3: N tasks (after Level 2)
```
