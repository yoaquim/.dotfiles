# Claude Code Workflow Improvements

Based on analysis of 1,702 sessions and 9,300+ hours of usage.

## The Problem

Your insights reveal a clear pattern:
- **396 UI styling sessions** with high partial achievement rate (76%)
- **264 occurrences** of buggy code friction
- **132 sessions** marked frustrated due to wrong approach
- Claude repeatedly claiming fixes are complete before they work

You currently have **zero hooks configured**. Hooks are Claude Code's quality gates - they run automatically at lifecycle events to enforce standards before you ever see broken code.

---

## Hooks Primer

Hooks execute at specific moments:

| Hook Event | When It Fires | Use Case |
|------------|---------------|----------|
| `PreToolUse` | Before Claude runs a tool | Block dangerous commands, validate inputs |
| `PostToolUse` | After a tool succeeds | Auto-format code, run linters |
| `Stop` | When Claude finishes responding | Verify tests pass, check types |
| `SessionStart` | When a session begins | Inject project context |

Hook types:
- **command**: Shell scripts that read JSON input and control behavior via exit codes
- **agent**: Multi-turn Claude agent that can read files, run commands, verify conditions
- **prompt**: Single LLM call for quick evaluations

---

## Recommended Hooks Configuration

Create `.claude/settings.json` in your project root (or add to `~/.claude/settings.json` for global):

```json
{
  "hooks": {
    "PostToolUse": [
      {
        "matcher": "Edit|Write",
        "hooks": [
          {
            "type": "command",
            "command": "\"$CLAUDE_PROJECT_DIR\"/.claude/hooks/post-edit.sh",
            "timeout": 30,
            "statusMessage": "Checking types and formatting..."
          }
        ]
      }
    ],
    "Stop": [
      {
        "hooks": [
          {
            "type": "command",
            "command": "\"$CLAUDE_PROJECT_DIR\"/.claude/hooks/pre-stop-check.sh",
            "timeout": 120,
            "statusMessage": "Verifying code quality..."
          }
        ]
      }
    ],
    "PreToolUse": [
      {
        "matcher": "Edit|Write",
        "hooks": [
          {
            "type": "command",
            "command": "\"$CLAUDE_PROJECT_DIR\"/.claude/hooks/protect-critical.sh",
            "timeout": 5
          }
        ]
      }
    ],
    "SessionStart": [
      {
        "matcher": "startup|resume|compact",
        "hooks": [
          {
            "type": "command",
            "command": "\"$CLAUDE_PROJECT_DIR\"/.claude/hooks/inject-context.sh"
          }
        ]
      }
    ]
  }
}
```

---

## Hook Scripts

Create `.claude/hooks/` directory and add these scripts.

### 1. Post-Edit: Type Check + Format (`.claude/hooks/post-edit.sh`)

This addresses your #1 friction: buggy TypeScript code.

```bash
#!/bin/bash
# Runs after every Edit/Write - catches type errors immediately

INPUT=$(cat)
FILE_PATH=$(echo "$INPUT" | jq -r '.tool_input.file_path // .tool_input.file_path')

# Only process TypeScript/JavaScript files
if [[ ! "$FILE_PATH" =~ \.(ts|tsx|js|jsx)$ ]]; then
  exit 0
fi

cd "$CLAUDE_PROJECT_DIR" || exit 0

# Run TypeScript check (non-blocking - just adds context)
TSC_OUTPUT=$(npx tsc --noEmit 2>&1 | head -20)
if [ $? -ne 0 ]; then
  echo "{\"systemMessage\": \"TypeScript errors detected:\\n$TSC_OUTPUT\"}"
  exit 0
fi

# Auto-format the file
npx prettier --write "$FILE_PATH" 2>/dev/null

exit 0
```

### 2. Pre-Stop: Quality Gate (`.claude/hooks/pre-stop-check.sh`)

This prevents Claude from claiming "done" before verification.

```bash
#!/bin/bash
# Blocks Claude from stopping until quality checks pass

INPUT=$(cat)
STOP_ACTIVE=$(echo "$INPUT" | jq -r '.stop_hook_active // false')

# Prevent infinite loops
if [ "$STOP_ACTIVE" = "true" ]; then
  exit 0
fi

cd "$CLAUDE_PROJECT_DIR" || exit 0

# Check if package.json exists (Node.js project)
if [ ! -f "package.json" ]; then
  exit 0
fi

ERRORS=""

# 1. TypeScript compilation check
if [ -f "tsconfig.json" ]; then
  TSC_RESULT=$(npx tsc --noEmit 2>&1)
  if [ $? -ne 0 ]; then
    ERRORS="$ERRORS\n\nTypeScript errors:\n$(echo "$TSC_RESULT" | head -15)"
  fi
fi

# 2. ESLint check (if configured)
if [ -f ".eslintrc.json" ] || [ -f ".eslintrc.js" ] || [ -f "eslint.config.js" ]; then
  LINT_RESULT=$(npx eslint . --ext .ts,.tsx,.js,.jsx --max-warnings 0 2>&1 | head -20)
  if [ $? -ne 0 ]; then
    ERRORS="$ERRORS\n\nESLint errors:\n$LINT_RESULT"
  fi
fi

# 3. Test check (optional - uncomment if you want tests to block)
# TEST_RESULT=$(npm test 2>&1)
# if [ $? -ne 0 ]; then
#   ERRORS="$ERRORS\n\nTest failures:\n$(echo "$TEST_RESULT" | tail -20)"
# fi

if [ -n "$ERRORS" ]; then
  echo "{\"decision\": \"block\", \"reason\": \"Quality checks failed. Fix these before completing:$ERRORS\"}"
  exit 0
fi

exit 0
```

### 3. Pre-Edit: Protect Critical Files (`.claude/hooks/protect-critical.sh`)

Prevents accidental modifications to sensitive files.

```bash
#!/bin/bash
# Blocks edits to critical configuration files

INPUT=$(cat)
FILE_PATH=$(echo "$INPUT" | jq -r '.tool_input.file_path // ""')
FILE_NAME=$(basename "$FILE_PATH")

# Files that should require explicit confirmation
PROTECTED_PATTERNS=(
  ".env"
  ".env.local"
  ".env.production"
  "next.config.js"
  "next.config.mjs"
  "tailwind.config"
  "tsconfig.json"
  "package-lock.json"
  "yarn.lock"
  "pnpm-lock.yaml"
)

for pattern in "${PROTECTED_PATTERNS[@]}"; do
  if [[ "$FILE_NAME" == *"$pattern"* ]]; then
    # Ask permission instead of blocking
    echo "{\"hookSpecificOutput\": {\"hookEventName\": \"PreToolUse\", \"permissionDecision\": \"ask\", \"permissionDecisionReason\": \"Modifying protected file: $FILE_NAME\"}}"
    exit 0
  fi
done

exit 0
```

### 4. Session Start: Context Injection (`.claude/hooks/inject-context.sh`)

Re-injects important context after session start or compaction.

```bash
#!/bin/bash
# Injects project context at session start

INPUT=$(cat)
SOURCE=$(echo "$INPUT" | jq -r '.source // "startup"')

cd "$CLAUDE_PROJECT_DIR" || exit 0

CONTEXT=""

# Detect project type
if [ -f "next.config.js" ] || [ -f "next.config.mjs" ]; then
  CONTEXT="$CONTEXT\nProject: Next.js application."
fi

if [ -f "tailwind.config.js" ] || [ -f "tailwind.config.ts" ]; then
  CONTEXT="$CONTEXT Use Tailwind CSS for styling."
fi

if [ -f "tsconfig.json" ]; then
  CONTEXT="$CONTEXT TypeScript required - run type checks before completing."
fi

if [ -d "supabase" ] || grep -q "supabase" package.json 2>/dev/null; then
  CONTEXT="$CONTEXT Uses Supabase for backend."
fi

# Add reminder based on your specific friction points
CONTEXT="$CONTEXT\n\nIMPORTANT: Before claiming any UI fix is complete, explain what CSS properties changed and why they achieve the visual goal."

if [ -n "$CONTEXT" ]; then
  echo "{\"hookSpecificOutput\": {\"hookEventName\": \"SessionStart\", \"additionalContext\": \"$CONTEXT\"}}"
fi

exit 0
```

---

## Quick Setup

Run this to create the hooks directory and make scripts executable:

```bash
mkdir -p .claude/hooks
chmod +x .claude/hooks/*.sh
```

---

## Impact on Your Friction Points

| Friction Point | Hook Solution |
|----------------|---------------|
| Claude claims UI fixes done before they work | `Stop` hook blocks completion until TypeScript compiles |
| Buggy code (264 occurrences) | `PostToolUse` catches type errors immediately after each edit |
| Wrong approach (132 occurrences) | `SessionStart` injects project context to guide Claude |
| High partial achievement on styling | `Stop` hook with verification prevents premature completion |
| Protected files accidentally modified | `PreToolUse` asks before touching config files |

---

## Advanced: Agent-Based Stop Hook

For stricter verification, use an agent hook that actually runs and verifies:

```json
{
  "hooks": {
    "Stop": [
      {
        "hooks": [
          {
            "type": "agent",
            "prompt": "Before completing, verify: 1) Run 'npx tsc --noEmit' and confirm no TypeScript errors. 2) Run 'npm run lint' if available and confirm no errors. 3) If UI changes were made, describe exactly what CSS properties changed and why they work. Block if any verification fails. $ARGUMENTS",
            "timeout": 180
          }
        ]
      }
    ]
  }
}
```

This spawns a sub-agent that can read files and run commands to verify the work is actually complete.

---

## Async Linting (Non-Blocking)

If you don't want linting to slow you down, run it asynchronously:

```json
{
  "hooks": {
    "PostToolUse": [
      {
        "matcher": "Edit|Write",
        "hooks": [
          {
            "type": "command",
            "command": "cd \"$CLAUDE_PROJECT_DIR\" && npx eslint --fix \"$(jq -r '.tool_input.file_path')\" 2>/dev/null || true",
            "async": true,
            "timeout": 60
          }
        ]
      }
    ]
  }
}
```

Async hooks run in the background and deliver results on the next turn.

---

## Testing Your Hooks

Debug mode shows hook execution:

```bash
claude --debug
```

Test a hook manually:

```bash
echo '{"tool_input": {"file_path": "src/app/page.tsx"}}' | .claude/hooks/post-edit.sh
```

---

## Recommended Next Steps

1. **Start minimal**: Add just the `Stop` hook with TypeScript checking
2. **Observe**: See how often it catches issues before you would
3. **Expand**: Add `PostToolUse` formatting once comfortable
4. **Customize**: Tune the protected files list for your projects

The goal is to make Claude self-verify before claiming completion - addressing the core frustration pattern in your usage data.
