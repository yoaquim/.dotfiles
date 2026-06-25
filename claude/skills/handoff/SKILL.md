---
name: handoff
description: Distill the current session into a self-sufficient handoff doc so a fresh session continues cleanly via /pickup — a deliberate alternative to lossy auto-compact. Use at a clean boundary, around 70% context, or before /clear.
version: 1.0.0
argument-hint: "[focus]"
arguments: focus
allowed-tools: Read, Write, Edit, Glob, Grep, Bash(git*), Bash(date*), Bash(*handoff/scaffold.sh*)
---

# Handoff

Every word earns its place. The reader is the next agent, not a human — write for zero-ambiguity resumption.

**Input:** `$focus` — optional steer ("the auth refactor"). Empty → infer the active thread from the session.

`/handoff` writes the doc. `/pickup` resumes from it.

## 1. Scaffold

Run `~/.claude/skills/handoff/scaffold.sh "<slug-from-focus>"`. It returns `file:` (where to write), `prev:` (prior handoff), and git context (branch, commits, status, diffstat). Handoffs are ignored locally — never committed, zero repo footprint.

## 2. Distill

Fill `~/.claude/skills/handoff/templates/handoff.md`:

- **Self-sufficient snapshot, not a diff.** Carry forward every still-relevant decision, constraint, and dead end. The reader sees only this file.
- **Router, not copy.** Point to Linear, issues, and files — don't paste their contents.
- **Rejected approaches earn their section** — they're what stops the next agent re-trying dead ends.
- **Redact** keys, tokens, PII.
- Drop any section with nothing real to say. Keep the `# 🤝 HANDOFF` sentinel verbatim — `/pickup` finds it.
- `prev` goes under Pointers as history only; never tell the reader to walk the chain.

## 3. Write

Write to the `file:` path from step 1.

## 4. Close

Two lines:
- **What it captures** — plain English, the thread being handed off.
- **Where it lives** — the path, plus `/pickup` to resume.
