---
description: Comprehensive project status report with tasks, health, and next steps
allowed-tools: Read, Bash(git*), Bash(ls*), Glob
---

!git branch
!git status

You are providing a comprehensive project status report.

---

## Read These Documents

1. `.agent/README.md` - Documentation index
2. `.agent/system/overview.md` - Project overview and status
3. `.agent/features/` - Feature requirements (if exists)
4. `.agent/tasks/` - All task documents (focus on recent ones)
5. Git branch status (already captured via ! commands above)

---

## Generate Status Report

### Feature Requirements
Check `.agent/features/` directory:
- List defined features (numbered directories: 001-name/, 002-name/, etc.)
- Note which features have tasks
- Show last defined feature (from `.agent/.last-feature`)

### Recent Tasks (Last 5)
For each task, show:
- Task number and name
- Status (Complete, In Progress, Planned)
- Completion date (if complete)

### Current Work
- Which task is currently in progress?
- Which git branch are we on?
- Any uncommitted changes?

### Project Completions
Summary of what's been built:
- Total tasks completed
- Key features delivered
- Current test coverage (if available)

### Project Health
- Are docs up to date?
- Any tasks marked "In Progress" for > 1 week?
- Git workflow clean? (on main, no uncommitted changes)

### Next Steps
From `.agent/system/overview.md`:
- What's planned next?
- Any decisions still TBD?
- What's blocking progress?

### Quick Stats
- Total tasks: X (Complete: Y, In Progress: Z, Planned: W)
- Documentation files: Count from `.agent/`
- Current git branch
- Last commit date

---

## Format Example

```
PROJECT STATUS

Recent Tasks:
- [Complete] 05 - Tailwind Migration (Oct 16)
- [Complete] 04 - UI Redesign (Oct 15)
- [Complete] 03 - Authentication (Oct 15)

Current Work:
- No task currently in progress
- Branch: main
- Working directory clean

Project Health:
- All tasks up to date
- Documentation recently updated
- Git workflow clean
- Test Coverage: 88% (114 tests)

Next Steps:
- Refine models after kickoff meeting
- Implement user roles and permissions

Quick Stats:
- Total Tasks: 6 (Complete: 6, In Progress: 0, Planned: 0)
- Documentation: 15 files
- Last Commit: Today
```

---

## After Showing Status

Ask if user wants to:
- Define a new feature (`/feature`)
- Plan a task (`/workflow:plan-task`)
- Review documentation (`/workflow:review-docs`)
- View specific task details
