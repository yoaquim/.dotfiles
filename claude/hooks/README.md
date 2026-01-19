# Claude Code Hooks

Hooks allow you to run shell commands in response to Claude Code events. They can be used for validation, context loading, logging, and automation.

---

## Overview

### What Are Hooks?

Hooks are shell commands that execute at specific points in Claude Code's workflow:
- **Before** a prompt is processed (`UserPromptSubmit`)
- **After** Claude finishes responding (`Stop`)

### Use Cases

| Use Case | Hook Type | Example |
|----------|-----------|---------|
| Block dangerous commands | UserPromptSubmit | Prevent force push to main |
| Load context | UserPromptSubmit | Inject project overview |
| Log activity | Stop | Record what was done |
| Validate changes | Stop | Run linter after edits |

---

## Hook Types

### UserPromptSubmit

Runs **before** Claude processes your prompt.

**Use for:**
- Validation guards (blocking dangerous operations)
- Context injection (loading relevant docs)
- Pre-flight checks

**Output handling:**
- stdout is prepended to the conversation
- Non-zero exit code blocks the prompt

### Stop

Runs **after** Claude finishes responding.

**Use for:**
- Logging and auditing
- Cleanup operations
- Post-processing

**Output handling:**
- stdout is shown to user
- Exit code doesn't affect Claude's response

---

## Configuration

Hooks are configured in `settings.local.json` files:

### Global Hooks
```
~/.claude/settings.local.json
```

Applies to all Claude Code sessions.

### Project Hooks
```
<project>/.claude/settings.local.json
```

Applies only when Claude Code is run in this project.

---

## Configuration Format

```json
{
  "hooks": {
    "UserPromptSubmit": [
      {
        "matcher": "regex pattern to match prompt",
        "hooks": [
          {
            "type": "command",
            "command": "shell command to run"
          }
        ]
      }
    ],
    "Stop": [
      {
        "matcher": ".*",
        "hooks": [
          {
            "type": "command",
            "command": "echo 'Claude finished'"
          }
        ]
      }
    ]
  }
}
```

### Fields

| Field | Description |
|-------|-------------|
| `matcher` | Regex pattern to match against the prompt/event |
| `hooks` | Array of hook definitions |
| `type` | Always `"command"` for now |
| `command` | Shell command to execute |

---

## Matcher Patterns

The `matcher` field is a regex that determines when hooks run:

| Pattern | Matches |
|---------|---------|
| `.*` | All prompts |
| `git push.*--force` | Force push commands |
| `/implement\|/test` | Implement or test commands |
| `^$` | Empty prompts only |

**Note:** Patterns match against the user's prompt text, not Claude's response.

---

## Environment Variables

Hooks have access to these environment variables:

| Variable | Description |
|----------|-------------|
| `CLAUDE_PROMPT` | The user's prompt text |
| `CLAUDE_PROJECT` | Current project directory |
| `CLAUDE_SESSION_ID` | Current session identifier |

**Example:**
```bash
if echo "$CLAUDE_PROMPT" | grep -q "/implement"; then
  cat .agent/tasks/current.md
fi
```

---

## Best Practices

### Keep Hooks Fast
- Target: < 100ms execution time
- Slow hooks degrade user experience
- Use async logging if needed

### Use Conditional Loading
```bash
# Only load when relevant
if echo "$CLAUDE_PROMPT" | grep -qE "(/implement|/test)"; then
  head -50 .agent/tasks/*.md 2>/dev/null
fi
```

### Don't Bloat Context
- Limit output to ~1000 tokens
- Use `head` to truncate large files
- Load summaries, not full documents

### Fail Gracefully
```bash
# Don't break if file doesn't exist
cat .agent/overview.md 2>/dev/null || true
```

### Test Before Deploying
- Test hooks in a scratch project first
- Verify they don't break normal workflow
- Check for edge cases (empty projects, etc.)

---

## Common Patterns

### Validation Guard
Block dangerous operations before they happen.

```json
{
  "matcher": "git push.*--force.*(main|master)",
  "hooks": [{
    "type": "command",
    "command": "echo 'BLOCKED: Force push to main/master is dangerous'"
  }]
}
```

### Context Loader
Load relevant context at session start.

```json
{
  "matcher": ".*",
  "hooks": [{
    "type": "command",
    "command": "head -20 .agent/system/overview.md 2>/dev/null || true"
  }]
}
```

### Conditional Context
Load context only for specific commands.

```json
{
  "matcher": "/implement|working on task",
  "hooks": [{
    "type": "command",
    "command": "cat .agent/tasks/$(cat .agent/.current-task 2>/dev/null) 2>/dev/null || true"
  }]
}
```

### Activity Logging
Log Claude Code activity for review.

```json
{
  "hooks": {
    "Stop": [{
      "matcher": ".*",
      "hooks": [{
        "type": "command",
        "command": "echo \"$(date): Session ended\" >> ~/.claude/activity.log"
      }]
    }]
  }
}
```

---

## Anti-Patterns

### Loading Too Much Context
```json
// DON'T: Loads all feature docs every time
{
  "matcher": ".*",
  "hooks": [{
    "type": "command",
    "command": "cat .agent/features/*/README.md"
  }]
}
```

### Slow Commands
```json
// DON'T: Network request on every prompt
{
  "matcher": ".*",
  "hooks": [{
    "type": "command",
    "command": "curl https://api.example.com/context"
  }]
}
```

### Silent Failures
```json
// DON'T: No error handling, breaks if file missing
{
  "command": "cat .agent/required-file.md"
}
```

---

## Debugging Hooks

### Check if hooks are running
Add a debug echo:
```json
{
  "command": "echo 'DEBUG: Hook fired' && your_actual_command"
}
```

### View hook output
Hook stdout is shown in the conversation - check for output there.

### Test matcher patterns
```bash
# Test if your regex matches
echo "your prompt" | grep -qE "your_pattern" && echo "Matches"
```

---

## Documentation Files

| File | Purpose |
|------|---------|
| `README.md` | This file - hooks overview |
| `validation-guards.md` | Examples of validation/blocking hooks |
| `context-loaders.md` | Examples of context injection hooks |

---

## Related

- Claude Code documentation: https://docs.anthropic.com/claude-code
- Settings configuration: `~/.claude/settings.local.json`
- Project settings: `<project>/.claude/settings.local.json`
