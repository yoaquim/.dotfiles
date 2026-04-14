---
name: spec
description: Formalize conversations into Linear feature specs with implementation sub-issues. Use after discussing a problem and solution to capture it as a structured Linear ticket with sub-issues ready for /dispatch.
argument-hint: [context/project hints]
allowed-tools: Read, Write, Edit, Glob, Grep, Bash(ls*), Bash(mkdir*), Bash(date*), Bash(git*), AskUserQuestion, Task, EnterPlanMode, ExitPlanMode, mcp__claude_ai_Linear__*
---

# Spec

Formalize the current conversation into a Linear feature spec with implementation sub-issues. The conversation has already explored the problem and solution — this skill captures and structures it.

No arguments → show help.

## Main Flow (`/spec [context]`)

Arguments are hints — project name, area, or additional context. Not required.

### 1. Synthesize

Review the conversation so far. Extract:

- **Problem**: What are we solving and why?
- **Solution direction**: What approach was discussed?
- **Requirements**: What must be true when done?
- **Constraints**: Technical, business, timeline?
- **Open questions**: Anything unresolved?

If there are gaps or ambiguities that would block writing a clear spec, ask via `AskUserQuestion`. Keep it targeted — the conversation already happened, don't re-interview.

### 2. Linear Constraints

Determine where this lives in Linear:

- **Team**: Which Linear team?
- **Project**: Check arguments first, then CLAUDE.md for defaults, then conversation context. Confident → confirm. Unsure → ask.
- **Milestone**: Infer from project context. Ambiguous → ask.
- **Labels**: `Feature` required. Add area/domain labels as appropriate.
- **Priority**: Infer from conversation urgency. Default to "Normal" if unclear.
- **Estimate**: Point estimate for the master ticket (sum of expected sub-issue effort).

Use `mcp__claude_ai_Linear__list_projects`, `mcp__claude_ai_Linear__list_milestones`, `mcp__claude_ai_Linear__list_issue_labels` to validate choices exist in Linear.

Confirm via `AskUserQuestion` in a single summary: "Creating in [Team] / [Project] / [Milestone], labeled [labels], [X] points. Correct?"

### 3. Codebase Discovery

Explore relevant codebases to inform the implementation plan.

#### Repo Registry

Maintain `~/.claude/skills/spec/repos.md` — a registry of known repo paths and their purpose. On every run:

1. If current directory is a git repo → include it automatically
2. Read `repos.md` for known repos
3. Ask via `AskUserQuestion`: "Which repos should I explore?" — list known repos as options, include "add new repo" option
4. Update `repos.md` with any new repos added

#### Exploration

Spawn Explore subagents (one per repo) informed by the synthesized requirements. Collect:

- Relevant file paths and patterns
- Existing implementations to build on or integrate with
- Test infrastructure (framework, config, test directories)
- Reference files (similar features, related modules)

Keep findings structured and concise — paths and patterns, not file contents.

#### Practices

During exploration, read `~/.claude/practices/INDEX.md` for each target repo. Identify which practices apply by checking the detect rules against the repo's files. Read the matched practice files — these inform the implementation plan design.

### 4. Feature Spec

**Skip the spec doc** if the feature is small enough to be fully described by the master ticket alone (≤2 sub-issues, narrow scope, no constraints worth documenting). In that case, write the description inline on the master ticket and skip to step 5.

#### Spec Document

Create via `mcp__claude_ai_Linear__create_document`:

```markdown
## Problem
What user/business problem are we solving?

## Outcome
What changes when this is shipped?

## Scope
What's in / what's out.

## Acceptance Criteria
- Concrete, verifiable assertions
- Written so an agent or engineer can test them unambiguously

## Constraints
Technical, business, performance, security.

## Notes
Dependencies, links, edge cases, decisions made during discovery.
```

Spec-writing principles:

- **Codeless** — zero implementation details. That's the sub-issues' job.
- **Testable** — acceptance criteria as concrete, verifiable assertions.
- **Succinct** — value-dense, no filler. Enough context to understand without a meeting.

Confirm spec content via `AskUserQuestion` before creating in Linear.

#### Master Issue

Create via `mcp__claude_ai_Linear__save_issue`:

- **Title**: 3-5 words, Title Case, no verbs, no marker suffixes (no `(spec)`, `[Feature]`, etc.) — labels handle classification
- **Description**: One-line summary linking to the spec document (or inline content if spec was skipped)
- Set team, project, milestone, labels, priority, estimate from step 2
- Attach the spec document to the issue (if created)

### 5. Implementation Plan

Design sub-issues under the master ticket. Each sub-issue is picked up by `/dispatch` for autonomous execution.

#### Design Sub-Issues

Informed by codebase discovery + practices:

1. Break the feature into ordered, independently-shippable steps
2. Each step = one sub-issue
3. Sequence when order matters — use Linear blocking relationships for dependencies

#### Sub-Issue Structure

Create each via `mcp__claude_ai_Linear__save_issue` as child of the master issue:

- **Title**: 3-5 words, Title Case, no verbs, no marker suffixes
- **Description**:

```markdown
## Goal
What this step accomplishes (delta from parent spec).

## Scope
What's in / out for this specific step.

## Acceptance Criteria
- Testable assertions for this step

## Testing Criteria
- Tests to add, update, or remove
- Brief reason for each

## Context
- Parent spec reference
- Relevant code paths (from discovery)
- Dependencies on prior steps

## Practices
- <practice-name>: <one-line why it applies to this step>
```

- Set: same team / project / milestone as parent
- Label: `Feature`
- Estimate: points for this sub-issue
- Set blocking relationships where order matters

#### Practices in Sub-Issues

The `## Practices` section lists which practices from `~/.claude/practices/` apply to this specific sub-issue and why. This is directed guidance — the runner's `inject-practices.sh` hook will inject the full practice files deterministically at startup, but the sub-issue listing tells the runner which practices are most relevant to *this* task.

Only list practices that are genuinely relevant to the sub-issue's work. A database migration sub-issue doesn't need the React practice listed even if the project has React.

#### Sub-Issue Qualities

- **Small** — completable in a single `/dispatch` session
- **Independent** — no waiting on other sub-issues where possible
- **Ordered** — sequenced when order matters
- **Dispatch-ready** — enough detail for an agent to implement without clarification

#### Scope Check

Before creating:

- **8+ sub-issues** → surface to user: "This is a large feature. Consider splitting into phases."
- **Sub-issue too broad** (touching 5+ files, multiple concerns) → suggest splitting further

Confirm the full plan via `AskUserQuestion`: show the ordered list of sub-issues with titles, brief scope, and estimated points.

### 6. Create in Linear

After confirmation, create everything:

1. Create the spec document (if not skipped)
2. Create the master issue, attach the document (if created)
3. Create sub-issues in order, setting parent and blocking relationships

Report: master ticket ID + URL, sub-issue count, total points, next step (`/dispatch <ticket-id>` for each sub-issue).

### 7. Discovery Capture (Optional)

After creating the feature spec, offer via `AskUserQuestion`:

"The conversation that led to this spec was itself discovery work. Want to capture it as a completed ticket?"

If yes:
- Create issue via `mcp__claude_ai_Linear__save_issue`:
  - Title: "Discovery: [topic summary]"
  - Label: `Discovery`
  - Status: set to `Done`
  - Same project / milestone as the feature spec
  - Description: concise summary of what was explored, key findings, decisions reached
  - Link to the spec document if one was created; otherwise link to the master issue
  - Estimate: 1-2 points

If no → skip.

---

## Help (no arguments)

```
SPEC — Conversation -> Linear feature spec

Usage:
  /spec [context]              Formalize conversation into Linear feature spec
  /spec add to ProjectName     Spec into a specific Linear project

Workflow:
  1. Discuss problem + solution with Claude
  2. /spec                     — capture as feature spec + sub-issues
  3. /dispatch ENG-142         — runner picks up each sub-issue

What it creates:
  - Spec document (attached to master ticket)
  - Master ticket (feature spec) in Linear
  - Sub-issues (implementation plan) ready for /dispatch
  - Optional: Discovery ticket for the conversation itself

Repos:
  ~/.claude/skills/spec/repos.md — known repo registry (auto-maintained)
```

---

## Examples

`/spec` → synthesizes conversation, confirms Linear project, explores codebase, creates feature spec with sub-issues.

`/spec add to Auth Rewrite` → same flow, targets the "Auth Rewrite" Linear project.

---

## Troubleshooting

**Linear MCP unavailable**: Verify `mcp__claude_ai_Linear__*` tools are connected.

**"Which project?"**: Set default in your project's CLAUDE.md: `Linear project: <project-name>`.

**Repos not found**: Add them when prompted during discovery, or edit `~/.claude/skills/spec/repos.md` directly.
