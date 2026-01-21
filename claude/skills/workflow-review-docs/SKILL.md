---
description: Comprehensive review of .agent documentation for accuracy and consistency
allowed-tools: Read, Grep, Glob, Bash(ls*), Bash(git*)
---

You are performing a comprehensive review of `.agent` documentation for accuracy, consistency, and completeness.

---

## Review All Documentation In

- `.agent/README.md`
- `.agent/CLAUDE.md` (if exists)
- `.agent/system/*.md`
- `.agent/features/*/README.md` (numbered feature directories)
- `.agent/tasks/*.md`
- `.agent/sops/*.md`

---

## Check for These Issues

### 1. Outdated Information
- [ ] Status markers not matching reality
- [ ] Completion dates missing on completed tasks
- [ ] "Current State" doesn't match actual codebase
- [ ] Tech stack listed doesn't match actual setup
- [ ] File structure diagrams out of sync
- [ ] Database schema doesn't match models

### 2. Inconsistencies
- [ ] Task numbers out of sequence
- [ ] Conflicting information between documents
- [ ] Different terminology for same concepts
- [ ] Status markers differ between README and task docs
- [ ] Git references missing or incorrect
- [ ] Feature directories not properly numbered
- [ ] Tasks reference non-existent features

### 3. Missing Information
- [ ] Features without README.md in their directories
- [ ] Tasks without completion dates
- [ ] Tasks without git references (branch, commits)
- [ ] Missing cross-references between related docs
- [ ] Tasks don't reference their feature requirements
- [ ] Success criteria not checked off
- [ ] Test results not documented
- [ ] Implementation summaries missing

### 4. Documentation Gaps
- [ ] New features not reflected in System docs
- [ ] SOPs not created for new processes
- [ ] README.md index incomplete
- [ ] Task templates not followed

### 5. Git Workflow Issues
- [ ] Tasks merged but not marked complete
- [ ] Branch references incorrect
- [ ] Commit hashes not documented

---

## Generate Review Report

```
DOCUMENTATION REVIEW REPORT

Critical Issues (Must Fix):
- [List any critical outdated info or broken references]

Improvements Needed:
- [List inconsistencies or missing info]

Suggestions:
- [List optional improvements]

Well Documented:
- [Note what's good/complete]

Stats:
- Total tasks: X (Y marked complete)
- System docs: X files
- SOP docs: X files
- Last updated: [most recent doc change]
```

---

## For Each Issue Found

- Specify the file and section
- Explain what's wrong or missing
- Suggest specific fix

---

## After Review

Ask if user wants to:
- Fix issues automatically (you'll update docs)
- Review specific sections in detail
- Continue with current state
