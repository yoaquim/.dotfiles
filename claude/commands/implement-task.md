---
description: Implement a documented task with feature branch workflow
argument-hint: [task-number|feature-name]
allowed-tools: Read, Edit, Write, Bash(git*), Bash(docker*), Bash(pytest*), Bash(npm*), Grep, Glob
---

You are implementing a documented task.

**Parameter**: Task number (e.g., `03`, accessed via `$1`) or feature name (e.g., `authentication`)
- If no parameter provided, find the most recently created task (highest number in `.agent/tasks/`)
- If parameter is a number, use that task (e.g., `03` → `.agent/tasks/03-authentication.md`)
- If parameter is text, search for task with matching filename

**CRITICAL: Read these documents FIRST (in order):**
1. `CLAUDE.md` - Core project instructions and principles
2. `.agent/README.md` - Documentation index
3. The specific task document being implemented (`.agent/tasks/XX-*.md`)
4. Feature requirements if referenced in task (`.agent/features/<feature>.md`)
5. All SOP documents referenced in the task
6. `.agent/system/architecture.md` - Technical architecture
7. `.agent/system/database-schema.md` - Database structure (if relevant)
8. Any other System docs mentioned in the task

**Before starting implementation:**
- Confirm which task is being implemented
- Read the entire task document thoroughly
- Understand the problem, solution, and implementation plan
- Note all success criteria (you'll verify these later)
- Review any dependencies or prerequisites

**Implementation approach:**
1. **Create feature branch** (follow `.agent/sops/branching-workflow.md`)
   - Branch name format: `feature/feature-name` or `fix/bug-name`
   - Always branch from up-to-date `main`

2. **Follow the implementation plan**
   - Complete each phase in order
   - Implement exactly as specified in task
   - Make frequent, descriptive commits
   - Follow commit message guidelines from branching-workflow.md

3. **Follow project principles**
   - SIMPLICITY FIRST - don't over-engineer
   - Follow existing patterns in the codebase
   - Use established conventions from SOPs
   - Write clean, readable code

4. **Test as you go**
   - Write tests for new functionality
   - Run existing tests frequently
   - Verify success criteria incrementally

5. **Commit strategy**
   - Commit logical chunks of work
   - Use descriptive commit messages
   - Reference task number if helpful

**Track your progress:**
- Update task document status to "🔄 In Progress"
- Check off completed items in success criteria as you go

**After implementation:**
- Report what was completed
- List commits made
- Note any deviations from plan (if any)

**🛑 STOP HERE - DO NOT CONTINUE 🛑**

**CRITICAL**: After implementation is complete, you MUST:
1. **STOP** - Do not run tests
2. **STOP** - Do not merge branches
3. **STOP** - Do not complete the task
4. **STOP** - Do not update documentation beyond marking task as "In Progress"
5. **WAIT** for the user to run `/test-task XXX` command

The user will explicitly run `/test-task XXX` when they are ready to test.

**If you encounter issues:**
- Document blockers or challenges
- Suggest solutions or alternatives
- Ask for guidance if plan needs adjustment