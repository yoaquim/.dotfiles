# Claude Code Skills

Skills are slash commands that extend Claude Code with custom capabilities.

## Available Skills

| Skill | Invocation | Description |
|-------|------------|-------------|
| setup | `/setup` | Initialize new project with scaffolding and documentation |
| feature | `/feature` | Define feature requirements through interactive conversation |
| plan | `/plan` | Plan feature implementation across task management systems |
| bug | `/bug` | Document bugs with optional feature linking and VK integration |
| roadmap | `/roadmap` | Create/update project roadmap from unstructured input |
| test-plan | `/test-plan` | Generate test plans and Playwright tests |

## Skill Structure

Each skill is a directory containing:

```
skills/
├── feature/
│   ├── SKILL.md           # Main skill definition (required)
│   └── ears-format.md     # Supporting reference material
├── plan/
│   └── SKILL.md
├── bug/
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

## Creating New Skills

1. Create directory: `skills/my-skill/`
2. Create `SKILL.md` with frontmatter and instructions
3. Add supporting files as needed
4. Skill is immediately available as `/my-skill`

## Skill Resolution Order

1. **Project-local** (`.claude/skills/` in project root)
2. **Global** (`~/.claude/skills/`)

This allows project-specific overrides while maintaining global defaults.

## Automatic vs Manual Invocation

- **Manual**: User types `/feature`, `/plan`, etc.
- **Automatic**: Claude loads skill when detecting relevant context (e.g., loading `/feature` when user says "let's define what we're building")

To disable automatic invocation, add to frontmatter:
```yaml
---
disable-model-invocation: true
---
```

## Adapters

The `/plan` skill uses adapters for different task management backends:

| Adapter | Command | Purpose |
|---------|---------|---------|
| VK | `/plan vk 001` | Creates VK planning tickets for parallel execution |
| Local | `/plan local 001` | Creates task documents in `.agent/tasks/` |
| Linear | `/plan linear 001` | Linear integration (placeholder) |

See `~/.claude/adapters/` for adapter implementations.
