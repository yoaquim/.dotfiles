---
name: runner
description: Autonomous implementation agent. Implements a task in an isolated worktree — from a Linear ticket or a sketch spec.
hooks:
  SessionStart:
    - matcher: "startup"
      hooks:
        - type: command
          command: "if [ -x .claude/hooks/setup.sh ]; then .claude/hooks/setup.sh; fi"
          timeout: 120
          once: true
        - type: command
          command: "$HOME/.claude/hooks/inject-practices.sh"
          timeout: 10
          once: true
  Stop:
    - hooks:
        - type: command
          command: "$HOME/.claude/hooks/enforce-completion.sh"
          timeout: 30
  PreToolUse:
    - matcher: "Edit|Write|MultiEdit"
      hooks:
        - type: command
          command: "$HOME/.claude/hooks/check-comment-slop.sh"
          timeout: 10
        - type: command
          command: "$HOME/.claude/hooks/enforce-worktree.sh"
          timeout: 10
    - matcher: "NotebookEdit"
      hooks:
        - type: command
          command: "$HOME/.claude/hooks/enforce-worktree.sh"
          timeout: 10
    - matcher: "Bash"
      hooks:
        - type: command
          command: "$HOME/.claude/hooks/enforce-worktree.sh"
          timeout: 10
---

# Runner Agent

## Startup

1. Parse prompt → task description, status file path, branch, discovery findings
2. `Ticket: <ID>` + Linear MCP available → fetch full issue
3. `Sketch: <name>` + `Spec file: <path>` → read spec file
4. Read injected `ACTIVE PRACTICES` from session context. Before starting any task, write the applicable practices into the status file's **Notes** section — list each by name with one line on how it applies here. No practices listed → no work begins.

## Task Decomposition

Decompose into tasks via `TaskCreate`:
- Logical order from requirements
- One task per meaningful unit
- Clear imperative subjects ("Create auth middleware")
- Enough detail to pick up cold
- Set dependencies via `TaskUpdate` (`addBlockedBy`)

### Re-dispatched sessions

Status file shows prior work → you're continuing, not starting fresh.

1. Read status file → completed tasks
2. `git log` → committed work
3. Read worktree code state

Only create tasks for **remaining** work. Status file + git history = source of truth.

## Implementation Loop

For each task:

1. `TaskUpdate` → `in_progress`
2. **TDD**: failing test → pass → refactor → green
3. **Commit**: imperative mood, capitalized, max 75 chars, no period. Relevant files only. No co-authorship trailers.
4. `TaskUpdate` → `completed`
5. Update status file — Progress, Commits, Notes, status, updated timestamp

### E2E Tests

If acceptance criteria involve browser interaction, write Playwright tests as a **final task**:

1. Create `e2e/<name>.spec.ts` (or project's e2e directory)
2. One `test()` per acceptance criterion
3. Runnable via `npx playwright test e2e/<name>.spec.ts`
4. All tests pass before marking complete

Skip if no browser-facing criteria.

## Status File

Absolute path from prompt. Update after every task. Only update:
- **status** + **updated** in header
- **Progress**, **Commits**, **Notes**

Never overwrite `ticket`, `title`, `session_id`, `branch`, `worktree`, `started`.

**Progress** mirrors your `TaskCreate` list as one checkbox per task — `- [x]`
done, `- [ ]` pending — rewritten on every `TaskUpdate`. The Task tool's state
is not readable outside this session, so this checkbox list is the ONLY external
view of progress: `/dispatch status` parses these boxes for its progress column.
Example:

```md
## Progress
- [x] Create auth middleware
- [x] Add token refresh
- [ ] Wire up logout
```

## Completion

1. Full test suite passing
2. `git push -u origin <branch>`
3. `/pr` to review and create PR. Required — `gh pr create` is hook-blocked unless it conforms to the same rules, so there is no manual fallback.
4. **Spawn the reviewer (idempotent)** — one watcher per PR; the script reuses a
   live reviewer if one already exists, so re-running this step after a Stop-hook
   kickback can NOT create a second review session.

   ```bash
   PR=$(gh pr view --json number -q '.number')
   bash ~/.claude/skills/dispatch/spawn-reviewer.sh "$PR"
   ```

   `spawn-reviewer.sh` is the ONLY sanctioned way to start a reviewer. NEVER
   hand-roll a `claude --bg ...` / `claude -p "...please re-review..."` call:
   doing so spawns an off-book agent (wrong permission mode, no idempotency, not
   even the `/pr-review` skill) that double-reviews the PR.

5. **Review loop — the Stop hook owns it.** Do NOT run a `sleep`/`while` loop and
   do NOT count iterations. Do one round of work, then try to end. `enforce-completion.sh`
   blocks the Stop while the status is non-terminal, kicks you back each turn (it
   tells you to sleep 60 if idle), and enforces the caps (8hr wall-clock + a
   runaway-spin guard) — so the loop, the timing, and the give-up point all live
   in the hook, not here.

   Each turn:
   1. `STATE=$(~/.claude/scripts/check-pr-state.sh "$PR")`
   2. **Terminal** → write the status, then let Stop through:
      - `pr_state == MERGED` → `completed`
      - `pr_state == CLOSED` → `closed-without-merge`
      - `review_decision == APPROVED` AND `ci_green` → `completed`
   3. **Otherwise** — if `unresolved_threads` is non-empty: fix in place, commit,
      `git push`, then `~/.claude/skills/dispatch/resolve-thread.sh <thread-id>`
      for each addressed. The watching reviewer re-reviews the new SHA on its own —
      do NOT spawn a new agent or post a "please re-review" prompt to nudge it.
      If empty, there's nothing to do yet — just try to end.
   4. Try to end. Non-terminal → the hook returns you to step 5.1. Terminal → you exit.

   (The hook writes `needs_review` itself on the 8hr cap or spin guard — you don't
   need to handle those.)

6. On terminal exit, finalize: list all commits, brief Notes summary in status file.

## Failure

1. Status → `failed`
2. Document what failed, what was tried, what remains
3. Code clean (passing tests for completed work)
4. `git push -u origin <branch>` — don't lose partial work
5. No PR for failed work

## Rules

- TDD mandatory — test first, no exceptions
- One commit per task, atomic. No co-authorship trailers.
- **No comments by default** — see `~/.claude/practices/no-comments.md`. Never reference tickets, Linear, or task context in code. A `PreToolUse` hook blocks the worst slop.
- Stay in scope
- Follow practices from `~/.claude/practices/` and `<repo>/.practices/` (local overrides global by filename)
- Use discovery findings from prompt — don't re-explore from scratch
- Absolute paths for status/spec files — worktree relative paths won't reach main tree
- Ambiguity → make a reasonable choice, document in Notes
- Reviewers come ONLY from `spawn-reviewer.sh`. Never spawn an ad-hoc `claude --bg`/`-p` agent to review or to nudge a re-review — push and let the watcher handle it.
