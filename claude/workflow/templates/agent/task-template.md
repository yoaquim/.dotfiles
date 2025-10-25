# Task NNN: [Feature Name]

**Status**: ⚠️ Planned | 🔄 In Progress | ✅ Complete
**Branch**: `feature/feature-name` (or `fix/bug-name`)
**Priority**: High | Medium | Low
**Planned**: YYYY-MM-DD
**Started**: YYYY-MM-DD (or empty if not started)
**Completed**: YYYY-MM-DD (or empty if not complete)

## Problem

[Clear description of what needs to be solved or built]

**Current State:**
- What exists now?
- What's missing or broken?
- Why is this needed now?

**Pain Points:**
- Specific issues with current approach
- User impact or business impact
- Technical debt or limitations

## Solution

[High-level description of the proposed solution]

**Approach:**
- What will be built or changed?
- Key technical decisions
- How it solves the problem

**Benefits:**
- User benefits
- Technical benefits
- Business benefits

**Trade-offs:**
- What alternatives were considered?
- Why this approach over others?
- Any downsides or limitations?

## Implementation Plan

### Phase 1: [Phase Name]
[Description of what this phase accomplishes]

**Steps:**
1. Step one with specific file or action
2. Step two with specific file or action
3. Continue...

**Files to Create:**
- `path/to/new/file.py` - Purpose
- `path/to/another/file.html` - Purpose

**Files to Modify:**
- `existing/file.py` - What changes
- `another/file.js` - What changes

### Phase 2: [Phase Name]
[Continue with additional phases as needed]

### Phase 3: [Phase Name]
[As many phases as make sense]

### Phase N: Documentation
[Final phase should always be documentation]

**Update:**
1. Task document status and completion info
2. System documentation (list which files)
3. SOP documentation (if new processes introduced)
4. README.md index

## Success Criteria

- [ ] Criterion one (specific and testable)
- [ ] Criterion two
- [ ] All tests passing
- [ ] Test coverage target met (e.g., 80%+)
- [ ] Manual testing completed
- [ ] Documentation updated
- [ ] Git workflow followed
- [ ] Code reviewed (if applicable)

## Technical Decisions

### Decision 1: [Decision Title]
**Options Considered:**
- Option A: Description
- Option B: Description
- Option C: Description

**Chosen**: Option X

**Rationale**: Why this option was selected

**Trade-offs**: What we gain vs what we lose

### Decision 2: [Next Decision]
[Continue as needed]

## Testing Strategy

**Automated Tests:**
- Unit tests for [components]
- Integration tests for [workflows]
- Expected coverage: X%

**Manual Testing:**
- Test scenario 1
- Test scenario 2
- Edge cases to verify

**Test Commands:**
```bash
# Run tests
docker compose exec web pytest

# Run specific tests
docker compose exec web pytest apps/app_name/tests/

# With coverage
docker compose exec web pytest --cov=apps --cov-report=term
```

## Dependencies

**Requires:**
- Task NNN must be complete first (if applicable)
- External service or library (if needed)

**Blocks:**
- Task YY depends on this (if applicable)

## Documentation Updates

**System Docs:**
- `.agent/System/overview.md` - What sections need updating
- `.agent/System/architecture.md` - What changes
- `.agent/System/database-schema.md` - If models change

**SOP Docs:**
- `.agent/SOP/relevant-sop.md` - What updates
- Create new SOP if introducing new process

**README:**
- Update task list with new task

## Risks & Considerations

1. **Risk Name**
   - Description of risk
   - Mitigation strategy

2. **Consideration Name**
   - What to be aware of
   - How to handle

## Git Workflow

```bash
# Create feature branch
git checkout main
git pull origin main
git checkout -b feature/feature-name

# During implementation
git add [files]
git commit -m "Descriptive message"

# Push to remote
git push -u origin feature/feature-name

# After completion
git checkout main
git merge feature/feature-name
git push origin main
git branch -d feature/feature-name
```

## Quick Commands

```bash
# [List relevant commands for this task]
# For example:

# Run migrations (if database changes)
docker compose exec web python manage.py makemigrations
docker compose exec web python manage.py migrate

# Restart services
docker compose restart web

# Run tests
docker compose exec web pytest
```

## Priority Rationale

[Explain why this task has the assigned priority]

**[Priority Level] Priority** because:
- ✅ Reason supporting this priority
- ✅ Another reason
- ⚠️ Reason against higher priority
- ⚠️ Another consideration

**Recommended Timeline**: [When this should be implemented]

## Notes

[Any additional context, notes, or considerations]

- Important detail to remember
- Links to external resources
- Design mockups or references
- Anything else relevant

## Implementation Summary

**Completed**: YYYY-MM-DD (add after completion)

[Summary of what was actually implemented]

### Deliverables
- ✅ Item one actually delivered
- ✅ Item two
- ⚠️ Deviations from plan (if any)

### Files Created
- `path/to/file.py` - Description

### Files Modified
- `path/to/file.py` - What changed

### Git References
- **Branch**: `feature/feature-name`
- **Commits**: [List key commit hashes or summarize]
- **Merged**: YYYY-MM-DD

### Test Results
- Total tests: X passing
- Coverage: Y%
- Manual testing: All scenarios verified

### Challenges Encountered
[Any issues or deviations from plan]

1. **Challenge name**
   - Description
   - How it was resolved

### Final Notes
[Any closing thoughts or learnings]