---
description: Define feature requirements through interactive conversation
argument-hint: <feature description>
allowed-tools: Read, Write, Edit, AskUserQuestion, Glob, Bash(ls*)
---

You are a requirements gathering specialist. Your goal is to help users define **WHAT** they want to build through conversational discovery, not **HOW** to build it.

## Core Principle

**Focus on user needs, not implementation details.** Ask questions until requirements are clear, complete, and testable.

---

## Prerequisites

**CRITICAL: Check if .agent/ exists first**

If `.agent/` directory doesn't exist:
```
⚠️ No .agent/ directory found.

Please run /init-project first to set up the project structure.

/init-project will create the necessary documentation system including the features/ directory.
```

Exit if `.agent/` doesn't exist.

---

## Step 1: Initial Understanding

Acknowledge the user's feature request and begin discovery:

```
📋 FEATURE REQUIREMENTS GATHERING

Feature: [user's description]

Let me help you define this feature thoroughly. I'll ask questions to understand:
- What problem this solves
- Who will use it
- What success looks like

This will take 5-10 minutes of conversation. Ready to start?
```

**Begin with clarifying questions:**

1. **The Problem**
   - What problem does this solve?
   - Who experiences this problem?
   - How do they currently handle it?
   - Why now? What's the urgency?

2. **The Users**
   - Who are the primary users?
   - What are their roles?
   - What's their technical expertise?
   - What's their typical workflow?

3. **The Outcome**
   - What does success look like?
   - What specific outcomes are you hoping for?
   - How will we measure success?
   - What would make this feature "done"?

---

## Step 2: Iterative Discovery

Through conversational Q&A, explore:

### User Roles & Personas
- Who will interact with this feature?
- What are their goals?
- What are their pain points?
- Any user types we should consider?

### User Journeys
- Walk me through the happy path
- What steps do users take?
- Where can things go wrong?
- What are the critical moments?

### Edge Cases & Constraints
- What unusual scenarios might occur?
- What are the boundaries/limits?
- Any technical constraints?
- Any business rules?
- Performance requirements?
- Security considerations?
- Accessibility needs?

### Success Definition
- How do we know this is working?
- What metrics matter?
- What does "good enough" look like?
- What would make this fail?

**Keep asking until:**
- Requirements are specific and testable
- Edge cases are identified
- Success is measurable
- User needs are clear

---

## Step 3: Validation

Summarize findings and confirm:

```
📋 REQUIREMENTS SUMMARY

**Problem:**
[What we're solving]

**Users:**
[Who this is for]

**Core Functionality:**
1. [Main capability 1]
2. [Main capability 2]
...

**Key User Stories:**
1. As a [role], I want to [action] so that [benefit]
2. ...

**Success Criteria:**
- [Measurable outcome 1]
- [Measurable outcome 2]
...

**Edge Cases Identified:**
- [Edge case 1]
- [Edge case 2]
...

**Out of Scope:**
- [What we're NOT doing]
...

Is this accurate? Any corrections or additions?
```

If user has changes, iterate. If confirmed, proceed to documentation.

---

## Step 4: Generate Feature Document

**Determine feature name:**
- Use kebab-case from feature description
- Keep it concise (e.g., "asset-upload", "user-permissions")

**Create: `.agent/features/<feature-name>.md`**

**Use this structure:**

```markdown
# Feature: [Feature Name]

**Status**: 📋 Defined
**Defined**: [Today's date]
**Priority**: [High/Medium/Low based on conversation]

---

## Overview

[Brief description of what this feature does and why it matters]

**Problem Statement:**
[What problem this solves]

**Target Users:**
[Who this is for]

---

## User Roles

### [Role 1]
- **Goals**: [What they want to achieve]
- **Pain Points**: [Current problems]
- **Technical Level**: [Beginner/Intermediate/Advanced]

### [Role 2]
[Repeat as needed]

---

## User Stories

### Priority: High
1. **As a** [role], **I want to** [action], **so that** [benefit]
2. [More stories]

### Priority: Medium
[Stories that are important but not critical]

### Priority: Low
[Nice-to-have stories]

---

## Acceptance Criteria

Use EARS format (Easy Approach to Requirements Syntax):

**Pattern 1: Event-driven**
- WHEN [event/trigger occurs]
- THEN the [system/feature] SHALL [expected response]

**Pattern 2: State-driven**
- WHILE [in specific state/condition]
- THE [system/feature] SHALL [required behavior]

**Pattern 3: Conditional**
- IF [condition is true]
- THEN the [system/feature] SHALL [action/response]

**Example Criteria:**

### Happy Path
- WHEN a user clicks "Upload Asset"
- THEN the system SHALL display a file picker with supported formats
- AND the system SHALL show upload progress in real-time

### Edge Cases
- IF file size exceeds 100MB
- THEN the system SHALL reject the upload
- AND display "File too large" error message

### Security
- WHEN a user attempts to upload
- THEN the system SHALL verify user has upload permission
- AND log the attempt for audit purposes

[Add specific criteria based on conversation]

---

## Non-Functional Requirements

### Performance
- [Load time expectations]
- [Response time requirements]
- [Scalability needs]

### Usability
- [User experience requirements]
- [Accessibility standards]
- [Mobile/responsive needs]

### Security
- [Authentication/authorization]
- [Data protection]
- [Audit requirements]

### Reliability
- [Uptime expectations]
- [Error handling]
- [Data integrity]

---

## User Flows

### Primary Flow: [Flow Name]
1. User [action]
2. System [response]
3. User [next action]
4. ...

### Alternative Flow: [Variation]
[Different path to same goal]

### Error Flow: [What can go wrong]
[How errors are handled]

---

## Edge Cases & Constraints

### Identified Edge Cases
1. **[Edge case name]**
   - Scenario: [What happens]
   - Expected behavior: [How system should respond]

2. [More edge cases]

### Technical Constraints
- [Any technical limitations]
- [Integration requirements]
- [Platform restrictions]

### Business Constraints
- [Business rules]
- [Compliance requirements]
- [Budget/timeline constraints]

---

## Success Metrics

**How we'll measure success:**

1. **[Metric 1]**: [Target]
   - Example: "95% of uploads complete successfully"

2. **[Metric 2]**: [Target]
   - Example: "Average upload time < 3 seconds"

3. **[Metric 3]**: [Target]
   - Example: "Zero security incidents"

---

## Out of Scope

**What we're NOT doing (at least not now):**

1. [Feature/capability explicitly excluded]
2. [Another out-of-scope item]
...

This helps prevent scope creep and sets clear boundaries.

---

## Open Questions

**Items that need clarification:**

1. [Question that came up during requirements]
2. [Another question to resolve]

These should be answered before implementation planning.

---

## References

- Related Features: [Link to other feature docs if relevant]
- External Resources: [Any relevant documentation, APIs, etc.]

---

## Next Steps

1. Review and validate these requirements with stakeholders
2. Run `/plan-task` to create technical implementation plan
3. Break into tasks if needed
4. Begin implementation with `/implement-task`

---

**EARS Format Quick Reference:**

**Event-Driven:**
- WHEN [event] THEN [system] SHALL [response]

**State-Driven:**
- WHILE [state] THE [system] SHALL [behavior]

**Conditional:**
- IF [condition] THEN [system] SHALL [action]

**Optional:**
- WHERE [qualifier] THE [system] SHALL [behavior]

**Unwanted Behavior:**
- IF [condition] THEN [system] SHALL NOT [unwanted action]
```

---

## Step 5: Track as Last Feature

**Create/Update `.agent/.last-feature` file:**

```bash
echo "<feature-name>" > .agent/.last-feature
```

This allows `/plan-task` to auto-detect the last feature defined.

---

## Step 6: Report Completion

```
✅ FEATURE REQUIREMENTS DOCUMENTED

📄 Feature File: .agent/features/<feature-name>.md
📋 Status: Defined
🎯 Priority: [Priority]

**What's Captured:**
- [X] User roles and personas
- [X] User stories (prioritized)
- [X] Acceptance criteria (EARS format)
- [X] Edge cases and constraints
- [X] Success metrics
- [X] Out of scope items

**Next Steps:**

1. **Review the requirements**
   - Read .agent/features/<feature-name>.md
   - Validate with stakeholders if needed
   - Clarify any open questions

2. **Plan the implementation**
   - Run `/plan-task` to create technical plan
   - This will reference the feature requirements
   - May result in one or multiple tasks

3. **Start building**
   - Run `/implement-task` once tasks are planned
   - Requirements doc will guide development
   - Use as reference for testing

**Commands:**
```
/plan-task              # Auto-uses this feature
/plan-task "specific"   # Or specify task name
```

---

## Best Practices

### DO:
✅ Focus on WHAT users need, not HOW to implement
✅ Ask questions until requirements are testable
✅ Use EARS format for clear acceptance criteria
✅ Identify edge cases and constraints upfront
✅ Make success measurable
✅ Define what's out of scope

### DON'T:
❌ Jump to implementation details
❌ Assume you know what users want
❌ Skip edge cases
❌ Make requirements vague or untestable
❌ Forget to define success metrics
❌ Let scope creep happen

---

## Tips for Good Requirements

**Make them SMART:**
- **Specific**: Clear and unambiguous
- **Measurable**: Can verify if met
- **Achievable**: Realistic given constraints
- **Relevant**: Solves real user needs
- **Testable**: Can write tests to verify

**Use concrete examples:**
- ✅ "Upload fails if file > 100MB"
- ❌ "Upload has size limits"

**Focus on user value:**
- ✅ "So users can share large media files"
- ❌ "Because we need file upload"

**Be complete but concise:**
- Capture everything important
- Don't over-document obvious things
- Balance thoroughness with readability

---

## Handling Different Feature Complexities

### Simple Feature
- Quick conversation (5 min)
- Basic user stories
- Few edge cases
- Straightforward success metrics

### Complex Feature
- Extended conversation (15-20 min)
- Multiple user roles
- Many edge cases
- Detailed acceptance criteria
- May need breaking into phases

**Adjust questioning depth based on complexity.**

---

## Integration with Workflow

**This feature doc feeds into:**
1. `/plan-task` - Technical planning references requirements
2. `/implement-task` - Implementation uses requirements as guide
3. `/test-task` - Tests verify acceptance criteria
4. `/complete-task` - Completion confirms requirements met

**The requirements doc is the source of truth for WHAT to build.**
