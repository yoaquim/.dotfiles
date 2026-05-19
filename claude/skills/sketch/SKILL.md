---
name: sketch
description: Quickly capture a feature idea as a dispatch-ready spec file. Lightweight ZeeSpec — one question at a time, progressively building context. Use when you want to flesh out what you need before dispatching, without Linear.
version: 1.0.0
argument-hint: <name> [context]
allowed-tools: Read, Write, Edit, Glob, Grep, Bash(ls*), Bash(mkdir*), Bash(date*), Bash(git*), AskUserQuestion, Task, EnterPlanMode, ExitPlanMode
hooks:
  PostToolUse:
    - matcher: "Write|Edit"
      hooks:
        - type: command
          command: "$HOME/.claude/hooks/lint-spec.sh"
          timeout: 10
---

# Sketch

`/sketch <name> [context]` — name required, context optional.

## 1. Gather

Start from conversation context + arguments. Fill gaps **one question at a time** via `AskUserQuestion` — don't front-load a questionnaire.

### ZeeSpec-lite dimensions

Skip what's obvious or irrelevant.

- **WHAT** (always): Core entities, states, data
- **WHY** (always): Problem it solves
- **HOW** (usually): Approach, key decisions, sequencing
- **WHERE** (if ambiguous): Codebase scope, what's out
- **WHEN/WHO** (rarely): Only if timing/permissions are critical

### Progressive questioning

1. Synthesize what you know from conversation + arguments
2. Identify the single biggest gap
3. Ask ONE question via `AskUserQuestion`
4. Incorporate, reassess, repeat
5. Target 2-4 questions. Past 5 = over-speccing.

## 2. Discover

1. Spawn Explore subagents — relevant files, patterns, test infra
2. Read `~/.claude/practices/INDEX.md` — check detect rules, read matched practices
3. Practices shape the sketch (e.g., TDD → testable acceptance criteria)

Keep findings to paths and patterns, not file contents.

## 3. Scope Check

- **Single goal**: One sentence without "and"?
- **Steps**: >8 → suggest splitting
- **Files**: >10 → likely too broad

If any fail, ask: "This is broad. Split or keep?" Advisory, not blocking.

## 4. Write

`mkdir -p .dispatch/sketches`

Write `.dispatch/sketches/<name>.md`:

```markdown
# <name>

## What
What to build. Core entities/states if relevant.

## Why
Why this matters. Problem it solves. Business rules or constraints.

## Done When
- Concrete, testable acceptance criteria
- Written so a runner can verify without asking

## Approach
Implementation strategy. Key decisions. Ordered steps.
Include build-vs-buy decisions if applicable.

1. Step one
2. Step two
...

## Files
- path/to/file — new|modify, description

## Practices
- <practice>: <why it applies>
```

Every line is a decision, not a description. "Handle errors gracefully" is slop. "On timeout: retry once, return 503" is a decision. A runner reads this cold and builds without clarification.

## 5. Confirm + Report

Confirm via `AskUserQuestion`: "Sketch ready?" → "Save it" / "Need changes"

Report: file path, step count, next command: `/dispatch <name>`

---

## Help (no arguments)

```
SKETCH — Feature idea → dispatch-ready spec

Usage:
  /sketch <name> [context]       Flesh out a feature interactively
  /sketch jwt-auth               Start from scratch
  /sketch jwt-auth "API routes"  Start with context hints

Workflow:
  1. /sketch jwt-auth            — answer a few questions
  2. /dispatch jwt-auth           — runner picks it up

Files:
  .dispatch/sketches/<name>.md
```
