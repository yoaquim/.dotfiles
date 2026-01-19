---
description: Create or update project roadmap from unstructured input
argument-hint: [brain dump, notes, or update instructions]
allowed-tools: Read, Write, Edit, AskUserQuestion, Glob, Bash(ls*)
---

# Roadmap Command

Create or update a project roadmap from unstructured input (brain dumps, notes, ideas).

**This command:**
1. Accepts unstructured input (ideas, notes, feature requests)
2. Structures it into phases with numbered items
3. Uses AskUserQuestion sparingly (only critical clarifications)
4. Supports both creation and update modes

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

## Step 1: Determine Mode

**Check if ROADMAP.md exists:**

```bash
ls -la .agent/ROADMAP.md 2>/dev/null
```

**If exists**: Update mode
**If not exists**: Creation mode

---

## Step 2: Gather Input

### Creation Mode

If no argument provided, ask:
```
Let's create your project roadmap.

Share your thoughts about this project - this can be:
- Feature ideas and goals
- User stories or problems to solve
- Technical requirements
- Phases or milestones you're thinking about
- Random brain dump of ideas

Just write freely - I'll help structure it.
```

If argument provided, use that as the initial input.

### Update Mode

**Read existing roadmap:**
```
Read .agent/ROADMAP.md
```

Ask what to update:
```
Current roadmap found. What would you like to do?

1. Add new items (provide your ideas)
2. Update status of existing items
3. Reorganize phases
4. Add notes/context
5. Full brain dump (I'll merge with existing)

Or just share what's on your mind and I'll figure it out.
```

---

## Step 3: Parse Unstructured Input

**Analyze the input to extract:**

1. **Vision/Goals** - High-level project purpose
2. **Feature Ideas** - Specific capabilities or features
3. **User Stories** - Problems to solve, user needs
4. **Technical Items** - Infrastructure, architecture, technical debt
5. **Phases/Milestones** - Groupings or sequencing hints
6. **Constraints** - Limitations, requirements, dependencies
7. **Notes** - Context that doesn't fit elsewhere

**Identification patterns:**

| Pattern | Extract As |
|---------|------------|
| "users should be able to..." | Feature idea |
| "we need to..." | Feature or technical item |
| "first we should..." | Phase 1 item |
| "later..." / "eventually..." | Later phase or backlog |
| "the goal is..." | Vision |
| "it must..." / "it should..." | Requirement/constraint |
| "I'm thinking..." / "maybe..." | Backlog item |

---

## Step 4: Ask Clarifying Questions (Sparingly)

**Only ask questions when:**
- Input is too vague to structure meaningfully
- Critical ambiguity that affects phase assignment
- Multiple valid interpretations exist

**Use AskUserQuestion tool:**

```
question: "[Specific clarifying question]"
header: "Clarification"
options:
  - label: "[Option 1]"
    description: "[What this means]"
  - label: "[Option 2]"
    description: "[What this means]"
```

**Prefer to make reasonable assumptions and note them** rather than asking many questions.

---

## Step 5: Structure Into Roadmap Format

### For Creation Mode

**Template from:** `~/.claude/workflow/templates/agent/ROADMAP.md.template`

**Assign items to phases:**

| Phase | Criteria |
|-------|----------|
| Phase 1 | Core functionality, MVP features, "must haves" |
| Phase 2 | Enhanced features, "should haves" |
| Phase 3 | Advanced features, polish, "nice to haves" |
| Backlog | Ideas without clear phase, "maybes" |

**Number items:**
- Phase 1 items: R1.1, R1.2, R1.3...
- Phase 2 items: R2.1, R2.2, R2.3...
- Phase 3 items: R3.1, R3.2, R3.3...
- Backlog items: B1, B2, B3...

**Item format:**
```markdown
| R1.1 | [Brief Title] | [One-line description] | Planned |
```

### For Update Mode

**Merge new items with existing:**

1. Read current ROADMAP.md
2. Parse existing items and their IDs
3. Add new items with next available IDs
4. Update statuses if specified
5. Reorganize phases if requested
6. Preserve all existing content

---

## Step 6: Validate Structure

Before writing, verify:

1. **Vision** is present (even if brief)
2. **At least Phase 1** has items
3. **No duplicate IDs** exist
4. **Items are actionable** (not too vague)
5. **Phases make logical sense** (dependencies flow correctly)

If issues found, make reasonable fixes and note them.

---

## Step 7: Write/Update ROADMAP.md

### Creation Mode

**Write new file:**
```
.agent/ROADMAP.md
```

Use template structure with populated content.

### Update Mode

**Edit existing file:**

For adding items:
- Find appropriate phase section
- Add new rows to item table
- Maintain ID sequence

For status updates:
- Find item by ID
- Update status column

For reorganization:
- Move items between phases
- Update IDs if needed (note old → new mapping)

---

## Step 8: Report Completion

### Creation Mode

```
ROADMAP CREATED

Location: .agent/ROADMAP.md

Vision: [Brief vision statement]

Phase 1 - [Name]: X items
Phase 2 - [Name]: X items
Phase 3 - [Name]: X items (if any)
Backlog: X items

Items Added:
- R1.1: [Title]
- R1.2: [Title]
- R2.1: [Title]
- B1: [Title]
...

Assumptions Made:
- [Any assumptions about phase assignment or interpretation]

Next Steps:
1. Review the roadmap at .agent/ROADMAP.md
2. When ready to implement an item, run:
   /feature [description referencing roadmap item]
3. The feature will link back to the roadmap item
```

### Update Mode

```
ROADMAP UPDATED

Location: .agent/ROADMAP.md

Changes:
- Added X new items
- Updated X item statuses
- [Any reorganization made]

New Items:
- R1.4: [Title]
- B3: [Title]

Status Changes:
- R1.1: Planned → Defined (→ Feature 001)
- R1.2: Planned → In Progress

Next Steps:
[Contextual next steps based on changes made]
```

---

## Item Status Transitions

```
Future → Planned → Defined → In Progress → Implemented → Released
                     ↓
              (Feature created)
```

**When to update status:**
- **Planned**: Item assigned to a phase
- **Defined**: `/feature` created for this item
- **In Progress**: Implementation started
- **Implemented**: Development complete
- **Released**: Live in production

---

## Linking Roadmap to Features

When creating a feature from a roadmap item:

1. Note the roadmap item ID (e.g., R1.2)
2. Run `/feature [description]`
3. Feature will include "Roadmap Reference" section
4. Update roadmap item status to "Defined"
5. Add feature link: `Defined → Feature 001`

---

## Examples

### Example 1: Initial Brain Dump

**Input:**
```
I want to build a task manager. Users should be able to create tasks,
mark them done, and organize them into projects. Later I want to add
collaboration so teams can share projects. Maybe notifications too.
Oh and it needs to work offline eventually.
```

**Output structure:**
```
Phase 1: Core Task Management
- R1.1: Task CRUD - Create, read, update, delete tasks
- R1.2: Task completion - Mark tasks as done/undone
- R1.3: Project organization - Group tasks into projects

Phase 2: Collaboration
- R2.1: Team projects - Share projects with other users
- R2.2: Notifications - Alert users about changes

Backlog:
- B1: Offline mode - Work without internet connection
```

### Example 2: Update Existing

**Input:**
```
I finished the login feature and started working on the dashboard.
Also I had an idea for dark mode.
```

**Changes:**
```
Status Updates:
- R1.1 (User Login): Planned → Implemented
- R1.2 (Dashboard): Planned → In Progress

New Items:
- B4: Dark mode - Theme toggle for dark/light modes
```

---

## Best Practices

### DO:
- Accept messy input and make it structured
- Make reasonable assumptions about phasing
- Note assumptions so user can correct
- Preserve all existing content on updates
- Use brief, actionable item titles
- Keep descriptions to one line

### DON'T:
- Ask too many clarifying questions
- Reject input as "too vague"
- Create overly detailed roadmaps
- Remove existing items without asking
- Create features directly (that's /feature's job)
