# VK (Vibe Kanban) Adapter

**System**: Vibe Kanban
**MCP Tools**: `mcp__vibe_kanban__list_projects`, `mcp__vibe_kanban__create_task`, `mcp__vibe_kanban__list_tasks`

This adapter directly creates numbered implementation tasks in VK for a feature.

---

## Prerequisites

- VK MCP server running and configured
- Project exists in VK
- Feature document exists at `.agent/features/NNN-name/README.md`

---

## Implementation

### check_prerequisites()

**Verify VK connection:**

```
Use mcp__vibe_kanban__list_projects to verify:
1. MCP connection works
2. At least one project exists
3. Identify the project for current repository
```

**If connection fails:**
```
Cannot connect to VK.

Ensure:
1. VK is running
2. MCP server is configured
3. Project exists in VK
```

**If multiple projects found:**
Ask user to confirm which project to use.

---

### parse_feature(feature_arg)

**Standard feature parsing** (see interface.md for details):

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

Usage: /plan vk 001
       /plan vk 001-sidebar
```

---

### plan_tasks(feature)

**Analyze the feature and create tasks directly.**

1. **Read** the feature document at `.agent/features/{num}-{name}/README.md`
2. **Review** any images/mockups in `.agent/features/{num}-{name}/images/`
3. **Read** `~/.claude/practices/INDEX.md` to see available coding practices and when to use each
4. **Evaluate build-vs-buy** for each functional area (see Library Evaluation section below)
5. **Analyze** requirements and identify logical task breakdown
6. **For each task**, select relevant practices from the index, read those practice files, and **inline their full content** into the task description
7. **Create tasks** via VK MCP with proper numbering and dependencies

---

## IMPORTANT: Practice Content Embedding

VK tags (`@tag-name`) do NOT auto-expand when creating tasks via MCP.

**You MUST inline practice content directly into task descriptions.** Follow this process:

1. Read `~/.claude/practices/INDEX.md` — it lists each practice, its file, and when to use it
2. For each task, pick the relevant practices based on the index's "Use When" column
3. Read only the selected practice files from `~/.claude/practices/`
4. Paste the full content of each selected practice into the task description

**Do NOT use `@tag-name` syntax in MCP-created tasks — it won't expand.**

**Note:** VK handles git workflow automatically through worktrees. Do NOT include git branching instructions in tasks.

---

## CRITICAL: Library Evaluation (Build vs Buy)

Before creating tasks, **actively investigate** whether well-established libraries exist for each functional area.

### When to Use Existing Libraries

**PREFER existing libraries when:**
- The problem is **solved and battle-tested** (auth, toasts, date handling, validation, etc.)
- The library has **active maintenance** (recent commits, responsive to issues)
- The library has **significant adoption** (stars, downloads, community)
- Rolling your own would take **more than 2-3 hours** for equivalent quality
- The functionality involves **security-sensitive** code (crypto, auth, sanitization)
- The library handles **edge cases** you'd likely miss (timezones, i18n, accessibility)

**ROLL YOUR OWN when:**
- The requirement is **trivially simple** (a single utility function)
- Existing libraries are **over-engineered** for your needs
- You need **tight integration** with existing architecture
- The library is **unmaintained** or has security vulnerabilities
- Your use case is **genuinely unique**

### Common Patterns by Ecosystem

**JavaScript/TypeScript:**
| Need | Use Instead |
|------|-------------|
| Toast notifications | react-hot-toast, sonner, react-toastify |
| Form handling | react-hook-form, formik, tanstack-form |
| Data fetching | tanstack-query, swr, apollo |
| Date/time | date-fns, dayjs, luxon |
| Validation | zod, yup, joi |
| Animations | framer-motion, react-spring |

**Python:**
| Need | Use Instead |
|------|-------------|
| HTTP requests | requests, httpx |
| Validation | pydantic, marshmallow |
| CLI parsing | click, typer |
| Date handling | pendulum, arrow |
| Async tasks | celery, dramatiq, rq |

---

## Task Numbering System

Number tasks by **dependency level**:

| Level | Meaning | Can Start |
|-------|---------|-----------|
| `0.x` | No dependencies | Immediately (parallel) |
| `1.x` | Needs Level 0 done | After all `0.x` complete |
| `2.x` | Needs Level 1 done | After all `1.x` complete |

### CRITICAL: Same Level = Parallel Execution

**Tasks within the same level run in PARALLEL on separate git worktrees.**

**Tasks at the same level MUST NOT modify the same files** or you'll get merge conflicts.

**BAD Example:**
```
[1.1] Implement room creation     → modifies LobbyRoom.ts
[1.2] Implement room joining      → modifies LobbyRoom.ts  CONFLICT!
```

**GOOD Example:**
```
[1.1] Create LobbyRoom with all handlers
[1.2] Create RoomListService      → separate file
[1.3] Create ChatMessage schema   → separate file
```

---

## Task Title Format

```
[f-{num}] [{level}.{seq}] {Task Title}
```

**Examples:**
```
[f-001] [0.1] Install all dependencies
[f-001] [0.2] Create database migration
[f-001] [1.1] Implement core functionality
[f-001] [2.1] Add comprehensive tests
```

---

## Task Sizing

- **1-2 points** per task (30-120 minutes of work)
- **Prefer many small tasks** over few large ones
- If task feels large, break it down further
- Do NOT artificially limit task counts

---

## Dependency Levels

### Level 0: Setup & Foundation
- **[0.1] ALL dependencies** - Consolidate ALL packages into ONE ticket
- Creating new files/directories
- Database migrations
- Configuration changes

### Level 1+: Core Implementation
Identify "core files" that multiple features will touch. Use ONE task for all logic in a core file, or use sequential levels.

### Final Levels: Testing & Documentation
- Unit tests
- Integration tests
- E2E tests
- Documentation updates

---

## Creating Tasks via VK MCP

**IMPORTANT: Create tasks in REVERSE order (highest level first, lowest level last).**

VK displays tasks with most recently created at top. Create from highest level to lowest so Level 0 appears at top.

```javascript
// Create Level 2 first (if exists)
// Then Level 1
// Then Level 0 LAST (so it appears at top)
```

---

### create_tasks(tasks, project_id)

**Create all tasks directly in VK:**

```javascript
const projects = await mcp__vibe_kanban__list_projects();
const projectId = projects[0].id; // or user-selected

// Sort tasks by level DESCENDING (highest first)
const sortedTasks = tasks.sort((a, b) => b.level - a.level);

for (const task of sortedTasks) {
  await mcp__vibe_kanban__create_task({
    project_id: projectId,
    title: `[f-${featureNum}] [${task.level}.${task.seq}] ${task.title}`,
    description: task.description // with embedded tag content
  });
}
```

**Result**: All implementation tasks created directly in VK, ready to execute.

---

### report_completion(results)

```
VK TASKS CREATED for Feature {num}: {Feature Title}

Level 0 (Start immediately - can run in parallel):
  - [f-{num}] [0.1] {title}
  - [f-{num}] [0.2] {title}

Level 1 (After Level 0):
  - [f-{num}] [1.1] {title}
  - [f-{num}] [1.2] {title}

Level 2 (After Level 1):
  - [f-{num}] [2.1] {title}

Total: {count} tasks created

Next steps:
1. Go to VK and start Level 0 tasks (they can run in parallel)
2. After Level 0 completes, start Level 1 tasks
3. Continue through each level
```

---

## System-Specific Notes

### VK Worktrees
VK handles git workflow automatically through worktrees. Do NOT include git branching instructions in tasks.

### Tag Embedding
Tags (`@tag-name`) do NOT auto-expand in VK MCP. You MUST read tag files from `~/.claude/practices/` and include their content directly in task descriptions.

### Task Order
Create tasks in reverse level order so Level 0 tasks appear at the top of VK's TODO list.
