---
description: Document bugs discovered during feature testing and create VK tickets for fixes
argument-hint: <feature-number>
allowed-tools: Read, Write, Edit, Bash(ls*), Bash(cp*), Bash(mkdir*), Glob, Grep, AskUserQuestion, mcp__vibe_kanban__list_projects, mcp__vibe_kanban__create_task
---

You are documenting bugs discovered during feature testing and creating VK tickets for fixes.

**Use this when:**
- Testing a feature and finding bugs
- Multiple bugs to report for a single feature
- Bugs need VK tickets for tracking/implementation
- Want bugs tied to feature documentation (not global known-issues)

**This is NOT for:**
- Fixing bugs immediately (use `/workflow:fix-bug`)
- Documenting already-fixed bugs (use `/workflow:document-issue`)
- Bugs unrelated to a specific feature

---

## Prerequisites

**CRITICAL: Check if feature exists first**

If feature directory doesn't exist:
```
Feature XXX not found at .agent/features/XXX-*/

Available features:
- 001-feature-name
- 002-other-feature

Please specify a valid feature number.
```

---

## Step 1: Identify Feature

**If feature number provided:**
```bash
ls -d .agent/features/XXX-*/
```

**If no feature number provided:**
1. Check `.agent/.last-feature` for most recent feature
2. List available features and ask user to confirm

**Confirm feature:**
```
FEATURE BUG TRACKING

Feature: XXX - [Feature Name]
Location: .agent/features/XXX-feature-name/

Is this the correct feature? (yes/no/other feature number)
```

---

## Step 2: Gather Bug Reports

Ask user about bugs discovered:

```
What bugs did you discover during testing?

For each bug, I'll need:
- Brief title/summary
- Steps to reproduce
- Expected vs actual behavior
- Screenshots (if available - provide file paths)
- Severity (Critical/High/Medium/Low)

You can describe multiple bugs at once, or we can go one at a time.
```

**For each bug, gather:**
1. **Title**: Brief descriptive name
2. **Symptoms**: What went wrong
3. **Repro Steps**: How to reproduce
4. **Expected**: What should happen
5. **Actual**: What actually happened
6. **Screenshots**: File paths to screenshots (optional)
7. **Severity**: Critical/High/Medium/Low
8. **Technical Notes**: Suspected cause, files to investigate (optional)

**Ask clarifying questions as needed:**
- "What exactly did you see when X happened?"
- "Can you reproduce this consistently?"
- "Do you have screenshots I can include?"
- "Which files do you think are involved?"

---

## Step 3: Create Bug Directory Structure

```bash
mkdir -p .agent/features/XXX-feature-name/bugs/images
```

---

## Step 4: Copy Screenshots

If user provided screenshot paths:

```bash
# Copy and rename to descriptive names
cp /path/to/screenshot1.png .agent/features/XXX-feature-name/bugs/images/bug-001-description.png
cp /path/to/screenshot2.png .agent/features/XXX-feature-name/bugs/images/bug-002-description.png
```

**Naming convention:**
- `bug-NNN-brief-description.png`
- `bug-001-user-in-room.png`
- `bug-001-error-message.png` (multiple screenshots per bug OK)

---

## Step 5: Determine Bug Numbers

Check existing bugs:
```bash
ls .agent/features/XXX-feature-name/bugs/BUG-*.md 2>/dev/null
```

Start from BUG-001, or continue from highest existing number.

**Note**: Bug numbers use 3-digit format (BUG-001, BUG-002, etc.)

---

## Step 6: Create Bug Documentation

**For each bug, create: `.agent/features/XXX-feature-name/bugs/BUG-NNN-brief-title.md`**

**Template:**

```markdown
# BUG-NNN: [Descriptive Title]

**Status**: Open
**Severity**: [Critical/High/Medium/Low]
**Type**: [Bug/Enhancement]
**Reported**: [Today's date]
**Feature**: XXX-feature-name

---

## Summary

[Brief description of what's wrong]

---

## Steps to Reproduce

1. [Step 1]
2. [Step 2]
3. [Step 3]
4. **Expected**: [What should happen]
5. **Actual**: [What actually happened]

---

## Screenshots

[Include if provided]

### [Description of screenshot]
![Alt text](./images/bug-NNN-description.png)

---

## Technical Analysis

### Suspected Root Cause

[If user provided technical notes, include them here]

Possible issues:
1. [Suspected cause 1]
2. [Suspected cause 2]

### Files to Investigate

| File | Purpose |
|------|---------|
| `path/to/file.ts` | [Why this file might be involved] |
| `path/to/other.ts` | [Why this file might be involved] |

### Key Code Paths

[If known, describe the code flow that's likely broken]

```
ComponentA
  -> calls ServiceB
  -> ServiceB queries [...]
  -> Error occurs at [...]
```

---

## Acceptance Criteria for Fix

- [ ] [Specific testable criteria]
- [ ] [Another criteria]
- [ ] [Error handling criteria]
- [ ] [Edge case criteria]

---

## Related

- Feature: [XXX-feature-name](../README.md)
- Related Bug: [BUG-NNN if related]
```

---

## Step 7: Ask About E2E Tests

```
Do you want to create VK tickets for Playwright e2e tests?

This will create test tickets that depend on the bug fixes:
- E2E test for each bug's happy path
- E2E test for error scenarios
- Tests run after bug fixes are merged

Create e2e test tickets? (yes/no)
```

---

## Step 8: Create VK Tickets

### Get Project ID

```
Use mcp__vibe_kanban__list_projects to find the project ID
```

### Ticket Structure

Use feature number as prefix: `[f-XXX-bug]`

**Level 0 (if DB changes needed):**
- `[f-XXX-bug] [0.1] Database model changes for [feature area]`

**Level 1 - Bug Fixes:**
- `[f-XXX-bug] [1.1] Fix [bug 1 title]`
- `[f-XXX-bug] [1.2] Fix [bug 2 title]`
- `[f-XXX-bug] [1.3] Fix [bug 3 title]`

**Level 2 - E2E Tests (if requested):**
- `[f-XXX-bug] [2.1] E2E test: [bug 1 scenario]`
- `[f-XXX-bug] [2.2] E2E test: [bug 2 scenario]`
- `[f-XXX-bug] [2.3] E2E test: [bug 3 scenario]`

### Ticket Descriptions

**For bug fix tickets, include:**
```markdown
## Overview
[Brief description of the bug]

## Current Behavior
[What's happening now]

## Expected Behavior
[What should happen]

## Technical Details
[From bug documentation - suspected cause, files to modify]

## Acceptance Criteria
[From bug documentation]

## Related
- Bug documentation: `.agent/features/XXX-feature-name/bugs/BUG-NNN-title.md`
- Feature: XXX-feature-name
```

**For e2e test tickets, include:**
```markdown
## Overview
Create Playwright e2e tests to verify [bug scenario] works correctly after fix.

**Depends on**: [1.X] Bug fix must be implemented first

## Test Scenarios

### Test 1: [Happy path]
```typescript
test('[description]', async ({ page }) => {
  // Test outline
});
```

### Test 2: [Error scenario]
```typescript
test('[description]', async ({ page }) => {
  // Test outline
});
```

## File Location
`client/e2e/[feature-area].spec.ts`

## Acceptance Criteria
- [ ] All test scenarios pass
- [ ] Tests run in CI pipeline

## Related
- Bug fix: [1.X] Fix [bug title]
- Bug documentation: `BUG-NNN-title.md`
```

---

## Step 9: Report Completion

```
FEATURE BUGS DOCUMENTED

Feature: XXX - [Feature Name]
Bug Directory: .agent/features/XXX-feature-name/bugs/

BUGS DOCUMENTED:
- BUG-001: [Title] (Severity: [X])
- BUG-002: [Title] (Severity: [X])
- BUG-003: [Title] (Severity: [X])

SCREENSHOTS:
- [X] images copied to bugs/images/

VK TICKETS CREATED:

Level 0 (Setup):
- [0.1] [Title if applicable]

Level 1 (Bug Fixes):
- [1.1] Fix [bug 1]
- [1.2] Fix [bug 2]
- [1.3] Fix [bug 3]

Level 2 (E2E Tests):
- [2.1] E2E test: [scenario 1]
- [2.2] E2E test: [scenario 2]
- [2.3] E2E test: [scenario 3]

EXECUTION ORDER:
1. Level 0 runs first (if any)
2. Level 1 tasks run in parallel (bug fixes)
3. Level 2 tasks run in parallel (e2e tests after fixes merge)

Bug documentation is linked to feature and ready for implementation.
```

---

## Best Practices

### DO:
- Include screenshots when available
- Write clear reproduction steps
- Identify suspected root cause when possible
- Create testable acceptance criteria
- Link bugs to feature documentation
- Include e2e tests for regression prevention

### DON'T:
- Document trivial issues (typos, etc.)
- Skip reproduction steps
- Leave acceptance criteria vague
- Create duplicate bug reports
- Mix bugs from different features

---

## Bug Severity Guide

**Critical:**
- Feature is completely broken
- Data loss or corruption
- Security vulnerability
- Blocks all users

**High:**
- Major functionality broken
- Significant user impact
- No workaround available
- Affects core user journey

**Medium:**
- Feature partially works
- Workaround exists
- Moderate user impact
- Affects secondary flows

**Low:**
- Minor inconvenience
- Edge case only
- Easy workaround
- Cosmetic issues

---

## Integration with VK

VK ticket levels ensure proper execution order:
- **Level 0**: Setup/infrastructure (runs first, sequentially)
- **Level 1**: Bug fixes (run in parallel after level 0)
- **Level 2**: E2E tests (run in parallel after level 1 merges)

This prevents merge conflicts and ensures tests verify actual fixes.

---

## Relation to Other Commands

| Command | When to Use |
|---------|-------------|
| `/feature-bugs` | Bugs found during feature testing, need VK tickets |
| `/workflow:fix-bug` | Need to fix a bug RIGHT NOW |
| `/workflow:document-issue` | Document a FIXED bug for future reference |

**Workflow:**
1. `/feature` - Define feature requirements
2. `/vk-plan` - Create implementation tickets
3. [VK implements feature]
4. `/feature-bugs` - Document bugs found during testing
5. [VK fixes bugs via created tickets]
