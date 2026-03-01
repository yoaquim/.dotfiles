---
description: Dispatch Linear tickets to autonomous runners in isolated worktrees
argument-hint: <ticket-id|search-query|status|attach> [name]
allowed-tools: Read, Write, Edit, Glob, Grep, Bash(mkdir*), Bash(date*), Bash(git*), Bash(*dispatch/spawn.sh*), Bash(*dispatch/status.sh*), Bash(*dispatch/attach.sh*), AskUserQuestion, Task, mcp__linear__*
---

# Dispatch

Parse first argument as subcommand. No arguments → show help.

Scripts live alongside this file at `~/.claude/skills/dispatch/`. Use them — do not construct raw bash commands for spawn, status checks, or attach.

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

Check for prior runs: `bash ~/.claude/skills/dispatch/status.sh <project-root> <name>`. Parse the `state:` line:
- `state:alive` → stop: "Runner is still active. Use `/dispatch status <name>` or `/dispatch attach <name>`."
- `state:completed` or `state:failed` → ask via `AskUserQuestion`: "This ticket was previously dispatched (status: <status>). Re-dispatch?" → "Yes, re-dispatch" / "No, cancel"
- No status file → proceed (fresh dispatch)

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

### 5. Prompt File

Get absolute project root: `git rev-parse --show-toplevel`

Write prompt to `.dispatch/prompts/<name>.md` (use `mkdir -p .dispatch/prompts` first):

```
Ticket: <TICKET-ID>
Status file: <project-root>/.dispatch/status/<name>.md
Branch: <branch>

## Discovery
<structured findings from step 3>

## Context
<user answers from step 4>
```

Branch: use Linear issue's branch name if set, else `dispatch/<name>`.

### 6. Status File

Write `.dispatch/status/<name>.md` (use `mkdir -p .dispatch/status` first):

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
bash ~/.claude/skills/dispatch/spawn.sh <name> <branch> <project-root> <project-root>/.dispatch/prompts/<name>.md
```

The script handles: worktree creation (reuse/existing-branch/new-branch), runner spawn with `--dangerously-skip-permissions`, PID capture. Output is key:value lines:

```
worktree_status:reused|created-existing-branch|created-new-branch
worktree:<path>
pid:<number>
pid_start:<lstart string>
```

### 8. Update Status

Parse spawn.sh output. Update the status file's `pid` and `pid_start` fields with the values from the script output.

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

Run the status script:

```bash
bash ~/.claude/skills/dispatch/status.sh <project-root> [name]
```

**With name** — output has a structured header then the full status file:
```
state:alive|dead|completed|failed
worktree:<path>
---
<full status file>
```

If `state:dead` → warn: "Runner exited without completing. Check `.dispatch/logs/<name>.log` for details."

**Without name** — formatted summary table:
```
DISPATCH STATUS

  eng-142          ● running      2/5    Fix auth token refresh
  eng-155          ✓ completed    4/4    Add user export endpoint
  eng-160          ✗ failed       1/3    Migrate to new billing API

Runners: 1 active, 1 completed, 1 failed
```

Display the script output directly.

---

## `attach <name>`

1. Run `bash ~/.claude/skills/dispatch/status.sh <project-root> <name>` → parse `state:` and `worktree:` from output. The script searches sibling repos if the status file isn't found locally, so attach works even when invoked from a different repo than where the runner was dispatched.
2. No status file → fail: "No runner for '<name>'. Run `/dispatch <ticket-id>` first."
3. If `state:alive` → warn via `AskUserQuestion`: "Runner is still active. This opens a separate interactive session alongside it — changes may conflict. Proceed?" → "Yes" / "No"
4. Run: `bash ~/.claude/skills/dispatch/attach.sh <name> <worktree-path>` — the worktree path from the status file is absolute, so tmux opens in the correct directory regardless of which repo you're in.
5. Confirm: "Opened tmux window 'dispatch-<name>' in <worktree-path>"

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
  .dispatch/prompts/  — runner prompt files
```
