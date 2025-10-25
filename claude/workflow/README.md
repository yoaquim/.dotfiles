# Claude Code Global Configuration

Global configuration for Claude Code workflow system. This provides a standardized, reusable documentation and workflow system for all projects.

**Location**: `~/.dotfiles/config/claude/` (symlinked to `~/.claude/`)

---

## Table of Contents

- [Overview](#overview)
- [Quick Start](#quick-start)
- [Directory Structure](#directory-structure)
- [Configuration](#configuration)
- [Universal SOPs](#universal-sops)
- [Templates](#templates)
- [Slash Commands](#slash-commands)
- [Cross-Project Features](#cross-project-features)
- [Setup on New Machine](#setup-on-new-machine)
- [Customization](#customization)
- [Maintenance](#maintenance)

---

## Overview

This global configuration provides:

1. **Universal SOPs** - Documentation standards, git workflow, testing principles that apply to ALL projects
2. **Project Templates** - Reusable templates for initializing `.agent/` directories in new projects
3. **Slash Commands** - Global commands available in all projects (`/plan-task`, `/fix-bug`, etc.)
4. **Cross-Project Search** - Search known-issues across all projects
5. **Standardized Naming** - Lowercase directories, kebab-case files, consistent numbering

---

## Quick Start

### On This Machine (Already Set Up)

The symlink `~/.claude` → `~/.dotfiles/config/claude/` is already created.

**Available commands in any project:**
```
/init-project   - Initialize .agent/ for new or existing project
/plan-task      - Plan a new feature
/implement-task - Implement a task
/fix-bug        - Quick bug fix workflow
/document-issue - Document known issues
/status         - Show project status
```

### On a New Machine

```bash
cd ~/.dotfiles/config/claude/
./setup.sh
```

This will:
- Create symlink `~/.claude` → `~/.dotfiles/config/claude/`
- Verify all required files
- Display configuration

---

## Directory Structure

```
~/.dotfiles/config/claude/         # Source (version controlled)
├── README.md                      # This file
├── IMPLEMENTATION.md              # Implementation plan and decisions
├── config.yml                     # Global configuration
├── setup.sh                       # Setup script for new machines
├── commands/                      # Slash commands (global)
│   ├── plan-task.md
│   ├── implement-task.md
│   ├── fix-bug.md
│   ├── document-issue.md
│   ├── status.md
│   └── ...
├── sops/                          # Universal SOPs (referenced, not copied)
│   ├── README.md
│   ├── git-workflow.md
│   ├── testing-principles.md
│   └── documentation-standards.md
└── templates/                     # Project templates (copied by /init-project)
    ├── CLAUDE.md.template
    ├── agent/
    │   ├── README.md.template
    │   ├── task-template.md
    │   ├── system/
    │   │   ├── overview.md.template
    │   │   └── architecture.md.template
    │   ├── sops/
    │   │   └── README.md.template
    │   └── known-issues/
    │       └── README.md.template
    └── ...

~/.claude/                          # Symlink to above
```

### Project Structure (After /init-project)

```
your-project/
├── CLAUDE.md                       # Project-specific instructions
├── .agent/
│   ├── README.md                   # Documentation index
│   ├── task-template.md            # Template for new tasks
│   ├── tasks/                      # Tasks (000-999)
│   │   ├── 000-initial-setup.md
│   │   └── 001-feature-name.md
│   ├── system/                     # System documentation
│   │   ├── overview.md
│   │   └── architecture.md
│   ├── sops/                       # Project-specific SOPs
│   │   └── README.md               # References universal + lists local
│   └── known-issues/               # Known issues (01-99)
│       ├── README.md
│       └── 01-issue-name.md
└── .claude/
    └── commands/                   # Project-local commands (optional)
```

---

## Configuration

### config.yml

```yaml
projects_dir: ~/Projects      # Where your projects live
editor: nvim                   # Your preferred editor
task_digits: 3                 # Task numbering (000-999)
auto_update_docs: true         # Auto-update docs after tasks
```

**Edit**:
```bash
nvim ~/.claude/workflow/config.yml
```

**Customize**:
- `projects_dir`: Change if your projects are elsewhere
- `editor`: Use `code`, `vim`, or any other editor
- `task_digits`: Currently 3 (000-999), could extend to 4 if needed
- `auto_update_docs`: Disable if you prefer manual doc updates

---

## Universal SOPs

**Location**: `~/.claude/workflow/sops/`

These apply to **ALL projects** and are **referenced**, not copied:

### [Git Workflow](./sops/git-workflow.md)
- Branch naming conventions (`feature/`, `fix/`, `hotfix/`)
- Commit message format
- Merge workflow
- Best practices

### [Testing Principles](./sops/testing-principles.md)
- Test types (unit, integration, e2e)
- Coverage goals (80%+)
- Arrange-Act-Assert pattern
- Best practices

### [Documentation Standards](./sops/documentation-standards.md)
- Naming conventions (lowercase, kebab-case)
- Task numbering (3-digit: 000-999)
- Known issue numbering (2-digit: 01-99)
- `.agent/` structure standards
- Markdown standards

**Why Universal SOPs?**
- Single source of truth across all projects
- Update once, applies everywhere
- No duplication or drift
- Easy to maintain and improve

---

## Templates

**Location**: `~/.claude/workflow/templates/`

Used by `/init-project` command to create new project documentation.

### Template Variables

Templates use `{{VARIABLE}}` placeholders that are replaced during `/init-project`:

- `{{PROJECT_NAME}}` - Project name
- `{{LANGUAGE}}` - Programming language
- `{{FRAMEWORK}}` - Framework (Django, React, etc.)
- `{{DATABASE}}` - Database system
- `{{TEST_FRAMEWORK}}` - Testing framework
- `{{DEV_COMMAND}}` - Development start command
- `{{TEST_COMMAND}}` - Test run command
- `{{BUILD_COMMAND}}` - Build command
- `{{INIT_DATE}}` - Initialization date
- `{{FRAMEWORK_LOWER}}` - Framework name in lowercase

### Key Templates

- `CLAUDE.md.template` - Core project instructions
- `agent/README.md.template` - Documentation index
- `agent/task-template.md` - Task document template
- `agent/system/overview.md.template` - System overview
- `agent/system/architecture.md.template` - Architecture docs
- `agent/sops/README.md.template` - SOPs index (references universal)
- `agent/known-issues/README.md.template` - Known issues index

**Customize**:
Edit templates to match your preferred structure or add new sections.

---

## Slash Commands

All commands are available globally in any project.

### Planning & Documentation

- **`/init-project`** - Initialize `.agent/` directory for new or existing project
- **`/plan-task <description>`** - Create a new task document with implementation plan
- **`/status`** - Show project status, active tasks, recent changes
- **`/review-docs`** - Review documentation for issues or outdated info
- **`/update-doc`** - Manually update documentation

### Implementation

- **`/implement-task [XXX]`** - Implement a task (defaults to latest)
- **`/test-task [XXX]`** - Test a task implementation
- **`/complete-task [XXX]`** - Finalize task, update docs, git workflow

### Bug Fixes

- **`/fix-bug <description>`** - Intelligent bug fix workflow
  - **Quick hotfix** for simple bugs (done in one command)
  - **Bug task** for complex issues (full investigation + fix)
  - **Cross-project search** for similar issues automatically

### Issue Documentation

- **`/document-issue`** - Document a known issue or bug
  - Searches similar issues across all projects
  - Creates numbered issue document (NN: 01-99)
  - Updates known-issues index
  - Links to related tasks

### Command Resolution Order

1. **Project-local** (`.claude/commands/` in project root)
2. **Global** (`~/.claude/commands/`)

This allows project-specific overrides while maintaining global defaults.

---

## Cross-Project Features

### Known Issues Search

Known issues are searchable across **all projects** in `~/Projects`:

```bash
# Manual search
find ~/Projects -type f -path "*/\.agent/known-issues/*.md" -exec grep -l "keyword" {} \;

# Automatic search in /fix-bug and /document-issue commands
```

**Why?**
- Learn from issues in other projects
- Avoid solving the same problem twice
- Build institutional knowledge
- Pattern recognition across codebases

### Task Insights

While tasks are project-specific, you can search across projects for similar implementations:

```bash
find ~/Projects -type f -path "*/\.agent/tasks/*.md" -exec grep -l "authentication" {} \;
```

---

## Setup on New Machine

### Prerequisites

1. Clone dotfiles:
   ```bash
   git clone <dotfiles-repo> ~/.dotfiles
   ```

2. Ensure `~/.dotfiles/config/claude/` exists

### Run Setup

```bash
cd ~/.dotfiles/config/claude/
./setup.sh
```

The script will:
- ✅ Create symlink `~/.claude` → `~/.dotfiles/config/claude/`
- ✅ Verify all required files
- ✅ Check configuration
- ✅ Display available commands

### Verify Setup

```bash
ls -la ~/.claude          # Should show symlink
cat ~/.claude/workflow/config.yml  # Should display config
```

---

## Customization

### Add New Universal SOP

1. Create new `.md` file in `~/.claude/workflow/sops/`
2. Follow documentation standards format
3. Update `~/.claude/workflow/sops/README.md`
4. Commit to dotfiles repo
5. All projects automatically reference it

### Add New Slash Command

**Global command:**
1. Create `.md` file in `~/.claude/commands/`
2. Follow existing command format
3. Available in all projects immediately

**Project-local command:**
1. Create `.claude/commands/` in project root
2. Add `.md` file with command
3. Only available in that project
4. Overrides global command if same name

### Modify Templates

1. Edit files in `~/.claude/workflow/templates/`
2. Test with `/init-project` on a test project
3. Commit changes to dotfiles
4. Future projects use updated templates

### Change Projects Directory

Edit `~/.claude/workflow/config.yml`:
```yaml
projects_dir: ~/Code  # or wherever your projects live
```

This affects cross-project search paths.

---

## Maintenance

### Regular Reviews

**Quarterly** (every 3 months):
- Review universal SOPs for accuracy
- Update templates based on learnings
- Refactor verbose documentation
- Archive obsolete known issues

**After Major Workflow Changes**:
- Update relevant SOPs
- Update command files if needed
- Update templates to reflect new patterns

### Version Control

**This directory is part of dotfiles:**
```bash
cd ~/.dotfiles
git add config/claude/
git commit -m "Update Claude Code config: <description>"
git push
```

**Keep synced across machines:**
```bash
cd ~/.dotfiles
git pull
```

### Backup Strategy

**Dotfiles repo** provides version control and backup.

**Additional safety**:
- Known issues are per-project (in each repo)
- Tasks are per-project (in each repo)
- Only global config and templates live here

---

## Naming Conventions

### Directories
- **ALL lowercase**: `tasks/`, `known-issues/`, `sops/`, `system/`
- **kebab-case** for multi-word: `known-issues/`

### Files
- **lowercase** for content: `git-workflow.md`, `overview.md`
- **UPPERCASE** for special files: `CLAUDE.md`, `README.md`
- **kebab-case** for multi-word: `testing-principles.md`

### Task Numbering
- **3-digit zero-padded**: `000` to `999`
- Examples: `000-initial-setup.md`, `001-user-auth.md`, `042-feature.md`

### Known Issue Numbering
- **2-digit zero-padded**: `01` to `99`
- Examples: `01-database-timeout.md`, `02-api-rate-limit.md`

---

## Architecture Decisions

### Why Universal SOPs?

**Decision**: SOPs like git workflow and testing principles are **referenced**, not copied

**Rationale**:
- Single source of truth
- Update once, applies everywhere
- No duplication or drift
- Easy to maintain and improve

**Trade-off**: Projects depend on external files, but that's acceptable since they're version controlled in dotfiles.

### Why Hybrid Approach?

**Decision**: Universal SOPs + Project-Specific SOPs

**Rationale**:
- Universal patterns (git, testing) don't change per-project
- Framework setup (Django, React) varies by tech stack
- Best of both worlds

**Trade-off**: Slightly more complex, but much more maintainable.

### Why Cross-Project Search?

**Decision**: Known issues searchable across all projects in `~/Projects`

**Rationale**:
- Bugs repeat across codebases
- Solutions transfer between projects
- Build institutional knowledge
- Pattern recognition

**Trade-off**: Requires consistent naming and structure, which we enforce via documentation standards.

### Why Lowercase Directories?

**Decision**: All `.agent/` subdirectories use lowercase (tasks, system, sops, known-issues)

**Rationale**:
- Consistency across all projects
- Unix/Linux convention
- Easier to type and remember
- No case sensitivity issues

**Trade-off**: Required migration from old capitalized format, but one-time cost.

---

## Troubleshooting

### Symlink Issues

**Problem**: `~/.claude` is a directory, not a symlink

**Solution**:
```bash
cd ~/.dotfiles/config/claude/
./setup.sh  # Will backup and recreate
```

### Command Not Found

**Problem**: Slash command doesn't work

**Solution**:
1. Verify command exists: `ls ~/.claude/commands/`
2. Check command name matches exactly
3. Restart Claude Code session

### Template Variables Not Replaced

**Problem**: `{{VARIABLE}}` appears in generated files

**Solution**:
- Re-run `/init-project`
- Ensure you answered all prompts
- Check template file has correct variable names

### Cross-Project Search Returns Nothing

**Problem**: `find ~/Projects ...` returns no results

**Solution**:
1. Verify `projects_dir` in `~/.claude/workflow/config.yml`
2. Check projects have `.agent/known-issues/` directory
3. Ensure known issues exist in those projects

---

## Contributing

This is personal configuration, but you can:

1. **Fork** for your own use
2. **Adapt** templates and commands to your workflow
3. **Share** improvements or ideas
4. **Maintain** as part of your dotfiles

---

## Version History

- **2025-10-25** - Initial global configuration
  - Extracted from project-specific setup
  - Created universal SOPs
  - Implemented cross-project search
  - Standardized lowercase naming
  - 3-digit task numbering

---

## Related Documentation

- [Universal SOPs](./sops/README.md)
- [Implementation Plan](./IMPLEMENTATION.md)
- [Setup Script](./setup.sh)

---

**Location**: `~/.dotfiles/config/claude/README.md`
**Symlink**: `~/.claude/README.md`
**Last Updated**: 2025-10-25
