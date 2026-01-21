# Bug Severity Guide

Quick reference for categorizing bug severity.

## Severity Levels

### Critical
**Impact**: System unusable, data loss, security vulnerability

**Examples**:
- Login fails for all users
- Data corruption or loss
- Authentication bypass
- Payment processing completely broken
- Production database accessible without auth

**Response**: Fix immediately, potentially outside normal workflow

---

### High
**Impact**: Major functionality broken, no workaround, blocks core user journey

**Examples**:
- Can't save changes (data not persisted)
- Payment fails after user completes checkout
- Critical feature returns 500 errors
- User session ends unexpectedly
- Core API endpoint returns wrong data

**Response**: Prioritize over new features, fix within 24-48 hours

---

### Medium
**Impact**: Feature partially works, workaround exists, secondary flow affected

**Examples**:
- Slow page load (5+ seconds)
- Occasional timeout on specific action
- UI glitch that doesn't block functionality
- Export feature produces slightly wrong format
- Search returns results but sorting is wrong

**Response**: Schedule for next sprint, fix within a week

---

### Low
**Impact**: Minor inconvenience, cosmetic, rare edge case

**Examples**:
- Typo in UI text
- Alignment issue in footer
- Tooltip shows wrong text
- Edge case with < 1% of users
- Cosmetic issue only visible on one browser

**Response**: Add to backlog, fix when convenient

---

## Quick Decision Matrix

| Question | If Yes → |
|----------|----------|
| Is the system completely unusable? | Critical |
| Could this cause data loss or security issues? | Critical |
| Is a core feature completely broken? | High |
| Is there no workaround? | High |
| Does it affect most users? | High |
| Can users accomplish their goal despite the bug? | Medium |
| Is it primarily a cosmetic issue? | Low |
| Does it only affect edge cases? | Low |

## When in Doubt

- Ask: "How many users are affected?"
- Ask: "Can users accomplish their goal another way?"
- Ask: "What's the business impact?"

Default to one level higher if uncertain - it's better to over-prioritize than miss a critical issue.
