---
description: Orchestrate epics, plans, runners, and worktrees — the full lifecycle
argument-hint: <epic|plan|dispatch|status|attach|resume|accept|close> [name] [context]
allowed-tools: Read, Write, Edit, Glob, Grep, Bash(ls*), Bash(mkdir*), Bash(tmux*), Bash(date*), Bash(git*), Bash(*claude*--agent*--dangerously*), Bash(ps*), Bash(gh*), Bash(*hooks/teardown*), AskUserQuestion, Task, EnterPlanMode, ExitPlanMode, mcp__playwright__*
---

# Deck

Parse first argument as subcommand. No arguments → show help.

```
/deck epic <name> [context]     — define big-picture work, create plan stubs
/deck plan <name> [context]     — flesh out a plan (stub or standalone)
/deck dispatch <name>           — spawn runner in background worktree
/deck status [name]             — check progress + worktree state
/deck attach <name>             — tmux window in worktree
/deck resume <name>             — re-dispatch runner to continue work
/deck accept <name>             — E2E test acceptance criteria via Playwright (optional)
/deck close <name>              — merge/confirm merged, teardown, mark done
```

---

## `epic`

Captures a milestone/body of work and breaks it into plan stubs. Produces `.deck/epics/<name>.md` + stub files in `.deck/plans/`.

### Initialize

1. `mkdir -p .deck/epics .deck/plans .deck/status`
2. If `.deck/epics/<name>.md` exists → ask overwrite or new name

### Discovery

Use `AskUserQuestion` throughout. Adapt depth to input detail.

1. **Goal**: What's the end state? What does "done" look like for this milestone?
2. **Problem**: What's broken or missing today?
3. **Users**: Who benefits? How does their workflow change?
4. **Constraints**: Technical, business, timeline, compatibility?
5. **Scope**: What's explicitly out?

Use Explore subagents to check codebase for relevant context before asking user.

### Break Down

Identify the discrete units of work (plans) needed to complete this epic. For each:
- A short name (kebab-case, used as plan filename)
- 2-3 sentence description: what it does, why it's needed, rough scope

Use `AskUserQuestion` to confirm the breakdown: "Does this split look right?" → "Yes" / "Adjust" / "Start over"

### Save

Write `.deck/epics/<name>.md`:

```markdown
# <name>

<!-- deck
created: <today's date>
-->

## Goal
End state for this milestone.

## Problem
What's broken or missing.

## Constraints
- ...

## Plans
- [ ] plan-name-1 — brief description
- [ ] plan-name-2 — brief description
- [ ] plan-name-3 — brief description
```

Create a stub file for each plan in `.deck/plans/`:

```markdown
# <plan-name>

<!-- deck
status: stub
epic: <epic-name>
created: <today's date>
-->

## What
2-3 sentences: what this plan covers and why.
```

Report: epic path, number of plan stubs created, next step (`/deck plan <first-plan-name>`).

---

## `plan`

Flesh out a plan into a full implementation spec. Works on stubs (from epic) or creates standalone plans.

### Initialize

1. `mkdir -p .deck/plans .deck/status`
2. Check if `.deck/plans/<name>.md` exists:
   - **Stub** (status: stub) → read it + read parent epic from `.deck/epics/` for context. Use both as input to requirements gathering.
   - **Already planned** → ask overwrite or new name
   - **Doesn't exist** → standalone plan, start fresh
3. Collect any additional context from arguments

### Requirements Gathering

Use `AskUserQuestion` for all questions. Skip what's already answered by context (stub + epic + arguments).

**Areas to cover** (adapt depth to input detail):

1. **Problem**: What, who, why now?
2. **Users**: Primary users, their workflow?
3. **Flows**: Main user journey, critical moments?
4. **Constraints**: Technical, business, performance, security?
5. **Acceptance criteria**: Definition of done, written as Given-When-Then scenarios (see format below). What would make it fail?
6. **Scope**: What's explicitly out?

**Adaptive**: detailed input → only ask gaps. Brief input → ask all. Use Explore subagents to check codebase before asking user.

### Discovery

Before designing the implementation, resolve unknowns:

1. Review the requirements gathered above — are there ambiguities, undefined behaviors, or technical questions that would block implementation?
2. If yes → use Explore subagents and WebSearch to investigate. Check existing codebase for patterns, prior art, and constraints that inform the design.
3. Surface findings to the user via `AskUserQuestion` only if there are decisions to make. If the research resolved the unknowns, proceed.
4. If no unknowns → skip this phase entirely.

### Validate

Summarize as text block, confirm via `AskUserQuestion`: "Is this summary accurate?" → "Yes, looks good" / "Need corrections" / "Add more details". Iterate until confirmed.

### Build vs Buy

Before designing the implementation, evaluate existing solutions:

1. For each major functional area in the plan, check if a well-established library/framework solves it
2. Use WebSearch and Explore subagents to evaluate options
3. **Prefer existing libraries** when: battle-tested, actively maintained, significant adoption, handles edge cases you'd miss (especially security-sensitive code)
4. **Build from scratch** when: trivially simple, existing options are over-engineered for the need, tight integration required, or the use case is genuinely unique
5. **Fit check**: the library must work well with the project's existing stack, patterns, and dependencies — don't introduce a library that fights the codebase

Include library decisions in the plan's Approach section with brief rationale.

### Plan Implementation

Shift from WHAT to HOW:

1. Explore subagents → analyze codebase (files, patterns, reuse)
2. Apply build-vs-buy decisions from above
3. Design approach — architecture decisions, new vs modified files
4. Break into ordered steps (runner's work items)
5. List files to create/modify
6. **8+ major steps** → suggest splitting via `AskUserQuestion`

### Confirm + Save

Confirm via `AskUserQuestion`: "Does this plan look right?" → "Yes, save it" / "Need changes" / "Start over"

Write `.deck/plans/<name>.md` (overwrites stub if it was one):

```markdown
# <name>

<!-- deck
status: planned
epic: <epic-name if applicable>
created: <today's date>
branch: <git-branch if applicable>
-->

## Context
Problem statement. Target users. Why.

## Approach
Implementation strategy. Key decisions.

## Steps
1. ...

## Files
- path/to/file — new|modify, description

## Acceptance criteria

Given-When-Then format:

- **Given** [precondition], **When** [action], **Then** [outcome]
- **Given** [precondition], **When** [action], **Then** [outcome]

## Constraints
- ...
```

If no `branch` is provided, dispatch will default to `deck/<name>`.

If plan belongs to an epic, update the epic's checklist (mark this plan as defined, not checked — checked means completed).

Report: plan path, step count, next command (`/deck dispatch <name>`).

---

## `dispatch`

Spawns runner as a background claude process in an isolated worktree.

### Validate

1. Read `.deck/plans/<name>.md` — fail if missing
2. If status is `stub` → fail: "Plan '<name>' is a stub. Run /deck plan <name> to flesh it out first."
3. If status is `pr_open`, `closed`, or `abandoned` → fail: "Plan '<name>' is <status>. Run /deck close <name> or /deck plan <name> to start fresh."
4. If status is `dispatched` → warn, confirm re-dispatch
5. If `.deck/status/<name>.md` exists → verify runner alive (see status section) → if alive, warn: runner still active

### Setup

1. `mkdir -p .deck/logs .deck/status`
2. Determine branch:
   - Plan has `branch` field → use that
   - Else → `deck/<name>`
3. Get absolute project root: `git rev-parse --show-toplevel`
4. Create worktree (if it doesn't already exist):
   - Worktree exists at `.claude/worktrees/<name>` → reuse it (previous dispatch or resume)
   - Branch exists (`git rev-parse --verify <branch> 2>/dev/null`): `git worktree add .claude/worktrees/<name> <branch>`
   - Branch doesn't exist: `git worktree add .claude/worktrees/<name> -b <branch>`
   - If branch is checked out in another worktree → fail: "Branch '<branch>' is already checked out at <path>. Remove that worktree first."

### Record + Spawn

1. Update plan metadata: `status: planned` → `status: dispatched`
2. Create `.deck/status/<name>.md` with process fields as `pending`:

```markdown
# <name>

- **pid**: pending
- **pid_start**: pending
- **branch**: <branch>
- **worktree**: <worktree-path>
- **status**: in_progress
- **started**: <ISO timestamp>
- **updated**: <ISO timestamp>

## Progress
Runner starting...

## Commits
(none yet)

## Notes
Dispatched.
```

3. Spawn runner via Bash:

```bash
cd <worktree-path> && nohup claude --agent deck-runner -p "<prompt>" --dangerously-skip-permissions > <project-root>/.deck/logs/<name>.log 2>&1 & echo $!
```

Prompt (passed via `-p`):

```
Plan name: <name>
Plan file: <project-root>/.deck/plans/<name>.md
Status file: <project-root>/.deck/status/<name>.md
```

4. Capture PID from command output. Get process start time: `ps -p <pid> -o lstart=`. Update the status file's `pid` and `pid_start` fields.

Report: plan name, PID, branch, worktree path, next commands (`/deck status <name>`, `/deck attach <name>`).

---

## `status`

### Verifying runner alive

Used by status, attach, resume, dispatch, and close. A runner is alive only if both conditions hold:

1. PID exists: `ps -p <pid> > /dev/null 2>&1`
2. Start time matches: `ps -p <pid> -o lstart=` equals stored `pid_start`

If PID exists but start time doesn't match → PID was recycled by OS, runner is dead.

### With name:
1. Read `.deck/status/<name>.md`
2. If status is `completed`, `failed`, `closed`, `pr_open`, or `abandoned` → display as-is, skip PID check
3. If status is `in_progress` → verify runner alive:
   - Alive → display as "running"
   - Dead → flag: "Runner exited without completing. Check `.deck/logs/<name>.log` for details. Use `/deck resume <name>` to continue."

### Without name:
1. Read all `.deck/status/` files + `.deck/plans/` for unstarted plans
2. For each status file with `in_progress`, verify runner alive (PID + start time)
3. Check for orphaned worktrees: `git worktree list` → any worktree under `.claude/worktrees/` whose plan is `completed`/`failed` but worktree still exists
4. Group by epic if applicable
5. Summary table:

```
DECK STATUS

Epic: auth-overhaul
  jwt-middleware    ● running      3/7    .claude/worktrees/jwt-middleware
  token-refresh     ○ stub         —      not planned yet
  session-migration ◻ planned      —      not dispatched

Standalone:
  fix-signup-bug    ✓ completed    5/5    .claude/worktrees/fix-signup-bug  ⚠ not cleaned up

Worktrees: 2 active, 1 orphaned
```

---

## `attach`

1. Read `.deck/status/<name>.md` → get worktree path
2. No status file → fail: "No runner for '<name>'. Run /deck dispatch <name> first."
3. If status is `closed` or `abandoned` → fail: "Plan '<name>' is <status>. Worktree was removed."
4. Verify worktree path exists on disk. If missing → fail: "Worktree not found at <path>. It may have been removed. Use /deck dispatch <name> to re-create."
5. If status is `in_progress` → verify runner alive. If alive → warn: "Runner is still active. This opens a separate interactive session alongside it — changes may conflict. Proceed?" Confirm via `AskUserQuestion`.
6. `tmux new-window -n "deck:<name>" -c "<worktree-path>" "claude"`
7. Confirm: "Opened tmux window 'deck:<name>' in <worktree-path>"

---

## `resume`

Re-dispatches a runner to continue work on an incomplete plan.

1. Read `.deck/status/<name>.md` — fail if missing
2. Verify runner alive → if alive: "Runner is still active. Use /deck attach <name> to interact."
3. If status is `completed`, `closed`, `abandoned`, or `pr_open` → "Plan already finished (status: <status>). Nothing to resume."
4. Spawn new background claude process in the existing worktree (note `>>` to append, preserving previous runner logs):

```bash
cd <worktree-path> && nohup claude --agent deck-runner -p "<prompt>" --dangerously-skip-permissions >> <project-root>/.deck/logs/<name>.log 2>&1 & echo $!
```

Prompt:

```
Plan name: <name>
Plan file: <project-root>/.deck/plans/<name>.md
Status file: <project-root>/.deck/status/<name>.md
A previous runner worked on this plan. Check the status file and git log for what's done. Continue from where it left off.
```

5. Capture PID and start time (`ps -p <pid> -o lstart=`). Update `pid`, `pid_start`, `status` (set to `in_progress`), and `updated` in status file.

---

## `accept`

E2E acceptance testing of a plan's criteria using Playwright MCP. Optional — not required before close.

### Steps:

1. `mkdir -p .deck/accept`
2. Read `.deck/plans/<name>.md` → extract acceptance criteria
3. If no acceptance criteria found → fail: "Plan has no acceptance criteria to test."
4. Ensure the app is running (ask user to confirm or provide URL)
5. For each criterion:
   - Translate to Playwright steps (navigate, click, fill, assert)
   - Execute via `mcp__playwright__*` tools (`browser_navigate`, `browser_snapshot`, `browser_click`, `browser_fill_form`, `browser_wait_for`, etc.)
   - Record pass/fail with screenshot on failure (`browser_take_screenshot`)
6. Report results:

```
ACCEPT: <name>

[PASS] Login returns valid JWT
[PASS] Protected routes reject invalid tokens
[FAIL] Token refresh extends session — timeout after 5s waiting for refresh response

3 criteria: 2 passed, 1 failed

Screenshots:
  .deck/accept/<name>/fail-token-refresh.png
```

7. Save results to `.deck/accept/<name>.md` with timestamps and failure details

---

## `close`

Finalize a plan: merge (or confirm merged), teardown worktree, mark done. Run this when you're done with a plan — whether it succeeded or you're abandoning it.

### Steps:

1. Read `.deck/status/<name>.md` — fail if missing
2. Read `.deck/plans/<name>.md` → get metadata (branch, epic)
3. Verify runner is NOT alive — if alive: "Runner is still active. Wait for it to finish or stop it first."
4. If status is `pr_open` → skip the generic question. Ask via `AskUserQuestion`: "PR was already opened. What now?" → "Already merged (confirm)" / "Abandon". Then proceed to the matching path below.
5. Otherwise, ask via `AskUserQuestion`: "How do you want to close this plan?" → "Merge locally" / "Open PR" / "Already merged (confirm)" / "Abandon"

### Merge locally
1. Get current branch: `git branch --show-current`
2. Merge plan branch: `git merge <branch>`
3. If merge conflicts → report and stop. User resolves manually, then re-runs close.

### Open PR
1. Push branch: `git push -u origin <branch>`
2. Create PR via `gh pr create` with plan context (title from plan name, body from plan Context + Acceptance criteria)
3. Report PR URL. **Do not teardown yet** — user runs `/deck close <name>` again after PR is merged.
4. Update status file: set status to `pr_open`, set `updated` timestamp.
5. Update plan file (`.deck/plans/<name>.md`): set `status` in deck metadata to `pr_open`.
6. Stop here.

### Already merged (confirm)
1. Verify branch was merged: `gh pr list --head <branch> --state merged` or `git branch --merged` check
2. If not actually merged → warn and stop

### Abandon
1. Skip merge entirely

### Teardown (all paths except "Open PR")
1. Run teardown in the worktree if it exists: `cd <worktree-path> && if [ -x .claude/hooks/teardown.sh ]; then .claude/hooks/teardown.sh; fi`
2. Remove worktree: `git worktree remove .claude/worktrees/<name>`
3. Delete branch if it was deck-created (`deck/*`). For custom branches, leave them.
4. Update status file: set status to `closed` (or `abandoned`), set `updated` timestamp
5. Update plan file (`.deck/plans/<name>.md`): set `status` in deck metadata to `closed` (or `abandoned`)
6. If plan belongs to an epic:
   - Closed → check off the plan in the epic's checklist
   - Abandoned → note it as abandoned in the epic

Report: plan name, close type, worktree removed, branch status.

---

## Help (no arguments)

```
DECK

Commands:
  /deck epic <name> [context]    Big-picture milestone → plan stubs
  /deck plan <name> [context]    Flesh out a plan (stub or standalone)
  /deck dispatch <name>          Spawn runner in background worktree
  /deck status [name]            Check progress + worktree state
  /deck attach <name>            tmux window in runner's worktree
  /deck resume <name>            Re-dispatch runner to continue work
  /deck accept <name>            E2E test acceptance criteria (optional)
  /deck close <name>             Merge/confirm merged, teardown, done

Workflow (epic):
  1. /deck epic auth-overhaul "migrate sessions to JWT"
  2. /deck plan jwt-middleware
  3. /deck dispatch jwt-middleware
  4. /deck status
  5. /deck accept jwt-middleware       (optional)
  6. /deck close jwt-middleware

Workflow (standalone):
  1. /deck plan fix-signup "gmail users can't register"
  2. /deck dispatch fix-signup
  3. /deck close fix-signup

Files:
  .deck/epics/    — milestone briefs
  .deck/plans/    — implementation plans (stubs or full)
  .deck/status/   — runner progress
  .deck/logs/     — runner output logs
  .deck/accept/   — E2E acceptance test results
```
