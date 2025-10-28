---
description: Sync .agent/ documentation with Vibe Kanban task progress
allowed-tools: Read, Edit, Write, Grep, Glob, mcp__vibe_kanban__*
---

You are synchronizing `.agent/` system documentation with current Vibe Kanban task progress.

**Purpose**: Keep project documentation current as VK tasks complete.

**When to use:**
- Backup to auto-generated documentation subtasks
- When documentation subtasks skipped/delayed
- Periodic documentation health check
- Before major milestones or demos

**Note**: In VK workflow, each epic should have a documentation subtask. This command is a **backup option** if those subtasks aren't executed or need supplementing.

---

## Prerequisites

**Check VK workflow enabled:**

```bash
# Check for .agent/.vk-enabled marker
ls .agent/.vk-enabled 2>/dev/null
```

If not VK-enabled:
```
⚠️ This command is for VK-enabled projects.

Use /review-docs or /update-doc for standard workflow.
```

Exit if not VK-enabled.

**Check VK connection:**
```
mcp__vibe_kanban__list_projects
```

If fails:
```
❌ Cannot connect to Vibe Kanban.

Cannot sync without VK connection.
Check MCP server configuration.
```

Exit if VK unavailable.

---

## Step 1: Get VK Task Status

**List current project:**
```
mcp__vibe_kanban__list_projects
```

Extract `project_id` for current directory/repo.

**Get all tasks:**
```
mcp__vibe_kanban__list_tasks project_id=<project_id>
```

**Analyze task structure:**
- Identify completed epics (Tasks)
- Identify completed subtasks
- Identify in-progress work
- Calculate completion percentages

**Report current state:**
```
📊 VK TASK STATUS ANALYSIS

Project: [Project Name]

**Epics (Tasks):**
- Total: [X]
- Done: [Y]
- In Progress: [Z]
- Todo: [W]

**Subtasks:**
- Total: [A]
- Done: [B] ([B/A]%)
- In Progress: [C]
- Todo: [D]

**Recently Completed:**
1. [Epic/Subtask name] - [Completion date]
2. [Epic/Subtask name] - [Completion date]
...

---

Analyzing what documentation needs updating...
```

---

## Step 2: Read Current Documentation

**Read all .agent/system/ docs:**

```bash
# Read all system documentation
.agent/system/overview.md
.agent/system/architecture.md
.agent/system/database-schema.md (if exists)
[Any other system docs]
```

**Analyze documentation:**
- What features are documented?
- What's the documented current state?
- What technical details are captured?
- When was last update?

**Identify gaps:**
- Completed VK tasks not reflected in docs
- Architecture changes not documented
- New components/modules not described
- Outdated "Current State" sections

**Report documentation health:**
```
📋 DOCUMENTATION HEALTH CHECK

**Last Updated**: [Date from docs]

**Documented Features:**
- [Feature 1] - ✅ Current
- [Feature 2] - ⚠️ Partially outdated
- [Feature 3] - ❌ Not documented

**Completed VK Work Not Documented:**
1. [Epic name] - Completed [date], not in docs
2. [Epic name] - Completed [date], partially documented
...

**Gaps Identified:**
- [ ] Overview.md missing completed features
- [ ] Architecture.md missing new components
- [ ] Database schema not updated
- [ ] Tech stack changes not captured

---

Proceeding with documentation updates...
```

---

## Step 3: Update .agent/system/overview.md

**Read feature requirements (if exist):**
```bash
# Check for feature docs
ls .agent/features/*.md
```

Link completed VK tasks to features.

**Update overview.md:**

### 3.1 Update "Current State" Section

Add completed features:
```markdown
## Current State

**Status**: [Active Development / Beta / Production]

**Completed Features:**
- ✅ [Feature from completed VK epic] - Completed [date]
- ✅ [Another completed feature] - Completed [date]
- 🔄 [In-progress feature] - In Progress
- ⚠️ [Planned feature] - Planned

**Recent Additions** (Last updated: [Today]):
- [What was recently completed from VK]
- [Major milestones achieved]
```

### 3.2 Update "Decisions Complete" Section

Add technical decisions from completed work:
```markdown
**Decisions Complete:**
- [Decision based on completed epic]
- [Another decision]
- [Tech stack choices made]
```

### 3.3 Update "Next Steps" Section

Based on VK backlog:
```markdown
## Next Steps

**In Progress:**
1. [Epic currently active in VK]
2. [Another active epic]

**Upcoming Priorities:**
1. [Next planned epic]
2. [Future work]

**Future Considerations:**
- [Longer-term plans]
```

### 3.4 Update Technology Stack (if changed)

If VK tasks introduced new tools/libraries:
```markdown
## Technology Stack

- **Language**: [Language]
- **Framework**: [Framework]
- **Database**: [Database]
- **New Additions**:
  - [Tool added in Epic X]
  - [Library added in Epic Y]
```

**Report updates:**
```
✏️ Updated: .agent/system/overview.md
- Current state reflects completed VK work
- Next steps updated with active epics
- Tech stack additions noted
```

---

## Step 4: Update .agent/system/architecture.md

**Identify architectural changes from VK tasks:**
- New models/components created
- New API endpoints added
- Database schema changes
- New modules or services
- Integration points added
- File structure changes

**Update architecture sections:**

### 4.1 Components Section

```markdown
## Key Components

### [New Component from Epic X]
**Purpose**: [What it does]
**Location**: [File path]
**Created**: [Date from VK task completion]

[Description based on what was implemented]

**Key Functions:**
- [Function 1]
- [Function 2]
```

### 4.2 API Endpoints (if applicable)

```markdown
## API Endpoints

### [New endpoints from Epic Y]

**POST /api/[endpoint]**
- Purpose: [What it does]
- Auth: [Required/Optional]
- Added: [Date]

**GET /api/[endpoint]**
- Purpose: [What it does]
- Auth: [Required/Optional]
- Added: [Date]
```

### 4.3 Database Schema (if changed)

```markdown
## Database Models

### [New Model]
Created in Epic: [Epic name]

Fields:
- `field1`: [Type] - [Description]
- `field2`: [Type] - [Description]

Relationships:
- [Relationship description]
```

### 4.4 File Structure

Update file tree if new directories/files:
```markdown
## File Structure

\`\`\`
project/
├── [existing structure]
├── [new directory from Epic Z]/
│   ├── [new files]
│   └── [created in VK tasks]
```

### 4.5 Data Flow

If data flow changed, update diagrams/descriptions.

**Report updates:**
```
✏️ Updated: .agent/system/architecture.md
- [X] new components documented
- [Y] API endpoints added
- Database schema updated
- File structure reflects current state
```

---

## Step 5: Update database-schema.md (if needed)

If VK tasks involved database changes:

**Check for schema doc:**
```bash
ls .agent/system/database-schema.md 2>/dev/null
```

If doesn't exist but database changes made, create it.

**Update with:**
- New models/tables
- New fields
- Relationships
- Migrations applied
- Indexes added

**Report updates:**
```
✏️ Updated: .agent/system/database-schema.md
- New models from [Epic names]
- Fields and relationships documented
- Migration history updated
```

---

## Step 6: Check SOPs (Project-Specific)

**Review .agent/sops/README.md:**

Did VK tasks introduce new processes needing documentation?
- New deployment procedures
- New testing patterns
- New development workflows
- New tools/commands

If yes, prompt:
```
📝 New processes detected from VK work.

Consider documenting:
1. [Process from Epic X]
2. [Pattern from Epic Y]

Would you like to:
A) Document these now (add to .agent/sops/)
B) Skip for now
C) Remind me later

Choose: (A/B/C)
```

If A, help create new SOP documents.

---

## Step 7: Update .agent/README.md (Documentation Index)

**Update documentation index:**

If new docs created or major updates made:

```markdown
## System Documentation

- [overview.md](./system/overview.md) - **Updated [Today]** - Project overview and current state
- [architecture.md](./system/architecture.md) - **Updated [Today]** - Technical architecture
- [database-schema.md](./system/database-schema.md) - **Updated [Today]** - Database schema

## Features

Recent features completed via VK:
- [Feature 1](./features/feature-1.md) - ✅ Complete
- [Feature 2](./features/feature-2.md) - 🔄 In Progress
```

**Report updates:**
```
✏️ Updated: .agent/README.md
- Documentation index current
- Update timestamps added
- VK-completed features noted
```

---

## Step 8: Verification

**Check documentation consistency:**

```bash
# Verify all referenced files exist
grep -r "\.agent/" .agent/README.md
grep -r "\.agent/" .agent/system/overview.md
grep -r "\.agent/" .agent/system/architecture.md
```

**Verify:**
- [ ] No broken internal links
- [ ] All completed VK epics reflected in docs
- [ ] Architecture matches implementation
- [ ] Tech stack is current
- [ ] Update dates are today
- [ ] Next steps reflect VK backlog

**Report verification:**
```
✅ VERIFICATION COMPLETE

- No broken links found
- Documentation consistent
- All major VK work documented
- Ready for review
```

---

## Step 9: Final Summary

```
✅ DOCUMENTATION SYNC COMPLETE

📊 VK Status:
- Epics: [Y]/[X] complete
- Subtasks: [B]/[A] complete

📝 Documentation Updated:
- ✅ .agent/system/overview.md
- ✅ .agent/system/architecture.md
- ✅ .agent/system/database-schema.md (if applicable)
- ✅ .agent/README.md

🔄 Synced:
- [X] completed VK epics documented
- [Y] components/features captured
- [Z] architecture changes noted
- Tech stack current

⚠️ Gaps/Notes:
[Any remaining gaps or manual follow-up needed]

---

## Recommendations

**Documentation Subtasks:**
Going forward, ensure each VK epic has a documentation subtask.
This makes documentation automatic and reduces need for manual sync.

**Current VK epics missing doc subtasks:**
- [Epic name] - Consider adding doc subtask
- [Epic name] - Consider adding doc subtask

**Next Steps:**
1. Review updated documentation
2. Commit doc updates to git (if applicable)
3. Ensure future VK plans include doc subtasks (/vk-plan does this automatically)

---

Would you like to:
A) Review updated docs
B) Commit documentation updates
C) Check VK status (/vk-status)
D) Continue

Choose: (A/B/C/D)
```

---

## Git Integration (Optional)

If user chooses B (Commit documentation updates):

```bash
# Stage documentation changes
git add .agent/system/
git add .agent/README.md

# Show what changed
git diff --cached

# Confirm commit
```

Ask user:
```
📦 Ready to commit documentation updates.

Files changed:
[List files]

Commit message:
"Sync .agent/ docs with VK task progress

- Update overview with completed features
- Update architecture with new components
- Update database schema
- Sync reflects [X] completed VK epics

🤖 Generated with Claude Code /vk-sync-docs"

Commit? (yes/no)
```

If yes:
```bash
git commit -m "[message above]"
```

---

## Error Handling

### VK Connection Lost

```
❌ Lost connection to Vibe Kanban

Cannot retrieve task status.

Try:
1. Check VK is running
2. Verify MCP connection
3. Run /vk-status to test

Cannot complete sync without VK data.
```

### No Completed Tasks

```
ℹ️ No completed VK tasks found.

Current VK status: [All tasks todo/in-progress]

Documentation is already current.

Run this command again after VK tasks complete.
```

### Documentation Read Errors

```
⚠️ Cannot read some documentation files

Missing:
- [file that should exist]

Would you like to:
A) Create missing doc from template
B) Skip this doc
C) Cancel sync

Choose: (A/B/C)
```

---

## Best Practices

### When to Run This Command

**Good times:**
- ✅ After completing several VK epics
- ✅ Before major milestones
- ✅ Weekly documentation health check
- ✅ When documentation subtasks skipped
- ✅ Before demos or presentations

**Avoid:**
- ❌ After every single subtask (too frequent)
- ❌ When no VK work completed yet
- ❌ During active development (wait for epics to complete)

### What This Command Does NOT Do

This command:
- ❌ Does NOT create implementation code
- ❌ Does NOT modify VK tasks
- ❌ Does NOT replace documentation subtasks (they're still recommended)
- ❌ Does NOT guarantee 100% accuracy (manual review recommended)

It's a **sync helper**, not a replacement for proper documentation discipline.

### Making Documentation Subtasks Work

**Best approach:**
1. Use `/vk-plan` (auto-generates doc subtasks per epic)
2. Let VK execute doc subtasks (documentation stays current automatically)
3. Use `/vk-sync-docs` as backup/verification

**This way:**
- Documentation is part of the workflow
- No manual sync needed
- Documentation always current

---

## Integration with VK Workflow

**This command complements:**
- `/vk-plan` - Which creates doc subtasks
- `/vk-status` - Which shows VK progress
- VK doc subtasks - Which update docs automatically

**Use when:**
- Doc subtasks not executed
- Need to verify doc currency
- Want comprehensive doc health check
- Preparing for milestone/demo

**Prevention:**
- Always include doc subtasks in VK plans
- Prioritize doc subtasks
- Don't skip documentation work
- Regular doc reviews

---

## Advanced: Detecting Implementation Details

**Limitation:**
This command syncs based on VK task **metadata** (titles, descriptions, status).
It cannot analyze actual implementation code.

**For deep sync:**
1. Read completed VK task descriptions
2. Infer what was likely implemented
3. Check actual code files if needed
4. Update docs based on findings

**Example:**
```
VK Epic: "User Authentication" - Complete

Likely implementation (from task description):
- User model with email/password fields
- POST /api/register endpoint
- POST /api/login endpoint
- JWT token generation
- Password hashing

Verifying in code:
[Check for these files/functions]

Documenting in architecture.md:
[Add these components]
```

**Best practice:**
VK task descriptions should be detailed enough that this command can sync accurately without reading code.

---

## Documentation Standards

Follow standards from:
- `~/.claude/workflow/sops/documentation-standards.md`

Ensure updates match:
- Naming conventions (lowercase, kebab-case)
- Markdown standards
- Section structure
- Update timestamp format
- Reference format
