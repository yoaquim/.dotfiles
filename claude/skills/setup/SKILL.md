---
description: Initialize a project with CLAUDE.md, git, hooks, and dependencies
allowed-tools: Read, Write, Edit, Bash, Glob, AskUserQuestion
---

# Setup

Initialize a project for Claude Code. Creates CLAUDE.md, hooks scaffolding with check/verify/setup/teardown scripts, optionally sets up git and installs dependencies.

---

## Step 1: Check Current State

Check what exists: CLAUDE.md, .claude/, git repo, package.json/requirements.txt/go.mod/Cargo.toml, existing source files.

If CLAUDE.md exists → ask: "CLAUDE.md already exists. Overwrite or cancel?"

---

## Step 2: Gather Project Info

Use `AskUserQuestion` for each. Skip what's obvious from existing files.

1. **Project name** — default to directory name
2. **Language/framework** — detect from existing files if possible, otherwise ask
3. **Brief description** — what does it do, who is it for (1-2 sentences)

---

## Step 3: Analyze Codebase

If existing code is present, use Explore subagents or Glob/Grep to understand:
- Directory structure and key files
- Architecture patterns (monolith, API + frontend, microservices, etc.)
- Test setup and commands
- Build/dev/run commands
- Docker setup (Dockerfile, docker-compose.yml, services, etc.)

This informs the CLAUDE.md content and the hooks scripts. For new/empty projects, skip and base it on the answers from Step 2.

---

## Step 4: Write CLAUDE.md

Generate a project-specific CLAUDE.md. Keep it succinct — this is read by Claude on every session.

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

Adapt sections to the project. Omit what doesn't apply. Add sections if the project warrants it (e.g. "Environment Variables" if .env is used).

---

## Step 5: Git Init (if needed)

If not already a git repo, ask: "Initialize git repo?" → "Yes" / "No"

If yes: `git init`, create appropriate .gitignore for the stack (include `.deck/`).

---

## Step 6: Hooks Scaffolding

Run the init-hooks script to create `.claude/` structure:

```bash
bash ~/.claude/skills/setup/init-hooks.sh
```

This creates the static scaffolding:
- `.claude/settings.json` — hooks config (PostToolUse check + Stop verify)
- `.claude/check.sh` — placeholder
- `.claude/verify.sh` — placeholder
- `.claude/setup.sh` — placeholder
- `.claude/teardown.sh` — placeholder

If `.claude/settings.json` or any script already exists, the script skips it.

---

## Step 7: Configure Hook Scripts

Using what was learned in Steps 2-3, fill in the four scripts with project-specific commands. Each script should be short (5-15 lines). Use Docker (`docker compose exec -T` or `docker compose run --rm`) if the project uses Docker. Pipe check output through `head -20` to keep it short.

| Script | Purpose | Trigger | Blocking? | Speed |
|--------|---------|---------|-----------|-------|
| `check.sh` | Lint + typecheck | Every Edit/Write (PostToolUse) | No | < 10s |
| `verify.sh` | Full lint + typecheck + test suite | Claude stops (Stop hook) | Yes — non-zero exit forces Claude to fix | OK to be slow |
| `setup.sh` | Install deps, run migrations, start services | Runner SessionStart (deck dispatch) | N/A | One-time |
| `teardown.sh` | Tear down what setup.sh created | `/deck clean` | N/A | One-time |

If the project doesn't use Docker, setup.sh/teardown.sh may be minimal or empty — that's fine.

---

## Step 8: Install Dependencies (if needed)

If project files exist but deps aren't installed, ask before running:
- Node: `npm install`
- Python: `python3 -m venv venv && pip install -r requirements.txt`
- Go: `go mod tidy`
- Rust: `cargo build`

---

## Step 9: Report

```
SETUP COMPLETE

Project: <name>
CLAUDE.md: created
Git: <initialized / already existed / skipped>
Hooks: <created / already existed>
  check.sh:    <configured / skipped>
  verify.sh:   <configured / skipped>
  setup.sh:    <configured / skipped>
  teardown.sh: <configured / skipped>
Deps: <installed / skipped / not applicable>

Next:
  /deck epic <name>     — plan a milestone
  /deck plan <name>     — plan a single feature
```
