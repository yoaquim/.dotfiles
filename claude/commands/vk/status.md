---
description: Comprehensive project status with VK tasks, features, and documentation health
allowed-tools: Read, Bash(git*), Bash(ls*), Grep, Glob, mcp__vibe_kanban__*
---

You are providing a comprehensive status report for a VK-Claude Code project.

**Shows:**
- VK task/subtask progress
- Feature completion status
- Documentation health
- Git repository status
- Next recommended actions

**Use for:**
- Daily standup information
- Progress tracking
- Identifying blockers
- Planning next steps
- Health check

---

## Prerequisites

**Check VK workflow enabled:**

```bash
ls .agent/.vk-enabled 2>/dev/null
```

If not VK-enabled:
```
⚠️ This project is not VK-enabled.

Use /status for standard workflow.
```

Exit if not VK-enabled.

**Check VK connection:**
```
mcp__vibe_kanban__list_projects
```

If fails:
```
⚠️ Cannot connect to Vibe Kanban.

Will show limited status (local .agent/ only).
VK task status unavailable.

[Continue with limited status]
```

---

## Status Report Structure

```
╔═══════════════════════════════════════════════╗
║          PROJECT STATUS REPORT                ║
║          [Project Name]                       ║
║          Generated: [Date Time]               ║
╚═══════════════════════════════════════════════╝

[Section 1: VK Task Progress]
[Section 2: Feature Status]
[Section 3: Documentation Health]
[Section 4: Git Status]
[Section 5: Next Steps]
[Section 6: Recommendations]
```

---

## Section 1: VK Task Progress

**Get VK project:**
```
mcp__vibe_kanban__list_projects
```

Extract `project_id` for current repo.

**Get all tasks:**
```
mcp__vibe_kanban__list_tasks project_id=<project_id>
```

**Parse dependencies for each task:**

For each task, read description and parse:
```markdown
**Depends On**:
- [Epic] Task name (ID: abc123)
- [Epic] Another task (ID: def456)
```

Build dependency map:
```
Task A: depends on []           → Ready (if status = todo)
Task B: depends on [abc123]     → Check abc123 status
  - If abc123 is done → Ready
  - If abc123 is todo/inprogress → Blocked
Task C: depends on [abc123, def456] → Check both
  - If ALL done → Ready
  - If ANY not done → Blocked
```

**Calculate readiness:**
- **Ready**: status = todo AND (no dependencies OR all dependencies done)
- **Blocked**: status = todo AND (any dependency NOT done)
- **In Progress**: status = inprogress (active attempt)
- **Done**: status = done
- **In Review**: status = inreview

**Analyze and display:**

```
🎯 VIBE KANBAN PROGRESS
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

**Project**: [Project Name]
**VK Project ID**: [ID]

### Tasks Overview

**Total**: [X] tasks ([X] story points - all 1pt)
**Done**: [Y] ([Y/X]%) ████████░░ [Progress bar]
**In Progress**: [Z] (active attempts)
**Todo**: [W] (not started yet)

**Average Time/Task**: [Calculated if data available]

### Task Readiness

**Ready to Start**: [N] tasks
- All dependencies met
- Can start immediately via /vk:start

**Blocked**: [M] tasks
- Waiting on dependencies
- Will become ready when blockers complete

**In Review**: [P] tasks
- Implementation complete
- Awaiting review

### Recently Completed

1. ✅ [Epic] Task name - Completed [time ago]
2. ✅ [Epic] Task name - Completed [time ago]
3. ✅ [Epic] Task name - Completed [time ago]

### Currently Active (Running Attempts)

1. 🔄 [Epic] Task name - Attempt [attempt-id]
2. 🔄 [Epic] Task name - Attempt [attempt-id]

### Top Blockers

[If tasks are blocked, show what's blocking them]
⚠️ [Epic] Task A (blocks 3 other tasks)
⚠️ [Epic] Task B (blocks 2 other tasks)

[If none]
✅ No blocking dependencies

---
```

**Calculate velocity (if enough history):**
```
📈 VELOCITY (Last 7 days)

**Completed**:
- [N] subtasks completed
- [N] story points delivered
- [N/7] avg subtasks/day

**Trend**: [Increasing/Stable/Decreasing]
```

---

## Section 2: Feature Status

**Read feature requirements:**

```bash
# List all features
ls .agent/features/*.md 2>/dev/null
```

**For each feature:**
1. Read feature file
2. Check if VK epic(s) exist for it
3. Determine status (planned/in-progress/complete)
4. Calculate completion %

**Display:**

```
📋 FEATURE STATUS
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

### Completed Features

1. ✅ **[Feature Name]** (100%)
   - Defined: [Date]
   - Completed: [Date]
   - Epics: [X] (all done)
   - File: .agent/features/[name].md

### In Progress Features

1. 🔄 **[Feature Name]** ([X]% complete)
   - Defined: [Date]
   - Epics: [Y]/[Z] done
   - Active subtasks: [N]
   - File: .agent/features/[name].md
   - **Status**: [Current phase/milestone]

### Planned Features

1. 📋 **[Feature Name]** (Not started)
   - Defined: [Date]
   - Status: Requirements documented, not yet planned in VK
   - File: .agent/features/[name].md
   - **Next**: Run /vk:plan to create VK tasks

### Features Without VK Tasks

[If any feature requirements exist but no VK tasks created]
⚠️ [Feature Name] - Requirements defined but not planned
   → Run: /vk:plan "[feature name]"

---
```

---

## Section 3: Documentation Health

**Check documentation status:**

```bash
# Read key documentation files
.agent/README.md
.agent/system/overview.md
.agent/system/architecture.md
.agent/system/database-schema.md (if exists)
.agent/sops/README.md
```

**Analyze:**
- Last updated date
- Completed VK work reflected?
- Architecture current?
- Known gaps?

**Display:**

```
📚 DOCUMENTATION HEALTH
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

### System Documentation

**overview.md**
- Status: ✅ Current / ⚠️ Needs update / ❌ Outdated
- Last updated: [Date]
- Coverage: [Assessment]

**architecture.md**
- Status: ✅ Current / ⚠️ Needs update / ❌ Outdated
- Last updated: [Date]
- Coverage: [Assessment]

**database-schema.md**
- Status: ✅ Current / ⚠️ Needs update / ❌ Outdated / ℹ️ N/A
- Last updated: [Date]
- Coverage: [Assessment]

### Documentation Gaps

[If any gaps identified]
⚠️ [X] completed VK epics not documented
⚠️ Architecture section needs update
⚠️ Database schema outdated

[If no gaps]
✅ No documentation gaps detected

### Upcoming Doc Subtasks

**Scheduled** (from VK):
1. [Doc subtask name] - Epic [epic name]
2. [Doc subtask name] - Epic [epic name]

**Recommendation**:
[If gaps] → Run /vk:sync-docs to update documentation
[If current] → Documentation is current

---
```

---

## Section 4: Git Status

**Check git repository:**

```bash
# Get current branch
git branch --show-current

# Check status
git status --porcelain

# Recent commits
git log --oneline -5

# Check if ahead/behind remote
git status -sb

# Count uncommitted changes
git diff --shortstat
```

**Display:**

```
📦 GIT STATUS
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

**Current Branch**: [branch-name]
**Status**: [Clean / Uncommitted changes / Ahead of remote]

[If uncommitted changes]
**Uncommitted Changes**:
- Modified: [N] files
- Added: [N] files
- Deleted: [N] files

Changes:
[List key changed files]

[If clean]
✅ Working directory clean

**Recent Commits** (Last 5):
1. [hash] [message] - [time ago]
2. [hash] [message] - [time ago]
...

**Remote Status**:
[Ahead X commits / Behind Y commits / Up to date]

---
```

**VK Git Worktrees** (if can detect):
```
**VK Worktrees** (Active subtasks):
- [worktree path] - [subtask name]
- [worktree path] - [subtask name]

[If any]
ℹ️ VK manages these worktrees automatically
```

---

## Section 5: Next Steps

**Based on analysis, suggest specific next actions:**

```
🎯 NEXT STEPS
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

### Immediate Actions

[Prioritized based on current state]

1. **[Action]** [Priority: High/Medium/Low]
   - Reason: [Why this matters now]
   - Command: [Specific command to run]

2. **[Action]** [Priority: High/Medium/Low]
   - Reason: [Why this matters now]
   - Command: [Specific command to run]

### This Week

- [ ] [Broader goal 1]
- [ ] [Broader goal 2]
- [ ] [Broader goal 3]

### Upcoming Priorities

1. [Next epic/feature to tackle]
2. [After that]
3. [Future consideration]

---
```

**Common scenarios and suggestions:**

**If no features defined:**
```
1. **Define first feature** [Priority: High]
   - Reason: No features defined yet
   - Command: /vk:feature "your feature description"
```

**If features defined but not planned:**
```
1. **Plan features in VK** [Priority: High]
   - Reason: [N] features defined but not in VK
   - Command: /vk:plan
```

**If tasks created but not prioritized:**
```
1. **Prioritize tasks** [Priority: High]
   - Reason: [N] tasks in VK, no dependencies set
   - Command: /vk:prioritize
```

**If tasks ready but not started:**
```
1. **Start task execution** [Priority: High]
   - Reason: [N] tasks ready (dependencies met)
   - Command: /vk:start
   - Or: /vk:start --watch (continuous mode)
```

**If VK tasks active (attempts running):**
```
1. **Monitor active attempts** [Priority: Medium]
   - Reason: [N] attempts in progress
   - Action: Check VK UI for progress
   - Next: Run /vk:start when ready for next wave
```

**If tasks blocked:**
```
1. **Review blockers** [Priority: High]
   - Reason: [N] tasks blocked by dependencies
   - Action: Check if blockers can be started
   - Command: /vk:execute <blocker-task-id>
```

**If documentation outdated:**
```
1. **Sync documentation** [Priority: Medium]
   - Reason: [X] completed epics not documented
   - Command: /vk:sync-docs
```

**If epics complete:**
```
1. **Plan next feature** [Priority: High]
   - Reason: Current epics done, ready for next work
   - Command: /vk:feature "next feature"
   - Then: /vk:plan
```

---

## Section 6: Recommendations & Insights

```
💡 RECOMMENDATIONS
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

[Context-aware recommendations based on project state]

### Workflow Health

**✅ Going Well:**
- [Positive observation 1]
- [Positive observation 2]

**⚠️ Watch Out For:**
- [Concern or anti-pattern noticed]
- [Potential issue]

### Performance Insights

[If velocity data available]
**Velocity**: [N] subtasks/week
**Est. Remaining Time**: [X] weeks based on backlog

[If specific patterns noticed]
**Pattern Detected**: [Observation]
**Suggestion**: [How to improve]

### Documentation

[If doc subtasks not being executed]
⚠️ Documentation subtasks exist but not executed yet
→ Prioritize doc subtasks to keep docs current

[If no doc subtasks in recent epics]
⚠️ Recent VK plans missing documentation subtasks
→ Run /vk:plan again for new features to auto-generate doc tasks

### Testing

[If test subtasks not being executed]
⚠️ Test subtasks exist but not executed
→ Prioritize testing for quality assurance

[If test coverage appears low based on subtask ratios]
💡 Consider more test subtasks in future planning

### Best Practices

[Relevant tips based on project state]
- [Tip 1]
- [Tip 2]

---
```

---

## Section 7: Quick Commands

```
⚡ QUICK COMMANDS
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Based on your project state, here are relevant commands:

[Context-aware command suggestions]

/vk:feature "..."     - Define new feature requirements
/vk:plan              - Plan feature implementation in VK
/vk:sync-docs         - Sync documentation with VK progress
/fix-bug "..."        - Quick bug fix
/document-issue       - Document known issue

[If specific action recommended]
→ Suggested next: /vk:feature "your next feature"

---
```

---

## Final Summary Bar

```
╔═══════════════════════════════════════════════╗
║  📊 PROJECT HEALTH: [Excellent/Good/Fair/Attention Needed]
╚═══════════════════════════════════════════════╝

VK Progress: [B]/[A] subtasks ([%]%) ████████░░
Features: [Y]/[X] complete ([%]%)
Documentation: [Current/Needs Attention]
Git: [Clean/Changes pending]

Last updated: [Date Time]
Next status: Run /vk:status anytime
```

---

## Error Handling

### VK Connection Failed

```
⚠️ Cannot connect to Vibe Kanban

Showing limited status (local .agent/ only).

**Available:**
- ✅ Feature status (from .agent/features/)
- ✅ Documentation health
- ✅ Git status

**Unavailable:**
- ❌ VK task progress
- ❌ Epic/subtask metrics
- ❌ Velocity data

To see full status:
1. Check VK is running
2. Verify MCP connection
3. Run /vk:status again
```

Continue with limited status report.

### No VK Project Found

```
⚠️ No VK project found for this repository

Current directory: [pwd]

This could mean:
- Project not added to VK yet
- VK project path mismatch

Check: mcp__vibe_kanban__list_projects

[Show local status only]
```

### No Features Defined

```
ℹ️ No features defined yet.

To get started:
1. Define your first feature: /vk:feature "feature description"
2. Plan implementation: /vk:plan
3. Let VK orchestrate: VK will spawn CC instances

Run /vk:status after features are defined.
```

---

## Advanced: Health Scoring

**Calculate overall project health score:**

```
Project Health Score: [X]/100

Breakdown:
- VK Progress (40 pts): [Score]/40
  - Based on: Velocity, completion rate, blocked tasks

- Documentation (30 pts): [Score]/30
  - Based on: Currency, coverage, gaps

- Feature Planning (20 pts): [Score]/20
  - Based on: Defined features, planned epics, clarity

- Code Quality (10 pts): [Score]/10
  - Based on: Test coverage (from test subtasks), git hygiene

Assessment: [Excellent 90+ / Good 75-89 / Fair 60-74 / Needs Attention <60]
```

---

## Comparison with Previous Status

**If status run previously (future enhancement):**

```
📈 PROGRESS SINCE LAST CHECK ([time ago])

**Then:**
- Subtasks complete: [B1]
- Features done: [Y1]

**Now:**
- Subtasks complete: [B2]
- Features done: [Y2]

**Progress:**
- +[B2-B1] subtasks completed
- +[Y2-Y1] features finished
- [Trend assessment]
```

---

## Output Format Options

**By default, show comprehensive status.**

**For quick check:**
```
/vk:status quick
```

Shows condensed version:
```
PROJECT: [Name]

VK: [B]/[A] subtasks ([%]%)
Features: [Y]/[X] done
Docs: [Status]
Git: [Status]

Next: [Primary recommendation]
```

**For specific section:**
```
/vk:status vk       - VK progress only
/vk:status features - Feature status only
/vk:status docs     - Documentation health only
/vk:status git      - Git status only
```

---

## Best Practices

### When to Check Status

**Good times:**
- ✅ Daily standup prep
- ✅ Before planning next feature
- ✅ End of week review
- ✅ After major epic completion
- ✅ When feeling lost or unsure of next steps

**Avoid:**
- ❌ Every few minutes (obsessive checking)
- ❌ While VK tasks actively running (give them time)

### Interpreting Status

**Healthy project:**
- ✅ Steady velocity
- ✅ No blocked tasks
- ✅ Documentation current
- ✅ Clear next steps
- ✅ Features progressing

**Needs attention:**
- ⚠️ Many blocked tasks
- ⚠️ Documentation outdated
- ⚠️ No clear next steps
- ⚠️ Velocity declining
- ⚠️ Uncommitted changes piling up

### Acting on Status

**Don't just read, act:**
1. Identify highest priority action
2. Run suggested command
3. Address blockers immediately
4. Keep documentation current
5. Maintain steady progress

**Status is a tool for action, not just information.**

---

## Integration with VK Workflow

**This command integrates:**
- VK MCP tools (task data)
- .agent/ documentation (project context)
- Git (code status)
- Feature requirements (progress mapping)

**Shows:**
- Complete project picture
- How pieces fit together
- Where attention needed
- What to do next

**Use regularly:**
- Part of daily routine
- Before making decisions
- When planning next work
- For team communication

---

## Export Options (Future Enhancement)

**Generate status report formats:**

```
/vk:status --format=markdown > status-report.md
/vk:status --format=json > status.json
/vk:status --format=html > status.html
```

For:
- Team sharing
- Documentation
- Automated reporting
- Dashboard integration
