---
description: Complete project kickoff - identify features, gather requirements, create VK tasks
allowed-tools: Read, Write, Edit, AskUserQuestion, Glob, Bash(ls*), mcp__vibe_kanban__*
---

You are orchestrating a complete project kickoff for VK-Claude workflow.

**What this does:**
1. Read product vision from `.agent/system/overview.md`
2. Analyze and identify ALL needed features
3. **Automatically run `/vk-feature` for each feature** (gather requirements)
4. **Automatically run `/vk-plan` for each feature** (create flat VK tasks with [Epic] prefixes)
5. Report complete setup

**VK Task Structure:**
- Flat (all independent VK Tasks)
- Grouped by `[Epic]` prefix
- All 1-point (1-2 hours each)
- VK orchestrates execution (starts Attempts)

**User provides spec once, you do everything.**

---

## Prerequisites

**Check VK enabled:**
```bash
ls .agent/.vk-enabled 2>/dev/null
```

If not exists:
```
⚠️ VK workflow not enabled.

Run /vk-init-project first.
```

**Check VK connection:**
```
mcp__vibe_kanban__list_projects
```

If fails:
```
❌ Cannot connect to Vibe Kanban.

Ensure VK is running and MCP server configured.
```

**Check product vision exists:**
```bash
ls .agent/system/overview.md 2>/dev/null
```

If not exists:
```
⚠️ No product vision found.

Run /vk-init-project first to capture product vision.
```

---

## Step 1: Read Product Context

Read:
- `.agent/system/overview.md` (product vision, goals, users)
- `CLAUDE.md` (project instructions)
- Any existing `.agent/features/*.md` (if user started manually)

Extract:
- Product description
- Target users
- Key goals
- Tech stack
- Any constraints

---

## Step 2: Identify Features

Analyze product vision and identify ALL features needed.

**Common patterns:**
- User accounts? → Authentication, Profiles, Password Reset
- Content creation? → CRUD, Editor, Media Upload
- Social? → Comments, Following, Notifications
- Search? → Full-text search, Filters, Tags
- Admin? → Admin Panel, Moderation

**Present feature list:**
```
📋 FEATURE IDENTIFICATION

Based on your product vision, here are ALL features needed:

Core Features:
1. User Authentication
2. User Profiles
3. [Feature 3]
4. [Feature 4]

Secondary Features:
5. [Feature 5]
6. [Feature 6]

Nice-to-Have:
7. [Feature 7]
8. [Feature 8]

Total: X features identified

---

Would you like to:
A) Use all features (I'll gather requirements for each)
B) Select subset for Phase 1
C) Modify list (add/remove features)

Choose: (A/B/C)
```

**If B or C:** Get user modifications

---

## Step 3: Run vk-feature for Each Feature

**For each approved feature:**

```
🔄 Feature 1/X: [Feature Name]

Running /vk-feature workflow...
```

**Execute full /vk-feature workflow inline:**
1. Ask clarifying questions (problem, users, outcome)
2. Iterative discovery (roles, journeys, edge cases)
3. Validate requirements summary
4. Generate feature document
5. Create `.agent/features/<feature-name>.md`
6. Track as `.agent/.last-feature`

**After each feature:**
```
✅ Feature 1/X complete: .agent/features/<feature-name>.md
```

**Repeat for ALL features.**

---

## Step 4: Run vk-plan for Each Feature

**For each feature:**

```
🔄 Planning 1/X: [Feature Name]

Running /vk-plan workflow...
```

**Execute full /vk-plan workflow inline:**
1. Read feature requirements
2. Break into epics (logical grouping)
3. Break epics into 1-point tasks (flat structure)
4. Auto-generate doc tasks (per epic)
5. Auto-generate test tasks (TDD approach)
6. Create all tasks in VK with `[Epic]` prefix
7. Report creation

**After each feature:**
```
✅ Planning 1/X complete:
   - Epics identified: Y
   - VK Tasks created: Z (all 1-point, flat)
```

**Repeat for ALL features.**

---

## Step 5: Final Report

```
╔═══════════════════════════════════════════════╗
║   🎉 PROJECT KICKOFF COMPLETE                 ║
╚═══════════════════════════════════════════════╝

📋 FEATURES DEFINED: X
───────────────────────────────────────────────
[List each feature with .agent/features/<name>.md]

🎯 VK TASKS CREATED
───────────────────────────────────────────────
- Total Epics: Y (logical grouping)
- Total Tasks: Z (all 1-point, flat structure)
  - Implementation: [N]
  - Tests: [M]
  - Documentation: [P]

**Task Structure:** Flat with [Epic] prefixes
**All tasks in VK backlog** (not started yet)

⏱️ ESTIMATED EFFORT
───────────────────────────────────────────────
- Story Points: Z points
- Sequential: ~[Z * 1.5] hours
- VK Parallel: Could complete much faster!

📁 FILES CREATED
───────────────────────────────────────────────
.agent/features/
  - [feature-1].md
  - [feature-2].md
  ...

🎯 NEXT STEPS
───────────────────────────────────────────────
Would you like to:
A) **PRIORITIZE NOW** (/vk-prioritize)
   → Set dependencies and execution order
   → Then start execution

B) **START EXECUTION** (/vk-start)
   → Skip prioritization, start all tasks

C) **REVIEW IN VK UI FIRST**
   → Manually review tasks
   → Set priorities/dependencies in VK
   → Then run commands

Choose: (a/b/c)
```

**If A chosen:** Run `/vk-prioritize` workflow inline.

**If B chosen:** Offer `/vk-start` options:
```
Start execution how?
A) Start all ready tasks (/vk-start)
B) Watch mode (/vk-start --watch)
C) Batch mode (/vk-start --batch-size=5)

Choose: (a/b/c)
```

**If C chosen:** Exit with instructions:
```
✅ Tasks created! Review in VK UI.

When ready:
- /vk-prioritize (set dependencies)
- /vk-start (begin execution)
- /vk-status (monitor progress)

Ready to build! 🚀
```

---

## Implementation Details

### Feature Identification Logic

Analyze product vision for common patterns:

**User Management:**
- Mentions "users", "accounts", "login" → Authentication, Profiles

**Content:**
- Mentions "posts", "articles", "content" → Content CRUD, Editor, Media

**Social:**
- Mentions "comments", "follow", "social" → Comments, Following, Notifications

**Search:**
- Complex content or mentions "search" → Search, Tags, Filters

**Admin:**
- Almost always needed → Admin Panel, Moderation

**API:**
- Mentions "integrations", "API" → REST API, Webhooks

### Automatic Feature Detection

```
Product: "Blog platform for writers"

Detected needs:
→ User accounts (writers need accounts)
→ Blog posts (core content)
→ Rich editor (writing experience)
→ Comments (engagement)
→ Search (finding content)
→ Admin (content moderation)

Propose 6-8 features
```

### Calling vk-feature Inline

**Execute the entire vk-feature workflow:**
- Same questions
- Same EARS format
- Same validation
- Creates same `.agent/features/<name>.md`

**Don't skip anything** - full requirements gathering per feature.

### Calling vk-plan Inline

**Execute the entire vk-plan workflow:**
- Read feature requirements
- Break into epics and subtasks
- Enforce 1-point rule
- Auto-generate doc/test subtasks
- Create VK tasks

**Don't skip anything** - full planning per feature.

---

## Error Handling

### No Product Vision

```
❌ Cannot identify features without product vision.

Run /vk-init-project first to capture:
- Product description
- Target users
- Key goals
```

### VK Connection Lost

```
❌ Lost connection to VK during task creation.

Features defined successfully:
[List completed features]

But VK tasks not created.

Retry? (yes/no)
```

### User Cancels Mid-Process

```
⚠️ Kickoff cancelled.

Progress so far:
- Features defined: X/Y
- VK tasks created: A/B

You can:
- Resume with /vk-kickoff (will skip completed features)
- Continue manually with /vk-feature and /vk-plan
```

---

## Best Practices

### Time Investment

This command takes time (intentional):
- Feature requirements: 10-15 min per feature
- Implementation planning: 5 min per feature
- **Total: 15-20 min per feature**

**For 8 features: ~2 hours**

**Worth it** - comprehensive planning upfront.

### Interaction Required

This is **not** fire-and-forget:
- You answer questions during /vk-feature
- You approve plans during /vk-plan

**Interactive by design** - ensures quality requirements.

### Can Be Re-Run

If you add features later:
- Run /vk-kickoff again
- Will detect existing features
- Only process new ones

---

## Integration

### With /vk-init-project

User can run:
```bash
/vk-init-project    # Setup
/vk-kickoff         # Complete planning
```

Or `/vk-init-project` can offer to run this automatically at end.

### With Standard Commands

Can still use:
```bash
/vk-feature "new feature"  # Add one feature manually
/vk-plan "specific feature"  # Plan one feature
```

Kickoff just automates running these for all features.

---

## Example Session

```bash
/vk-kickoff
```

**Output:**
```
📋 Reading product vision...
✅ Product: Blog Platform
✅ Users: Writers and content creators
✅ Goals: Simple writing, social features, great search

🔍 Identifying features...

Based on your vision, I've identified 8 features:

Core:
1. User Authentication
2. User Profiles
3. Blog Post Management
4. Rich Text Editor

Secondary:
5. Comments System
6. User Following
7. Search
8. Admin Panel

Use all 8 features? (yes/no/modify)
```

**You:** `yes`

```
🚀 Starting feature requirements gathering...

This will take ~2 hours (15-20 min per feature)
Interactive - I'll ask questions about each feature

Ready? (yes/no)
```

**You:** `yes`

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Feature 1/8: User Authentication
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Running /vk-feature workflow...

What problem does authentication solve?
[Your answer]

Who experiences this problem?
[Your answer]

[Full vk-feature conversation]

✅ Feature doc created: .agent/features/user-authentication.md

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Feature 2/8: User Profiles
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

[Repeat for all 8 features]

✅ All features documented!

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Planning VK Tasks
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Planning 1/8: User Authentication
→ 4 epics, 17 subtasks created in VK

Planning 2/8: User Profiles
→ 2 epics, 8 subtasks created in VK

[Repeat for all 8]

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

🎉 PROJECT KICKOFF COMPLETE!

Features: 8 defined
Epics: 24 created in VK
Tasks: 96 created (all 1-point)

---

Would you like to:
A) PRIORITIZE NOW (/vk-prioritize)
B) START EXECUTION (/vk-start)
C) REVIEW IN VK UI FIRST

[Interactive choice follows - see Step 5 above]
```

---

## Notes

**This command orchestrates other commands** - it's a meta-command.

**Calls:**
- `/vk-feature` workflow (inline) for each feature
- `/vk-plan` workflow (inline) for each feature

**Result:** Complete project setup in one command.

**User provides spec once**, everything else is automatic.
