---
name: dispatch
description: Dispatch work to autonomous runners in isolated worktrees. Accepts Linear tickets or sketch specs. Use when assigning work to background Claude runners or checking runner status.
argument-hint: <ticket-id|sketch-name|search-query|status> [name]
allowed-tools: Read, Write, Edit, Glob, Grep, Bash(ls*), Bash(mkdir*), Bash(date*), Bash(git*), Bash(*dispatch/spawn.sh*), Bash(*dispatch/status.sh*), AskUserQuestion, Task, EnterPlanMode, ExitPlanMode, mcp__linear-work__*, mcp__linear-personal__*, mcp__linear-simpliruta__*
---

# Dispatch

Parse first argument as subcommand. No arguments → show help.

Scripts live at `~/.claude/skills/dispatch/`. Use them — don't construct raw bash commands.

```
/dispatch <ticket-id>              — fetch ticket, discover, spawn runner
/dispatch <sketch-name>            — read sketch spec, discover, spawn runner
/dispatch <search-terms>           — search Linear, pick ticket, then dispatch
/dispatch status [name]            — check runner progress
```

Attaching to a runner is native now: `claude agents` (TUI) or `claude attach <session-id>` — the session ID is in the status file.

---

## Argument Detection

1. `status` → subcommand
2. Ticket ID pattern (letters + hyphen + digits, e.g. `ENG-142`) → Linear ticket flow
3. Matches `.dispatch/sketches/<arg>.md` → sketch flow
4. Otherwise → Linear search query

### 1. Fetch

Fetch via the Linear MCP `get_issue` tool. Pick the server matching the repo's Linear workspace (see notes in `~/.claude/scripts/repo-projects.json`); default to the primary workspace server. Fail if not found.

### 2. Name

Lowercase the ticket identifier (`ENG-142` → `eng-142`).

Check prior runs: `bash ~/.claude/skills/dispatch/status.sh <project-root> <name>`. Parse `state:`:
- `alive` → stop: "Runner still active. Use `/dispatch status <name>` or `claude attach <session-id>`."
- `completed` or `failed` → ask: "Previously dispatched (status: <status>). Re-dispatch?" → "Yes" / "No"
- No status file → proceed

### 3. Discover

Spawn Explore subagents from the issue title/description. Collect relevant paths, test infra, reference files. Paths and patterns, not contents.

### 4. Ask

Ask via `AskUserQuestion` — adaptive:
- Clear ticket → single confirmation: "Ready to dispatch with this scope?"
- Vague ticket → targeted questions on scope, approach, ambiguities

### 5. Prompt File

Get project root: `git rev-parse --show-toplevel`

Write `.dispatch/prompts/<name>.md` (`mkdir -p .dispatch/prompts`):

```
Ticket: <TICKET-ID>
Status file: <project-root>/.dispatch/status/<name>.md
Branch: <branch>

## Task
<what to do AND why — enough architectural context for the runner to resolve ambiguity. If part of a larger effort, describe the end-state.>

## Discovery
<structured findings from step 3>

## Context
<user answers from step 4>

## Stop Conditions

You run unattended — you can't ask. If any of these hit, do NOT push through:

- Spec/ticket is fundamentally ambiguous and discovery didn't resolve it
- Same test failing 3+ times with different fixes (the architecture is probably wrong)
- Required dependency / resource is missing or inaccessible

On stop: commit WIP with `WIP: <one-line reason>`, update the status file with `status: blocked` and a paragraph explaining what you need, then exit. Faking progress wastes the operator's debugging time.
```

Branch: Linear issue's branch name if set, else `dispatch/<name>`.

### 6. Status File

Write `.dispatch/status/<name>.md` (`mkdir -p .dispatch/status`):

```markdown
# <name>

- **ticket**: <TICKET-ID>
- **title**: <issue title>
- **session_id**: pending
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

### 7. Spawn

```bash
bash ~/.claude/skills/dispatch/spawn.sh <name> <branch> <project-root> <project-root>/.dispatch/prompts/<name>.md
```

Output is key:value lines:
```
worktree_status:reused|created-existing-branch|created-new-branch
worktree:<path>
session_id:<id>
```

### 8. Update Status

Parse spawn.sh output. Update `session_id` in the status file.

Report: ticket ID, title, session ID, branch, worktree path, next commands (`/dispatch status <name>`, `claude attach <session-id>`, `claude logs <session-id>`).

---

## Sketch Flow (`/dispatch <sketch-name>`)

When argument matches `.dispatch/sketches/<name>.md`.

### 1. Read Sketch

Read the sketch file. Fail if not found: "No sketch '<name>'. Run `/sketch <name>` first."

### 2. Name + Prior Run Check

Name = sketch name. Check prior runs same as ticket flow.

### 3. Discover

Spawn Explore subagents from the sketch's What and Approach sections. Same as ticket flow.

### 4. Prompt File

Write `.dispatch/prompts/<name>.md`:

```
Sketch: <name>
Spec file: <project-root>/.dispatch/sketches/<name>.md
Status file: <project-root>/.dispatch/status/<name>.md
Branch: sketch-<name>

## Task
<sketch content — What + Why sections>

## Discovery
<structured findings from step 3>

## Stop Conditions

You run unattended — you can't ask. If any of these hit, do NOT push through:

- Sketch is fundamentally ambiguous and discovery didn't resolve it
- Same test failing 3+ times with different fixes (the architecture is probably wrong)
- Required dependency / resource is missing or inaccessible

On stop: commit WIP with `WIP: <one-line reason>`, update the status file with `status: blocked` and a paragraph explaining what you need, then exit. Faking progress wastes the operator's debugging time.
```

### 5. Status File

```markdown
# <name>

- **session_id**: pending
- **branch**: sketch-<name>
- **worktree**: <worktree-path>
- **status**: in_progress
- **started**: <ISO timestamp>
- **updated**: <ISO timestamp>

## Progress
Runner starting...

## Commits
(none yet)

## Notes
Dispatched from sketch.
```

### 6. Spawn + Update

Same as ticket flow steps 7-8.

---

## Find (`/dispatch <search-terms>`)

1. Linear MCP `list_issues` (same server selection as the ticket flow) with `query: <search-terms>`, limit 15.
2. Present top matches via `AskUserQuestion`: "Which ticket?" → up to 4 options (identifier + title), mention remaining count if more.
3. Selected → proceed to main flow.

No results → tell user, suggest refining query or providing ticket ID directly.

---

## `status [name]`

```bash
bash ~/.claude/skills/dispatch/status.sh <project-root> [name]
```

**With name** — output:
```
state:alive|dead|completed|failed
worktree:<path>
---
<full status file>
```

If `state:dead` → warn: "Runner exited without completing. Check `.dispatch/logs/<name>.log`. Re-dispatch with `/dispatch <ticket-id>`."

**Without name** — summary table. Display script output directly.

---

## Review feedback loop

When a runner's PR receives `/pr-review` feedback (inline comments + `reviewDecision: CHANGES_REQUESTED`):

1. Runner detects unresolved threads via `gh pr view <pr> --json reviews,reviewThreads`.
2. Apply `receiving-review` practice gates to each thread (already injected at SessionStart via `inject-practices.sh`).
3. Fix → commit → push. Don't resolve threads manually — the next `/pr-review` pass will approve and the reviewer's resolve closes them.
4. `/pr-review` watch loop detects the new commit and re-reviews automatically.

Cycle ends when `/pr-review` posts `APPROVE` (`reviewDecision: APPROVED`) and the runner's Stop hook lets it exit.

---

## Help (no arguments)

```
DISPATCH — Work → autonomous runner

Commands:
  /dispatch <ticket-id>            Fetch Linear ticket, discover, spawn runner
  /dispatch <sketch-name>          Read sketch spec, discover, spawn runner
  /dispatch <search-terms>         Search Linear, pick ticket, dispatch
  /dispatch status [name]          Check runner progress

Attach/inspect runners natively:
  claude agents                    TUI of all background sessions
  claude attach <session-id>       Attach to a runner (id in status file)

Workflows:
  Linear:  /dispatch ENG-142       — fetch, discover, spawn
  Sketch:  /sketch jwt-auth        — flesh out feature
           /dispatch jwt-auth      — read sketch, discover, spawn

Files:
  .dispatch/sketches/  — sketch specs (from /sketch)
  .dispatch/status/    — runner progress
  .dispatch/prompts/   — runner prompt files
```
