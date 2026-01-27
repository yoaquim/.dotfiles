# Context Loaders

Context loaders are hooks that inject relevant information into Claude Code's context at the right time.

---

## Overview

Context loaders use `UserPromptSubmit` hooks to:
- Detect when specific context is needed
- Load relevant files or information
- Inject it into the conversation

**Key principle**: Load context **selectively** to avoid bloating Claude's context window.

---

## Selective Loading Pattern

**Don't**: Load everything on every prompt
```bash
# BAD: Loads all features every time
cat .agent/features/*/README.md
```

**Do**: Load only when relevant
```bash
# GOOD: Only loads when implementing
if echo "$CLAUDE_PROMPT" | grep -qE "(/implement|/test|working on task)"; then
  head -50 .agent/tasks/*.md 2>/dev/null | head -1
fi
```

---

## Recommended Context Loaders

### 1. Project Overview (Lightweight)

Load basic project context for new sessions.

```json
{
  "hooks": {
    "UserPromptSubmit": [
      {
        "matcher": ".*",
        "hooks": [{
          "type": "command",
          "command": "head -20 .agent/system/overview.md 2>/dev/null || true"
        }]
      }
    ]
  }
}
```

**Output**: First 20 lines of project overview (~500 tokens max)

### 2. Current Task (On Demand)

Load current task only when implementing.

```json
{
  "hooks": {
    "UserPromptSubmit": [
      {
        "matcher": "/implement|working on",
        "hooks": [{
          "type": "command",
          "command": "cat .agent/tasks/$(cat .agent/.current-task 2>/dev/null) 2>/dev/null || echo 'No current task set'"
        }]
      }
    ]
  }
}
```

### 3. Feature Context (When Testing)

Load feature requirements when testing.

```json
{
  "hooks": {
    "UserPromptSubmit": [
      {
        "matcher": "/test|/bug|testing",
        "hooks": [{
          "type": "command",
          "command": "if [ -f .agent/.last-feature ]; then head -50 \".agent/features/$(cat .agent/.last-feature)/README.md\" 2>/dev/null; fi"
        }]
      }
    ]
  }
}
```

### 4. Git Status (On Git Commands)

Load git context when working with git.

```json
{
  "hooks": {
    "UserPromptSubmit": [
      {
        "matcher": "git|commit|push|branch|merge",
        "hooks": [{
          "type": "command",
          "command": "echo '--- Git Status ---' && git status --short 2>/dev/null | head -10"
        }]
      }
    ]
  }
}
```

### 5. Known Issues (On Debugging)

Load known issues when debugging.

```json
{
  "hooks": {
    "UserPromptSubmit": [
      {
        "matcher": "bug|error|issue|debug|fix",
        "hooks": [{
          "type": "command",
          "command": "echo '--- Known Issues ---' && ls .agent/known-issues/*.md 2>/dev/null | head -5"
        }]
      }
    ]
  }
}
```

---

## Anti-Patterns to Avoid

### 1. Loading All Features
```json
// DON'T
{
  "matcher": ".*",
  "hooks": [{
    "type": "command",
    "command": "cat .agent/features/*/README.md"
  }]
}
```
**Problem**: Could be thousands of tokens, loaded every prompt.

### 2. Loading Full Task History
```json
// DON'T
{
  "matcher": ".*",
  "hooks": [{
    "type": "command",
    "command": "cat .agent/tasks/*.md"
  }]
}
```
**Problem**: Task history grows unbounded.

### 3. Auto-Loading Large Files
```json
// DON'T
{
  "matcher": ".*",
  "hooks": [{
    "type": "command",
    "command": "cat src/**/*.ts"
  }]
}
```
**Problem**: Source code can be massive.

### 4. Unconditional Context
```json
// DON'T
{
  "matcher": ".*",
  "hooks": [{
    "type": "command",
    "command": "cat architecture.md && cat api-docs.md && cat style-guide.md"
  }]
}
```
**Problem**: Not all prompts need all this context.

---

## Context Budget

Keep total hook output under **~1000 tokens**:

| Content Type | Recommended Limit |
|--------------|-------------------|
| Project overview | ~20 lines (500 tokens) |
| Current task | ~50 lines (300 tokens) |
| Git status | ~10 lines (100 tokens) |
| File lists | ~10 items (100 tokens) |

**Total**: ~1000 tokens max per prompt

---

## Conditional Loading Scripts

### Multi-Condition Loader

```bash
#!/bin/bash
# Save as ~/.claude/hooks/smart-loader.sh

# Only output if conditions match
output=""

# Project overview on any prompt (minimal)
if [ -f ".agent/system/overview.md" ]; then
  output+="--- Project ---\n"
  output+="$(head -10 .agent/system/overview.md)\n"
fi

# Task context only when implementing
if echo "$CLAUDE_PROMPT" | grep -qE "implement|build|create|add"; then
  if [ -f ".agent/.current-task" ]; then
    task=$(cat .agent/.current-task)
    if [ -f ".agent/tasks/$task" ]; then
      output+="\n--- Current Task ---\n"
      output+="$(head -30 .agent/tasks/$task)\n"
    fi
  fi
fi

# Known issues only when debugging
if echo "$CLAUDE_PROMPT" | grep -qE "bug|error|fix|debug"; then
  issues=$(ls .agent/known-issues/*.md 2>/dev/null | wc -l)
  if [ "$issues" -gt 0 ]; then
    output+="\n--- Known Issues ($issues) ---\n"
    output+="$(ls .agent/known-issues/*.md | head -5)\n"
  fi
fi

# Output if we have something
if [ -n "$output" ]; then
  echo -e "$output"
fi
```

**Configuration:**
```json
{
  "hooks": {
    "UserPromptSubmit": [
      {
        "matcher": ".*",
        "hooks": [{
          "type": "command",
          "command": "bash ~/.claude/hooks/smart-loader.sh"
        }]
      }
    ]
  }
}
```

---

## Project-Specific Loaders

For project-specific context, use `<project>/.claude/settings.local.json`:

### Django Project
```json
{
  "hooks": {
    "UserPromptSubmit": [
      {
        "matcher": "model|migration|django",
        "hooks": [{
          "type": "command",
          "command": "echo '--- Models ---' && ls */models.py 2>/dev/null"
        }]
      }
    ]
  }
}
```

### React Project
```json
{
  "hooks": {
    "UserPromptSubmit": [
      {
        "matcher": "component|hook|state",
        "hooks": [{
          "type": "command",
          "command": "echo '--- Components ---' && ls src/components/*.tsx 2>/dev/null | head -10"
        }]
      }
    ]
  }
}
```

---

## When to Use Subagents Instead

Prefer **subagents** over **hooks** when:

| Situation | Use Hooks | Use Subagents |
|-----------|-----------|---------------|
| < 1000 tokens | ✓ | |
| > 1000 tokens | | ✓ |
| Simple file read | ✓ | |
| Search/exploration | | ✓ |
| Static context | ✓ | |
| Dynamic analysis | | ✓ |

**Example**: Reading ROADMAP.md for `/feature` command

Hook approach (if small):
```json
{
  "matcher": "/feature",
  "hooks": [{
    "type": "command",
    "command": "head -30 .agent/ROADMAP.md 2>/dev/null"
  }]
}
```

Subagent approach (if large or needs analysis):
```
In the /feature command, use Task tool with subagent_type="Explore":
"Read .agent/ROADMAP.md and extract items related to [topic]. Return a brief summary."
```

---

## Debugging Context Loaders

### Check Output Size
```bash
# Test your loader command and count output
your_loader_command | wc -c  # Should be < 4000 characters (~1000 tokens)
```

### Test Conditional Matching
```bash
# Test pattern matching
CLAUDE_PROMPT="implement the login feature"
if echo "$CLAUDE_PROMPT" | grep -qE "implement|build"; then
  echo "Would load task context"
fi
```

### Verify in Claude Code
1. Add a debug line to your loader: `echo "DEBUG: Loader fired"`
2. Run a matching prompt
3. Check if debug output appears
4. Remove debug line after testing

---

## Best Practices Summary

| Do | Don't |
|----|-------|
| Load selectively based on prompt | Load everything every time |
| Use `head` to limit output | Cat entire files |
| Handle missing files gracefully | Let commands fail loudly |
| Keep output under 1000 tokens | Inject thousands of tokens |
| Use subagents for heavy reading | Use hooks for large files |
| Test patterns before deploying | Deploy untested hooks |
