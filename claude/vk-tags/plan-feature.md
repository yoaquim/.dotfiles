Break down a feature into numbered, dependency-aware VK tasks.

## Instructions

1. **Read the feature document** at `.agent/features/{number}-{name}/README.md`
2. **Review any images/mockups** in `.agent/features/{number}-{name}/images/`
3. **Analyze requirements** and identify logical task breakdown
4. **Create tasks via VK MCP** with proper numbering and dependencies

## Task Numbering System

Number tasks by **dependency level**:

- **`0.x`** = No dependencies, can start immediately (run in parallel)
- **`1.x`** = Blocked by all `0.x` tasks completing
- **`2.x`** = Blocked by all `1.x` tasks completing
- **`3.x`** = Blocked by all `2.x` tasks completing
- Continue as needed

## Task Title Format

```
[f-{feature-num}] [{level}.{seq}] {Task Title}
```

**Examples:**
```
[f-001] [0.1] Add Lucide icons CDN
[f-001] [0.2] Add rimas-badge.svg asset
[f-001] [1.1] Implement toggle JavaScript
[f-001] [2.1] Add animations
```

## Task Sizing Guidelines

- **1-2 agile points** per task (small and focused)
- **30-120 minutes** of work per task
- If larger, break into multiple tasks
- Prefer many small tasks over few large ones
- **Create as many levels and tasks as needed**—do NOT default to a fixed count
- A complex feature may have 15+ tasks; a simple one may have 4

## Task Description Template

Include relevant context and tags:

**For UI implementation:**
```markdown
{Brief description of what to implement}

**Design Reference:**
See `.agent/features/{num}-{name}/images/{mockup}.png`

**Requirements:**
- {Specific requirement 1}
- {Specific requirement 2}

@git-workflow {other relevant tags}
```

**For setup/config:**
```markdown
{Brief description}

@git-workflow
```

**For tasks requiring TDD:**
```markdown
{Brief description}

@tdd @git-workflow
```

## Image References

When mockups/diagrams exist, **reference them in task descriptions**:

```markdown
**Design Reference:**
`.agent/features/001-collapsible-sidebar/images/open.png`
`.agent/features/001-collapsible-sidebar/images/closed.png`
```

Agents can read these images to understand visual requirements.

## Dependency Level Breakdown

### Level 0: Setup & Foundation (0.x)
Tasks with **no dependencies** that can run in parallel:
- Adding libraries/dependencies
- Creating new files/directories
- Adding static assets (images, icons)
- Database migrations
- Configuration changes

**Example:**
```
[f-001] [0.1] Add Lucide icons CDN to base.html
[f-001] [0.2] Add rimas-badge.svg to static/images/
[f-001] [0.3] Create initial sidebar HTML structure
```

### Level 1: Core Implementation (1.x)
Main feature logic, **blocked by Level 0**:
- Business logic implementation
- View functions
- JavaScript functionality
- Basic styling

**Example:**
```
[f-001] [1.1] Implement sidebar toggle JavaScript
[f-001] [1.2] Implement section expand/collapse
[f-001] [1.3] Add localStorage state persistence
```

### Level 2: Integration & Polish (2.x)
Refinements, **blocked by Level 1**:
- Animations and transitions
- Edge case handling
- Permission integration
- Advanced styling

**Example:**
```
[f-001] [2.1] Add smooth animations
[f-001] [2.2] Integrate permission checks
[f-001] [2.3] Handle edge cases
```

### Level 3+: Testing & Documentation (3.x)
Final tasks, **blocked by previous levels**:
- Comprehensive testing
- Documentation updates
- Performance optimization

**Example:**
```
[f-001] [3.1] Add comprehensive tests
[f-001] [3.2] Update .agent/System docs
```

## Using VK MCP Tools

```javascript
// 1. List projects to get project_id
const projects = await list_projects();
const projectId = projects[0].id;

// 2. Create each task
await create_task({
  project_id: projectId,
  title: "[f-001] [0.1] Add Lucide icons CDN",
  description: `Add Lucide icons library from CDN.

Include in base.html <head> section for navigation icons.

@django-patterns @git-workflow`
});
```

## Tag Selection Guide

**Include these tags based on task type:**

- **All tasks**: `@git-workflow`
- **Business logic / validation / pure functions**: `@tdd`
- **Django code**: `@django-patterns`
- **UI/Frontend**: `@tailwind-utilities`
- **Features with auth**: `@permission-checks`
- **Bug fixes**: `@bug_analysis`
- **Refactoring**: `@code_refactoring`

## Complete Example: Feature 001

**Feature:** Collapsible Sidebar Navigation
**Location:** `.agent/features/001-collapsible-sidebar/`
**Images:** `images/open.png`, `images/closed.png`

> **Note:** This is ONE example. Actual task counts vary by feature complexity. Create as many levels and tasks as needed—don't force a fixed structure.

**Level 0 - Parallel Setup (2 tasks):**

```
[f-001] [0.1] Add Lucide icons CDN
Description: Add Lucide icons library from CDN
Tags: @git-workflow

[f-001] [0.2] Create sidebar HTML structure
Description: Replace horizontal nav with vertical sidebar
Design Reference: .agent/features/001-collapsible-sidebar/images/open.png
Tags: @git-workflow
```

**Level 1 - Core Logic (5 tasks):**

```
[f-001] [1.1] Implement sidebar toggle JavaScript
Description: Toggle between open/closed states
Design Reference: Both mockup images
Tags: @git-workflow

[f-001] [1.2] Implement section expand/collapse
Description: Expandable headers with rotating chevrons
Tags: @git-workflow

[f-001] [1.3] Add localStorage persistence
Description: Save sidebar and section states to localStorage
Tags: @tdd @git-workflow

[f-001] [1.4] Apply styling
Description: Apply theme colors, transitions
Tags: @git-workflow

[f-001] [1.5] Integrate permission checks
Description: Hide/show nav items based on user permissions
Tags: @git-workflow
```

**Level 2 - Testing (1 task):**

```
[f-001] [2.1] Add comprehensive tests
Description: Test toggle, persistence, permissions
Tags: @tdd @git-workflow
```

**Total:** 8 tasks across 3 levels

> A simpler feature might be 4 tasks (2-1-1). A complex feature might be 15+ tasks. Let the requirements drive the breakdown.

## Output Summary

After creating tasks, provide:

```
✅ Created N tasks for Feature 001: Collapsible Sidebar

Breakdown:
- Level 0 (Start now): X tasks
- Level 1 (After L0): Y tasks
- Level 2 (After L1): Z tasks
(continue as needed)

Tasks created via VK MCP server and ready to start!
```

## Key Principles

1. **Small tasks** = faster completion, easier parallelization
2. **Clear dependencies** = know exactly when you can start
3. **Proper tagging** = agents have all context they need
4. **Image references** = agents can see visual requirements
5. **Numbered systematically** = easy to track and execute
