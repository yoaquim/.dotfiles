# VK Tags

This directory contains backups of Vibe Kanban task tags.

Tags are text snippets that can be inserted into task descriptions using `@tag-name` in the VK UI.

**Note:** When creating tasks via VK MCP (programmatically), the `@tag` syntax does NOT auto-expand. The `/vk-plan` command reads these files and includes the relevant content directly in task descriptions.

## Available Tags

| Tag | Purpose | File |
|-----|---------|------|
| `@bug_analysis` | Comprehensive bug analysis checklist | `bug_analysis.md` |
| `@add_unit_tests` | Unit testing checklist | `add_unit_tests.md` |
| `@code_refactoring` | Refactoring checklist | `code_refactoring.md` |
| `@django-patterns` | Django best practices | `django-patterns.md` |
| `@testing-requirements` | Testing standards (80%+ coverage) | `testing-requirements.md` |
| `@git-workflow` | Feature branch workflow | `git-workflow.md` |
| `@permission-checks` | Django RBAC permissions | `permission-checks.md` |
| `@tailwind-utilities` | Tailwind CSS + Rimas design system | `tailwind-utilities.md` |
| `@plan-feature` | Feature breakdown into numbered VK tasks | `plan-feature.md` |

## Usage

### In VK UI
Type `@tag-name` in a task description to auto-insert the tag content.

### Via /vk-plan Command
The command reads the feature doc, creates a planning ticket, and when VK executes it, Claude Code reads these tag files to include relevant context in subtask descriptions.

## Syncing with VK

These files are exported from VK's SQLite database:
```
~/Library/Application Support/ai.bloop.vibe-kanban/db.sqlite
```

To re-export tags:
```sql
sqlite3 ~/Library/Application\ Support/ai.bloop.vibe-kanban/db.sqlite "SELECT tag_name, content FROM tags;"
```

## Adding to VK

To add a new tag to VK:
1. Open VK → Settings → General → Task Tags
2. Click "Add Tag"
3. Enter tag name (snake_case, no spaces)
4. Paste content from the corresponding file here
