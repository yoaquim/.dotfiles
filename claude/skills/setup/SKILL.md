---
description: Initialize a project with CLAUDE.md, git, and dependencies
allowed-tools: Read, Write, Edit, Bash, Glob, AskUserQuestion
---

# Setup

Initialize a project for Claude Code. Creates CLAUDE.md with project context, optionally sets up git and installs dependencies.

---

## Step 1: Check Current State

Check what exists: CLAUDE.md, git repo, package.json/requirements.txt/go.mod/Cargo.toml, existing source files.

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

This informs the CLAUDE.md content. For new/empty projects, skip and base it on the answers from Step 2.

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

## Step 6: Install Dependencies (if needed)

If project files exist but deps aren't installed, ask before running:
- Node: `npm install`
- Python: `python3 -m venv venv && pip install -r requirements.txt`
- Go: `go mod tidy`
- Rust: `cargo build`

---

## Step 7: Report

```
SETUP COMPLETE

Project: <name>
CLAUDE.md: created
Git: <initialized / already existed / skipped>
Deps: <installed / skipped / not applicable>

Next:
  /deck epic <name>     — plan a milestone
  /deck plan <name>     — plan a single feature
```
