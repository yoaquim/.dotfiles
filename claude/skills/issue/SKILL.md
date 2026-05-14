---
name: issue
description: Create a single Linear issue — correctly titled, pointed, milestoned, and labeled. The style-enforcement primitive that /spec composes. Use when capturing a bug, feature, or improvement as a well-formed Linear issue.
version: 1.0.0
argument-hint: "[subject]"
arguments: subject
allowed-tools: Read, Glob, Grep, Bash(git*), Bash(date*), Bash(open*), Bash(*/resolve-project.sh*), Bash(*/resolve-label.sh*), Bash(*/validate-title.sh*), AskUserQuestion, mcp__claude_ai_Linear__list_projects, mcp__claude_ai_Linear__list_milestones, mcp__claude_ai_Linear__list_issue_labels, mcp__claude_ai_Linear__list_issue_statuses, mcp__claude_ai_Linear__list_teams, mcp__claude_ai_Linear__list_issues, mcp__claude_ai_Linear__save_issue, mcp__claude_ai_Linear__get_project, mcp__claude_ai_Linear__get_issue
---

# Issue

Every word earns its place. Be direct, succinct, and precise in all output — the issue, the confirmation, and any questions.

Create a single, well-formed Linear issue. One piece of work, captured in the right style.

**Input:** `$subject` is the issue subject — a short description of the work. Can include metadata hints like project or type (e.g., `SES bounce handling for Pulse`, `bug: dashboard 500s on empty state`). When `$subject` is empty, infer everything from conversation context. When there is no conversation context and no subject, ask what the issue is about.

## /issue vs /spec

`/issue` enforces style on a single Linear issue — title, description, labels, milestone, estimate. That's it. No sub-issues, no spec documents, no codebase exploration.

`/spec` orchestrates discovery, writes structured specs using ZeeSpec, and calls `/issue` to create each ticket it needs. If the work needs exploration or multi-stream breakdown, use `/spec`.

## 1. Understand the Work

Read the conversation and arguments. Extract: **what** (the work), **why** (motivation), **type** (bug, feature, improvement).

Ask via `AskUserQuestion` only if the subject is genuinely ambiguous. Don't re-interview — the user came here to capture, not to brainstorm.

## 2. Resolve Linear Placement

### Step 1: Run `resolve-project.sh` (required)

Run `~/.claude/scripts/resolve-project.sh` before any Linear API calls. This script reads the current git remote, looks up `repo-projects.json`, and returns the team and project(s) deterministically.

- **Single project returned** (`needs_confirmation: false`): use it directly.
- **Multiple projects returned** (`needs_confirmation: true`): present the list and ask the user which one.
- **Exit code 1** (no mapping): ask the user for the team and project. Suggest they add the repo to `~/.claude/scripts/repo-projects.json`.

### Step 2: Resolve remaining metadata

With team and project resolved, determine **milestone**, **labels**, **priority**, **estimate** from:

1. **`$subject` hints** — e.g., `bug:` prefix -> Bug label
2. **Conversation context** — if the user mentioned a milestone or priority, use it
3. **CLAUDE.md defaults** — e.g., `Linear project: <name>`
4. **Ask the user** — absolute last resort, ideally zero questions. Only ask if the issue literally cannot be created without the answer.

### Step 3: Validate milestone

Fetch milestones via `mcp__claude_ai_Linear__list_milestones`. Then:

1. If a milestone fits the work, assign it.
2. If milestones exist but none fit, leave unmilestoned.
3. If the project has zero milestones, leave unmilestoned.

Do not ask the user to pick a milestone. Make the call — the user can correct in Linear.

### Step 4: Label

Run `~/.claude/scripts/resolve-label.sh "$subject"` to deterministically resolve the label from the subject text. If confidence is `"default"` and conversation context strongly suggests a different label, override. Otherwise use the script's output.

### Step 5: Estimate

Assign a fibonacci estimate (1, 2, 3, 5, 8) based on apparent complexity. Just pick one — don't ask. The user can adjust in Linear if they disagree.

## 3. Write the Issue

### Title

Write the title, then validate it by running `~/.claude/scripts/validate-title.sh "Your Title Here"`. If it fails, fix the title and re-validate. Do not call `save_issue` with an invalid title.

Rules (enforced by the script):
- **Concise noun phrase**, 2-7 words
- **Title Case** (capitalize major words)
- **No verb prefixes** — don't start with "Add", "Fix", "Update", "Implement"
- **Area prefix with colon** when it adds clarity (e.g., `MSAL SSO: Token Renewal Fallback`, `Trends: Percentage Cap`)

Good: `Credential Expiry Tracker`, `Note API Endpoint`, `Dashboard Nil Commission`, `SES Mailer Regression`
Bad: `Add credential tracking feature`, `Fix the bug with notes`, `Update API endpoints for notes`

### Description

State the problem or feature clearly enough that an engineer or AI agent can act on it. No two tickets are the same — some need one sentence, some need a paragraph with context. The rule is a **ceiling, not a floor**: include what's needed, nothing more.

- No checklists — if items are worth tracking, they're worth being sub-issues.
- No implementation details (class names, file paths, code) — that's for the implementing agent/PR, not the ticket.
- No boilerplate acceptance criteria like "all tests pass" — CI handles that.
- Parent/master issues carry the spec weight. Sub-issues inherit that context and should be short.

Examples of good descriptions:
- _"Make sure the exec can't change priority."_
- _"The chatbox on /deals/agent is too small and users can't see the text they are typing."_
- _"Gantt chart timescale option: default 3 months, offer 6 months, or all year."_
- _"Users authenticated via Entra SSO hit a timed_out error when returning after inactivity. Only workaround is closing the entire browser."_
- _"Trend indicators display percentage changes in the thousands (e.g. +3,400%). Cap at +/-200% and fall back to absolute delta."_

### Tone

Write like a senior engineer talking to another senior engineer. Direct, no filler. Personality is fine — slop is not.

## 4. Create

No confirmation step. Create the issue via `mcp__claude_ai_Linear__save_issue`, then open it:

```bash
open "$ISSUE_URL"
```

Report the issue ID and URL. The user can correct anything directly in Linear — it's faster than a chat round-trip.

A `PostToolUse` hook (`validate-issue.sh`) automatically checks the created issue for style violations and surfaces warnings. No action needed — it runs on every `save_issue` call.
