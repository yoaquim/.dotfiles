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
- Planning features (use `/plan-task`)
- Fixing bugs actively (use `/fix-bug`)
- General documentation updates (use `/update-doc`)

**CRITICAL: Before documenting, read:**
1. `CLAUDE.md` (project root) - Core instructions
2. `.agent/README.md` - Documentation index
3. `.agent/known-issues/README.md` - Index of existing issues (if exists)

## Step 0.5: Search for Similar Issues Across Projects

**IMPORTANT: Search ALL projects** to see if a similar issue has been documented before using relevant keywords from the issue (e.g., "admin", "fieldsets", "timezone").

**Report findings:**
```
🔍 CROSS-PROJECT SEARCH RESULTS

Found [N] similar issues in other projects:
- [Project name]: .agent/known-issues/NN-issue-name.md
  - Similar problem: [brief description]
  - Solution: [what worked]
  - Applicable: Yes/No/Partially

[Or]
No similar issues found in other projects.
```

**If similar issue found:**
- Reference it in your documentation
- Note differences in context or solution
- Link to the other project's issue
- Consider if this is a pattern worth adding to SOPs

## Step 1: Gather Issue Information

Ask the user for details (if not provided):

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

**Example prompt from user:**
```
I want to document an issue where Django admin threw a FieldError 
when accessing /admin/auth/user/add/ because 'role' was in fieldsets 
but it's a form field, not a model field. 

This was from Task 06. The fix was removing 'role' from the regular 
fieldsets and keeping it only in add_fieldsets.

File: apps/users/admin.py
```

## Step 2: Determine Issue Number

**Check for existing known-issues directory:**

If `.agent/known-issues/` doesn't exist:
1. Create `.agent/known-issues/` directory
2. Create `.agent/known-issues/README.md` index
3. This is issue 01

If `.agent/known-issues/` exists:
1. Read `.agent/known-issues/` directory
2. Find highest existing issue number
3. Use next sequential number (e.g., if last is 02, create 03)

**Note**: Known issues use 2-digit numbering (01-99)

## Step 3: Create Issue Document

**Filename**: `NN-brief-title.md` (kebab-case, 2-digit number)
**Location**: `.agent/known-issues/`

**Template:**

```markdown
# Known Issue NN: [Short Descriptive Title]

**Date**: [Today's date]
**Severity**: [Low | Medium | High]
**Status**: [Resolved | Workaround | Ongoing]
**Related Task**: [Task XXX if applicable, or "N/A"]

## Cross-Project Context

**Similar issues found**: [Y/N]
[If yes, list similar issues from other projects with brief summary and links]

## The Problem

[Clear description of what went wrong]

**Symptoms:**
- What did users/developers experience?
- Error messages
- Unexpected behavior

**Context:**
- When was this discovered?
- What were you doing when it occurred?
- Environment (development/production/testing)

## Root Cause

[Why did this happen?]

**Analysis:**
- What was the underlying issue?
- Why did the code/config behave this way?
- What assumptions were incorrect?

## The Fix

[How was it resolved?]

**Solution:**
- What changes were made?
- Which files were modified?
- Configuration changes?

**Code Changes** (if applicable):
```diff
# File: path/to/file.py
- old problematic code
+ new fixed code
```

Or reference specific lines:
- File: `apps/users/admin.py`
- Lines: 80-95
- Change: Removed 'role' from fieldsets

## Prevention

[How to avoid this in the future]

**Recommendations:**
- What to check before making similar changes?
- Warning signs to watch for
- Best practices to follow

**Related Documentation:**
- Link to relevant SOPs if this should update procedures
- Link to task documentation
- Link to similar issues (both local and cross-project)

## Tags

[Keywords for searchability]
`django` `admin` `fields` `configuration` `forms`

## References

- Task: [Task XXX](../tasks/XXX-task-name.md)
- Commit: [hash if relevant]
- Related Issues (Local): [Issue NN if any]
- Related Issues (Other Projects): [Project-name]/.agent/known-issues/NN-issue.md
- External Resources: [Stack Overflow, docs, etc. if relevant]
```

## Step 4: Update Known-Issues Index

**If this is the first issue:**

Create `.agent/known-issues/README.md`:

```markdown
# Known Issues & Troubleshooting

This directory contains documentation for bugs, issues, and gotchas encountered during development. These serve as a reference to avoid repeating mistakes and to understand common pitfalls.

## Purpose

Document issues that:
- Were non-obvious or tricky to debug
- Could happen again
- Provide learning value
- Help future developers avoid the same problem

## Issues by Number

- [01 - Issue Title](./01-issue-name.md) - Brief description [Status]

## Issues by Category

### Django
- [01 - Issue Title](./01-issue-name.md)

### Database
_(None yet)_

### Infrastructure
_(None yet)_

### Frontend
_(None yet)_

## Cross-Project Search

Known issues are searchable across **all projects** in `~/Projects`:

```bash
# Search all known-issues directories
find ~/Projects -type f -path "*/\.agent/known-issues/*.md" -exec grep -r "keyword" {} \;

# Or use /fix-bug which searches automatically
```

This allows you to learn from issues encountered in other projects.

## How to Use

1. Search this directory when encountering errors
2. Reference issue numbers in task documentation
3. Add new issues with `/document-issue` command
4. Update status if issue resurfaces or is resolved differently
5. Search across all projects for similar patterns

## Index

[Full alphabetical index will be maintained here as issues grow]
```

**If known-issues/README.md already exists:**

Update it by:
1. Adding new issue to "Issues by Number" list
2. Adding to appropriate category
3. Maintaining numerical order

Format:
```markdown
- [NN - Issue Title](./NN-issue-name.md) - Brief one-line description [Status]
```

## Step 5: Update Main Documentation Index

Update `.agent/README.md`:

**Add section after "Standard Operating Procedures":**

```markdown
### Known Issues & Troubleshooting
- [Known Issues Index](./known-issues/README.md) - Documented bugs, gotchas, and troubleshooting guides
```

**Or if section exists, ensure link is present.**

## Step 6: Link from Related Task (If Applicable)

If user provided a related task number:

1. Open `.agent/tasks/XXX-task-name.md`
2. Find or create "Known Issues" section (usually near end or in Implementation Summary)
3. Add reference:

```markdown
## Known Issues

- [Issue NN: Brief Title](../known-issues/NN-issue-name.md) - Discovered during implementation
```

## Step 7: Report Creation

```
✅ ISSUE DOCUMENTED: Issue NN - [Title]

📄 Issue File: .agent/known-issues/NN-issue-name.md
📊 Severity: [Level]
✅ Status: [Status]

[If related to task]
🔗 Linked to Task XXX: [Task name]
📝 Updated task documentation

[If similar issues found in other projects]
🔍 Referenced similar issues from [N] other project(s)

📚 Updated: .agent/known-issues/README.md
📚 Updated: .agent/README.md

This issue is now documented for future reference and searchable across all projects.

Would you like to:
A) Document another issue
B) Review all known issues
C) Continue with current work
```

## Categorization

Auto-categorize based on content/tags:

**Django** - Django-specific issues
**Database** - Schema, migrations, queries
**Infrastructure** - Docker, deployment, services
**Frontend** - HTMX, Tailwind, templates
**Testing** - Test-related issues
**Security** - Auth, permissions, vulnerabilities
**Performance** - Slow queries, optimization

Add to appropriate category in README.md.

## Tips for Good Issue Documentation

**DO:**
- ✅ Be specific about error messages
- ✅ Include file paths and line numbers
- ✅ Explain WHY it was wrong, not just WHAT was wrong
- ✅ Add prevention tips
- ✅ Use tags for searchability
- ✅ Link to related tasks/commits

**DON'T:**
- ❌ Document trivial typos (use /fix-bug instead)
- ❌ Document one-time environment issues
- ❌ Duplicate information already in SOPs
- ❌ Write vague descriptions
- ❌ Skip the root cause analysis

## When to Use vs Other Commands

**Use `/document-issue` when:**
- Bug is FIXED and you want to capture lessons learned
- Non-obvious issue worth documenting
- Will help future developers

**Use `/fix-bug` when:**
- Bug needs to be FIXED right now
- Active debugging and resolution

**Use `/update-doc` when:**
- Updating general project documentation
- Not specifically about an issue/bug

**Use `/plan-task` when:**
- Planning new features or improvements
- Not about problems/bugs

## Issue Lifecycle

1. **Discovered** → Document with status "Ongoing" or "Workaround"
2. **Fixed** → Update to status "Resolved", add fix details
3. **Resurfaces** → Add note about recurrence, link related issues
4. **Prevented** → Update prevention section with new insights

Issues are never deleted - they serve as historical knowledge base.

## Search Tips

Users can search issues by:
```bash
# Search local issues only
grep -r "error message" .agent/known-issues/

# Search across ALL projects
find ~/Projects -type f -path "*/\.agent/known-issues/*.md" -exec grep -l "error message" {} \;

# Find Django-related issues (all projects)
find ~/Projects -type f -path "*/\.agent/known-issues/*.md" -exec grep -l "django" {} \;

# Find by severity (all projects)
find ~/Projects -type f -path "*/\.agent/known-issues/*.md" -exec grep -l "Severity: High" {} \;
```

Or browse `.agent/known-issues/README.md` by category.

**Cross-project search is powerful** - use it to learn from similar issues in other codebases!
