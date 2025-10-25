You are providing a comprehensive project status report.

**Read these documents:**
1. `.agent/README.md` - Documentation index
2. `.agent/system/overview.md` - Project overview and status
3. `.agent/tasks/` - All task documents (focus on recent ones)
4. Git branch status (run `git branch` and `git status`)

**Generate a status report with:**

## 📋 Recent Tasks (Last 5)
For each task, show:
- Task number and name
- Status (✅ Complete, 🔄 In Progress, ⚠️ Planned)
- Completion date (if complete)

## 🔧 Current Work
- Which task is currently in progress? (status = 🔄)
- Which git branch are we on?
- Any uncommitted changes?

## ✅ Project Completions
Summary of what's been built:
- Total tasks completed
- Key features delivered
- Current test coverage (if available in docs)

## 📊 Project Health
- Are docs up to date? (check last modified dates)
- Any tasks marked "In Progress" for > 1 week? (check dates)
- Git workflow clean? (on main, no uncommitted changes)

## 🎯 Next Steps
From `.agent/system/overview.md`:
- What's planned next?
- Any decisions still TBD?
- What's blocking progress?

## 🔍 Quick Stats
- Total tasks: X (✅ Complete: Y, 🔄 In Progress: Z, ⚠️ Planned: W)
- Documentation files: Count from `.agent/`
- Current git branch
- Last commit date

**Format example:**
```
📋 RIMAS DAM - PROJECT STATUS

Recent Tasks:
- ✅ 05 - Tailwind Migration (Completed Oct 16)
- ✅ 04 - UI Redesign (Completed Oct 15)
- ✅ 03 - Authentication (Completed Oct 15)
- ✅ 02 - Add Testing (Completed Oct 14)
- ✅ 01 - Basic Asset Models (Completed Oct 14)

Current Work:
🔄 No task currently in progress
📌 Branch: main
✅ Working directory clean

Project Health:
✅ All tasks up to date
✅ Documentation recently updated
✅ Git workflow clean
📊 Test Coverage: 88% (114 tests)

Next Steps:
- Refine models after kickoff meeting
- Implement user roles and permissions
- Add audio metadata extraction

Quick Stats:
- Total Tasks: 6 (✅ 6 Complete, 🔄 0 In Progress, ⚠️ 0 Planned)
- Documentation: 15 files
- Last Commit: Today
```

**After showing status:**
Ask if user wants to:
- Start a new feature (`/plan-task`)
- Review documentation (`/review-docs`)
- View specific task details