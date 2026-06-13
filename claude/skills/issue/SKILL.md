---
name: issue
description: Create a single Linear issue — correctly titled, pointed, milestoned, and labeled. The style-enforcement primitive that /spec composes. Use when capturing a bug, feature, or improvement as a well-formed Linear issue.
version: 1.0.0
argument-hint: "[subject]"
arguments: subject
allowed-tools: Read, Glob, Grep, Bash(git*), Bash(date*), Bash(open*), Bash(*/resolve-project.sh*), Bash(*/resolve-label.sh*), Bash(*/validate-title.sh*), AskUserQuestion, mcp__linear-work__*, mcp__linear-personal__*, mcp__linear-simpliruta__*
hooks:
  PostToolUse:
    - matcher: "mcp__.*__save_issue"
      hooks:
        - type: command
          command: "$HOME/.claude/hooks/validate-issue.sh"
          timeout: 10
---

# Issue

Every word earns its place. Direct, succinct, precise.

**Input:** `$subject` — short description of the work. Can include hints (e.g., `bug: dashboard 500s on empty state`). Empty → infer from conversation. No context at all → ask.

`/issue` = single issue with correct style. `/spec` = discovery + ZeeSpec + sub-issues (calls `/issue` internally).

## 1. Understand the Work

Extract from conversation + arguments: **what**, **why**, **type** (bug/feature/improvement). Ask via `AskUserQuestion` only if genuinely ambiguous.

## 2. Resolve Linear Placement

### Step 1: `resolve-project.sh` (required)

Run `~/.claude/scripts/resolve-project.sh` before any Linear API calls. Linear MCP servers are scoped per project, so use whichever Linear MCP server is available in the current session for all Linear calls. If more than one is connected, pick the one whose workspace matches the resolved team/project.

- Single project (`needs_confirmation: false`) → use directly
- Multiple projects (`needs_confirmation: true`) → ask which one
- Exit code 1 → ask for team/project, suggest adding to `repo-projects.json`

### Step 2: Remaining metadata

Determine **milestone**, **labels**, **priority**, **estimate** from:
1. `$subject` hints (e.g., `bug:` → Bug label)
2. Conversation context
3. CLAUDE.md defaults
4. Ask the user — last resort, ideally zero questions

### Step 3: Milestone

Fetch via the Linear MCP `list_milestones` tool. Assign if one fits, otherwise leave unmilestoned. Don't ask — the user can correct in Linear.

### Step 4: Label

Run `~/.claude/scripts/resolve-label.sh "$subject"`. Override if confidence is `"default"` and context strongly suggests otherwise.

### Step 5: Estimate

Fibonacci (1, 2, 3, 5, 8). Pick one based on complexity. Don't ask.

## 3. Write the Issue

### Title

Validate via `~/.claude/scripts/validate-title.sh "Title"`. Don't call `save_issue` with an invalid title.

Rules:
- **Concise noun phrase**, 2-7 words, **Title Case**
- **No verb prefixes** ("Add", "Fix", "Update", "Implement")
- **No ticket ID prefix** ("PER-83", "ABC-123") — Linear adds the identifier automatically
- **Area prefix with colon** when it adds clarity

Good: `Credential Expiry Tracker`, `Dashboard Nil Commission`, `MSAL SSO: Token Renewal Fallback`
Bad: `Add credential tracking feature`, `Fix the bug with notes`, `PER-83: Credential Tracker`

### Description

State the problem clearly enough to act on. Ceiling, not a floor — include what's needed, nothing more.

- No checklists (use sub-issues instead)
- No implementation details (that's for the PR)
- No boilerplate acceptance criteria (CI handles that)
- Sub-issues inherit parent context — keep them short

### Tone

Senior engineer to senior engineer. Personality fine, slop not.

## 4. Create

No confirmation. Linear MCP `save_issue`, then `open "$ISSUE_URL"`.

Report issue ID + URL. A `PostToolUse` hook (`validate-issue.sh`) auto-checks style on every `save_issue` call.
