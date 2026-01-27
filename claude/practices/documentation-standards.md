# Documentation Standards

**Universal SOP** - Documentation principles that apply to all projects.

---

## Documentation Philosophy

**For Humans**: Write docs that help developers understand the system quickly

**Stay Current**: Update docs immediately after changes

**Be Specific**: Include exact commands, file paths, and examples

**Cross-Reference**: Link related documents together

**Simplify**: If a document gets too long, split it up

---

## .agent/ Structure

All projects use this standard structure:

```
.agent/
├── README.md              # Documentation index
├── task-template.md       # Template for new tasks
├── tasks/                 # PRDs and implementation plans
│   ├── 000-initial-setup.md
│   ├── 001-feature-name.md
│   └── ...
├── system/                # Current state documentation
│   ├── overview.md
│   └── architecture.md
├── sops/                  # Project-specific procedures
│   ├── README.md         # References universal + lists local
│   └── [framework]-setup.md
└── known-issues/          # Troubleshooting knowledge base
    ├── README.md
    ├── 01-issue-name.md
    └── ...
```

---

## Naming Conventions

### Directories
- **ALL lowercase**
- **Use kebab-case** for multi-word names
- Examples: `tasks/`, `known-issues/`, `sops/`

### Files
- **lowercase** for content files
- **kebab-case** for multi-word names
- **UPPERCASE** for special files (convention)
- Examples:
  - `git-workflow.md` (content)
  - `database-schema.md` (content)
  - `CLAUDE.md` (special)
  - `README.md` (special)

### Task Numbering
- **3-digit zero-padded**: `000` to `999`
- Examples:
  - `000-initial-setup.md`
  - `001-user-authentication.md`
  - `042-feature-name.md`

### Known Issue Numbering
- **2-digit zero-padded**: `01` to `99`
- Examples:
  - `01-database-timeout.md`
  - `02-api-rate-limit.md`

---

## Task Document Standards

### Required Sections
1. **Problem** - What needs to be solved
2. **Solution** - How we'll solve it
3. **Implementation Plan** - Step-by-step approach
4. **Success Criteria** - How we know it's done
5. **Implementation Summary** - What actually happened (after completion)

### Status Markers
- ⚠️ **Planned** - Task documented, not started
- 🔄 **In Progress** - Currently being implemented
- ✅ **Complete** - Finished, tested, merged, documented

### Template
Use `.agent/task-template.md` for consistency

---

## System Documentation Standards

### overview.md
**Purpose**: Project goals, context, tech stack

**Update When**:
- Tech stack changes
- Project goals evolve
- Major milestones reached

**Must Include**:
- Project description
- Technology stack
- Current status
- Key decisions

### architecture.md
**Purpose**: Technical architecture and design

**Update When**:
- Architecture changes
- New integrations added
- Design patterns introduced

**Must Include**:
- System components
- Data flow
- External integrations
- Design patterns

---

## SOP Documentation Standards

### Universal SOPs
**Location**: `~/.claude/scaffolds/sops/`

**Reference** (don't copy):
- Git workflow
- Testing principles
- Documentation standards

### Project-Specific SOPs
**Location**: `.agent/sops/`

**Copy from templates**:
- Framework setup (e.g., Django, React)
- Deployment procedures
- Local development workflows

### README.md Structure
```markdown
## Universal SOPs
See `~/.claude/scaffolds/sops/` for procedures that apply to all projects:
- [Git Workflow](~/.claude/scaffolds/sops/git-workflow.md)
- [Testing Principles](~/.claude/scaffolds/sops/testing-principles.md)

## Project-Specific SOPs
- [Django Setup](./django-setup.md)
- [Deployment](./deployment.md)
```

---

## Known Issues Documentation

### When to Document
- Issue was non-obvious or tricky to debug
- Issue could happen again
- Solution provides learning value
- Would help future developers

### Required Sections
1. **The Problem** - What went wrong
2. **Root Cause** - Why it happened
3. **The Fix** - How it was resolved
4. **Prevention** - How to avoid in future
5. **Tags** - Keywords for searchability

### Cross-Project Search
Known issues are searchable across all projects in `~/Projects` (configurable in `~/.claude/scaffolds/config.yml`)

---

## CLAUDE.md Standards

### Purpose
Central instructions file for Claude Code

### Must Include
1. **Documentation structure** - Explain `.agent/` organization
2. **Slash commands** - List available commands
3. **Common commands** - Project-specific commands
4. **Quick reference** - Task statuses, git workflow
5. **Guiding principles** - Project-specific values

### References to Global
```markdown
## Standard Operating Procedures

### Universal Procedures
See `~/.claude/scaffolds/sops/` for procedures that apply to all projects:
- Git Workflow
- Testing Principles
- Documentation Standards

### Project-Specific
See `.agent/sops/` for this project's procedures:
- Django Setup
- Deployment
```

---

## Markdown Standards

### Headings
```markdown
# H1 - Document Title
## H2 - Major Sections
### H3 - Subsections
#### H4 - Details (use sparingly)
```

### Code Blocks
Always specify language:
```markdown
\`\`\`bash
git commit -m "message"
\`\`\`

\`\`\`python
def hello():
    print("world")
\`\`\`
```

### Links
- Use relative links for same repo
- Use absolute links for external resources
- Make link text descriptive

```markdown
Good: [See the Git Workflow guide](~/.claude/scaffolds/sops/git-workflow.md)
Bad: [Click here](~/.claude/scaffolds/sops/git-workflow.md)
```

---

## Maintenance

### After Every Feature
1. Update task document (mark complete, add summary)
2. Update system docs (if architecture changed)
3. Update SOPs (if new processes introduced)
4. Update `.agent/README.md` (task status in index)

### Regular Reviews
- Review docs quarterly for accuracy
- Archive obsolete tasks/issues
- Update tech stack if changed
- Refactor verbose docs into smaller files

---

**Location**: `~/.claude/scaffolds/sops/documentation-standards.md`
**Referenced By**: All projects via `.agent/sops/README.md`
**Last Updated**: 2025-10-25
