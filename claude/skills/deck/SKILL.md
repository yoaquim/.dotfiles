---
description: Orchestrate specs, runners, and worktrees — the full lifecycle
argument-hint: <spec|dispatch|status|attach|resume|accept|close> [name] [context]
allowed-tools: Read, Write, Edit, Glob, Grep, Bash(ls*), Bash(mkdir*), Bash(date*), Bash(git*), Bash(*deck/spawn.sh*), Bash(*deck/status.sh*), Bash(*deck/attach.sh*), Bash(gh*), Bash(*hooks/teardown*), Bash(npx playwright*), AskUserQuestion, Task, EnterPlanMode, ExitPlanMode, mcp__playwright__*
---

# Deck

Parse first argument as subcommand. No arguments → show help.

Scripts live alongside this file at `~/.claude/skills/deck/`. Use them — do not construct raw bash commands for spawn, status checks, or attach.

```
/deck spec <name> [context]     — spec out a feature
/deck dispatch <name>           — spawn runner in background worktree
/deck status [name]             — check progress + worktree state
/deck attach <name>             — tmux window in worktree
/deck resume <name>             — re-dispatch runner to continue work
/deck accept <name>             — E2E test acceptance criteria (optional)
/deck close <name>              — merge/confirm merged, teardown, done
```

---

## `spec`

Flesh out a spec into a full implementation document. Creates or updates `.deck/specs/<name>.md`.

### Initialize

1. `mkdir -p .deck/specs .deck/status`
2. Check if `.deck/specs/<name>.md` exists:
   - **status: stub** → read it for context. Use as input to requirements gathering.
   - **status: specced** or later → ask overwrite or new name
   - **Doesn't exist** → start fresh
3. Collect any additional context from arguments

### Requirements Gathering

Use `AskUserQuestion` for all questions. Skip what's already answered by context (stub + arguments).

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

1. For each major functional area in the spec, check if a well-established library/framework solves it
2. Use WebSearch and Explore subagents to evaluate options
3. **Prefer existing libraries** when: battle-tested, actively maintained, significant adoption, handles edge cases you'd miss (especially security-sensitive code)
4. **Build from scratch** when: trivially simple, existing options are over-engineered for the need, tight integration required, or the use case is genuinely unique
5. **Fit check**: the library must work well with the project's existing stack, patterns, and dependencies — don't introduce a library that fights the codebase

Include library decisions in the spec's Approach section with brief rationale.

### Plan Implementation

Shift from WHAT to HOW:

1. Explore subagents → analyze codebase (files, patterns, reuse)
2. Apply build-vs-buy decisions from above
3. Design approach — architecture decisions, new vs modified files
4. Break into ordered steps (runner's work items)
5. List files to create/modify
6. **8+ major steps** → suggest splitting via `AskUserQuestion`

### Confirm + Save

Confirm via `AskUserQuestion`: "Does this spec look right?" → "Yes, save it" / "Need changes" / "Start over"

Write `.deck/specs/<name>.md` (overwrites stub if it was one):

```markdown
# <name>

<!-- deck
status: specced
created: <today's date>
branch: <git-branch if applicable>
-->

## Context
Problem statement. Target users. Why.

## Acceptance Criteria
- **Given** [precondition], **When** [action], **Then** [outcome]

## Constraints
- ...

## Approach
Implementation strategy. Key decisions.

## Steps
1. ...

## Files
- path/to/file — new|modify, description
```

If no `branch` is provided, dispatch will default to `deck/<name>`.

Report: spec path, step count, next command (`/deck dispatch <name>`).

---

## `dispatch`

Spawns runner as a background claude process in an isolated worktree.

### Validate

1. Read `.deck/specs/<name>.md` — fail if missing
2. If status is `stub` → fail: "Spec '<name>' is a stub. Run /deck spec <name> to flesh it out first."
3. If status is `pr_open`, `closed`, or `abandoned` → fail: "Spec '<name>' is <status>. Run /deck close <name> or /deck spec <name> to start fresh."
4. If status is `dispatched` → check for prior runs: `bash ~/.claude/skills/deck/status.sh <project-root> <name>`. Parse the `state:` line:
   - `state:alive` → stop: "Runner is still active. Use `/deck status <name>` or `/deck attach <name>`."
   - `state:completed` or `state:failed` → ask via `AskUserQuestion`: "This spec was previously dispatched (status: <status>). Re-dispatch?" → "Yes, re-dispatch" / "No, cancel"
   - No status file → proceed (fresh dispatch)

### Setup

1. `mkdir -p .deck/status`
2. Determine branch:
   - Spec has `branch` field → use that
   - Else → `deck/<name>`
3. Get absolute project root: `git rev-parse --show-toplevel`

### Status File

1. Update spec metadata: `status: specced` → `status: dispatched`
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

### Spawn

```bash
bash ~/.claude/skills/deck/spawn.sh <name> <branch> <project-root> <spec-path>
```

The script handles: worktree creation (reuse/existing-branch/new-branch), prompt construction, runner spawn with `--dangerously-skip-permissions`, PID capture. Output is key:value lines:

```
worktree_status:reused|created-existing-branch|created-new-branch
worktree:<path>
pid:<number>
pid_start:<lstart string>
```

### Update Status

Parse spawn.sh output. Update the status file's `pid` and `pid_start` fields with the values from the script output.

Report: spec name, PID, branch, worktree path, next commands (`/deck status <name>`, `/deck attach <name>`).

---

## `status`

Run the status script:

```bash
bash ~/.claude/skills/deck/status.sh <project-root> [name]
```

**With name** — output has a structured header then the full status file:
```
state:alive|dead|completed|failed
worktree:<path>
---
<full status file>
```

If `state:dead` → warn: "Runner exited without completing. Check `.deck/logs/<name>.log` for details. Use `/deck resume <name>` to continue."

**Without name** — formatted summary table:
```
DECK STATUS

  jwt-middleware      ● running      3/7    .claude/worktrees/jwt-middleware
  fix-signup-bug      ✓ completed    5/5    .claude/worktrees/fix-signup-bug
  token-refresh       ○ stub         —
  session-migration   ◻ specced      —

Runners: 1 active, 1 completed, 0 failed
```

Display the script output directly.

---

## `attach`

1. Run `bash ~/.claude/skills/deck/status.sh <project-root> <name>` → parse `state:` and `worktree:` from output. The script searches sibling repos if the status file isn't found locally, so attach works even when invoked from a different repo than where the runner was dispatched.
2. No status file → fail: "No runner for '<name>'. Run `/deck dispatch <name>` first."
3. If `state:alive` → warn via `AskUserQuestion`: "Runner is still active. This opens a separate interactive session alongside it — changes may conflict. Proceed?" → "Yes" / "No"
4. Run: `bash ~/.claude/skills/deck/attach.sh <name> <worktree-path>` — the worktree path from the status file is absolute, so tmux opens in the correct directory regardless of which repo you're in.
5. Confirm: "Opened tmux window 'deck-<name>' in <worktree-path>"

---

## `resume`

Re-dispatches a runner to continue work on an incomplete spec.

1. Run `bash ~/.claude/skills/deck/status.sh <project-root> <name>` → parse `state:` line.
   - No status file → fail: "No runner for '<name>'. Run `/deck dispatch <name>` first."
   - `state:alive` → "Runner is still active. Use `/deck attach <name>` to interact."
   - `state:completed`, `state:closed`, `state:abandoned`, or `state:pr_open` → "Spec already finished (status: <status>). Nothing to resume."
2. Get absolute project root: `git rev-parse --show-toplevel`
3. Read branch from status file or spec file (`.deck/specs/<name>.md`).
4. Spawn via script (`--resume` appends to log and adds continuation note to prompt):

```bash
bash ~/.claude/skills/deck/spawn.sh <name> <branch> <project-root> .deck/specs/<name>.md --resume
```

5. Parse spawn.sh output. Update `pid`, `pid_start`, `status` (set to `in_progress`), and `updated` in status file.

---

## `accept`

Run the Playwright E2E tests the runner wrote for a spec. Optional — not required before close.

### Steps:

1. Find the test file: check `e2e/<name>.spec.ts`, then search for `**/<name>.spec.ts` in the project's e2e/test directories. Fail if not found: "No E2E test file found for '<name>'. The runner may not have written one (spec may not be browser-facing)."
2. Ensure the app is running — ask user to confirm or provide URL via `AskUserQuestion`
3. Run: `npx playwright test <test-file> --reporter=list`
4. Report results directly from Playwright output
5. If failures: use `mcp__playwright__*` tools to interactively debug — navigate to failing pages, take screenshots (`browser_take_screenshot`), inspect state (`browser_snapshot`). Report what's actually rendering vs what's expected.

---

## `close`

Finalize a spec: merge (or confirm merged), teardown worktree, mark done. Run this when you're done with a spec — whether it succeeded or you're abandoning it.

### Steps:

1. Run `bash ~/.claude/skills/deck/status.sh <project-root> <name>` — fail if no status file.
2. Read `.deck/specs/<name>.md` → get metadata (branch).
3. If `state:alive` → "Runner is still active. Wait for it to finish or stop it first."
4. If status is `pr_open` → skip the generic question. Ask via `AskUserQuestion`: "PR was already opened. What now?" → "Already merged (confirm)" / "Abandon". Then proceed to the matching path below.
5. Otherwise, ask via `AskUserQuestion`: "How do you want to close this spec?" → "Merge locally" / "Open PR" / "Already merged (confirm)" / "Abandon"

### Merge locally
1. Get current branch: `git branch --show-current`
2. Merge spec branch: `git merge <branch>`
3. If merge conflicts → report and stop. User resolves manually, then re-runs close.

### Open PR
1. Push branch: `git push -u origin <branch>`
2. Create PR via `gh pr create` with spec context (title from spec name, body from spec Context + Acceptance Criteria)
3. Report PR URL. **Do not teardown yet** — user runs `/deck close <name>` again after PR is merged.
4. Update status file: set status to `pr_open`, set `updated` timestamp.
5. Update spec file: set `status` in deck metadata to `pr_open`.
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
5. Update spec file: set `status` in deck metadata to `closed` (or `abandoned`)

Report: spec name, close type, worktree removed, branch status.

---

## Help (no arguments)

```
DECK

Commands:
  /deck spec <name> [context]    Spec out a feature
  /deck dispatch <name>          Spawn runner in background worktree
  /deck status [name]            Check progress + worktree state
  /deck attach <name>            tmux window in runner's worktree
  /deck resume <name>            Re-dispatch runner to continue work
  /deck accept <name>            E2E test acceptance criteria (optional)
  /deck close <name>             Merge/confirm merged, teardown, done

Workflow:
  1. /deck spec jwt-middleware "add JWT auth to API routes"
  2. /deck dispatch jwt-middleware
  3. /deck status
  4. /deck accept jwt-middleware       (optional)
  5. /deck close jwt-middleware

Files:
  .deck/specs/    — feature specs
  .deck/status/   — runner progress
  .deck/logs/     — runner output logs
```
