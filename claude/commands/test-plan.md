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

**Check if .agent/ exists:**

```bash
ls -la .agent/ 2>/dev/null
```

If `.agent/` doesn't exist:
```
This project doesn't have a .agent/ directory.

Please run /setup first to initialize the project structure.
```

---

## Step 1: Parse Arguments

**Extract from command:**
1. **Feature identifier**: `001`, `001-sidebar`, etc.
2. **--run flag**: Whether to execute tests immediately

**If no feature specified:**
```bash
# Check for last feature
cat .agent/.last-feature 2>/dev/null
```

If no last feature:
```
No feature specified and no recent feature found.

Usage: /test-plan <feature-number>
       /test-plan 001
       /test-plan 001 --run
```

---

## Step 2: Find and Read Feature

**Locate feature directory:**

```bash
ls -d .agent/features/*/ 2>/dev/null
```

**Match the feature argument:**
- `001` → `.agent/features/001-*/`
- `001-sidebar` → `.agent/features/001-sidebar*/`

**If not found:**
```
Feature not found: [argument]

Available features:
[List feature directories]

Usage: /test-plan 001
```

**Read feature document:**
```
.agent/features/{num}-{name}/README.md
```

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

**From the feature document, extract:**

### 1. Happy Path Scenarios
- Primary user flows from the feature doc
- Main success scenarios
- Core functionality tests

### 2. Alternative Flows
- Secondary paths to success
- Different user roles or permissions
- Variations in input

### 3. Error Handling Scenarios
- Invalid inputs
- Missing permissions
- System errors
- Network failures

### 4. Edge Cases
- Boundary conditions
- Empty states
- Large data sets
- Concurrent operations

### 5. Non-Functional Tests
- Performance (load times, response times)
- Accessibility (keyboard nav, screen readers)
- Security (injection, unauthorized access)

---

## Step 5: Generate Test Plan Document

**Create: `.agent/test-plans/{num}-{name}-test-plan.md`**

**Use template from:** `~/.claude/workflow/templates/test-plan.md.template`

**Replace variables:**
- `{{FEATURE_NAME}}` → Feature name
- `{{FEATURE_NUMBER}}` → Feature number (e.g., 001)
- `{{FEATURE_DESCRIPTION}}` → From feature overview
- `{{FEATURE_SLUG}}` → kebab-case name
- `{{INIT_DATE}}` → Today's date
- `{{ENVIRONMENT}}` → Development/Staging
- `{{BROWSERS}}` → Chrome, Firefox, Safari
- `{{BASE_URL}}` → localhost or configured URL

**Populate test scenarios** based on feature analysis.

---

## Step 6: Generate Playwright Spec File

**Determine test file location:**

Check for existing test structure:
```bash
ls -la tests/e2e/ 2>/dev/null || ls -la e2e/ 2>/dev/null || ls -la playwright/ 2>/dev/null
```

**Default location:** `tests/e2e/{feature-slug}.spec.ts`

**Generate spec file:**

```typescript
import { test, expect } from '@playwright/test';

test.describe('{Feature Name}', () => {
  test.beforeEach(async ({ page }) => {
    // Setup: navigate to starting point
    await page.goto('/');
  });

  test('should [happy path scenario 1]', async ({ page }) => {
    // Arrange
    // ... setup steps

    // Act
    // ... user actions

    // Assert
    // ... verify expected outcomes
  });

  test('should [happy path scenario 2]', async ({ page }) => {
    // ... test implementation
  });

  test('should handle [error scenario]', async ({ page }) => {
    // ... error handling test
  });

  test('should handle [edge case]', async ({ page }) => {
    // ... edge case test
  });
});
```

**Best practices in generated tests:**
- Use `data-testid` attributes for selectors when possible
- Include meaningful test descriptions
- Add comments explaining non-obvious assertions
- Use page object patterns for complex pages

---

## Step 7: Ask Clarifying Questions (if needed)

**If feature requirements are ambiguous:**

Use `AskUserQuestion`:
```
question: "What is the expected behavior when [ambiguous scenario]?"
header: "Test Scenario"
options:
  - label: "[Option A]"
    description: "[What this means for testing]"
  - label: "[Option B]"
    description: "[What this means for testing]"
```

**Keep questions minimal** - prefer making reasonable assumptions based on feature doc.

---

## Step 8: Run Tests (if --run flag)

**If `--run` flag was provided:**

### Check Playwright MCP availability

Verify Playwright MCP tools are available:
- `mcp__playwright__browser_navigate`
- `mcp__playwright__browser_click`
- `mcp__playwright__browser_snapshot`

### Execute Test Scenarios

For each test scenario, use Playwright MCP tools:

```
1. Navigate to starting URL
2. Take initial snapshot
3. Execute test steps using:
   - mcp__playwright__browser_click
   - mcp__playwright__browser_type
   - mcp__playwright__browser_fill_form
4. Take snapshot after actions
5. Verify expected state
6. Record pass/fail
```

### Record Results

Update test plan document with:
- Pass/Fail status for each scenario
- Screenshots of failures
- Actual vs expected results

---

## Step 9: Report Completion

```
TEST PLAN GENERATED

Feature: {num} - {Feature Name}

Test Plan: .agent/test-plans/{num}-{name}-test-plan.md
Playwright Spec: tests/e2e/{feature-slug}.spec.ts

TEST SCENARIOS:

Happy Path:
  - Scenario 1: [Description]
  - Scenario 2: [Description]

Error Handling:
  - Scenario 3: [Description]
  - Scenario 4: [Description]

Edge Cases:
  - Scenario 5: [Description]

Total: X scenarios

[If --run was used]
TEST RESULTS:
  Passed: X
  Failed: X
  Blocked: X

[If tests failed]
BUGS FOUND:
  Use /bug {num} to document bugs discovered during testing.

NEXT STEPS:

1. Review test plan at .agent/test-plans/{num}-{name}-test-plan.md
2. Run tests: npx playwright test tests/e2e/{feature-slug}.spec.ts
3. Document any bugs: /bug {num}
4. Update test results in test plan
```

---

## Playwright MCP Integration

### Available Tools

| Tool | Purpose |
|------|---------|
| `browser_navigate` | Navigate to URL |
| `browser_snapshot` | Capture accessibility tree (better than screenshot for verification) |
| `browser_click` | Click elements |
| `browser_type` | Type text into inputs |
| `browser_fill_form` | Fill multiple form fields |
| `browser_take_screenshot` | Visual capture |
| `browser_wait_for` | Wait for text/elements |
| `browser_evaluate` | Run JavaScript |

### Test Execution Flow

```
1. browser_navigate(url)
2. browser_snapshot()           # Verify starting state
3. browser_click(element)       # User action
4. browser_type(element, text)  # User input
5. browser_snapshot()           # Verify result
6. Compare snapshot to expected
7. Record pass/fail
```

### Handling Failures

When a test fails:
1. Take screenshot: `browser_take_screenshot()`
2. Capture console: `browser_console_messages()`
3. Record in test plan under "Bugs Found"
4. Suggest using `/bug {num}` to document

---

## Generated File Structure

After running `/test-plan 001`:

```
.agent/
├── test-plans/
│   └── 001-feature-name-test-plan.md
├── features/
│   └── 001-feature-name/
│       └── README.md
tests/
└── e2e/
    └── feature-name.spec.ts
```

---

## Best Practices

### DO:
- Base scenarios on feature acceptance criteria
- Include both positive and negative tests
- Test at user story level, not implementation level
- Use meaningful test descriptions
- Generate runnable Playwright code
- Map tests to acceptance criteria

### DON'T:
- Test implementation details
- Over-engineer test fixtures
- Skip error handling scenarios
- Forget accessibility tests
- Generate tests without reading feature doc

---

## Integration with Bug Workflow

When bugs are found during testing:

1. Document in test plan "Bugs Found" section
2. Run `/bug {feature-num}` to create detailed bug documentation
3. Bugs are linked to the feature being tested
4. Bug fixes can be tracked and re-tested

---

## Example Usage

```
# Generate test plan for feature 001
/test-plan 001

# Generate and immediately run tests using Playwright MCP
/test-plan 001 --run

# Generate for most recent feature
/test-plan
```
