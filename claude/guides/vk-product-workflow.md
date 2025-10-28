# Building a Product with VK-Claude Workflow

**Guide for Humans** 👤

This guide walks you through building a complete product using Vibe Kanban + Claude Code workflow, from initial idea to shipped features.

**Last Updated**: 2025-10-27

---

## Table of Contents

- [Overview](#overview)
- [Prerequisites](#prerequisites)
- [The 5-Phase Workflow](#the-5-phase-workflow)
- [Complete Example: Blog Platform](#complete-example-blog-platform)
- [Common Scenarios](#common-scenarios)
- [Best Practices](#best-practices)
- [Troubleshooting](#troubleshooting)
- [FAQ](#faq)

---

## Overview

### What is VK-Claude Workflow?

A system that combines:
- **Vibe Kanban (VK)**: Orchestrates multiple Claude Code instances in parallel
- **Claude Code (CC)**: AI coding agent that implements features
- **`.agent/` Directory**: Project context and documentation

### How It Works

```
You define requirements → Claude plans implementation → VK orchestrates → Features get built
```

1. **You**: Describe what you want (product vision, features)
2. **Claude**: Breaks it down into agile plan (epics, 1-point subtasks)
3. **VK**: Spawns multiple Claude instances to work in parallel
4. **Result**: Features implemented, tested, documented

### Key Benefits

✅ **Parallel Execution**: Multiple tasks run simultaneously
✅ **Structured Planning**: Agile breakdown (epics → subtasks)
✅ **Automated Documentation**: Docs updated as features complete
✅ **TDD-Friendly**: Tests and implementation are separate
✅ **Progress Visibility**: See exactly what's done/in-progress
✅ **Isolated Work**: Each task in own git worktree (no conflicts)

---

## Prerequisites

### Setup

1. **Claude Code**: Installed and working
2. **Vibe Kanban**: Installed with MCP server configured
3. **VK Workflow**: Commands installed in `~/.claude/commands/`
4. **Project**: New or existing codebase

### Check Your Setup

```bash
# Verify Claude Code
claude --version

# Verify VK commands available
ls ~/.claude/commands/vk-*

# Should see:
# vk-init-project.md
# vk-feature.md
# vk-plan.md
# vk-status.md
# vk-sync-docs.md
```

---

## The 5-Phase Workflow

### Phase 1: Product Definition

**What**: Define your product vision and context

**Command**: `/vk-init-project`

**You provide**:
- Product description and goals
- Target users
- Tech stack preferences
- Any mockups/designs

**Claude creates**:
- `.agent/` documentation structure
- `CLAUDE.md` with project instructions
- System documentation with your vision
- VK workflow enabled (no `.agent/tasks/` directory)

**Time**: 10-15 minutes

---

### Phase 2: Feature Decomposition

**What**: Break product into features with detailed requirements

**Command**: `/vk-feature <description>`

**For each major feature**:
- Interactive conversation about user needs
- Define user stories
- Specify acceptance criteria (EARS format)
- Identify edge cases
- Set success metrics

**Claude creates**:
- `.agent/features/<name>.md` per feature
- EARS format acceptance criteria
- Linked for traceability

**Time**: 10-20 minutes per feature

**Tip**: Define multiple features before planning!

---

### Phase 3: Agile Planning

**What**: Turn feature requirements into VK task hierarchy

**Command**: `/vk-plan [feature-name]`

**Claude does**:
1. Reads feature requirements
2. Breaks into Epics (VK Tasks)
3. Breaks epics into 1-point Subtasks
4. Auto-generates documentation subtasks
5. Auto-generates test subtasks
6. Creates all tasks in Vibe Kanban

**Result**:
- Epics with 3-10 subtasks each
- Every subtask is 1 point (1-2 hours)
- Tests separate from implementation (TDD)
- Documentation built into workflow

**Time**: 5-10 minutes per feature

---

### Phase 4: Prioritization & Execution

**What**: Set dependencies and start task execution

**Phase 4a: Prioritization**

**Command**: `/vk-prioritize`

**What happens**:
- Analyzes all pending tasks
- Identifies logical dependencies (DB before API, implementation before tests)
- Asks clarifying questions
- Builds dependency graph
- Updates task descriptions with dependency metadata
- Assigns execution waves (Wave 1, Wave 2, etc.)

**Output**: Clear execution plan showing which tasks can start immediately and which are blocked.

**Time**: 5-10 minutes (interactive)

**Phase 4b: Execution**

**Commands**:
- `/vk-start` - Start all ready tasks (one-shot)
- `/vk-start --watch` - Continuous mode (auto-start as tasks complete)
- `/vk-execute <task-id>` - Start specific task manually

**What happens when you run /vk-start**:
- Reads all tasks and parses dependencies
- Identifies tasks where all dependencies are done
- Starts Attempts for ready tasks via VK

**VK does (per Attempt)**:
- Creates isolated git worktree
- Spawns CC instance with full context
- Runs multiple tasks in parallel
- Merges completed work
- Marks task done, unblocks dependent tasks

**Each CC instance gets**:
- Task description (specific instructions)
- Feature requirements (acceptance criteria)
- Project documentation (`.agent/` context)
- Available tools (slash commands)

**You monitor** with: `/vk-status`

**Next wave**: Call `/vk-start` again when ready, or use `--watch` mode for automatic continuation.

**Time**: Varies (but parallel = much faster)

---

### Phase 5: Monitoring & Iteration

**What**: Track progress, sync docs, repeat for next features

**Commands**:
- `/vk-status` - Check progress anytime
- `/vk-sync-docs` - Sync documentation if needed

**When done with features**:
- Review completed work
- Define next features
- Repeat Phase 2-5

---

## Complete Example: Blog Platform

### Scenario

**You want to build**: A blog platform with user accounts, posts, comments, and search.

**Let's walk through the complete workflow.**

---

### Step 1: Initialize Project

```bash
cd ~/Projects/my-blog
/vk-init-project
```

**Claude asks questions:**
```
What is your product about?
```

**You answer:**
```
A modern blog platform where users can:
- Create accounts
- Write and publish blog posts
- Comment on posts
- Search content
- Follow other users

Target users: Writers, content creators, hobbyist bloggers
Key goals: Simple, fast, great writing experience
```

**Claude asks about tech:**
```
Language? Framework? Database?
```

**You answer:**
```
- Python
- Django
- PostgreSQL
- pytest for testing
```

**Claude creates:**
```
✅ .agent/ structure (no tasks/ directory)
✅ CLAUDE.md with your vision
✅ .agent/system/overview.md with product context
✅ .agent/system/architecture.md (starter)
✅ VK workflow enabled
```

**Time**: ~10 minutes

---

### Step 2: Define Features

#### Feature 1: User Accounts

```bash
/vk-feature "User account management with registration and authentication"
```

**Claude asks:**
- What problem does this solve?
- Who are the users?
- What does success look like?

**You answer** (conversational):
- Writers need accounts to publish
- Email/password registration
- JWT authentication for API
- Profile pages

**Claude creates:**
`.agent/features/user-account-management.md` with:
- User stories (prioritized)
- Acceptance criteria (EARS format):
  ```
  WHEN a user submits valid registration info
  THEN the system SHALL create account
  AND send verification email
  ```
- Edge cases (duplicate emails, weak passwords)
- Success metrics (95% successful registrations)

**Time**: ~15 minutes

---

#### Feature 2: Blog Posts

```bash
/vk-feature "Blog post creation, editing, and publishing"
```

**Conversation about:**
- WYSIWYG editor? Markdown?
- Draft vs published states?
- Media uploads?

**Claude creates:**
`.agent/features/blog-post-management.md` with complete requirements

**Time**: ~15 minutes

---

#### Feature 3: Comments

```bash
/vk-feature "Comment system for blog posts"
```

**Time**: ~10 minutes

---

#### Feature 4: Search

```bash
/vk-feature "Full-text search for posts and users"
```

**Time**: ~10 minutes

---

**After defining features:**

You have 4 comprehensive feature requirement documents.
Each has user stories, acceptance criteria, edge cases.

**Total time for Phase 2**: ~50 minutes

---

### Step 3: Plan First Feature

```bash
/vk-plan
```

**Claude detects last feature (Search), but you want to start with accounts:**

```bash
/vk-plan "user account management"
```

**Claude:**
1. Reads `.agent/features/user-account-management.md`
2. Analyzes requirements
3. Proposes breakdown:

```
📋 VK AGILE PLAN: User Account Management

Feature Requirements: .agent/features/user-account-management.md
Total Epics: 4
Total Subtasks: 17 (all 1-point)

---

Epic 1: User Model & Database
Value: Foundation for user accounts
Subtasks: 4

1. Create User model with email/password/profile fields [1pt]
2. Write User model unit tests [1pt]
3. Create database migrations for User model [1pt]
4. Update database schema docs [1pt]

Epic 2: User Registration
Value: Users can create accounts
Subtasks: 5

1. Build POST /api/register endpoint [1pt]
2. Add email validation logic [1pt]
3. Add password hashing (bcrypt) [1pt]
4. Write registration endpoint tests [1pt]
5. Update API documentation [1pt]

Epic 3: User Authentication
Value: Users can log in
Subtasks: 5

1. Build POST /api/login endpoint [1pt]
2. Add JWT token generation [1pt]
3. Add JWT token validation middleware [1pt]
4. Write authentication tests [1pt]
5. Update auth architecture docs [1pt]

Epic 4: User Profiles
Value: Users have public profiles
Subtasks: 3

1. Build GET /api/users/:id endpoint [1pt]
2. Build PUT /api/users/:id endpoint [1pt]
3. Write profile endpoint tests [1pt]

---

Total Story Points: 17
Estimated Duration: 25-34 hours (VK can parallelize)
1-Point Rule: ✅ All subtasks validated

Would you like to CREATE these tasks in Vibe Kanban?
```

**You approve:**
```
CREATE
```

**Claude creates all 17 subtasks in VK, linked and organized.**

**Time**: ~8 minutes

---

### Step 4: Prioritize & Execute

**Step 4a: Set Dependencies**

```bash
/vk-prioritize
```

**Claude analyzes** the 17 tasks and proposes:

```
Wave 1 (No dependencies):
- [User Model] Create User model
- [User Model] Create database migrations

Wave 2 (After Wave 1):
- [User Model] Write tests
- [Registration] Build POST /api/register endpoint

Wave 3 (After Wave 2):
- [Registration] Add email validation
- [Login] Build POST /api/login endpoint

Wave 4 (After Wave 3):
- [Login] Add JWT generation
- All documentation tasks
```

**You confirm** the dependency plan.

**Claude updates** all task descriptions with dependency metadata.

**Time**: ~5 minutes

**Step 4b: Start Execution**

```bash
/vk-start --watch
```

**VK starts working:**
- Starts Wave 1 tasks (2 tasks, no dependencies)
- Spawns CC instances in parallel
- Each in isolated git worktree
- Each with full project context

**As tasks complete:**
- VK marks them done
- Wave 2 becomes ready
- VK auto-starts Wave 2 (watch mode)
- Process continues through all waves

**You monitor:**

```bash
/vk-status
```

**Output:**
```
🎯 VIBE KANBAN PROGRESS

Tasks: 17 total
Done: 5 (29%)
In Progress: 3 (Wave 2)
Blocked: 9 (waiting on dependencies)

Recently Completed:
✅ [User Model] Create User model - 2 hours ago
✅ [User Model] Create migrations - 2 hours ago
✅ [User Model] Write tests - 1 hour ago
✅ [Registration] Build endpoint - 30 min ago
✅ [Registration] Add validation - 10 min ago

Currently Active (Wave 3):
🔄 [Login] Build POST /api/login endpoint
🔄 [Login] Add JWT generation
🔄 [Login] Write login tests

Ready: 0 (all waves in progress)
Blocked: 6 (Wave 4 - waiting on Wave 3)
```

**You do**: Monitor progress, watch mode handles everything!

**Time**: Completes over next few hours (parallel + dependency-aware)

---

### Step 5: Check Results

**After epic completes:**

```bash
/vk-status
```

```
Epics: 1/4 done (Epic 1: User Model complete)
Subtasks: 4/17 done
Documentation: Current (doc subtask executed)

Next: Epic 2 (Registration) in progress
```

**Review:**
- Check git commits (VK merged work)
- Run tests (should pass)
- Review `.agent/system/` (updated by doc subtasks)

**Continue monitoring** as VK works through remaining epics.

---

### Step 6: Plan Next Feature

**When User Accounts feature complete:**

```bash
/vk-plan "blog post management"
```

**Repeat cycle:**
- Claude plans epics and subtasks
- Creates in VK
- VK executes
- Features get built

---

### Results After Complete Workflow

**You now have:**

✅ **Working Features:**
- User accounts (registration, login, profiles)
- Blog posts (create, edit, publish)
- Comments system
- Search functionality

✅ **Complete Documentation:**
- Feature requirements in `.agent/features/`
- Updated architecture in `.agent/system/`
- Database schema documented
- All current

✅ **Tests:**
- Unit tests (models, utilities)
- Integration tests (API endpoints)
- Edge case coverage
- 80%+ coverage

✅ **Visibility:**
- VK shows progress throughout
- Git history clean
- All work traceable

**Total Active Time** (your time):
- Phase 1: 10 min (init project)
- Phase 2: 50 min (define 4 features)
- Phase 3: 30 min (plan 4 features)
- Phase 5: 20 min (monitoring, status checks)

**= ~2 hours of your time** to define complete product

**VK Execution Time**: Varies, but parallel execution significantly faster than sequential.

---

## Common Scenarios

### Scenario 1: Starting Fresh Project

```bash
cd ~/Projects/new-project
/vk-init-project
/vk-feature "First feature"
/vk-plan
# VK executes
/vk-status
```

**Time**: ~1 hour to define and plan, then VK builds

---

### Scenario 2: Adding Features to Existing Project

**If project not VK-enabled yet:**

```bash
cd ~/Projects/existing-project
/vk-init-project
# Choose: "Existing project, integrate VK"
```

**Then:**

```bash
/vk-feature "New feature"
/vk-plan
# VK executes new work
```

**Existing code untouched**, new features via VK.

---

### Scenario 3: Complex Feature Needs Phasing

**If `/vk-plan` shows 50+ subtasks:**

```
⚠️ This feature appears very complex.
Estimated: 12 epics, 58 subtasks

Recommendation: Break into phases

Options:
B) Break into Feature Phase 1, Phase 2, etc.
```

**Choose B:**

```
Phase 1: Core Functionality
- Epic 1: Essential epic
- Epic 2: Essential epic
(8 epics, 28 subtasks)

Phase 2: Advanced Features
(4 epics, 18 subtasks)

Plan Phase 1 now?
```

**Plan Phase 1**, let VK execute, then plan Phase 2.

---

### Scenario 4: Quick Bug Fix

**During development, find a bug:**

**VK-spawned CC instance can:**

```bash
/fix-bug "Upload fails for files > 10MB"
```

**Or manually fix and commit** - VK is flexible.

---

### Scenario 5: Documentation Falling Behind

**If doc subtasks not executed:**

```bash
/vk-sync-docs
```

**Claude reads VK progress, updates `.agent/system/`**

**Better**: Don't skip doc subtasks!

---

## Best Practices

### Product Definition (Phase 1)

✅ **DO:**
- Spend time on product vision (guides everything)
- Provide mockups/designs if available
- Be specific about users and goals
- Include constraints (budget, timeline)

❌ **DON'T:**
- Rush this phase
- Be vague about vision
- Skip user definition

---

### Feature Definition (Phase 2)

✅ **DO:**
- Define multiple features before planning
- Take time for thorough requirements
- Include edge cases
- Define success metrics
- Use EARS format (guided by `/vk-feature`)

❌ **DON'T:**
- Jump straight to implementation
- Skip edge cases
- Make requirements vague
- Forget out-of-scope items

---

### Planning (Phase 3)

✅ **DO:**
- Review Claude's breakdown carefully
- Request changes if needed
- Ensure epics deliver value
- Verify 1-point subtasks
- Accept auto-generated doc/test subtasks

❌ **DON'T:**
- Blindly accept without review
- Remove doc subtasks
- Remove test subtasks
- Allow multi-point subtasks

---

### Execution (Phase 4)

✅ **DO:**
- Let VK work (it's automated)
- Check `/vk-status` periodically
- Review completed work
- Run tests
- Check documentation updates

❌ **DON'T:**
- Micromanage VK
- Interfere with git worktrees
- Skip code review
- Ignore test failures

---

### Monitoring (Phase 5)

✅ **DO:**
- Run `/vk-status` regularly
- Celebrate completed epics
- Plan next features proactively
- Keep documentation synced
- Review and iterate

❌ **DON'T:**
- Obsessively check status (hourly is too much)
- Let features pile up unplanned
- Ignore documentation health

---

## Troubleshooting

### "VK connection failed"

**Issue**: Can't connect to Vibe Kanban

**Checks:**
1. Is VK running?
2. MCP server configured?
3. Claude Code MCP settings correct?

**Solution**:
```bash
# Check VK status
# Restart VK if needed
# Verify MCP configuration
```

---

### "Feature is too complex"

**Issue**: `/vk-plan` generating 50+ subtasks

**Solution:**
- Break feature into phases
- Or split into multiple features
- Each phase should be 10-30 subtasks

---

### "Documentation is outdated"

**Issue**: `.agent/system/` doesn't reflect completed work

**Cause**: Doc subtasks not executed

**Solution:**
```bash
/vk-sync-docs
```

**Prevention**: Don't skip doc subtasks in VK

---

### "Subtask taking too long"

**Issue**: 1-point subtask taking >3 hours

**Possible causes:**
- Actually multi-point (mislabeled)
- Unexpected complexity
- Missing dependencies

**Solution:**
- Stop and reassess
- Break into smaller subtasks
- Document blocker
- Ask for help

---

### "Not sure what to do next"

**Solution:**
```bash
/vk-status
```

**Shows:**
- Current progress
- Next recommended actions
- Clear guidance

---

## FAQ

### Q: Do I need to use VK for everything?

**A**: No! Use VK when it makes sense:
- Complex features
- Want parallel execution
- Team environments

For simple, linear work, standard workflow is fine.

---

### Q: Can I mix VK and standard workflows?

**A**: Yes, per project:
- Some projects VK-enabled
- Some projects standard workflow
- Not mixed within same project

---

### Q: What if VK makes a mistake?

**A**: Review completed work:
- Check tests (should catch issues)
- Review code (normal code review)
- Fix bugs with `/fix-bug`
- Document issues with `/document-issue`

---

### Q: How do I know if a subtask is really 1 point?

**A**: Ask:
- Can be done in 1-2 hours?
- Single responsibility?
- 2-3 files modified max?
- Testable independently?

If NO to any, break down further.

---

### Q: What if I don't want TDD?

**A**: Test subtasks can come after implementation:
```
Epic
├─ Implementation [1pt]
├─ Tests for it [1pt]
└─ More implementation [1pt]
```

Flexibility exists, but having separate test subtasks is still valuable.

---

### Q: Can I modify VK tasks after creation?

**A**: Yes, in VK interface:
- Edit task descriptions
- Reorder subtasks
- Add/remove subtasks
- Adjust priorities

VK is flexible tool, not rigid system.

---

### Q: How do I learn more?

**A**: Resources:
- This guide (you're reading it!)
- Technical SOP: `~/.claude/workflow/sops/vk-integration.md`
- Project CLAUDE.md (per-project instructions)
- Run `/vk-status` (it guides you)

---

## Key Takeaways

1. **5 Phases**: Define → Features → Plan → Execute → Monitor
2. **Your Time**: Mostly Phase 1-2 (defining), VK does Phase 4 (building)
3. **1-Point Rule**: Critical for VK workflow success
4. **Documentation**: Automatic via doc subtasks
5. **Testing**: Separate subtasks, TDD-friendly
6. **Flexible**: Use when beneficial, not dogmatic

---

## Next Steps

**Ready to try?**

1. **Start small**: Simple project, 1-2 features
2. **Run through phases**: Init → Feature → Plan → Execute
3. **Monitor with `/vk-status`**
4. **Learn and adjust**: Iterate on process

**Then scale up** to more complex products.

---

## Example Prompts to Get Started

```bash
# Initialize new project
cd ~/Projects/my-idea
/vk-init-project

# Define first feature
/vk-feature "User can sign up with email and password"

# Plan it
/vk-plan

# Check status
/vk-status

# Sync docs
/vk-sync-docs
```

**That's it! You're building with VK-Claude workflow.**

---

**Happy Building!** 🚀

**Questions?** Check:
- `/vk-status` (guidance)
- `~/.claude/workflow/sops/vk-integration.md` (technical)
- `CLAUDE.md` (per-project)

**Last Updated**: 2025-10-27
