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
- Confirm with user: "Planning implementation for feature: [feature-name]. Correct? (yes/no)"
- If user says no or file doesn't exist, ask: "What feature would you like to plan?"

**Check for existing feature requirements:**
```bash
# Look for matching features
ls -la .agent/features/ 2>/dev/null
```

**If matching feature requirements found:**
- Read `.agent/features/<feature-name>.md` FIRST
- Use requirements as guide for planning
- Ensure implementation plan addresses all requirements
- Reference the requirements doc in the task

**If no feature requirements found:**
- Plan based on user's description
- Focus on technical implementation
- May suggest running `/feature` first for complex features

---

## Step 1: Read Context

**CRITICAL: Before planning, you MUST read:**
1. `CLAUDE.md` (project root) - Core project instructions
2. `.agent/README.md` - Documentation index
3. `.agent/system/overview.md` - Current project status and tech stack
4. `.agent/system/architecture.md` - Technical architecture
5. `.agent/tasks/` - Review completed tasks to understand what exists
6. Relevant SOP documents for the type of work (e.g., django-setup.md, branching-workflow.md)

**Planning approach:**
- Understand the current state before proposing changes
- Follow the SIMPLICITY principle - break complex features into smaller tasks
- Leverage existing patterns and infrastructure
- Consider testing strategy upfront
- Identify documentation that needs updating

**Your plan should include:**

1. **Problem Statement**
   - What needs to be solved or built?
   - Why is this needed now?
   - Current pain points or gaps

2. **Solution Overview**
   - High-level approach
   - Key technical decisions
   - Trade-offs considered

3. **Implementation Plan**
   - Break into phases (Phase 1, Phase 2, etc.)
   - Each phase should have clear steps
   - Identify files to create/modify
   - Reference relevant SOPs

4. **Success Criteria**
   - Specific, testable conditions
   - What "done" looks like
   - Testing requirements

5. **Technical Decisions**
   - Why this approach over alternatives?
   - Dependencies and integrations
   - Risks and considerations

6. **Documentation Updates**
   - Which System docs need updating?
   - Which SOPs are relevant?
   - Are new SOPs needed?

**After generating the plan:**

Present the complete plan, then ask:

```
📋 PLAN COMPLETE

Would you like to capture this as a task document?

Options:
✅ YES - Create task document and prepare for implementation
❌ NO - Keep plan in chat only (informal planning)
🔄 REVISE - Refine the plan before capturing

Choose: (yes/no/revise)
```

## If User Chooses YES - Capture Task

**Execute task capture workflow:**

### 1. Determine Task Number
- Read `.agent/tasks/` directory
- Find highest existing task number
- Use next sequential number (e.g., if last is 05, create 06)

### 2. Create Task Document

**Filename**: `XX-feature-name.md` (kebab-case from feature description)
**Location**: `.agent/tasks/`

Use the plan just generated and format it according to `.agent/task-template.md`:

```markdown
# Task XXX: [Feature Name]

**Status**: ⚠️ Planned
**Branch**: `feature/feature-name`
**Priority**: [Determined from plan]
**Planned**: [Today's date]
**Feature Requirements**: [Link to .agent/features/<feature>.md if exists, otherwise "N/A"]

## Problem

[Copy from plan]

## Solution

[Copy from plan]

## Implementation Plan

[Copy phases from plan]

## Success Criteria

[Copy/convert from plan]

## Technical Decisions

[Copy from plan]

## Testing Strategy

[From plan or generate based on feature]

## Documentation Updates

[From plan]

## Git Workflow

[Standard workflow]

## Priority Rationale

[From plan if included]
```

### 3. Update Documentation Index

Update `.agent/README.md`:
- Add task to the Tasks section
- Use format: `- [XX - Feature Name](./Tasks/XX-feature-name.md) - ⚠️ Planned - [Brief description]`
- Maintain numerical order

### 4. Update Project Status (if needed)

If significant feature, update `.agent/system/overview.md`:
- Add to "Next Steps" section
- Update "Current State" if relevant

### 5. Report Creation

```
✅ TASK DOCUMENTED: Task XXX - [Feature Name]

📄 Task File: .agent/tasks/XX-feature-name.md
📋 Status: Planned ⚠️
📚 Updated: .agent/README.md

Ready to implement!

Next steps:
→ Run /implement-task to start building
→ Or review the task document first
→ Or plan another task

What would you like to do?
```

## If User Chooses NO - Keep in Chat

```
Plan generated but not captured as task document.

You can:
- Run /plan-task again to create a task document
- Continue with implementation informally
- Plan another task
- Review and revise this plan

The plan remains in this conversation for reference.
```

## If User Chooses REVISE - Refine Plan

Ask what to change:
```
What would you like to revise?

Examples:
- "Add more detail to Phase 3"
- "Change the testing strategy"
- "Simplify the implementation"
- "Add security considerations"

Your feedback:
```

After receiving feedback:
- Regenerate the relevant sections
- Show updated plan
- Ask again: "Capture as task? (yes/no/revise)"