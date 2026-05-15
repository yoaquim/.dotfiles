---
name: setup
description: Initialize a project with CLAUDE.md, git, hooks, and dependencies. Use when starting a new project or onboarding an existing codebase to Claude Code.
allowed-tools: Read, Write, Edit, Bash, Glob, AskUserQuestion
---

# Setup

## Step 1: Check Current State

Check what exists: CLAUDE.md, .claude/, git repo, package manifests, source files.

If CLAUDE.md exists → read it, then ask: "CLAUDE.md already exists." → "Keep and add hooks only" / "Update with my additions" / "Overwrite completely" / "Cancel"

- **Keep**: Skip Step 4, use as-is, only set up hooks
- **Update**: Preserve existing content, add/update sections from analysis
- **Overwrite**: Replace entirely

## Step 2: Gather Project Info

Ask via `AskUserQuestion`. Skip what's obvious from files.

1. **Project name** — default to directory name
2. **Language/framework** — detect if possible
3. **Brief description** — 1-2 sentences

## Step 3: Analyze Codebase

If existing code, explore: directory structure, architecture patterns, test/build/dev commands, Docker setup. Skip for empty projects.

## Step 4: Write CLAUDE.md

Succinct — read every session.

```markdown
# <Project Name>

<One-line description.>

## Stack

- **Language**: <lang> + <framework>
- **Database**: <db if applicable>
- **Testing**: <test framework + command>

## Architecture

<2-5 sentences: how the project is structured, key directories, request flow.>

## Commands

```
<dev command>
<test command>
<build command if applicable>
```

## Conventions

- <Key convention 1 — e.g. "All API routes in src/routes/">
- <Key convention 2 — e.g. "Tests mirror source structure in tests/">
- <Any project-specific patterns>
```

Adapt sections. Omit what doesn't apply. Add sections if warranted (e.g., "Environment Variables").

## Step 5: Git Init (if needed)

Not a git repo → ask: "Initialize git repo?" If yes: `git init`, create .gitignore (include `.dispatch/`).

## Step 6: Hooks Scaffolding

```bash
bash ~/.claude/skills/setup/init-hooks.sh
```

Creates (skips existing):
- `.claude/settings.json` — hooks config
- `.claude/hooks/stop-verify.sh` — Stop hook wrapper (retry loop prevention)
- `.claude/hooks/check.sh` — placeholder (`$1` = file path)
- `.claude/hooks/verify.sh` — placeholder
- `.claude/hooks/setup.sh` — placeholder
- `.claude/hooks/teardown.sh` — placeholder

## Step 7: Configure Hook Scripts

Fill in `.claude/hooks/` scripts (5-15 lines each). Use Docker commands if project uses Docker. Do NOT edit `stop-verify.sh`.

| Script | Purpose | Trigger | Blocking? | Speed |
|--------|---------|---------|-----------|-------|
| `check.sh` | Lint + typecheck on `$1` | Every Edit/Write (PostToolUse) | No | < 10s |
| `verify.sh` | Full lint + typecheck + tests | Stop hook (via stop-verify.sh) | Yes first, reports-only on retry | OK slow |
| `setup.sh` | Install deps, migrations, services | Runner SessionStart | N/A | One-time |
| `teardown.sh` | Tear down setup.sh resources | Manual cleanup | N/A | One-time |

## Step 8: Install Dependencies (if needed)

Ask before running: `npm install` / `pip install -r requirements.txt` / `go mod tidy` / `cargo build`.

## Step 9: Report

```
SETUP COMPLETE

Project: <name>
CLAUDE.md: <created / updated / kept / skipped>
Git: <initialized / already existed / skipped>
Hooks: <created / already existed>
  check.sh:    <configured / skipped>
  verify.sh:   <configured / skipped>
  setup.sh:    <configured / skipped>
  teardown.sh: <configured / skipped>
Deps: <installed / skipped / not applicable>

Next:
  /sketch <name>        — sketch out a feature
  /dispatch <name>      — dispatch to a runner
```
