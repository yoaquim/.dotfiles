---
description: Plan a feature with detailed implementation plan and task documentation
argument-hint: [feature description]
allowed-tools: Read, Write, Grep, Glob, AskUserQuestion, Bash(ls*)
---

You are in PLAN MODE. Generate a detailed implementation plan (HOW to build) for the requested feature, then offer to capture it as a task document.

**This command combines planning and documentation in one flow.**

**Use this when:**
- Planning HOW to implement a feature
- Need structured approach before implementation
- Want to document the plan for future reference

**Note:** For defining WHAT to build (user requirements), use `/feature` first. This command focuses on HOW to implement.

---

## Step 0: Determine Feature to Plan

**If user provided argument** (e.g., `/plan-task "asset upload backend"`):
- Use that as the feature to plan
- Check if matching feature requirements exist in `.agent/features/`

**If NO argument provided:**
- Check for `.agent/.last-feature` file
- If exists, read it to get the last defined feature
- Confirm with user: "Planning implementation for feature: [feature-name]. Correct?"

**Check for existing feature requirements:**
```bash
ls -la .agent/features/ 2>/dev/null
```

**If matching feature requirements found:**
- Read `.agent/features/NNN-feature-name/README.md` FIRST
- Use requirements as guide for planning
- Reference the requirements doc in the task

---

## Step 1: Read Context

**CRITICAL: Before planning, you MUST read:**
1. `CLAUDE.md` (project root) - Core project instructions
2. `.agent/README.md` - Documentation index
3. `.agent/system/overview.md` - Current project status and tech stack
4. `.agent/system/architecture.md` - Technical architecture
5. `.agent/tasks/` - Review completed tasks to understand what exists
6. Relevant SOP documents

---

## Your Plan Should Include:

1. **Problem Statement**
   - What needs to be solved or built?
   - Why is this needed now?

2. **Solution Overview**
   - High-level approach
   - Key technical decisions
   - Trade-offs considered

3. **Implementation Plan**
   - Break into phases (Phase 1, Phase 2, etc.)
   - Each phase should have clear steps
   - Identify files to create/modify

4. **Success Criteria**
   - Specific, testable conditions
   - What "done" looks like

5. **Technical Decisions**
   - Why this approach over alternatives?

6. **Documentation Updates**
   - Which docs need updating?

---

## After Generating Plan

Present the complete plan, then ask:

```
PLAN COMPLETE

Would you like to capture this as a task document?

Options:
- YES - Create task document and prepare for implementation
- NO - Keep plan in chat only (informal planning)
- REVISE - Refine the plan before capturing

Choose: (yes/no/revise)
```

---

## If User Chooses YES - Capture Task

### 1. Determine Task Number
- Read `.agent/tasks/` directory
- Find highest existing task number
- Use next sequential number (3-digit: 001, 002, etc.)

### 2. Create Task Document

**Filename**: `XXX-feature-name.md`
**Location**: `.agent/tasks/`

Use `.agent/task-template.md` format:

```markdown
# Task XXX: [Feature Name]

**Status**: Planned
**Branch**: `feature/feature-name`
**Priority**: [Determined from plan]
**Planned**: [Today's date]
**Feature Requirements**: [Link to .agent/features/NNN-feature-name/README.md if exists]

## Problem
[Copy from plan]

## Solution
[Copy from plan]

## Implementation Plan
[Copy phases from plan]

## Success Criteria
[Copy from plan]

## Technical Decisions
[Copy from plan]

## Testing Strategy
[From plan]

## Documentation Updates
[From plan]
```

### 3. Update Documentation Index
Update `.agent/README.md` with new task.

### 4. Report Creation

```
TASK DOCUMENTED: Task XXX - [Feature Name]

Task File: .agent/tasks/XXX-feature-name.md
Status: Planned

Next steps:
→ Run /workflow:implement-task to start building
```

---

## If User Chooses REVISE

Ask what to change, regenerate sections, show updated plan, ask again.
