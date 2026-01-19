---
description: Document bugs with optional feature linking and VK ticket creation
argument-hint: [feature-number]
allowed-tools: Read, Write, Edit, Bash(ls*), Bash(cp*), Bash(mkdir*), Glob, Grep, AskUserQuestion, mcp__vibe_kanban__list_projects, mcp__vibe_kanban__create_task
---

# Bug Command

Document bugs with optional feature linking and VK ticket creation.

**Syntax:**
```
/bug 001     # Bug tied to feature 001 → .agent/features/001-*/bugs/
/bug         # Standalone bug → .agent/bugs/
```

---

## Prerequisites

**Check if .agent/ exists:**

```bash
ls -la .agent/ 2>/dev/null
```

If `.agent/` doesn't exist:
```
This project doesn't have a .agent/ directory.

Please run /setup first to initialize the project structure.
```

---

## Step 1: Determine Bug Location

**Parse arguments to determine where bug will be stored:**

### If feature number provided (e.g., `/bug 001`)

```bash
ls -d .agent/features/001-*/ 2>/dev/null
```

If feature found:
- Bug will be stored in `.agent/features/001-{name}/bugs/`
- Bug is tied to this feature

If feature not found:
```
Feature 001 not found.

Available features:
[List feature directories]

To create a standalone bug (not tied to a feature):
  /bug

To document a bug for a specific feature:
  /bug <feature-number>
```

### If no argument provided (`/bug`)

**Check context to suggest feature:**

1. Check `.agent/.last-feature` for recent feature
2. If recent feature exists, ask:
   ```
   question: "Is this bug related to a specific feature?"
   header: "Bug Context"
   options:
     - label: "Feature {last-feature}"
       description: "Link to most recently worked feature"
     - label: "Standalone bug"
       description: "Not tied to any feature"
     - label: "Different feature"
       description: "I'll specify the feature"
   ```

If "Different feature" selected, ask for feature number.

---

## Step 2: Create Bug Directory Structure

### For feature-tied bugs:
```bash
mkdir -p .agent/features/{num}-{name}/bugs/images
```

### For standalone bugs:
```bash
mkdir -p .agent/bugs/images
```

**If standalone bugs directory is new, create README:**
- Copy from `~/.claude/workflow/templates/agent/bugs/README.md.template`
- Replace `{{PROJECT_NAME}}` and `{{INIT_DATE}}`

---

## Step 3: Gather Bug Information

**Ask about the bug:**

```
Tell me about the bug you found.

I'll need:
- Brief title/summary
- What went wrong (symptoms)
- Steps to reproduce
- Expected vs actual behavior
- Screenshots (provide file paths if available)
- Severity (Critical/High/Medium/Low)

You can describe everything at once, or I'll ask follow-up questions.
```

**Use `AskUserQuestion` for severity if not provided:**

```
question: "How severe is this bug?"
header: "Severity"
options:
  - label: "Critical"
    description: "Feature broken, data loss, or security issue"
  - label: "High"
    description: "Major functionality broken, no workaround"
  - label: "Medium"
    description: "Feature partially works, workaround exists"
  - label: "Low"
    description: "Minor inconvenience or cosmetic issue"
```

**Gather for each bug:**
1. **Title**: Brief descriptive name
2. **Symptoms**: What went wrong
3. **Repro Steps**: How to reproduce
4. **Expected**: What should happen
5. **Actual**: What actually happened
6. **Screenshots**: File paths (optional)
7. **Severity**: Critical/High/Medium/Low
8. **Technical Notes**: Suspected cause, files to investigate (optional)

---

## Step 4: Determine Bug Number

**Check existing bugs:**

For feature-tied:
```bash
ls .agent/features/{num}-{name}/bugs/BUG-*.md 2>/dev/null
```

For standalone:
```bash
ls .agent/bugs/BUG-*.md 2>/dev/null
```

**Assign next available number** (3-digit format: BUG-001, BUG-002, etc.)

---

## Step 5: Copy Screenshots

If screenshots were provided:

```bash
# Copy and rename to descriptive names
cp /path/to/screenshot.png {bug-dir}/images/bug-{NNN}-{description}.png
```

**Naming convention:**
- `bug-001-error-message.png`
- `bug-001-broken-layout.png` (multiple screenshots per bug OK)

---

## Step 6: Create Bug Documentation

**Create: `{bug-dir}/BUG-{NNN}-{brief-title}.md`**

```markdown
# BUG-{NNN}: {Descriptive Title}

**Status**: Open
**Severity**: {Critical/High/Medium/Low}
**Type**: Bug
**Reported**: {Today's date}
**Feature**: {num}-{name} (or "Standalone" if not tied to feature)

---

## Summary

{Brief description of what's wrong}

---

## Steps to Reproduce

1. {Step 1}
2. {Step 2}
3. {Step 3}
4. **Expected**: {What should happen}
5. **Actual**: {What actually happened}

---

## Screenshots

{Include if provided}

### {Description of screenshot}
![Alt text](./images/bug-{NNN}-{description}.png)

---

## Technical Analysis

### Suspected Root Cause

{If user provided technical notes, include them here}

Possible issues:
1. {Suspected cause 1}
2. {Suspected cause 2}

### Files to Investigate

| File | Purpose |
|------|---------|
| `path/to/file.ts` | {Why this file might be involved} |

### Key Code Paths

{If known, describe the code flow that's likely broken}

---

## Acceptance Criteria for Fix

- [ ] {Specific testable criteria}
- [ ] {Another criteria}
- [ ] Error handling works correctly
- [ ] No regression in related functionality

---

## Related

{If feature-tied}
- Feature: [{num}-{name}](../README.md)

{If from test plan}
- Test Plan: [Test Plan](../../test-plans/{num}-{name}-test-plan.md)

{If VK ticket created}
- VK Ticket: {ticket title}
```

---

## Step 7: Ask About VK Ticket

```
question: "Create a VK ticket for this bug?"
header: "VK Ticket"
options:
  - label: "Yes"
    description: "Create VK ticket for tracking and implementation"
  - label: "No"
    description: "Just document locally for now"
```

---

## Step 8: Create VK Ticket (if requested)

### Get Project ID

```
Use mcp__vibe_kanban__list_projects to find the project ID
```

### Ticket Format

**For feature-tied bugs:**
```
Title: [f-{num}-bug] [1.1] Fix: {Bug Title}
```

**For standalone bugs:**
```
Title: [BUG] {Bug Title}
```

### Ticket Description

```markdown
## Overview

{Brief description of the bug}

## Current Behavior

{What's happening now - the symptoms}

## Expected Behavior

{What should happen instead}

## Steps to Reproduce

1. {Step 1}
2. {Step 2}
3. {Step 3}

## Technical Details

{From bug documentation - suspected cause, files to modify}

## Acceptance Criteria

{From bug documentation}

## Related

- Bug documentation: `.agent/{bug-path}/BUG-{NNN}-{title}.md`
{If feature-tied}
- Feature: {num}-{name}
```

---

## Step 9: Report Completion

```
BUG DOCUMENTED

Bug: BUG-{NNN}: {Title}
Severity: {Severity}
Location: {bug-dir}/BUG-{NNN}-{title}.md

{If screenshots}
Screenshots: {X} images copied to {bug-dir}/images/

{If feature-tied}
Feature: {num}-{name}

{If VK ticket created}
VK Ticket: [f-{num}-bug] [1.1] Fix: {Title}

NEXT STEPS:

{If VK ticket created}
1. VK ticket is ready for implementation
2. Bug fix will be tracked through VK

{If no VK ticket}
1. Fix the bug using /workflow:fix-bug
2. Or create VK ticket later with /bug and select "Yes" for VK

To document additional bugs:
  /bug {feature-num}  # For same feature
  /bug               # For standalone bugs
```

---

## Bug Severity Guide

| Severity | Criteria | Examples |
|----------|----------|----------|
| **Critical** | Feature completely broken, data loss, security vulnerability | Login fails for all users, data corruption, auth bypass |
| **High** | Major functionality broken, no workaround, blocks core journey | Can't save changes, payment fails, critical error |
| **Medium** | Feature partially works, workaround exists, secondary flow affected | Slow performance, occasional error, UI glitch |
| **Low** | Minor inconvenience, cosmetic, edge case | Typo, alignment issue, rare edge case |

---

## Comparison with Related Commands

| Command | Use When |
|---------|----------|
| `/bug` | Document bugs found during testing, with optional VK ticket |
| `/bug {feature}` | Document bugs tied to a specific feature |
| `/workflow:fix-bug` | Fix a bug immediately (quick hotfix workflow) |
| `/workflow:document-issue` | Document an already-fixed issue for future reference |
| `/test-plan` | Generate test plan that may discover bugs |

---

## Migration from /feature-bug

The `/feature-bug` command is deprecated. Use `/bug` instead:

```
OLD: /feature-bug 001
NEW: /bug 001
```

The new `/bug` command adds:
- Standalone bug support (no feature required)
- Auto-detection of recent feature context
- Improved VK ticket integration
- Consistent with unified command naming
