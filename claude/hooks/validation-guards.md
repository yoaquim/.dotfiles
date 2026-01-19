# Validation Guards

Validation guards are hooks that prevent dangerous or unwanted operations before they happen.

---

## Overview

Validation guards use `UserPromptSubmit` hooks to:
- Match prompts containing risky commands
- Output a warning/blocking message
- Optionally block the operation entirely

---

## Recommended Guards

### 1. Prevent Force Push to Main/Master

**Risk**: Force pushing to main/master can destroy commit history and break the team.

```json
{
  "hooks": {
    "UserPromptSubmit": [
      {
        "matcher": "git push.*--force.*(main|master)",
        "hooks": [{
          "type": "command",
          "command": "echo 'BLOCKED: Force push to main/master is dangerous. Use a feature branch.'"
        }]
      }
    ]
  }
}
```

### 2. Warn About Credential Files in Git Add

**Risk**: Accidentally committing secrets.

```json
{
  "hooks": {
    "UserPromptSubmit": [
      {
        "matcher": "git add.*(\\.env|credentials|secrets|password)",
        "hooks": [{
          "type": "command",
          "command": "echo 'WARNING: You may be adding a credential file to git. Please verify this is intentional.'"
        }]
      }
    ]
  }
}
```

### 3. Warn About Committing on Main Branch

**Risk**: Direct commits to main bypass code review.

```json
{
  "hooks": {
    "UserPromptSubmit": [
      {
        "matcher": "git commit",
        "hooks": [{
          "type": "command",
          "command": "if [ \"$(git branch --show-current)\" = \"main\" ] || [ \"$(git branch --show-current)\" = \"master\" ]; then echo 'WARNING: You are committing directly to main/master branch.'; fi"
        }]
      }
    ]
  }
}
```

### 4. Prevent Destructive Git Operations

**Risk**: Hard resets and branch deletions can lose work.

```json
{
  "hooks": {
    "UserPromptSubmit": [
      {
        "matcher": "git reset --hard|git branch -D|git clean -fd",
        "hooks": [{
          "type": "command",
          "command": "echo 'WARNING: This is a destructive git operation. Make sure you have backups.'"
        }]
      }
    ]
  }
}
```

### 5. Block Production Database Operations

**Risk**: Accidentally modifying production data.

```json
{
  "hooks": {
    "UserPromptSubmit": [
      {
        "matcher": "(DROP|DELETE|TRUNCATE|UPDATE).*(prod|production)",
        "hooks": [{
          "type": "command",
          "command": "echo 'BLOCKED: Production database operations are not allowed via Claude Code.'"
        }]
      }
    ]
  }
}
```

---

## Configuration Example

Full `settings.local.json` with multiple guards:

```json
{
  "hooks": {
    "UserPromptSubmit": [
      {
        "matcher": "git push.*--force.*(main|master)",
        "hooks": [{
          "type": "command",
          "command": "echo 'BLOCKED: Force push to main/master is dangerous.'"
        }]
      },
      {
        "matcher": "git add.*(\\.env|credentials|secrets)",
        "hooks": [{
          "type": "command",
          "command": "echo 'WARNING: Possible credential file in git add.'"
        }]
      },
      {
        "matcher": "git reset --hard",
        "hooks": [{
          "type": "command",
          "command": "echo 'WARNING: Hard reset will lose uncommitted changes.'"
        }]
      },
      {
        "matcher": "rm -rf /|rm -rf ~|rm -rf \\*",
        "hooks": [{
          "type": "command",
          "command": "echo 'BLOCKED: Dangerous rm command detected.'"
        }]
      }
    ]
  }
}
```

---

## Creating Custom Guards

### Template

```json
{
  "matcher": "PATTERN_TO_MATCH",
  "hooks": [{
    "type": "command",
    "command": "echo 'YOUR_WARNING_OR_BLOCK_MESSAGE'"
  }]
}
```

### Steps

1. **Identify the risk**: What operation are you guarding against?
2. **Write the pattern**: Create a regex that matches the risky prompt
3. **Decide severity**: Warning (informational) vs Block (prevents action)
4. **Write the message**: Clear, actionable message for the user
5. **Test**: Try the pattern with sample prompts

### Pattern Tips

| Pattern | Matches |
|---------|---------|
| `keyword` | Anywhere in prompt |
| `^keyword` | At start of prompt |
| `keyword$` | At end of prompt |
| `word1.*word2` | word1 followed by word2 |
| `word1\|word2` | word1 OR word2 |
| `\\.ext` | Literal dot (escaped) |

---

## Warning vs Blocking

### Warning (Informational)
- Outputs message, operation continues
- Use for: awareness, reminders, soft policies
- Message should explain the concern

### Blocking (Prevent Action)
- Currently, hooks can't truly "block" - they just prepend warnings
- For hard blocks, you'd need Claude to respect the message
- Strong warning language helps: "BLOCKED:", "DO NOT:", etc.

**Note**: Claude Code respects hook output and typically won't proceed with operations marked as "BLOCKED" in hook messages.

---

## Project-Specific Guards

Put project-specific guards in:
```
<project>/.claude/settings.local.json
```

**Example**: Block certain migrations
```json
{
  "hooks": {
    "UserPromptSubmit": [
      {
        "matcher": "migrate.*--fake|migrate.*zero",
        "hooks": [{
          "type": "command",
          "command": "echo 'BLOCKED: Fake or zero migrations not allowed in this project.'"
        }]
      }
    ]
  }
}
```

---

## Testing Guards

### Test Pattern Matching

```bash
# Test if pattern matches
echo "git push --force origin main" | grep -qE "git push.*--force.*(main|master)" && echo "Matches"

# Test multiple patterns
patterns=("git push --force" "git add .env" "DROP TABLE users")
for p in "${patterns[@]}"; do
  echo "$p" | grep -qE "your_pattern" && echo "Matches: $p"
done
```

### Verify in Claude Code

1. Add the guard to your settings
2. Restart Claude Code (or start new session)
3. Try a prompt that should trigger the guard
4. Verify the warning appears

---

## Common Patterns Reference

| Operation | Pattern |
|-----------|---------|
| Force push to main | `git push.*--force.*(main\|master)` |
| Any force push | `git push.*--force` |
| Hard reset | `git reset --hard` |
| Delete branch | `git branch -D` |
| Credential files | `\\.env\|credentials\|secrets\|password` |
| SQL destructive | `DROP\|DELETE\|TRUNCATE` |
| rm dangerous | `rm -rf /\|rm -rf ~` |
| npm publish | `npm publish` |
| Docker prune | `docker.*prune` |
