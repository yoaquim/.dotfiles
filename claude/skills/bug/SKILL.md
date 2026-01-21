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

If `.agent/` doesn't exist, instruct user to run `/setup` first.

---

## Step 1: Determine Bug Location

**Parse arguments to determine where bug will be stored:**

### If feature number provided (e.g., `/bug 001`)
- Bug stored in `.agent/features/001-{name}/bugs/`
- Bug is tied to this feature

### If no argument provided (`/bug`)
- Check `.agent/.last-feature` for recent feature
- Ask if bug is related to a feature or standalone
- Standalone bugs go to `.agent/bugs/`

---

## Step 2: Create Bug Directory Structure

```bash
# For feature-tied bugs:
mkdir -p .agent/features/{num}-{name}/bugs/images

# For standalone bugs:
mkdir -p .agent/bugs/images
```

---

## Step 3: Gather Bug Information

**Ask about the bug:**
- Brief title/summary
- What went wrong (symptoms)
- Steps to reproduce
- Expected vs actual behavior
- Screenshots (file paths if available)
- Severity (Critical/High/Medium/Low)

**Use `AskUserQuestion` for severity:**
- Critical: Feature broken, data loss, security issue
- High: Major functionality broken, no workaround
- Medium: Feature partially works, workaround exists
- Low: Minor inconvenience or cosmetic issue

---

## Step 4: Determine Bug Number

Check existing bugs in the target directory.
Assign next available number (3-digit: BUG-001, BUG-002, etc.)

---

## Step 5: Copy Screenshots

If screenshots provided:
```bash
cp /path/to/screenshot.png {bug-dir}/images/bug-{NNN}-{description}.png
```

---

## Step 6: Create Bug Documentation

**Create: `{bug-dir}/BUG-{NNN}-{brief-title}.md`**

```markdown
# BUG-{NNN}: {Descriptive Title}

**Status**: Open
**Severity**: {Critical/High/Medium/Low}
**Type**: Bug
**Reported**: {Today's date}
**Feature**: {num}-{name} (or "Standalone")

---

## Summary
{Brief description}

## Steps to Reproduce
1. {Step 1}
2. {Step 2}
3. **Expected**: {What should happen}
4. **Actual**: {What actually happened}

## Screenshots
![Alt text](./images/bug-{NNN}-{description}.png)

## Technical Analysis

### Suspected Root Cause
{If provided}

### Files to Investigate
| File | Purpose |
|------|---------|
| `path/to/file.ts` | {Why involved} |

## Acceptance Criteria for Fix
- [ ] {Specific testable criteria}
- [ ] Error handling works correctly
- [ ] No regression in related functionality
```

---

## Step 7: Ask About VK Ticket

Use `AskUserQuestion`:
- "Create a VK ticket for this bug?"
- Options: "Yes" / "No"

---

## Step 8: Create VK Ticket (if requested)

Get project ID and create ticket with appropriate format:
- Feature-tied: `[f-{num}-bug] [1.1] Fix: {Bug Title}`
- Standalone: `[BUG] {Bug Title}`

---

## Step 9: Report Completion

```
BUG DOCUMENTED

Bug: BUG-{NNN}: {Title}
Severity: {Severity}
Location: {bug-dir}/BUG-{NNN}-{title}.md

NEXT STEPS:
- Fix with /workflow:fix-bug
- Or work through VK ticket
```

---

## Bug Severity Guide

| Severity | Criteria | Examples |
|----------|----------|----------|
| **Critical** | Feature broken, data loss, security | Login fails, data corruption, auth bypass |
| **High** | Major functionality broken, no workaround | Can't save, payment fails |
| **Medium** | Partially works, workaround exists | Slow performance, occasional error |
| **Low** | Minor inconvenience, cosmetic | Typo, alignment issue |
