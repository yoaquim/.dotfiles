# VK-Claude Code Integration SOP

**Purpose**: Technical guidance for Vibe Kanban + Claude Code workflow integration
**Audience**: Claude Code agents (and technical humans)
**Last Updated**: 2025-10-27

---

## Overview

Vibe Kanban (VK) orchestrates Claude Code (CC) instances for parallel task execution. This SOP defines how VK and `.agent/` documentation work together.

### Core Separation

**Vibe Kanban:**
- Manages all tasks (flat structure with [Epic] prefixes)
- Orchestrates CC instances via Attempts
- Provides isolated git worktrees
- Handles parallelization

**`.agent/` Directory:**
- Provides project context
- Documents architecture
- Stores feature requirements
- References universal SOPs

**Key Differences from Standard Workflow:**
- ❌ No `.agent/tasks/` directory
- ✅ VK is source of truth for tasks
- ✅ Flat task structure (not hierarchical)
- ✅ VK orchestrates via Attempts (not manual execution)

---

## VK's Model: Tasks vs Attempts

**Critical to understand:**

**Task** = Work item in backlog (planning artifact)
- Created during planning (`/vk-plan`)
- Sits in VK backlog
- Not started yet
- Contains description, success criteria
- May have dependencies (stored in description)

**Attempt** = Execution instance (runtime)
- Started via `/vk-execute` or `/vk-start`
- VK creates Attempt for a Task
- VK spawns CC instance
- VK creates isolated git worktree
- CC implements the task
- Attempt completes or fails
- VK marks task done, unblocks dependent tasks

**Our workflow:**
1. **Planning**: Create Tasks (`/vk-plan`)
2. **Prioritization**: Set dependencies (`/vk-prioritize`)
3. **Execution**: Start Attempts (`/vk-start` or `/vk-execute`)
4. **Monitoring**: Track progress (`/vk-status`)

**You control when tasks start** - via execution commands.
**VK handles how tasks execute** - spawning instances, worktrees, parallelization.

---

## The 1-Point Rule (CRITICAL)

### Definition

**Every VK subtask MUST be 1 story point.**

**1 story point =**
- 1-2 hours of work for one CC instance
- Single, focused objective
- 2-3 files modified (not 10+)
- Testable in isolation
- No complex dependencies

**This is NON-NEGOTIABLE in VK workflow.**

### Why It Matters

1. **VK Isolation**: Each subtask runs in isolated git worktree
2. **Completability**: Work finished in one CC session
3. **Parallelization**: Multiple subtasks run concurrently
4. **Progress Visibility**: Granular progress tracking
5. **Reduced Risk**: Small changes easier to review
6. **Faster Feedback**: Quick completion → quick validation

### Examples

#### ✅ GOOD (1-point)

- "Create User model with email/password fields and migrations"
- "Build POST /api/register endpoint"
- "Write User model unit tests"
- "Add JWT token generation utility function"
- "Update authentication documentation in .agent/"

**Each:**
- Has single focus
- Completable in 1-2 hours
- Modifies 2-3 files
- Testable independently

#### ❌ BAD (Multi-point)

- "Build authentication system" (8+ points, too broad)
- "Create user API with all CRUD endpoints" (4+ points, multiple endpoints)
- "Implement auth backend and frontend" (5+ points, backend + frontend)
- "Build entire profile management feature" (6+ points, feature-level)

**Why bad:**
- Too broad/unfocused
- Would take days, not hours
- Touches many files
- Hard to test in isolation
- Can't complete in one session

### Breaking Down Multi-Point Work

**If subtask estimates >1 point, break it down:**

**"Build user API" (4 points) →**
- "Create POST /api/users endpoint" (1pt)
- "Create GET /api/users/:id endpoint" (1pt)
- "Create PUT /api/users/:id endpoint" (1pt)
- "Create DELETE /api/users/:id endpoint" (1pt)

**"Authentication system" (8 points) →** [Already epic-level, break into epics first]

**"Frontend feature X" (4 points) →**
- "Create UI components for X" (1pt)
- "Add state management for X" (1pt)
- "Connect X to API" (1pt)
- "Add form validation for X" (1pt)

### Enforcement

**The `/vk-plan` command enforces this by:**
1. Asking for breakdown if subtask seems >1pt
2. Validating each subtask against 1-point criteria
3. Refusing to create multi-point subtasks
4. Providing breakdown suggestions

---

## Task Structure: Flat with Epic Prefixes

### VK's Model vs Our Needs

**VK Native Structure:**
- Task (work item in backlog)
- Attempt (execution instance, can have subtasks during execution)

**Our Planning Structure:**
- Flat list of Tasks
- Use `[Epic Name]` prefix for grouping
- All tasks are 1-point
- No hierarchy during planning

**Why flat?**
- Subtasks are tied to Attempts (execution time, not planning time)
- We plan before execution, so can't use subtasks
- Flat structure fits VK's orchestration model better
- Each task = one future Attempt

### Task Naming Convention

**Format:** `[Epic Name] Task description`

**Examples:**
```
[User Model] Create User model with email/password fields
[User Model] Create database migrations for User
[User Model] Write User model unit tests
[User Model] Update database schema docs

[Registration] Build POST /register endpoint
[Registration] Add email validation logic
[Registration] Write registration endpoint tests
[Registration] Update API documentation

[Login] Build POST /login endpoint
[Login] Add JWT token generation
[Login] Write JWT validation tests
```

### Epic Grouping (Conceptual)

**Epics exist in planning, not VK structure:**

```
Epic: "User Model & Database" (conceptual grouping)
├─ [User Model] Create model [1pt] → VK Task
├─ [User Model] Create migrations [1pt] → VK Task
├─ [User Model] Write tests [1pt] → VK Task
└─ [User Model] Update docs [1pt] → VK Task

Epic: "Registration API" (conceptual grouping)
├─ [Registration] Build endpoint [1pt] → VK Task
├─ [Registration] Add validation [1pt] → VK Task
├─ [Registration] Write tests [1pt] → VK Task
└─ [Registration] Update docs [1pt] → VK Task
```

**In VK, you see:**
- Flat list of all tasks
- Filter/group by [Epic] prefix
- All independent, all 1-point

### Task Characteristics

**Every task:**
- **1 point** (1-2 hours)
- **Independent** (can execute in any order, unless you set dependencies)
- **Clear prefix** ([Epic Name])
- **Focused** (single responsibility)
- **Testable** (has success criteria)

**Types of tasks:**
1. **Setup**: Create models, schemas, migrations
2. **Implementation**: Build endpoints, functions, features
3. **Testing**: Write tests for specific functionality
4. **Documentation**: Update .agent/ docs

---

## Task Dependencies

### No Native VK Support

**VK MCP API has no built-in dependency/blocker fields.**

We store dependencies in task descriptions using structured metadata.

### Dependency Metadata Format

**In task description:**
```markdown
**Feature**: user-authentication (.agent/features/user-authentication.md)
**Epic**: Registration API
**Points**: 1
**Wave**: 2
**Depends On**:
- [User Model] Create User model (ID: abc123)
- [User Model] Create migrations (ID: def456)
```

### How It Works

**Planning (/vk-plan):**
- Creates tasks with empty dependencies section
- `**Depends On**: (Set by /vk-prioritize - initially empty)`

**Prioritization (/vk-prioritize):**
- Analyzes logical dependencies
- Updates task descriptions with dependency IDs
- Assigns wave numbers (execution priority)

**Execution (/vk-start):**
- Reads all task descriptions
- Parses dependencies
- Only starts tasks where all dependencies have `status: done`
- Respects dependency graph automatically

**Completion (VK):**
- VK marks task as `done` when attempt succeeds
- Dependent tasks become ready (dependencies met)
- Next `/vk-start` call can start newly-ready tasks

### Dependency Logic

**A task is "ready" if:**
- Status is `todo` (not already running)
- ALL dependencies have status `done` (or no dependencies)

**Common dependencies:**
- Database models before endpoints
- Endpoints before tests
- Implementation before documentation
- Core features before dependent features

---

## Auto-Generated Tasks

### Documentation Tasks

**Every epic automatically gets a documentation task (last in epic).**

**Example:**
```
Epic: "User Authentication"
└─ Subtask: "Update authentication docs in .agent/" [1pt]
```

**This subtask:**
- Always comes last in epic
- Always 1 point
- Specifies which docs to update
- Lists what changed in epic
- References completed work

**Updates typically include:**
- `.agent/system/overview.md` (current state)
- `.agent/system/architecture.md` (components/endpoints)
- `.agent/system/database-schema.md` (if models changed)

**Why automatic:**
- Documentation not forgotten
- Visible in VK board
- Can be assigned/scheduled
- Part of "done" definition

### Test Subtasks

**Implementation subtasks get corresponding test subtasks.**

**Pattern:**
```
Epic: "User Registration"
├─ Subtask: "Create User model" [1pt]
├─ Subtask: "Write User model tests" [1pt] ← Test subtask
├─ Subtask: "Build POST /register endpoint" [1pt]
├─ Subtask: "Write registration endpoint tests" [1pt] ← Test subtask
```

**Test subtasks:**
- Always 1 point
- Reference acceptance criteria from feature requirements
- Can come before or after implementation (TDD flexibility)
- Cover unit, integration, and edge cases

**Why separate:**
- Enables true TDD (tests first)
- Each is 1-point (focused)
- Can be parallelized
- Clear testing visibility

---

## TDD Approach

### Test-First Workflow

**VK workflow enables true TDD:**

```
Epic: "Login API"
├─ Subtask: "Write login endpoint tests" [1pt] ← Tests first
├─ Subtask: "Build POST /login endpoint" [1pt] ← Implementation
├─ Subtask: "Write JWT validation tests" [1pt] ← Tests first
└─ Subtask: "Add JWT token validation" [1pt] ← Implementation
```

**Flow:**
1. Test subtask writes tests (red)
2. Implementation subtask makes tests pass (green)
3. Repeat

**Benefits:**
- Tests written with fresh perspective
- Requirements drive tests, tests drive implementation
- No "we'll test later" technical debt

### Test-After Workflow

**Also supported if preferred:**

```
Epic: "Profile API"
├─ Subtask: "Build GET /profile endpoint" [1pt]
├─ Subtask: "Write GET /profile tests" [1pt]
├─ Subtask: "Build PUT /profile endpoint" [1pt]
└─ Subtask: "Write PUT /profile tests" [1pt]
```

### Test Coverage Goals

**Aim for 80%+ coverage:**
- Unit tests for models, utilities
- Integration tests for API endpoints
- Edge case tests from feature requirements

**Test subtasks reference:**
- Feature requirements (`.agent/features/*.md`)
- Acceptance criteria (EARS format)
- Testing SOP (`~/.claude/workflow/sops/testing-principles.md`)

---

## Feature Requirements Integration

### Feature Documents

**Location**: `.agent/features/<feature-name>.md`

**Created by**: `/vk-feature` command

**Contains:**
- User stories (prioritized)
- Acceptance criteria (EARS format)
- Edge cases and constraints
- Success metrics
- Out of scope items

**Purpose**: Define WHAT to build (user needs)

### Linking to VK Tasks

**Every VK task/subtask description includes:**

```markdown
**Feature**: .agent/features/user-authentication.md
```

**This link:**
- Provides context for implementation
- References acceptance criteria
- Shows user value
- Traces back to requirements

### Using Requirements in Subtasks

**When implementing a subtask:**

1. **Read your task description** (specific instructions)
2. **Read linked feature requirements** (broader context)
3. **Find relevant acceptance criteria** (what success looks like)
4. **Implement to satisfy criteria**

**Example:**

**Feature requirement says:**
```
WHEN a user submits invalid credentials
THEN the system SHALL return 401 status
AND display "Invalid email or password" message
```

**Your subtask implements this exactly.**

---

## VK Task Descriptions

### Epic (Task) Description Template

```markdown
# Epic: [Epic Name]

**Type**: Epic
**Feature**: .agent/features/[feature-name].md
**Delivers**: [Value this epic provides]

---

## Context

[From feature requirements and system architecture]

---

## Subtasks (All 1-point)

This epic breaks into [N] subtasks:

1. [Subtask 1] - [Brief description]
2. [Subtask 2] - [Brief description]
...

Each subtask is 1 point (1-2 hours of work for one CC instance).

---

## Success Criteria

[From feature requirements, specific to this epic]

WHEN [epic completes]:
- THEN [system capability 1]
- AND [system capability 2]

---

## Available Tools

Claude Code instances working on subtasks have access to:
- **Slash commands**: ~/.claude/commands/ (e.g., /fix-bug, /document-issue)
- **Project context**: .agent/ documentation
- **SOPs**: ~/.claude/workflow/sops/ and .agent/sops/
- **Feature requirements**: .agent/features/[feature-name].md

Use these tools as needed.

---

## References

- Feature Requirements: .agent/features/[feature-name].md
- System Architecture: .agent/system/architecture.md
- VK Integration SOP: ~/.claude/workflow/sops/vk-integration.md
```

### Subtask Description Template

**For implementation subtasks:**

```markdown
# [Subtask Name]

**Type**: Implementation
**Points**: 1 (1-2 hours)
**Epic**: [Epic Name]
**Feature**: .agent/features/[feature-name].md

---

## Objective

[Clear, focused objective - single responsibility]

---

## Context

**Related User Story:**
"As a [role], I want to [action], so that [benefit]"

**From Feature Requirements:**
[Relevant context from feature doc]

---

## Implementation Details

**What to create/modify:**
- File 1: [path] - [What changes]
- File 2: [path] - [What changes]

**Specific tasks:**
1. [Action 1]
2. [Action 2]

**Acceptance:**
- [ ] [Criterion 1]
- [ ] [Criterion 2]

---

## Success Criteria (EARS format)

WHEN [event]:
- THEN [expected behavior]

[From feature requirements]

---

## Resources

- Feature Requirements: .agent/features/[name].md
- Architecture: .agent/system/architecture.md
- Available commands: ~/.claude/commands/

---

## Estimated Time

1-2 hours for one Claude Code instance.
```

---

## Documentation Workflow

### When Docs Updated

**Automatically:**
- Documentation subtasks execute (last in each epic)
- Update `.agent/system/*` based on epic work
- Keeps docs current continuously

**Manually (backup):**
- `/vk-sync-docs` command
- Reads VK task completion
- Updates `.agent/system/*` accordingly

### What Gets Documented

**After each epic:**

**`.agent/system/overview.md`:**
- Current state (add completed feature)
- Tech stack (if tools added)
- Next steps (update priorities)

**`.agent/system/architecture.md`:**
- New components/modules
- New API endpoints
- Database schema changes
- File structure updates

**`.agent/system/database-schema.md`:**
- New models/tables
- New fields
- Relationships
- Migrations

### Documentation Standards

Follow:
- `~/.claude/workflow/sops/documentation-standards.md`

Use:
- Lowercase naming (tasks, system, sops)
- Kebab-case for multi-word
- Markdown formatting
- Clear section structure

---

## Git Workflow with VK

### Isolated Worktrees

**VK creates isolated git worktrees per subtask:**

```
project/.vibe/worktrees/
├── task-123-user-model/     # Subtask 1
├── task-124-user-tests/     # Subtask 2
└── task-125-login-endpoint/ # Subtask 3
```

**Each worktree:**
- Independent working directory
- Own branch
- Doesn't interfere with other subtasks
- Merged when complete

**You don't manage worktrees** - VK handles this automatically.

### Commit Messages

Follow standard git workflow:
- `~/.claude/workflow/sops/git-workflow.md`

VK subtask commits should:
- Be descriptive
- Reference subtask/epic if helpful
- Follow conventional commit format

---

## Available Tools for VK-Spawned Instances

### Slash Commands

**Planning phase (before execution):**
- `/vk-init` - Initialize VK workflow
- `/vk-kickoff` - Complete project kickoff (features → requirements → tasks)
- `/vk-feature <description>` - Define feature requirements
- `/vk-plan [feature]` - Create VK tasks from feature
- `/vk-prioritize` - Set dependencies and execution order

**Execution phase:**
- `/vk-start [flags]` - Start ready tasks (smart orchestration)
  - `--watch` - Continuous mode
  - `--batch-size=N` - Limit concurrency
  - `--feature=<name>` - Filter by feature
- `/vk-execute <task-id>` - Start single task manually

**Monitoring:**
- `/vk-status` - Check progress and readiness
- `/vk-sync-docs` - Sync documentation (if needed)

**When VK spawns CC instance (during execution):**
- `/fix-bug <description>` - Quick bug fix if discovered
- `/document-issue` - Document known issues found

**NOT available/needed during execution:**
- `/vk-plan` - Planning already done
- `/vk-feature` - Requirements already defined
- `/implement-task` - VK attempt handles this

### Documentation Access

**VK-spawned instances can read:**
- `CLAUDE.md` - Core project instructions
- `.agent/features/*.md` - Feature requirements
- `.agent/system/*.md` - System documentation
- `~/.claude/workflow/sops/*.md` - Universal SOPs

**This provides full project context.**

### When to Use Commands

**Use `/fix-bug` if:**
- Discover a bug while implementing
- Need quick hotfix workflow

**Use `/document-issue` if:**
- Find a gotcha or recurring issue
- Want to document for future

**Use project tools as needed:**
- Test commands
- Dev server commands
- Database commands

---

## Best Practices

### Epic Design

✅ **DO:**
- Align epics with feature requirements
- Keep epics focused (3-10 subtasks)
- Clear success criteria per epic
- Logical grouping of related work

❌ **DON'T:**
- Create epics with 20+ subtasks (too big)
- Mix unrelated functionality in one epic
- Skip success criteria

### Subtask Design

✅ **DO:**
- Always 1 point (enforce ruthlessly)
- Single responsibility
- Clear, focused objective
- Testable independently
- Reference acceptance criteria

❌ **DON'T:**
- Multi-point subtasks (breaks VK model)
- Vague objectives
- Multiple responsibilities
- "Implement everything" tasks

### Testing Strategy

✅ **DO:**
- Separate test subtasks
- Can do test-first (TDD)
- Reference feature acceptance criteria
- Cover unit + integration + edge cases
- Aim for 80%+ coverage

❌ **DON'T:**
- Combine testing with implementation (keep separate)
- Skip edge cases
- Forget acceptance criteria
- "We'll test later"

### Documentation

✅ **DO:**
- Auto-generate doc subtasks per epic
- Execute doc subtasks (don't skip)
- Keep `.agent/system/*` current
- Update after each epic

❌ **DON'T:**
- Skip documentation subtasks
- Let docs get stale
- Forget to document architecture changes
- "We'll document later"

---

## Common Anti-Patterns

### 1. Multi-Point Subtasks

**Anti-pattern:**
"Build authentication system" (8+ points)

**Why bad:**
- Too broad for one CC instance
- Can't complete in one session
- Hard to parallelize
- Unclear progress

**Fix:**
Break into 1-point subtasks (see examples above)

### 2. Skipping Test Subtasks

**Anti-pattern:**
Only implementation subtasks, no tests

**Why bad:**
- Tests get forgotten
- No TDD possibility
- Quality suffers
- Technical debt accumulates

**Fix:**
Always create test subtasks for major implementation

### 3. Skipping Documentation Subtasks

**Anti-pattern:**
Epic completes, no doc subtask

**Why bad:**
- Docs get stale
- Future work harder (no context)
- Architecture unclear
- Knowledge loss

**Fix:**
`/vk-plan` auto-generates doc subtasks - don't remove them

### 4. Vague Subtask Descriptions

**Anti-pattern:**
"Work on user stuff" [1pt]

**Why bad:**
- Unclear objective
- No acceptance criteria
- Can't verify completion
- Wasted CC instance time

**Fix:**
Specific, focused descriptions with clear acceptance criteria

### 5. Missing Feature Requirements

**Anti-pattern:**
Planning VK tasks without feature requirements

**Why bad:**
- No acceptance criteria
- Unclear user value
- Hard to know when "done"
- May build wrong thing

**Fix:**
Always run `/vk-feature` before `/vk-plan`

---

## Integration with Standard Workflow

### VK Projects vs Standard Projects

**Can coexist peacefully:**
- Some projects use VK
- Some use standard workflow
- Commands check for `.agent/.vk-enabled`

**VK Projects:**
- Have `.agent/.vk-enabled` marker
- NO `.agent/tasks/` directory
- Use `/vk-*` commands
- VK orchestrates execution

**Standard Projects:**
- Have `.agent/tasks/` directory
- Use standard commands (`/plan-task`, `/implement-task`, etc.)
- Manual execution

### When to Use Each

**Use VK workflow when:**
- Complex features need parallel work
- Want automated orchestration
- Multiple epics in parallel
- Team environment

**Use standard workflow when:**
- Simple, linear work
- Single developer
- Quick prototypes
- VK overhead not worth it

---

## Troubleshooting

### Subtask Taking Too Long

**If 1-point subtask taking >2 hours:**

**Possible issues:**
1. Subtask actually multi-point (mislabeled)
2. Unexpected complexity discovered
3. Missing dependencies
4. Unclear requirements

**Solutions:**
- Stop and reassess
- Break into smaller subtasks
- Document blocker
- Escalate if needed

### Documentation Falling Behind

**If `.agent/system/*` outdated:**

**Causes:**
1. Doc subtasks not executed
2. Doc subtasks skipped in planning
3. Manual sync not run

**Solutions:**
- Run `/vk-sync-docs`
- Prioritize doc subtasks
- Don't skip doc work

### VK Task Explosion

**If feature generating 50+ subtasks:**

**Issue:**
Feature too complex for single phase

**Solutions:**
- Break feature into phases
- Create multiple features
- Group into clear milestones
- Phase implementation

---

## Key Takeaways

1. **1-Point Rule**: Non-negotiable, every subtask 1-2 hours
2. **Auto-Generated**: Doc and test subtasks automatic
3. **Feature-Driven**: Requirements drive VK tasks
4. **Parallel**: VK runs multiple subtasks concurrently
5. **Documentation**: Part of done, not optional
6. **Testing**: Separate subtasks, TDD-friendly
7. **Context-Rich**: Feature requirements + `.agent/` docs provide full context

---

**For human-friendly guide, see**: `~/.claude/guides/vk-product-workflow.md`

**For core project instructions, see**: `CLAUDE.md` in project root

**Last Updated**: 2025-10-27
