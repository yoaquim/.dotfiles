---
description: Initialize a project with CLAUDE.md, git, hooks, and dependencies
allowed-tools: Read, Write, Edit, Bash, Glob, AskUserQuestion
---

# Setup

Initialize a project for Claude Code. Creates CLAUDE.md, hooks scaffolding with check/verify/setup/teardown scripts, optionally sets up git and installs dependencies.

---

## Step 1: Check Current State

Check what exists: CLAUDE.md, .claude/, git repo, package.json/requirements.txt/go.mod/Cargo.toml, existing source files.

If CLAUDE.md exists → read it first, then ask: "CLAUDE.md already exists. How should I handle it?" → "Keep and add hooks only" / "Update with my additions" / "Overwrite completely" / "Cancel"

- **Keep**: Skip Step 4 entirely. Use existing CLAUDE.md as-is, only set up hooks (Steps 6-7).
- **Update**: Read existing content, preserve everything in it, add or update sections based on codebase analysis. Do not remove content the user or team put there.
- **Overwrite**: Replace entirely with generated content.

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

Run the init-hooks script to create `.claude/hooks/` structure:

```bash
bash ~/.claude/skills/setup/init-hooks.sh
```

This creates the static scaffolding:
- `.claude/settings.json` — hooks config (PostToolUse check + Stop verify, with statusMessage)
- `.claude/hooks/stop-verify.sh` — Stop hook wrapper (handles retry loop prevention)
- `.claude/hooks/check.sh` — placeholder (receives file path as `$1`)
- `.claude/hooks/verify.sh` — placeholder
- `.claude/hooks/setup.sh` — placeholder
- `.claude/hooks/teardown.sh` — placeholder

If `.claude/settings.json` or any script already exists, the script skips it.

---

## Step 7: Configure Hook Scripts

Using what was learned in Steps 2-3, fill in the four scripts in `.claude/hooks/` with project-specific commands. Each script should be short (5-15 lines). Use Docker (`docker compose exec -T` or `docker compose run --rm`) if the project uses Docker. Do NOT edit `stop-verify.sh` — it's the wrapper that handles retry loop prevention.

| Script | Purpose | Trigger | Blocking? | Speed |
|--------|---------|---------|-----------|-------|
| `check.sh` | Lint + typecheck on `$1` (file path) | Every Edit/Write (PostToolUse) | No | < 10s |
| `verify.sh` | Full lint + typecheck + test suite | Claude stops (Stop hook, via stop-verify.sh) | Yes on first attempt, reports-only on retry | OK to be slow |
| `setup.sh` | Install deps, run migrations, start services | Runner SessionStart (deck dispatch) | N/A | One-time |
| `teardown.sh` | Tear down what setup.sh created | `/deck close` | N/A | One-time |

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
CLAUDE.md: <created / updated / kept / skipped>
Git: <initialized / already existed / skipped>
Hooks: <created / already existed>
  check.sh:    <configured / skipped>
  verify.sh:   <configured / skipped>
  setup.sh:    <configured / skipped>
  teardown.sh: <configured / skipped>
Deps: <installed / skipped / not applicable>

Next:
  /deck spec <name>     — spec out a feature
```
