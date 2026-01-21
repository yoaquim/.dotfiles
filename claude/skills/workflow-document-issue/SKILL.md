---
description: Document known issues, bugs, or troubleshooting insights for future reference
argument-hint: <issue description>
allowed-tools: Read, Write, Edit, Bash(find*), Bash(ls*), Bash(git*), Grep, Glob
---

You are documenting a known issue, bug, or troubleshooting insight for future reference.

**Use this when:**
- You encountered a bug and fixed it (want to document for future)
- Discovered a gotcha or edge case worth noting
- Learned something non-obvious while debugging
- Want to capture "what went wrong and how we fixed it"

**This is NOT for:**
- Planning features (use `/feature`)
- Fixing bugs actively (use `/workflow:fix-bug`)
- General documentation updates (use `/workflow:update-doc`)

---

## CRITICAL: Before Documenting, Read

1. `CLAUDE.md` (project root) - Core instructions
2. `.agent/README.md` - Documentation index
3. `.agent/known-issues/README.md` - Index of existing issues (if exists)

---

## Step 0.5: Search for Similar Issues Across Projects

**Search ALL projects** to see if a similar issue has been documented before.

**If similar issue found:**
- Reference it in your documentation
- Note differences in context or solution
- Consider if this is a pattern worth adding to SOPs

---

## Step 1: Gather Issue Information

**Required:**
- Issue title/summary
- What went wrong (symptoms)
- Root cause (why it happened)
- The fix/solution (how it was resolved)

**Optional:**
- Severity (Low/Medium/High)
- Related task number
- Code changes (diff or file references)
- Prevention tips
- Status (Resolved/Workaround/Ongoing)

---

## Step 2: Determine Issue Number

**If `.agent/known-issues/` doesn't exist:**
1. Create directory
2. Create README.md index
3. This is issue 01

**If exists:**
1. Find highest existing issue number
2. Use next sequential number (2-digit: 01, 02, etc.)

---

## Step 3: Create Issue Document

**Filename**: `NN-brief-title.md`
**Location**: `.agent/known-issues/`

```markdown
# Known Issue NN: [Short Descriptive Title]

**Date**: [Today's date]
**Severity**: [Low | Medium | High]
**Status**: [Resolved | Workaround | Ongoing]
**Related Task**: [Task XXX if applicable, or "N/A"]

## Cross-Project Context

**Similar issues found**: [Y/N]
[If yes, list similar issues from other projects]

## The Problem

[Clear description of what went wrong]

**Symptoms:**
- What did users/developers experience?
- Error messages
- Unexpected behavior

**Context:**
- When was this discovered?
- What were you doing?

## Root Cause

[Why did this happen?]

## The Fix

[How was it resolved?]

**Code Changes** (if applicable):
```diff
- old problematic code
+ new fixed code
```

## Prevention

[How to avoid this in the future]

## Tags

`tag1` `tag2` `tag3`

## References

- Task: [Task XXX](../tasks/XXX-task-name.md)
- Commit: [hash if relevant]
- Related Issues: [links]
```

---

## Step 4: Update Known-Issues Index

Update `.agent/known-issues/README.md`:
- Add new issue to "Issues by Number" list
- Add to appropriate category
- Maintain numerical order

---

## Step 5: Update Main Documentation Index

Ensure `.agent/README.md` links to known-issues directory.

---

## Step 6: Link from Related Task (If Applicable)

If related task provided:
1. Open `.agent/tasks/XXX-task-name.md`
2. Add reference to known issue in "Known Issues" section

---

## Step 7: Report Creation

```
ISSUE DOCUMENTED: Issue NN - [Title]

Issue File: .agent/known-issues/NN-issue-name.md
Severity: [Level]
Status: [Status]

[If related to task]
Linked to Task XXX

[If similar issues found]
Referenced similar issues from [N] other project(s)

Updated: .agent/known-issues/README.md
Updated: .agent/README.md

This issue is now documented and searchable across all projects.
```

---

## Categories

Auto-categorize based on content/tags:

- **Django** - Django-specific issues
- **Database** - Schema, migrations, queries
- **Infrastructure** - Docker, deployment
- **Frontend** - HTMX, Tailwind, templates
- **Testing** - Test-related issues
- **Security** - Auth, permissions
- **Performance** - Optimization

---

## Search Tips

```bash
# Search local issues
grep -r "error message" .agent/known-issues/

# Search ALL projects
find ~/Projects -type f -path "*/.agent/known-issues/*.md" -exec grep -l "keyword" {} \;
```

---

## When to Use vs Other Commands

| Command | Use When |
|---------|----------|
| `/workflow:document-issue` | Bug is FIXED, capturing lessons learned |
| `/workflow:fix-bug` | Bug needs to be FIXED right now |
| `/workflow:update-doc` | Updating general project documentation |
| `/feature` | Planning new features |
