# Claude Code Skills

Skills are the modern way to extend Claude Code with custom capabilities. They replace the older "commands" format.

## Key Differences from Commands

| Aspect | Old: Commands | New: Skills |
|--------|---------------|-------------|
| Location | `.claude/commands/name.md` | `.claude/skills/name/SKILL.md` |
| Triggering | Manual only (`/name`) | Manual OR automatic |
| Structure | Single file | Directory with supporting files |
| Features | Basic | Frontmatter config, tool restrictions |

## Available Skills

### Core Skills
| Skill | Invocation | Description |
|-------|------------|-------------|
| feature | `/feature` | Define feature requirements through interactive conversation |
| setup | `/setup` | Initialize new project with scaffolding and documentation |
| plan | `/plan` | Plan feature implementation across task management systems |
| bug | `/bug` | Document bugs with optional feature linking |
| roadmap | `/roadmap` | Create/update project roadmap from unstructured input |
| test-plan | `/test-plan` | Generate test plans and Playwright tests |

### Workflow Skills
| Skill | Invocation | Description |
|-------|------------|-------------|
| workflow-plan-task | `/workflow:plan-task` | Plan and document a task |
| workflow-implement-task | `/workflow:implement-task` | Implement a documented task |
| workflow-test-task | `/workflow:test-task` | Test a completed implementation |
| workflow-complete-task | `/workflow:complete-task` | Complete task and update docs |
| workflow-status | `/workflow:status` | Show comprehensive project status |
| workflow-review-docs | `/workflow:review-docs` | Review documentation for accuracy |
| workflow-fix-bug | `/workflow:fix-bug` | Fix bugs with hotfix or full workflow |
| workflow-document-issue | `/workflow:document-issue` | Document known issues |
| workflow-update-doc | `/workflow:update-doc` | Update project documentation |

## Skill Structure

Each skill is a directory containing:

```
skills/
├── feature/
│   ├── SKILL.md           # Main skill definition (required)
│   └── ears-format.md     # Supporting reference material
├── setup/
│   └── SKILL.md
└── ...
```

### SKILL.md Frontmatter

```yaml
---
description: Brief description shown in skill list
argument-hint: <expected arguments>
allowed-tools: Read, Write, Edit, ...
---
```

### Supporting Files

Skills can include supporting files for:
- Reference documentation (like `ears-format.md` in feature/)
- Templates
- Examples
- Checklists

Claude can read these files when executing the skill for additional context.

## Migration from Commands

The old `commands/` directory is deprecated. Skills provide:
- **Automatic invocation** - Claude can load skills based on context
- **Better organization** - Supporting files in the same directory
- **Richer config** - Tool restrictions, argument hints

## Creating New Skills

1. Create directory: `skills/my-skill/`
2. Create `SKILL.md` with frontmatter and instructions
3. Add supporting files as needed
4. Skill is immediately available as `/my-skill`

## Automatic vs Manual Invocation

- **Manual**: User types `/feature`, `/plan`, etc.
- **Automatic**: Claude loads skill when detecting relevant context (e.g., loading `/feature` when user says "let's define what we're building")

To disable automatic invocation, add to frontmatter:
```yaml
---
disable-model-invocation: true
---
```
