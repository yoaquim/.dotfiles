---
name: spec
description: Formalize conversations into Linear feature specs with implementation sub-issues. Use after discussing a problem and solution to capture it as a structured Linear ticket with sub-issues ready for /dispatch.
version: 2.0.0
allowed-tools: Read, Write, Edit, Glob, Grep, Bash(ls*), Bash(mkdir*), Bash(date*), Bash(git*), Bash(*/resolve-project.sh*), AskUserQuestion, Task, EnterPlanMode, ExitPlanMode, mcp__claude_ai_Linear__*
---

# Spec

Formalize the current conversation into a Linear feature spec with implementation sub-issues. The conversation has already explored the problem and solution — this skill captures and structures it.

Arguments are optional hints (project name, area, context). No arguments -> use conversation context.

## 1. Synthesize

Review the conversation. Extract: **problem** (what/why), **solution direction**, **requirements**, **constraints**, **open questions**. Ask via `AskUserQuestion` only if gaps would block writing a clear spec — don't re-interview.

## 2. Linear Constraints

Run `~/.claude/scripts/resolve-project.sh` to resolve team and project deterministically. Then determine milestone, labels (`Feature` required), priority (default Normal), and estimate (sum of sub-issues).

Single `AskUserQuestion` confirmation: "Creating in [Team] / [Project] / [Milestone], labeled [labels], [X] points. Correct?"

## 3. Codebase Discovery

**Repos:** Use `~/.claude/skills/spec/repos.md` as the registry of known repos. Include current dir if git repo.

**Explore:** Spawn Explore subagents per repo. Collect relevant paths, test infra, reference files. Concise — paths and patterns, not contents.

**Practices:** Read `~/.claude/practices/INDEX.md` per repo. Check detect rules, read matched practice files to inform the implementation plan.

## 4. Feature Spec (ZeeSpec)

**Skip the spec doc** if the feature is small enough to be fully described by the master ticket alone (<=2 sub-issues, narrow scope). Write the description inline on the master ticket and skip to step 5.

Otherwise, delegate spec writing to an isolated subagent. The subagent uses the **ZeeSpec methodology** to structure the document. Pass it the synthesized context from step 1.

### ZeeSpec Methodology

ZeeSpec structures specs around **6 dimensions** derived from the 5W1H model. Each dimension forces explicit decisions — anything left unanswered is a gap the implementing agent will guess at. The goal is **zero ambiguity**: when the spec is complete, there is no room for hallucination or creative interpretation.

Core principle: **"For every question — if you can't answer it, your system is undefined."**

#### Dimension 1: WHAT (Data & Entities)

Define the data entities involved and their valid states. This dimension answers:

- What are the core entities/objects this feature introduces or modifies?
- What are the valid states for each entity? (e.g., Loan can be ACTIVE, OVERDUE, CANCELLED, RETURNED)
- What state transitions are allowed? Which are forbidden?
- What data fields does each entity carry? Which are required vs optional?
- What are the invariants? (e.g., "A cancelled loan cannot have outstanding fees")
- What are the boundary values and edge cases? (e.g., max length, empty state, null handling)

**Example:**
> Loan entity: status can be `ACTIVE`, `OVERDUE`, `CANCELLED`, `RETURNED`. A loan can only transition to `CANCELLED` if it has no outstanding late fees. Cancellation updates status — never deletes the record. Fields: `id`, `member_id`, `book_id`, `status`, `due_date`, `cancelled_at` (nullable).

#### Dimension 2: WHERE (Scope & Boundaries)

Define where this feature lives and what it touches. This dimension answers:

- Which services, modules, or layers are affected?
- What are the system boundaries? (e.g., "only the API layer, not the worker")
- Which external systems or integrations are involved?
- What is explicitly out of scope?
- Are there geographic, environmental, or deployment boundaries? (e.g., "US region only", "staging first")

**Example:**
> Affects the Loans API (`/api/loans`) and the notification service. Does not touch the payment gateway — fee checks read from the fees table only. Out of scope: bulk cancellation, admin override.

#### Dimension 3: WHEN (Timing & Sequencing)

Define temporal rules and ordering constraints. This dimension answers:

- What triggers this feature? (user action, cron, event, webhook?)
- What is the sequence of operations? What must happen before what?
- Are there time windows, deadlines, or SLAs? (e.g., "cancellation must complete within 5s")
- What happens on timeout or delay?
- Are there scheduling or batching considerations?
- What are the concurrency rules? (e.g., "only one cancellation per loan at a time")

**Example:**
> Triggered by POST `/api/loans/:id/cancel`. Sequence: validate no outstanding fees → set status to CANCELLED → write audit log → send notification. If fee check takes >3s, timeout and return 503. No concurrent cancellations — use optimistic locking on loan status.

#### Dimension 4: WHO (Access & Permissions)

Define who can do what. This dimension answers:

- Which user roles or actors interact with this feature?
- What permissions are required for each action?
- Are there ownership rules? (e.g., "only the loan owner or staff can cancel")
- What about service-to-service auth? API keys? Scopes?
- Are there audit/compliance requirements for tracking who did what?

**Example:**
> Only the Member who owns the loan or a user with the `library_staff` role can cancel. API requires `loans:write` scope. All cancellations are audit-logged with actor ID, timestamp, and reason.

#### Dimension 5: WHY (Business Rules & Constraints)

Define the business motivation and rules that constrain the implementation. This dimension answers:

- What business problem does this solve? Why now?
- What are the regulatory or compliance constraints? (e.g., "financial records retained 7 years")
- What are the business rules that override technical convenience? (e.g., "never hard-delete")
- What are the success metrics? How will we know this worked?
- What are the failure modes the business cares about?

**Example:**
> Members currently call the front desk to cancel — this saves ~200 calls/month. All financial transactions must be archived for 7 years per regulation — cancellation updates status, never deletes. Success metric: 80% of cancellations self-service within 3 months.

#### Dimension 6: HOW (Procedures & Workflows)

Define the implementation approach at a procedural level — not code, but the workflow steps. This dimension answers:

- What is the step-by-step procedure for the happy path?
- What are the error handling procedures? (what happens when X fails?)
- What are the rollback or recovery procedures?
- What monitoring, alerting, or observability is needed?
- What is the migration or deployment procedure?

**Example:**
> On cancel: (1) check outstanding fees, (2) set status → CANCELLED, (3) set `cancelled_at` → now, (4) write audit log entry, (5) enqueue notification job. On fee-check failure: return 422 with fee details. On DB write failure: retry once, then return 500. No rollback needed — partial state is safe (audit log entry without status change is acceptable).

### Writing the Spec Document

The subagent:

1. **Structures the spec using all 6 ZeeSpec dimensions**, writing each as a section with concrete, specific entries. Use the examples above as a quality bar — every entry should be a decision, not a description.
2. **Drops any dimension that has fewer than 2 meaningful entries** — don't pad with filler. A narrow feature may only need 3-4 dimensions.
3. **Picks an icon and color** for the Linear document based on the feature domain.
4. **Returns** the spec content, icon, and color.

**Spec-writing principles:**

- **Codeless** — no implementation details like class names, file paths, or code snippets. That's for the implementing agent/PR.
- **Decision-forcing** — every entry is an explicit decision. "The system should handle errors gracefully" is slop. "On timeout: retry once, then return 503 with a retry-after header" is a decision.
- **Succinct** — value-dense, no filler. Enough context to implement without a meeting, not a word more.
- **Plain English** — no schemas, no DSLs. A senior engineer should be able to read this cold and know exactly what to build.

### Creating the Spec

Create the master issue first via `/issue`, then create the spec doc via `mcp__claude_ai_Linear__save_document` with `issue` set to the created issue identifier. Labels and style are handled by `/issue`.

## 5. Implementation Plan

Break feature into ordered sub-issues under the master ticket. Each designed for autonomous `/dispatch` execution.

Create each sub-issue via `/issue` with `parentId` set to the master issue. `/issue` handles title style, labels, estimates, and description — this skill only defines what's unique to sub-issues: ordering, parent linkage, and blocking relationships.

Keep phases to 8 issues or fewer, logically grouped. If a phase exceeds 8, split it.

### Sub-Issue Description

Each sub-issue description should include:

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

The `## Practices` section lists which practices from `~/.claude/practices/` apply to this specific sub-issue and why. This is directed guidance — the runner's `inject-practices.sh` hook will inject the full practice files deterministically at startup, but the sub-issue listing tells the runner which practices are most relevant to *this* task.

Only list practices that are genuinely relevant to the sub-issue's work.

### Sub-Issue Qualities

- **Small** — completable in a single `/dispatch` session
- **Independent** — no waiting on other sub-issues where possible
- **Ordered** — sequenced when order matters
- **Dispatch-ready** — enough detail for an agent to implement without clarification

Confirm full plan via `AskUserQuestion`: ordered list with titles, scope, points.

## 6. Create in Linear

Create: master issue (via `/issue`) -> spec document (attached to master issue) -> sub-issues in order (via `/issue`, set parent + blocking).

Report: master ticket ID + URL, sub-issue count, total points, next step (`/dispatch <ticket-id>`).

## 7. Discovery Capture (Optional)

After creating the feature spec, offer via `AskUserQuestion`:

"The conversation that led to this spec was itself discovery work. Want to capture it as a completed ticket?"

If yes:
- Create issue via `/issue`:
  - Subject: "Discovery: [topic summary]"
  - Label: `Discovery`
  - Status: set to `Done`
  - Same project / milestone as the feature spec
  - Description: concise summary of what was explored, key findings, decisions reached
  - Link to the spec document if one was created; otherwise link to the master issue
  - Estimate: 1-2 points

If no -> skip.

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
  ~/.claude/skills/spec/repos.md — known repo registry (auto-maintained)
```

---

## Examples

`/spec` -> synthesizes conversation, confirms Linear project, explores codebase, creates ZeeSpec feature spec with sub-issues.

`/spec add to Auth Rewrite` -> same flow, targets the "Auth Rewrite" Linear project.

---

## Troubleshooting

**Linear MCP unavailable**: Verify `mcp__claude_ai_Linear__*` tools are connected.

**"Which project?"**: Set default in your project's CLAUDE.md: `Linear project: <project-name>`.

**Repos not found**: Add them when prompted during discovery, or edit `~/.claude/skills/spec/repos.md` directly.
