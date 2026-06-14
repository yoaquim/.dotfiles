---
name: spec
description: Formalize conversations into Linear feature specs with implementation sub-issues. Use after discussing a problem and solution to capture it as a structured Linear ticket with sub-issues ready for /dispatch.
version: 2.0.0
allowed-tools: Read, Write, Edit, Glob, Grep, Bash(ls*), Bash(mkdir*), Bash(date*), Bash(git*), Bash(*/resolve-project.sh*), AskUserQuestion, Task, EnterPlanMode, ExitPlanMode, mcp__linear-work__*, mcp__linear-personal__*, mcp__linear-simpliruta__*, mcp__linear-mesa__*, mcp__linear-nullbreaker__*, mcp__linear-parchamusic__*
hooks:
  PostToolUse:
    - matcher: "mcp__.*__save_issue"
      hooks:
        - type: command
          command: "$HOME/.claude/hooks/validate-issue.sh"
          timeout: 10
    - matcher: "Write|Edit"
      hooks:
        - type: command
          command: "$HOME/.claude/hooks/lint-spec.sh"
          timeout: 10
---

# Spec

Arguments are optional hints (project name, area, context). No arguments → use conversation context.

## 1. Synthesize

Review the conversation. Extract: **problem** (what/why), **solution direction**, **requirements**, **constraints**, **open questions**. Ask via `AskUserQuestion` only if gaps would block a clear spec.

## 2. Linear Constraints

Run `~/.claude/scripts/resolve-project.sh` to resolve team and project. Then determine milestone, labels (`Feature` required), priority (default Normal), estimate (sum of sub-issues).

Single confirmation: "Creating in [Team] / [Project] / [Milestone], labeled [labels], [X] points. Correct?"

## 3. Codebase Discovery

**Repos:** Use `~/.claude/scripts/repo-projects.json` as the registry of known repos. Include current dir if git repo.

**Explore:** Subagents per repo. Collect paths, test infra, reference files — not contents.

**Practices:** Read `~/.claude/practices/INDEX.md` per repo. Check detect rules, read matched practices.

## 4. Feature Spec (ZeeSpec)

**Skip the spec doc** if <=2 sub-issues and narrow scope. Write description inline on the master ticket, skip to step 5.

Otherwise, delegate to an isolated subagent using **ZeeSpec methodology**. Pass synthesized context from step 1.

### ZeeSpec Methodology

Six dimensions from 5W1H. Each forces explicit decisions — unanswered questions are gaps the implementer will guess at. Goal: **zero ambiguity**.

Principle: **"If you can't answer it, your system is undefined."**

#### WHAT (Data & Entities)
Core entities, valid states, allowed/forbidden transitions, required/optional fields, invariants, boundary values.

> *Loan: status `ACTIVE|OVERDUE|CANCELLED|RETURNED`. Can only cancel if no outstanding fees. Cancellation updates status, never deletes. Fields: `id`, `member_id`, `book_id`, `status`, `due_date`, `cancelled_at` (nullable).*

#### WHERE (Scope & Boundaries)
Affected services/layers, system boundaries, external integrations, explicit out-of-scope.

> *Affects Loans API + notification service. Fee checks read from fees table only — no payment gateway. Out of scope: bulk cancellation, admin override.*

#### WHEN (Timing & Sequencing)
Triggers, operation sequence, time windows/SLAs, timeout behavior, concurrency rules.

> *POST `/api/loans/:id/cancel`. Validate fees → set CANCELLED → audit log → notify. Fee check >3s → 503. Optimistic locking on loan status.*

#### WHO (Access & Permissions)
Roles, permissions per action, ownership rules, service auth, audit requirements.

> *Loan owner or `library_staff` role. Requires `loans:write` scope. All cancellations audit-logged with actor, timestamp, reason.*

#### WHY (Business Rules & Constraints)
Business problem, regulatory constraints, business rules overriding technical convenience, success metrics.

> *Saves ~200 calls/month. Financial records retained 7 years — cancel updates, never deletes. Target: 80% self-service within 3 months.*

#### HOW (Procedures & Workflows)
Happy path steps, error handling, rollback, monitoring, migration/deployment.

> *Cancel: (1) check fees, (2) set CANCELLED, (3) set `cancelled_at`, (4) audit log, (5) enqueue notification. Fee-check fail → 422 with details. DB fail → retry once, then 500.*

### Writing the Spec

The subagent:

1. Writes each dimension as a section with concrete entries — every entry a decision, not a description
2. Drops dimensions with <2 meaningful entries
3. Picks icon and color for the Linear document
4. Returns spec content, icon, color

Principles: **codeless** (no class names/file paths), **decision-forcing**, **succinct**, **plain English**.

### Creating the Spec

Create master issue via `/issue`, then spec doc via the Linear MCP `save_document` tool (same server as the issue) with `issue` set to the master issue identifier.

## 5. Implementation Plan

Break into ordered sub-issues under master ticket, each designed for autonomous `/dispatch`.

Create via `/issue` with `parentId`. This skill only defines ordering, parent linkage, and blocking relationships.

Max 8 issues per phase. Exceeds 8 → split.

### Sub-Issue Description

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

### Practices in Sub-Issues

Lists which practices from `~/.claude/practices/` apply and why. The runner's `inject-practices.sh` injects full practice files at startup — this listing directs attention to the most relevant ones. Only list genuinely relevant practices.

### Sub-Issue Qualities

- **Small** — single `/dispatch` session
- **Independent** — no blocking where possible
- **Ordered** — sequenced when it matters
- **Dispatch-ready** — no clarification needed

Confirm via `AskUserQuestion`: ordered list with titles, scope, points.

## 6. Create in Linear

Create: master issue → spec document (attached) → sub-issues in order (set parent + blocking).

Report: master ticket ID + URL, sub-issue count, total points, next step (`/dispatch <ticket-id>`).

## 7. Discovery Capture (Optional)

Offer via `AskUserQuestion`: "The conversation that led to this spec was discovery work. Capture as a completed ticket?"

If yes, create via `/issue`:
- Subject: "Discovery: [topic summary]"
- Label: `Discovery`, Status: `Done`
- Same project/milestone as feature spec
- Description: what was explored, key findings, decisions
- Link to spec doc or master issue
- Estimate: 1-2 points

---

## Help (no arguments)

```
SPEC — Conversation -> Linear feature spec (ZeeSpec)

Usage:
  /spec [context]              Formalize conversation into Linear feature spec
  /spec add to ProjectName     Spec into a specific Linear project

Workflow:
  1. Discuss problem + solution with Claude
  2. /spec                     — capture as feature spec + sub-issues
  3. /dispatch ENG-142         — runner picks up each sub-issue

What it creates:
  - Spec document (ZeeSpec: What/Where/When/Who/Why/How dimensions)
  - Master ticket (feature spec) in Linear
  - Sub-issues (implementation plan) ready for /dispatch
  - Optional: Discovery ticket for the conversation itself

Repos:
  ~/.claude/scripts/repo-projects.json — repo registry (placement + discovery)
```
