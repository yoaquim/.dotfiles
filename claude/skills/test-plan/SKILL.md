---
description: Generate test plan and Playwright tests for a feature
argument-hint: <feature-number> [--run]
allowed-tools: Read, Write, Edit, Glob, Bash(ls*), Bash(mkdir*), AskUserQuestion, mcp__playwright__*
---

# Test Plan Command

Generate a comprehensive test plan and optional Playwright e2e tests for a feature.

**Syntax:**
```
/test-plan 001           # Generate test plan for feature 001
/test-plan 001 --run     # Generate and run via Playwright MCP
```

---

## Prerequisites

**Check if .agent/ exists first.**

---

## Step 1: Parse Arguments

**Extract:**
1. Feature identifier: `001`, `001-sidebar`, etc.
2. `--run` flag: Whether to execute tests immediately

**If no feature specified**, check `.agent/.last-feature`.

---

## Step 2: Find and Read Feature

**Locate feature directory:**
```bash
ls -d .agent/features/*/ 2>/dev/null
```

**Read feature document:**
`.agent/features/{num}-{name}/README.md`

**Extract:**
- Feature name and number
- Acceptance criteria
- User flows
- Edge cases
- Non-functional requirements

---

## Step 3: Create Test Plan Directory

```bash
mkdir -p .agent/test-plans
```

---

## Step 4: Analyze Feature for Test Scenarios

**Extract from feature document:**

### 1. Happy Path Scenarios
- Primary user flows
- Main success scenarios

### 2. Alternative Flows
- Secondary paths to success
- Different user roles

### 3. Error Handling Scenarios
- Invalid inputs
- Missing permissions
- System errors

### 4. Edge Cases
- Boundary conditions
- Empty states
- Large data sets

### 5. Non-Functional Tests
- Performance
- Accessibility
- Security

---

## Step 5: Generate Test Plan Document

**Create: `.agent/test-plans/{num}-{name}-test-plan.md`**

Use template from `~/.claude/scaffolds/templates/test-plan.md.template`.

---

## Step 6: Generate Playwright Spec File

**Determine test file location:**
```bash
ls -la tests/e2e/ 2>/dev/null || ls -la e2e/ 2>/dev/null
```

**Default location:** `tests/e2e/{feature-slug}.spec.ts`

**Generate spec file:**
```typescript
import { test, expect } from '@playwright/test';

test.describe('{Feature Name}', () => {
  test.beforeEach(async ({ page }) => {
    await page.goto('/');
  });

  test('should [happy path scenario]', async ({ page }) => {
    // Arrange, Act, Assert
  });

  test('should handle [error scenario]', async ({ page }) => {
    // Error handling test
  });
});
```

---

## Step 7: Run Tests (if --run flag)

**If `--run` flag provided:**

Use Playwright MCP tools:
1. `browser_navigate(url)`
2. `browser_snapshot()` - Verify starting state
3. `browser_click(element)` - User action
4. `browser_type(element, text)` - User input
5. `browser_snapshot()` - Verify result
6. Compare snapshot to expected
7. Record pass/fail

---

## Step 8: Report Completion

```
TEST PLAN GENERATED

Feature: {num} - {Feature Name}

Test Plan: .agent/test-plans/{num}-{name}-test-plan.md
Playwright Spec: tests/e2e/{feature-slug}.spec.ts

TEST SCENARIOS:

Happy Path:
  - Scenario 1
  - Scenario 2

Error Handling:
  - Scenario 3

Edge Cases:
  - Scenario 4

Total: X scenarios

NEXT STEPS:
1. Review test plan
2. Run tests: npx playwright test tests/e2e/{feature-slug}.spec.ts
3. Document any bugs: /bug {num}
```

---

## Playwright MCP Integration

### Available Tools

| Tool | Purpose |
|------|---------|
| `browser_navigate` | Navigate to URL |
| `browser_snapshot` | Capture accessibility tree |
| `browser_click` | Click elements |
| `browser_type` | Type text into inputs |
| `browser_fill_form` | Fill multiple form fields |
| `browser_take_screenshot` | Visual capture |
| `browser_wait_for` | Wait for text/elements |

### Handling Failures

When a test fails:
1. Take screenshot
2. Capture console messages
3. Record in test plan under "Bugs Found"
4. Suggest using `/bug {num}` to document

---

## Best Practices

### DO:
- Base scenarios on feature acceptance criteria
- Include both positive and negative tests
- Test at user story level, not implementation level
- Generate runnable Playwright code
- Map tests to acceptance criteria

### DON'T:
- Test implementation details
- Over-engineer test fixtures
- Skip error handling scenarios
- Forget accessibility tests
