# Universal Standard Operating Procedures

This directory contains SOPs that apply to **all projects**, regardless of language or framework.

---

## Available Universal SOPs

### [Git Workflow](./git-workflow.md)
Branching strategy, commit messages, and git best practices.

**Applies to**: All projects
**Topics**:
- Branch naming (`feature/`, `fix/`, `hotfix/`)
- Commit message format
- Merge workflow
- Common git commands

### [Testing Principles](./testing-principles.md)
Core testing philosophy and patterns.

**Applies to**: All projects
**Topics**:
- Test types (unit, integration, e2e)
- Coverage goals
- Test structure (Arrange-Act-Assert)
- Best practices

### [Documentation Standards](./documentation-standards.md)
How to write and organize documentation.

**Applies to**: All projects
**Topics**:
- `.agent/` structure
- Naming conventions
- Task documentation
- Markdown standards

---

## How to Use

### In CLAUDE.md
Reference these universal SOPs:

```markdown
## Standard Operating Procedures

### Universal
See `~/.claude/workflow/sops/` for procedures that apply to all projects:
- [Git Workflow](~/.claude/workflow/sops/git-workflow.md)
- [Testing Principles](~/.claude/workflow/sops/testing-principles.md)
- [Documentation Standards](~/.claude/workflow/sops/documentation-standards.md)

### Project-Specific
See `.agent/sops/` for this project's procedures.
```

### In Project .agent/sops/README.md
List universal SOPs + project-specific ones:

```markdown
## Universal SOPs
See `~/.claude/workflow/sops/` (referenced, not copied):
- Git Workflow
- Testing Principles
- Documentation Standards

## Project-Specific SOPs
(In this directory):
- Django Setup
- Deployment
```

---

## Adding New Universal SOPs

1. Create new `.md` file in this directory
2. Follow documentation-standards.md format
3. Update this README.md
4. Commit to dotfiles repo
5. All projects automatically reference it

---

## Project-Specific vs Universal

**Universal** (here):
- Applies to ALL projects
- Language/framework agnostic
- Referenced, not copied
- Version controlled in dotfiles

**Project-Specific** (in `.agent/sops/`):
- Specific to one project's tech stack
- Framework-specific (Django, React, etc.)
- Copied from templates during `/init-project`
- Version controlled in project repo

---

**Location**: `~/.claude/workflow/sops/`
**Symlinked From**: `~/.dotfiles/config/claude/sops/`
**Last Updated**: 2025-10-25
