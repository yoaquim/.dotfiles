---
description: Dispatch Linear tickets to autonomous runners in isolated worktrees
argument-hint: <ticket-id|search-query|status|attach> [name]
allowed-tools: Read, Write, Edit, Glob, Grep, Bash(ls*), Bash(mkdir*), Bash(tmux*), Bash(date*), Bash(git*), Bash(*claude*--agent*--dangerously*), Bash(ps*), Bash(gh*), AskUserQuestion, Task, mcp__linear__*
---

# Dispatch

Parse first argument as subcommand. No arguments → show help.

```
/dispatch <ticket-id>              — fetch ticket, discover, spawn runner
/dispatch <search-terms>           — search Linear, pick ticket, then dispatch
/dispatch status [name]            — check runner progress
/dispatch attach <name>            — tmux window in runner's worktree
```

---

## Main Flow (`/dispatch <ticket-id>`)

Argument detection: if the argument matches a ticket ID pattern (letters + hyphen + digits, e.g. `ENG-142`, `PROJ-7`) → treat as ticket ID. Otherwise → treat as a search query (see `find` below).

### 1. Fetch

`mcp__linear__get_issue` with the ticket ID. Fail if not found or Linear MCP unavailable.

### 2. Name

Lowercase the ticket identifier (e.g. `ENG-142` → `eng-142`).

Check `.dispatch/status/<name>.md` for prior runs:
- Exists and `in_progress` with alive runner (PID + start time check) → stop: "Runner is still active. Use `/dispatch status <name>` or `/dispatch attach <name>`."
- Exists and `completed` or `failed` → ask via `AskUserQuestion`: "This ticket was previously dispatched (status: <status>). Re-dispatch?" → "Yes, re-dispatch" / "No, cancel"

### 3. Discover

Spawn Explore subagents informed by the issue title and description. Collect:
- Relevant file paths and patterns
- Test infrastructure (framework, config, test directories)
- Reference files (similar implementations, related modules)

Keep findings structured and concise — paths and patterns, not file contents.

### 4. Ask

`AskUserQuestion` for scope confirmation and approach preferences.

Adaptive:
- Detailed ticket with clear requirements → single confirmation: "Ready to dispatch with this scope?"
- Vague or broad ticket → more targeted questions: scope boundaries, approach preferences, ambiguities

### 5. Worktree

```bash
mkdir -p .dispatch/status .dispatch/logs
```

Branch: use Linear issue's branch name if set in the issue, else `dispatch/<name>`.

Get absolute project root: `git rev-parse --show-toplevel`

Create worktree (same logic as deck):
- Worktree exists at `.claude/worktrees/<name>` → reuse it
- Branch exists (`git rev-parse --verify <branch> 2>/dev/null`): `git worktree add .claude/worktrees/<name> <branch>`
- Branch doesn't exist: `git worktree add .claude/worktrees/<name> -b <branch>`
- If branch is checked out in another worktree → fail: "Branch '<branch>' is already checked out at <path>. Remove that worktree first."

### 6. Status File

Write `.dispatch/status/<name>.md`:

```markdown
# <name>

- **ticket**: <TICKET-ID>
- **title**: <issue title>
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

### 7. Spawn

```bash
cd <worktree-path> && nohup claude --agent linear-runner -p "<prompt>" --dangerously-skip-permissions > <project-root>/.dispatch/logs/<name>.log 2>&1 & echo $!
```

Prompt format:

```
Ticket: <TICKET-ID>
Status file: <absolute-path>/.dispatch/status/<name>.md
Branch: <branch>

## Discovery
<structured findings from step 3>

## Context
<user answers from step 4>
```

### 8. PID

Capture PID from command output. Get process start time: `ps -p <pid> -o lstart=`. Update status file's `pid` and `pid_start` fields.

Report: ticket ID, title, PID, branch, worktree path, next commands (`/dispatch status <name>`, `/dispatch attach <name>`).

---

## Find (`/dispatch <search-terms>`)

When the argument doesn't match a ticket ID pattern — treat it as a search query.

1. Search Linear via `mcp__linear__list_issues` with `query: <search-terms>`, limit to 15 results.
2. If results found → present via `AskUserQuestion` with top matches: "Which ticket?" → options showing identifier + title (up to 4 options; if more results, show top 4 and mention remaining count).
3. Once selected → proceed to the main flow above with that ticket ID.

If search returns nothing, tell the user and suggest refining their query or providing the ticket ID directly.

---

## `status [name]`

### Verifying runner alive

A runner is alive only if both conditions hold:
1. PID exists: `ps -p <pid> > /dev/null 2>&1`
2. Start time matches: `ps -p <pid> -o lstart=` equals stored `pid_start`

If PID exists but start time doesn't match → PID was recycled, runner is dead.

### With name

1. Read `.dispatch/status/<name>.md`
2. If status is `completed` or `failed` → display as-is, skip PID check
3. If status is `in_progress` → verify runner alive:
   - Alive → display as "running"
   - Dead → flag: "Runner exited without completing. Check `.dispatch/logs/<name>.log` for details."

### Without name

1. Read all `.dispatch/status/` files
2. For each with `in_progress`, verify runner alive (PID + start time)
3. Summary table:

```
DISPATCH STATUS

  eng-142       ● running      2/5    Fix auth token refresh
  eng-155       ✓ completed    4/4    Add user export endpoint
  eng-160       ✗ failed       1/3    Migrate to new billing API

Runners: 1 active, 1 completed, 1 failed
```

---

## `attach <name>`

1. Read `.dispatch/status/<name>.md` → get worktree path
2. No status file → fail: "No runner for '<name>'. Run `/dispatch <ticket-id>` first."
3. Verify worktree path exists on disk. If missing → fail: "Worktree not found at <path>."
4. If status is `in_progress` → verify runner alive. If alive → warn via `AskUserQuestion`: "Runner is still active. This opens a separate interactive session alongside it — changes may conflict. Proceed?" → "Yes" / "No"
5. `tmux new-window -n "dispatch-<name>" -c "<worktree-path>" "claude"`
6. Confirm: "Opened tmux window 'dispatch-<name>' in <worktree-path>"

---

## Help (no arguments)

```
DISPATCH — Linear ticket → autonomous runner

Commands:
  /dispatch <ticket-id>            Fetch ticket, discover, spawn runner
  /dispatch <search-terms>         Search Linear, pick ticket, dispatch
  /dispatch status [name]          Check runner progress
  /dispatch attach <name>          tmux window in runner's worktree

Workflow:
  1. /dispatch ENG-142              — fetch, discover, confirm, spawn
  2. /dispatch status               — check all runners
  3. /dispatch attach eng-142       — interactive session in worktree
  4. Runner pushes + updates Linear on completion

Files:
  .dispatch/status/   — runner progress
  .dispatch/logs/     — runner output logs
```
