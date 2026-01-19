# Claude Code Global Configuration

Global configuration for Claude Code workflow system. This provides a standardized, reusable documentation and workflow system for all projects.

**Location**: `~/.dotfiles/claude/` (symlinked to `~/.claude/`)

---

## Table of Contents

- [Overview](#overview)
- [Quick Start](#quick-start)
- [Directory Structure](#directory-structure)
- [Configuration](#configuration)
- [Universal SOPs](#universal-sops)
- [Templates](#templates)
- [Slash Commands](#slash-commands)
- [Adapters](#adapters)
- [Hooks](#hooks)
- [Subagents](#subagents)
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

The symlink `~/.claude` → `~/.dotfiles/claude/` is already created.

**Available commands in any project:**
```
# Setup & Planning
/setup                      - Initialize .agent/ for new or existing project
/feature                    - Define WHAT to build (feature requirements)
/roadmap                    - Create/update project roadmap
/plan vk 001                - Plan feature in Vibe Kanban
/plan local 001             - Create local task documents
/test-plan 001              - Generate test plan with Playwright
/bug 001                    - Document bugs (feature-tied or standalone)

# Workflow Commands
/workflow:plan-task         - Plan HOW to build it (implementation)
/workflow:implement-task    - Implement a task
/workflow:test-task         - Test implementation
/workflow:complete-task     - Finalize task
/workflow:fix-bug           - Quick bug fix workflow
/workflow:document-issue    - Document known issues
/workflow:status            - Show project status
/workflow:review-docs       - Review documentation
/workflow:update-doc        - Update documentation

# Deprecated (still work, use alternatives)
/vk-plan 001                - Use /plan vk 001 instead
/feature-bug 001            - Use /bug 001 instead
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
~/.dotfiles/claude/                # Source (version controlled)
├── setup.sh                       # Setup script for new machines
├── commands/                      # Slash commands (global)
│   ├── feature.md                 # Define feature requirements
│   ├── setup.md                   # Project initialization
│   ├── roadmap.md                 # Create/update roadmaps
│   ├── plan.md                    # Unified planning (vk, local, linear)
│   ├── test-plan.md               # Test plan generation
│   ├── bug.md                     # Bug documentation
│   ├── vk-plan.md                 # [DEPRECATED] Use /plan vk
│   ├── feature-bug.md             # [DEPRECATED] Use /bug
│   └── workflow/                  # Workflow commands
│       ├── plan-task.md
│       ├── implement-task.md
│       ├── test-task.md
│       ├── complete-task.md
│       ├── fix-bug.md
│       ├── document-issue.md
│       ├── status.md
│       ├── review-docs.md
│       └── update-doc.md
├── adapters/                      # Pluggable adapter system
│   ├── interface.md               # Adapter contract specification
│   ├── vk.md                      # Vibe Kanban adapter
│   ├── local.md                   # Local filesystem adapter
│   └── linear.md                  # Linear adapter (placeholder)
├── hooks/                         # Hook documentation and examples
│   ├── README.md                  # Hooks overview
│   ├── validation-guards.md       # Validation/blocking examples
│   └── context-loaders.md         # Context injection examples
├── guides/                        # Usage guides
│   └── subagents.md               # Subagent usage guide
├── vk-tags/                       # Reusable VK task tags
│   ├── README.md
│   ├── plan-feature.md
│   ├── bug_analysis.md
│   └── ...
└── workflow/                      # Universal workflows and templates
    ├── README.md                  # This file
    ├── sops/                      # Standard operating procedures
    │   ├── README.md
    │   ├── git-workflow.md
    │   ├── testing-principles.md
    │   └── documentation-standards.md
    └── templates/                 # Project templates (copied by /setup)
        ├── CLAUDE.md.template
        ├── test-plan.md.template  # Test plan template
        └── agent/
            ├── README.md.template
            ├── ROADMAP.md.template # Project roadmap template
            ├── task-template.md
            ├── system/
            │   ├── overview.md.template
            │   └── architecture.md.template
            ├── sops/
            │   └── README.md.template
            ├── bugs/              # Standalone bugs template
            │   └── README.md.template
            └── known-issues/
                └── README.md.template

~/.claude/                         # Symlink to above
```

### Project Structure (After /setup)

```
your-project/
├── CLAUDE.md                       # Project-specific instructions
├── .agent/
│   ├── README.md                   # Documentation index
│   ├── task-template.md            # Template for new tasks
│   ├── .last-feature               # Tracks last feature for /plan-task
│   ├── features/                   # Feature requirements (WHAT)
│   │   ├── asset-upload.md
│   │   └── user-permissions.md
│   ├── tasks/                      # Implementation tasks (HOW) (000-999)
│   │   ├── 000-initial-setup.md
│   │   ├── 001-asset-upload-backend.md
│   │   └── 002-asset-upload-frontend.md
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

Configuration is managed through:
- **Slash commands**: Edit `.md` files in `~/.dotfiles/claude/commands/`
- **Templates**: Edit files in `~/.dotfiles/claude/workflow/templates/`
- **SOPs**: Edit or add files in `~/.dotfiles/claude/workflow/sops/`
- **VK Tags**: Edit files in `~/.dotfiles/claude/vk-tags/`

**Key conventions**:
- `projects_dir`: `~/Projects` (used for cross-project search)
- `task_digits`: 3-digit numbering (000-999)
- `issue_digits`: 2-digit numbering (01-99)

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

### Project Setup

- **`/setup`** - Initialize `.agent/` directory for new or existing project
  - Creates `features/`, `tasks/`, `system/`, `sops/`, `known-issues/` directories
  - Generates project documentation templates
  - References universal SOPs

### Feature Requirements (WHAT to Build)

- **`/feature <description>`** - Define feature requirements through interactive conversation
  - Uses EARS format for acceptance criteria
  - Creates `.agent/features/<feature-name>.md`
  - Tracks as last feature for `/workflow:plan-task` auto-detection
  - Focuses on WHAT users need, not HOW to implement

- **`/vk-plan`** - Create VK Kanban planning tickets for features
  - Integrates with Vibe Kanban system
  - Creates numbered task breakdowns

### Implementation Planning (HOW to Build)

- **`/workflow:plan-task [description]`** - Create technical implementation plan
  - Auto-detects last feature if no argument provided
  - Reads feature requirements if available
  - Creates `.agent/tasks/XXX-task-name.md`
  - Breaks complex features into multiple tasks if needed

### Building & Testing

- **`/workflow:implement-task [XXX]`** - Implement a task (defaults to latest)
- **`/workflow:test-task [XXX]`** - Test a task implementation
- **`/workflow:complete-task [XXX]`** - Finalize task, update docs, git workflow

### Status & Documentation

- **`/workflow:status`** - Show project status, features, active tasks, recent changes
- **`/workflow:review-docs`** - Review documentation for issues or outdated info
- **`/workflow:update-doc`** - Manually update documentation

### Bug Fixes

- **`/workflow:fix-bug <description>`** - Intelligent bug fix workflow
  - **Quick hotfix** for simple bugs (done in one command)
  - **Bug task** for complex issues (full investigation + fix)
  - **Cross-project search** for similar issues automatically

### Issue Documentation

- **`/workflow:document-issue`** - Document a known issue or bug
  - Searches similar issues across all projects
  - Creates numbered issue document (NN: 01-99)
  - Updates known-issues index
  - Links to related tasks

### Command Resolution Order

1. **Project-local** (`.claude/commands/` in project root)
2. **Global** (`~/.claude/commands/`)

This allows project-specific overrides while maintaining global defaults.

---

## Adapters

**Location**: `~/.claude/adapters/`

Adapters allow the `/plan` command to work with different task management systems through a unified interface.

### Available Adapters

| Adapter | Command | Purpose |
|---------|---------|---------|
| VK | `/plan vk 001` | Creates VK planning tickets |
| Local | `/plan local 001` | Creates task documents in `.agent/tasks/` |
| Linear | `/plan linear 001` | Linear integration (placeholder) |

### Adapter Architecture

Each adapter implements:
1. `check_prerequisites()` - Verify system is available
2. `parse_feature()` - Read feature document
3. `plan_tasks()` - Create task breakdown
4. `create_tasks()` - Execute in target system
5. `report_completion()` - Generate summary

See `~/.claude/adapters/interface.md` for the full contract specification.

---

## Hooks

**Location**: `~/.claude/hooks/`

Hooks run shell commands in response to Claude Code events for validation, context loading, and automation.

### Hook Types

| Type | When | Use For |
|------|------|---------|
| `UserPromptSubmit` | Before prompt processed | Validation guards, context injection |
| `Stop` | After response complete | Logging, cleanup |

### Configuration

```json
// ~/.claude/settings.local.json (global)
// <project>/.claude/settings.local.json (project)
{
  "hooks": {
    "UserPromptSubmit": [
      {
        "matcher": "git push.*--force.*(main|master)",
        "hooks": [{
          "type": "command",
          "command": "echo 'BLOCKED: Force push to main'"
        }]
      }
    ]
  }
}
```

### Documentation

| File | Purpose |
|------|---------|
| `hooks/README.md` | Hooks overview |
| `hooks/validation-guards.md` | Blocking dangerous operations |
| `hooks/context-loaders.md` | Loading context selectively |

---

## Subagents

**Location**: `~/.claude/guides/subagents.md`

Subagents preserve main context by delegating reading/searching to specialized Claude instances.

### When to Use

| Situation | Agent Type | Why |
|-----------|------------|-----|
| Reading large docs | Explore | Don't bloat main context |
| Codebase search | Explore | Efficient parallel searches |
| Complex research | general-purpose | Full tool access |
| Quick lookups | Explore + Haiku | Minimal cost |

### Usage Pattern

```markdown
## In command files:

Use Task tool with subagent_type="Explore" and model="haiku":
- Prompt: "Read .agent/ROADMAP.md and extract items related to [topic]"
- This preserves main context for implementation work.
```

See `~/.claude/guides/subagents.md` for comprehensive usage guide.

---

## Typical Workflow

### Complete Feature Development Flow

```bash
# 1. Initialize project (once per project)
/setup

# 2. Define WHAT to build (feature requirements)
/feature "Asset upload with metadata extraction"
  → Interactive conversation about user needs
  → Creates .agent/features/asset-upload.md
  → EARS format acceptance criteria
  → Tracks as last feature

# 3. Plan HOW to build it (implementation)
/workflow:plan-task
  → Auto-detects last feature (asset-upload)
  → Reads feature requirements
  → Creates technical implementation plan
  → May create multiple tasks if complex
  → Creates .agent/tasks/001-asset-upload-backend.md

# 4. Implement the task
/workflow:implement-task 001
  → Reads task doc and feature requirements
  → Creates feature branch
  → Implements according to plan
  → Commits work

# 5. Test the implementation
/workflow:test-task 001
  → Runs automated tests
  → Verifies acceptance criteria from feature requirements
  → Manual testing checklist

# 6. Complete and finalize
/workflow:complete-task 001
  → Updates task status to Complete
  → Updates system documentation
  → Merges branch
  → Cleans up
```

### Quick Feature (No Formal Requirements)

For simple features, skip `/feature`:

```bash
/workflow:plan-task "Add user logout button"
  → Plans directly without requirements doc
/workflow:implement-task
/workflow:test-task
/workflow:complete-task
```

### Bug Fix Flow

```bash
/workflow:fix-bug "Upload fails for files > 10MB"
  → Auto-searches similar issues across projects
  → Routes to quick hotfix OR full bug task
  → Implements fix
  → Tests and documents
```

### Check Status

```bash
/workflow:status
  → Shows defined features
  → Shows task progress
  → Shows git status
  → Suggests next steps
```

---

## Cross-Project Features

### Known Issues Search

Known issues are searchable across **all projects** in `~/Projects`:

```bash
# Manual search
find ~/Projects -type f -path "*/\.agent/known-issues/*.md" -exec grep -l "keyword" {} \;

# Automatic search in /workflow:fix-bug and /workflow:document-issue commands
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

2. Ensure `~/.dotfiles/claude/` exists

### Run Setup

```bash
cd ~/.dotfiles/claude/
./setup.sh
```

The script will:
- ✅ Create symlink `~/.claude` → `~/.dotfiles/claude/`
- ✅ Verify all required files
- ✅ Check configuration
- ✅ Display available commands

### Verify Setup

```bash
ls -la ~/.claude          # Should show symlink
ls ~/.claude/commands/    # Should list available commands
```

---

## Customization

### Add New Universal SOP

1. Create new `.md` file in `~/.dotfiles/claude/workflow/sops/`
2. Follow documentation standards format
3. Update `~/.dotfiles/claude/workflow/sops/README.md`
4. Commit to dotfiles repo
5. All projects automatically reference it

### Add New Slash Command

**Global command:**
1. Create `.md` file in `~/.dotfiles/claude/commands/`
2. Follow existing command format
3. Available in all projects immediately

**Project-local command:**
1. Create `.claude/commands/` in project root
2. Add `.md` file with command
3. Only available in that project
4. Overrides global command if same name

### Modify Templates

1. Edit files in `~/.dotfiles/claude/workflow/templates/`
2. Test with `/setup` on a test project
3. Commit changes to dotfiles
4. Future projects use updated templates

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
git add claude/
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
cd ~/.dotfiles/claude/
./setup.sh  # Will backup and recreate
```

### Command Not Found

**Problem**: Slash command doesn't work

**Solution**:
1. Verify command exists: `ls ~/.claude/commands/`
2. Check command name matches exactly (e.g., `/workflow:plan-task` not `/plan-task`)
3. Restart Claude Code session

### Template Variables Not Replaced

**Problem**: `{{VARIABLE}}` appears in generated files

**Solution**:
- Re-run `/setup`
- Ensure you answered all prompts
- Check template file has correct variable names

### Cross-Project Search Returns Nothing

**Problem**: `find ~/Projects ...` returns no results

**Solution**:
1. Verify projects are in `~/Projects` directory
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

- **2026-01-18** - Major workflow improvements
  - Added unified `/plan` command with adapter architecture (vk, local, linear)
  - Added `/roadmap` command for project planning
  - Added `/test-plan` command with Playwright integration
  - Added `/bug` command (replaces `/feature-bug`)
  - Added hooks documentation (validation guards, context loaders)
  - Added subagents guide for context preservation
  - Deprecated `/vk-plan` (use `/plan vk`)
  - Deprecated `/feature-bug` (use `/bug`)
  - Modified `/setup` to include roadmap option
  - Modified `/feature` to support roadmap references

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

**Location**: `~/.dotfiles/claude/workflow/README.md`
**Symlink**: `~/.claude/workflow/README.md`
**Last Updated**: 2026-01-18
