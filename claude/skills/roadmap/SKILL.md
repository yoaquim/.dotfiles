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

If `.agent/` doesn't exist, instruct user to run `/setup` first.

---

## Step 1: Determine Mode

**Check if ROADMAP.md exists:**

```bash
ls -la .agent/ROADMAP.md 2>/dev/null
```

- **If exists**: Update mode
- **If not exists**: Creation mode

---

## Step 2: Gather Input

### Creation Mode
If no argument provided, ask user to share their thoughts about the project.

### Update Mode
Read existing roadmap and ask what to update:
- Add new items
- Update status of existing items
- Reorganize phases
- Full brain dump (merge with existing)

---

## Step 3: Parse Unstructured Input

**Analyze input to extract:**
1. **Vision/Goals** - High-level project purpose
2. **Feature Ideas** - Specific capabilities
3. **User Stories** - Problems to solve
4. **Technical Items** - Infrastructure, architecture
5. **Phases/Milestones** - Groupings or sequencing hints
6. **Constraints** - Limitations, requirements

**Identification patterns:**
| Pattern | Extract As |
|---------|------------|
| "users should be able to..." | Feature idea |
| "first we should..." | Phase 1 item |
| "later..." / "eventually..." | Later phase or backlog |
| "the goal is..." | Vision |

---

## Step 4: Ask Clarifying Questions (Sparingly)

**Only ask when:**
- Input is too vague to structure
- Critical ambiguity affects phase assignment
- Multiple valid interpretations exist

**Prefer making reasonable assumptions and noting them.**

---

## Step 5: Structure Into Roadmap Format

**Assign items to phases:**

| Phase | Criteria |
|-------|----------|
| Phase 1 | Core functionality, MVP, "must haves" |
| Phase 2 | Enhanced features, "should haves" |
| Phase 3 | Advanced features, "nice to haves" |
| Backlog | Ideas without clear phase |

**Number items:**
- Phase 1: R1.1, R1.2, R1.3...
- Phase 2: R2.1, R2.2, R2.3...
- Phase 3: R3.1, R3.2, R3.3...
- Backlog: B1, B2, B3...

**Item format:**
```markdown
| R1.1 | [Brief Title] | [One-line description] | Planned |
```

---

## Step 6: Validate Structure

Before writing, verify:
1. Vision is present
2. At least Phase 1 has items
3. No duplicate IDs
4. Items are actionable
5. Phases make logical sense

---

## Step 7: Write/Update ROADMAP.md

Use template from `~/.claude/workflow/templates/agent/ROADMAP.md.template`.

---

## Step 8: Report Completion

### Creation Mode
```
ROADMAP CREATED

Location: .agent/ROADMAP.md

Phase 1 - [Name]: X items
Phase 2 - [Name]: X items
Backlog: X items

Assumptions Made:
- [Any assumptions]

Next Steps:
1. Review the roadmap
2. Run /feature [description referencing roadmap item]
```

### Update Mode
```
ROADMAP UPDATED

Changes:
- Added X new items
- Updated X statuses

New Items:
- R1.4: [Title]
- B3: [Title]
```

---

## Item Status Transitions

```
Future → Planned → Defined → In Progress → Implemented → Released
                     ↓
              (Feature created)
```

---

## Linking Roadmap to Features

When creating a feature from a roadmap item:
1. Note the roadmap item ID (e.g., R1.2)
2. Run `/feature [description]`
3. Feature includes "Roadmap Reference" section
4. Update roadmap item status to "Defined"

---

## Best Practices

### DO:
- Accept messy input and structure it
- Make reasonable assumptions about phasing
- Note assumptions for user to correct
- Preserve all existing content on updates
- Use brief, actionable item titles

### DON'T:
- Ask too many clarifying questions
- Reject input as "too vague"
- Create overly detailed roadmaps
- Remove existing items without asking
