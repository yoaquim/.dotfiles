You are completing a task by updating documentation and verifying git workflow.

**Parameter**: Task number (e.g., `03`)
- If not provided, complete the most recently implemented task

**CRITICAL: Read these first:**
1. The task document (`.agent/tasks/XX-*.md`)
2. `CLAUDE.md` - Documentation standards
3. `.agent/sops/branching-workflow.md` - Git workflow

**Steps to complete a task:**

## 1. Update Task Document

Update `.agent/tasks/XX-*.md`:
- Change status from "🔄 In Progress" to "✅ Complete"
- Add completion date (today)
- Add final test results section with:
  - Total tests passing
  - Coverage percentage
  - Any issues found and resolved
- Add git references:
  - Branch name used
  - Commit hash(es)
  - Note if merged to main
- Check off all items in Success Criteria
- Add "Implementation Summary" section if complex task

## 2. Update System Documentation

Based on what changed, update relevant docs:

**`.agent/system/overview.md`:**
- Update "Current State" or "Project Status" section
- Move from "Next Steps" to completed features
- Update tech stack decisions if new tools added
- Update "Decisions Complete" or "Decisions TBD" sections

**`.agent/system/architecture.md`:**
- Update if technical architecture changed
- Add new components or services
- Update diagrams (if text-based)
- Update technology stack section
- Update file structure if new apps/directories added

**`.agent/system/database-schema.md`:**
- Update if models changed
- Add new tables/fields
- Update relationships
- Update migrations list

## 3. Update or Create SOP Documentation

If task introduced new processes or patterns:
- Update relevant SOP documents
- Or create new SOP if needed
- Reference new SOPs from task document

## 4. Update README.md Index

Update `.agent/README.md`:
- Ensure task is listed with "✅ Complete" status
- Update any status summaries
- Add references to new documents if created

## 5. Verify Git Workflow

Check git status:
- ✅ Feature branch created?
- ✅ All changes committed?
- ✅ Branch merged to main?
- ✅ Feature branch deleted?
- ✅ All commits pushed to remote?

If not merged yet:
```bash
# Merge to main
git checkout main
git pull origin main
git merge feature/feature-name
git push origin main

# Delete feature branch
git branch -d feature/feature-name
git push origin --delete feature/feature-name
```

## 6. Final Verification

Run through this checklist:
- [ ] Task document updated with ✅ Complete status
- [ ] Completion date added
- [ ] Test results documented
- [ ] Git references added
- [ ] System docs updated (overview, architecture, schema if applicable)
- [ ] SOP docs updated if needed
- [ ] README.md index updated
- [ ] Branch merged to main
- [ ] Feature branch deleted
- [ ] All changes pushed

**After completion:**
- Provide summary of all documentation updates
- Confirm git workflow is clean
- Ask if user wants to:
  - Start a new feature (use `/plan-task`)
  - Review documentation (use `/review-docs`)
  - Check project status (use `/status`)