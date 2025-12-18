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
4. **Evaluate build-vs-buy** for each functional area (see Library Evaluation section below)
5. **Analyze** requirements and identify logical task breakdown
6. **Create tasks** via VK MCP with proper numbering, dependencies, and **embedded tag content**

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

## CRITICAL: Library Evaluation (Build vs Buy)

Before creating tasks, **actively investigate** whether well-established libraries exist for each functional area. This applies to ALL languages and frameworks.

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
- Existing libraries are **over-engineered** for your needs (bringing in 50KB for one function)
- You need **tight integration** with existing architecture that libraries don't support
- The library is **unmaintained** or has security vulnerabilities
- Your use case is **genuinely unique** and not covered by existing solutions

### Evaluation Process

For each major functional area in the feature, ask:

1. **What problem am I solving?** (toasts, forms, state, animations, etc.)
2. **Is this a common, solved problem?** (Search: "{problem} {language/framework} library")
3. **What are the top 2-3 libraries?** (Check GitHub stars, npm/pypi downloads, recent activity)
4. **Does the library fit our needs?** (Size, dependencies, API style, maintenance)

### Common Patterns by Ecosystem

**JavaScript/TypeScript:**
| Need | Don't Build | Use Instead |
|------|-------------|-------------|
| Toast notifications | Custom toast system | react-hot-toast, sonner, react-toastify |
| Form handling | Manual form state | react-hook-form, formik, tanstack-form |
| Data fetching | Custom fetch wrapper | tanstack-query, swr, apollo |
| Date/time | Custom formatting | date-fns, dayjs, luxon |
| Validation | Custom validators | zod, yup, joi |
| Animations | CSS transitions | framer-motion, react-spring |
| Tables | Custom table components | tanstack-table, ag-grid |
| Drag & drop | Custom DnD | dnd-kit, react-beautiful-dnd |

**Python:**
| Need | Don't Build | Use Instead |
|------|-------------|-------------|
| HTTP requests | urllib directly | requests, httpx |
| Validation | Manual checks | pydantic, marshmallow |
| CLI parsing | argparse complexity | click, typer |
| Date handling | strftime/strptime | pendulum, arrow |
| Async tasks | Threading manually | celery, dramatiq, rq |
| Testing | Assert statements | pytest with fixtures |

**Ruby:**
| Need | Don't Build | Use Instead |
|------|-------------|-------------|
| Background jobs | Manual threading | sidekiq, good_job |
| Pagination | Manual OFFSET/LIMIT | pagy, kaminari |
| Auth | Rolling your own | devise, rodauth |
| File uploads | Manual handling | shrine, carrierwave |

**Go:**
| Need | Don't Build | Use Instead |
|------|-------------|-------------|
| HTTP routing | net/http directly | chi, gin, echo |
| Validation | Manual checks | go-playground/validator |
| Config | Manual parsing | viper, envconfig |
| CLI | flag package | cobra, urfave/cli |

**General (any language):**
| Need | Don't Build | Use Instead |
|------|-------------|-------------|
| Auth/OAuth | Custom auth flows | Auth0, Clerk, or language-specific libs |
| Payments | Direct API calls | Stripe SDK, payment processor SDKs |
| Email | Raw SMTP | SendGrid, Resend, Postmark SDKs |
| Search | SQL LIKE queries | Elasticsearch, Meilisearch, Algolia |
| Real-time | Raw WebSockets | Socket.io, Pusher, Ably |

### Task Impact

When a library should be used:
1. **Add to [0.1] dependencies ticket** - Include the library installation
2. **Note in task description** - Specify which library to use and why
3. **Reference documentation** - Link to relevant docs for implementation

**Example task description with library:**
```markdown
Implement toast notification system for form feedback.

**Use:** react-hot-toast (lightweight, accessible, customizable)
**Docs:** https://react-hot-toast.com/docs

Requirements:
- Success toast on form submission
- Error toast with message from API
- Dismissible after 5 seconds

Note: Do NOT build a custom toast system. react-hot-toast handles accessibility, animations, and stacking out of the box.
```

### Red Flags (When NOT to reinvent)

If you catch yourself planning tasks for ANY of these, STOP and find a library:
- "Create reusable toast/notification component"
- "Build form validation logic"
- "Implement date formatting utilities"
- "Create drag and drop system"
- "Build authentication flow from scratch"
- "Implement table sorting/filtering/pagination"
- "Create modal/dialog system"
- "Build carousel/slider component"

These are **solved problems**. Use the ecosystem.

---

## Task Numbering System

Number tasks by **dependency level**. Create as many levels and tasks per level as needed—do NOT default to a fixed count (e.g., 3 tasks per level). Let the feature complexity drive the breakdown.

| Level | Meaning | Can Start |
|-------|---------|-----------|
| `0.x` | No dependencies | Immediately (parallel) |
| `1.x` | Needs Level 0 done | After all `0.x` complete |
| `2.x` | Needs Level 1 done | After all `1.x` complete |
| `3.x+` | Continue as needed | After previous level complete |

### CRITICAL: Same Level = Parallel Execution

**Tasks within the same level (e.g., 1.1, 1.2, 1.3) run in PARALLEL on separate git worktrees.**

This means: **Tasks at the same level MUST NOT modify the same files** or you'll get merge conflicts.

**BAD Example (merge conflict disaster):**
```
[1.1] Implement room creation     → modifies LobbyRoom.ts
[1.2] Implement room joining      → modifies LobbyRoom.ts  ❌ CONFLICT!
[1.3] Implement chat system       → modifies LobbyRoom.ts  ❌ CONFLICT!
```

**GOOD Example (no conflicts):**
```
[1.1] Create LobbyRoom with all handlers (skeleton + full implementation)
[1.2] Create RoomListService      → separate file
[1.3] Create ChatMessage schema   → separate file
```

**OR use sequential levels for same-file changes:**
```
[1.1] Create LobbyRoom skeleton with onCreate/onJoin
[2.1] Add chat handlers to LobbyRoom
[3.1] Add disconnection handling to LobbyRoom
```

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

### Level 1+: Core Implementation

**CRITICAL: Identify "Core Files" First**

Before assigning levels, identify files that multiple features will touch. These are **core files** and need special handling:

**Common Core File Patterns:**
- Main class/module for the feature (e.g., `LobbyRoom.ts`, `UserService.ts`)
- Central state management (e.g., `store.ts`, `context.tsx`)
- Main component that orchestrates sub-features
- API route files that handle multiple endpoints

**Strategy for Core Files:**

**Option A: One Big Task (Recommended for complex core files)**
Put ALL logic for the core file in ONE task at Level 1. This task may be larger, but avoids conflicts:
```
[1.1] Implement LobbyRoom with all handlers (create, join, leave, chat, ready, kick, disconnect)
[1.2] Create client-side room service      → separate file, can run parallel
[1.3] Create room list component           → separate file, can run parallel
```

**Option B: Sequential Levels (For very large core files)**
Break into sequential levels where each builds on the previous:
```
[1.1] Create LobbyRoom skeleton with basic lifecycle (onCreate, onJoin, onLeave)
[2.1] Add player state management to LobbyRoom (character select, ready toggle)
[2.2] Create room list API endpoint        → separate file, parallel with 2.1
[3.1] Add chat system to LobbyRoom
[3.2] Add disconnection handling to LobbyRoom  ← SAME LEVEL ONLY IF different methods
[4.1] Add room lifecycle (kick, start game) to LobbyRoom
```

**Option C: Separate Files (Best for parallelization)**
Design architecture so features live in separate files:
```
[1.1] Create LobbyRoom base class with lifecycle hooks
[1.2] Create ChatHandler class             → separate file
[1.3] Create PlayerStateHandler class      → separate file
[1.4] Create RoomLifecycleHandler class    → separate file
[2.1] Wire all handlers into LobbyRoom     → integration task
```

**Rule of Thumb:** If 3+ tasks would touch the same file, use Option A or B. Don't split same-file work across parallel tasks.

### Level 2+: Integration & Polish
Blocked by previous levels:
- Wiring components together
- Animations and transitions
- Edge case handling
- Permission integration
- Advanced styling

### Final Levels: Testing & Documentation
Blocked by all implementation:
- Unit tests
- Integration tests
- End-to-end tests
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

1. **Same level = parallel execution** - Tasks at the same level run simultaneously on different worktrees
2. **No same-file conflicts** - Tasks at the same level MUST NOT modify the same files
3. **Core files need special handling** - Use Option A (one big task) or Option B (sequential levels) for files touched by multiple features
4. **One dependency ticket** - ALL packages in [0.1], never split across tickets
5. **Small tasks where possible** - But not at the cost of merge conflicts
6. **Clear numbering** - Know exactly when tasks can start and what can run in parallel
7. **Read the feature doc thoroughly** before creating any tasks
8. **Use existing libraries for solved problems** - Don't reinvent toasts, forms, validation, auth, etc. Research and specify which libraries to use in task descriptions
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
