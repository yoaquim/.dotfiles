#!/usr/bin/env bash

# init-hooks.sh — Create .claude/ hooks scaffolding in a project
# Called by /setup skill. Claude fills in the scripts after.

set -e

mkdir -p .claude

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
            "command": "if [ -x .claude/check.sh ]; then .claude/check.sh; fi",
            "timeout": 30
          }
        ]
      }
    ],
    "Stop": [
      {
        "hooks": [
          {
            "type": "command",
            "command": "if [ -x .claude/verify.sh ]; then .claude/verify.sh || exit 2; fi",
            "timeout": 120
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

# --- Hook scripts ---
for script in check.sh verify.sh setup.sh teardown.sh; do
    if [[ ! -f ".claude/$script" ]]; then
        cat > ".claude/$script" << SCRIPT
#!/usr/bin/env bash
set -e
# TODO: Configure for this project's stack
SCRIPT
        chmod +x ".claude/$script"
        echo "+ .claude/$script"
    else
        echo "~ .claude/$script (already exists, skipping)"
    fi
done
