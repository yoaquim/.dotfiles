#!/usr/bin/env bash

# init-hooks.sh — Create .claude/hooks/ scaffolding in a project
# Called by /setup skill. Claude fills in the scripts after.

set -e

# Check for jq (required by hook scripts)
if ! command -v jq &>/dev/null; then
    echo "⚠ jq is not installed. Hooks that use jq (check, stop-verify) will fail silently."
    echo "  Install: brew install jq  (macOS) or apt install jq  (Linux)"
fi

mkdir -p .claude/hooks

# --- settings.json (hooks config) ---
# Only write hooks if settings.json doesn't exist or has no hooks key
if [[ ! -f .claude/settings.json ]]; then
    cat > .claude/settings.json << 'SETTINGS'
{
  "hooks": {
    "PostToolUse": [
      {
        "matcher": "Edit|Write",
        "hooks": [
          {
            "type": "command",
            "command": "if [ -x .claude/hooks/check.sh ]; then jq -r '.tool_input.file_path' | xargs .claude/hooks/check.sh; fi",
            "timeout": 30,
            "statusMessage": "Running checks..."
          }
        ]
      }
    ],
    "Stop": [
      {
        "hooks": [
          {
            "type": "command",
            "command": ".claude/hooks/stop-verify.sh",
            "timeout": 120,
            "statusMessage": "Verifying..."
          }
        ]
      }
    ]
  }
}
SETTINGS
    echo "+ .claude/settings.json"
else
    echo "~ .claude/settings.json (already exists, skipping)"
fi

# --- stop-verify.sh (wrapper that handles stop_hook_active) ---
if [[ ! -f .claude/hooks/stop-verify.sh ]]; then
    cat > .claude/hooks/stop-verify.sh << 'STOP'
#!/usr/bin/env bash
set -e

# Read hook input from stdin
INPUT=$(cat)
STOP_ACTIVE=$(echo "$INPUT" | jq -r '.stop_hook_active // false')

if [ ! -x .claude/hooks/verify.sh ]; then
    exit 0
fi

if [ "$STOP_ACTIVE" = "true" ]; then
    # Second attempt — Claude already tried to fix once.
    # Run verify but report instead of blocking (prevents infinite loops).
    .claude/hooks/verify.sh 2>&1 || echo "Verify still failing after retry — letting through."
    exit 0
fi

# First attempt — block if verify fails
.claude/hooks/verify.sh || exit 2
STOP
    chmod +x .claude/hooks/stop-verify.sh
    echo "+ .claude/hooks/stop-verify.sh"
else
    echo "~ .claude/hooks/stop-verify.sh (already exists, skipping)"
fi

# --- Project hook scripts ---
for script in check.sh verify.sh setup.sh teardown.sh; do
    if [[ ! -f ".claude/hooks/$script" ]]; then
        cat > ".claude/hooks/$script" << SCRIPT
#!/usr/bin/env bash
set -e
# TODO: Configure for this project's stack
SCRIPT
        chmod +x ".claude/hooks/$script"
        echo "+ .claude/hooks/$script"
    else
        echo "~ .claude/hooks/$script (already exists, skipping)"
    fi
done
