---
name: dispatch
description: Dispatch work to autonomous runners in isolated worktrees. Accepts Linear tickets or sketch specs. Use when assigning work to background Claude runners or checking runner status.
argument-hint: <ticket-id|sketch-name|search-query|status> [name] [--repo <name|path>] [--model <model>]
allowed-tools: Read, Write, Edit, Glob, Grep, Bash(ls*), Bash(mkdir*), Bash(date*), Bash(git*), Bash(*dispatch/spawn.sh*), Bash(*dispatch/status.sh*), Bash(*dispatch/resolve-repo.sh*), AskUserQuestion, Task, EnterPlanMode, ExitPlanMode, mcp__linear-work__*, mcp__linear-personal__*, mcp__linear-simpliruta__*, mcp__linear-mesa__*, mcp__linear-nullbreaker__*, mcp__linear-parchamusic__*, mcp__linear-lul__*, mcp__linear-rimas__*
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

## Target repo (`--repo`, optional)

By default the runner works in the **current** repo. If `--repo <name|path>` is in
`$ARGUMENTS`, strip it first and resolve the target:

```bash
TARGET_ROOT=$(bash ~/.claude/skills/dispatch/resolve-repo.sh "<value>") || { echo "$TARGET_ROOT"; exit 1; }
```

Otherwise `TARGET_ROOT=$(git rev-parse --show-toplevel)`.

`TARGET_ROOT` is the project root for everything below — prompt, status file,
worktree, and the `spawn.sh` call all use it; the runner runs in that repo. When
the target maps to a different Linear workspace (see `~/.claude/scripts/repo-projects.json`),
fetch the ticket from that workspace's MCP. `/dispatch status` finds the runner when
the target is the current repo or a sibling under the same parent.

## Model (`--model`, optional)

By default the runner inherits the CLI default model (`~/.claude.json`) —
`ANTHROPIC_MODEL` does NOT propagate to a `--bg` daemon's worker. If
`--model <model>` is in the arguments (e.g. `opus`, `sonnet`, `claude-opus-4-8`),
strip it first, then:

- Prefix the spawn call with the env var: `DISPATCH_MODEL=<model> bash ~/.claude/skills/dispatch/spawn.sh ...`
- Record it in the status file header as `- **model**: <model>` (omit the line when not set).

Note: the global default model is pinned to the 1M-context variant
(`claude-fable-5[1m]`), which long-running review loops pay for on every poll.
For routine tickets that don't need a huge context, `--model claude-fable-5`
(standard context) is the cheaper choice.

## Argument Detection

1. `status` → subcommand
2. Ticket ID pattern (letters + hyphen + digits, e.g. `ENG-142`) → Linear ticket flow
3. Matches `.dispatch/sketches/<arg>.md` → sketch flow
4. Otherwise → Linear search query

### 1. Fetch

Fetch via the Linear MCP `get_issue` tool. Linear MCP servers are scoped per project — use whichever is available in the current session; if more than one, pick the workspace matching the repo. Fail if not found.

### 2. Name

Lowercase the ticket identifier (`ENG-142` → `eng-142`).

Check prior runs: `bash ~/.claude/skills/dispatch/status.sh <project-root> <name>`. Parse `state:`:
- `alive` → stop: "Runner still active. Use `/dispatch status <name>` or `claude attach <session-id>`."
- `dead` → the runner **halted mid-loop** (status `in_progress`, no live session — machine sleep, crash, etc.). Do NOT re-discover or rewrite the prompt; **resume in place** so it continues from its status file + git. Read `branch` from the status file, then:
  ```bash
  bash ~/.claude/skills/dispatch/spawn.sh <name> <branch> <project-root> <project-root>/.dispatch/prompts/<name>.md
  ```
  Update `session_id` in the status file from spawn.sh output. (The watchdog LaunchAgent — installed by `claude/setup.sh` — does exactly this automatically every ~10 min for fresh halts; this is the on-demand path.)
- `completed` or `failed` → ask: "Previously dispatched (status: <status>). Re-dispatch?" → "Yes" / "No"
- No status file → proceed

### 3. Discover

Spawn Explore subagents from the issue title/description. Collect relevant paths, test infra, reference files. Paths and patterns, not contents.

### 4. Ask

Ask via `AskUserQuestion` — adaptive:
- Clear ticket → single confirmation: "Ready to dispatch with this scope?"
- Vague ticket → targeted questions on scope, approach, ambiguities

### 5. Prompt File

Project root = `TARGET_ROOT` (the current repo unless `--repo` was given; see Target repo above).

Write `<TARGET_ROOT>/.dispatch/prompts/<name>.md` (`mkdir -p`):

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

Write `<TARGET_ROOT>/.dispatch/status/<name>.md` (`mkdir -p`):

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
state:alive|dead|completed|failed|blocked|needs_review
worktree:<path>
---
<full status file>
```

If `state:dead` → warn: "Runner exited without completing. Check `claude logs <session_id>` (id from the status file). Re-dispatch with `/dispatch <ticket-id>`."
If `state:blocked` → the runner deliberately stopped for a human decision: surface the status file's Notes section and ask the operator how to proceed (the watchdog never auto-resumes `blocked`).
If `state:needs_review` → the runner hit its loop cap/timeout with the PR unmerged: link the PR and suggest taking over or re-dispatching.

**Without name** — summary table. Display script output directly.

---

## Review feedback loop

When a runner's PR receives `/pr-review` feedback (inline comments + `reviewDecision: CHANGES_REQUESTED`):

1. Runner detects unresolved threads via `gh pr view <pr> --json reviews,reviewThreads`.
2. Apply `receiving-review` practice gates to each thread (already injected at SessionStart via `inject-practices.sh`).
3. Fix → commit → push → resolve each addressed thread with `~/.claude/skills/dispatch/resolve-thread.sh <thread-id>` (the reviewer never resolves threads — runner.md "Completion" owns this).
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

Flags:
  --repo <name|path>               Dispatch into another repo (name resolved under
                                   ~/Projects, or an explicit path). Default: current repo.
  --model <model>                  Model for this runner (opus, sonnet, full id).
                                   Default: the CLI default in ~/.claude.json.

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
