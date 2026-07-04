---
name: pickup
description: Get a fresh session up to speed — read the latest handoff, the repo's Linear project (issues, milestones, documents), and the codebase (current plus related repos). The arrival counterpart to /handoff. Use at the start of a new session. Bare /pickup does it all.
version: 1.0.0
argument-hint: "[handoff-file]"
arguments: handoff_file
allowed-tools: Read, Glob, Grep, Task, Bash(ls*), Bash(git*), Bash(*/resolve-project.sh*), AskUserQuestion, mcp__linear-work__*, mcp__linear-personal__*, mcp__linear-simpliruta__*, mcp__linear-mesa__*, mcp__linear-nullbreaker__*, mcp__linear-parchamusic__*, mcp__linear-lul__*, mcp__linear-rimas__*
---

# Pickup

Orient from three sources, then state where we are and continue. Bare `/pickup` runs all of it.

## 1. Handoff

Use `$handoff_file` if given, else the newest by modification time:
`ls -1t "$(git rev-parse --show-toplevel)/.claude/handoffs/"*.md 2>/dev/null | head -1`.

Read **only that one** — it's a self-sufficient snapshot. Never walk the chain unless asked. None found → skip; orient from sources 2–3.

## 2. Linear

Run `~/.claude/scripts/resolve-project.sh`. If mapped (exit 0), read the project via whichever Linear MCP server is connected: open issues, milestones, and project documents — the whole picture. Exit 1 → no Linear project; skip.

## 3. Code

- **Current repo:** structure, recent commits (`git log --oneline -15`), and the files the handoff flags.
- **Related repos:** others in `~/.claude/scripts/repo-projects.json` sharing this repo's project(s). If checked out under `~/Projects`, skim them; otherwise just note them. Use `Task` to review in parallel.

## 4. Confirm

Brief: where things stand, the next step (from the handoff's Next), and anything unresolved. Then continue the work.
