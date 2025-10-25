You are performing a comprehensive review of `.agent` documentation for accuracy, consistency, and completeness.

**Review all documentation in:**
- `.agent/README.md`
- `.agent/CLAUDE.md` (if exists)
- `.agent/system/*.md`
- `.agent/tasks/*.md`
- `.agent/sops/*.md`

**Check for these issues:**

## 1. Outdated Information
- [ ] Status markers not matching reality (task says "In Progress" but is actually complete)
- [ ] Completion dates missing on completed tasks
- [ ] "Current State" doesn't match actual codebase
- [ ] Tech stack listed doesn't match requirements.txt or actual setup
- [ ] File structure diagrams out of sync
- [ ] Database schema doesn't match models

## 2. Inconsistencies
- [ ] Task numbers out of sequence
- [ ] Conflicting information between documents
- [ ] Different terminology for same concepts
- [ ] Status markers differ between README and task docs
- [ ] Git references missing or incorrect

## 3. Missing Information
- [ ] Tasks without completion dates
- [ ] Tasks without git references (branch, commits)
- [ ] Missing cross-references between related docs
- [ ] Success criteria not checked off
- [ ] Test results not documented
- [ ] Implementation summaries missing on complex tasks

## 4. Documentation Gaps
- [ ] New features not reflected in System docs
- [ ] SOPs not created for new processes
- [ ] README.md index incomplete
- [ ] Task templates not followed
- [ ] SIMPLICITY principle violated (docs too verbose)

## 5. Git Workflow Issues
- [ ] Tasks merged but not marked complete
- [ ] Branch references incorrect
- [ ] Commit hashes not documented

**Generate a review report:**

```
📝 DOCUMENTATION REVIEW REPORT

🔴 Critical Issues (Must Fix):
- [List any critical outdated info or broken references]

🟡 Improvements Needed:
- [List inconsistencies or missing info]

🟢 Suggestions:
- [List optional improvements]

✅ Well Documented:
- [Note what's good/complete]

📊 Stats:
- Total tasks: X (✅ Y marked complete)
- System docs: X files
- SOP docs: X files
- Last updated: [most recent doc change]
```

**For each issue found:**
- Specify the file and section
- Explain what's wrong or missing
- Suggest specific fix

**After review:**
Ask if user wants to:
- Fix issues automatically (you'll update docs)
- Review specific sections in detail
- Continue with current state