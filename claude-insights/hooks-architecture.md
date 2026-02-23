# Claude Code Hooks Architecture

Simple, deterministic hooks that delegate verification to project-level scripts.

---

## Concept

Global hooks don't try to detect project types or guess what commands to run. Instead:

1. **Global hook** calls a standard project-level script
2. **Project script** defines what verification means for that project
3. No detection logic, no fallback chains, no magic

If the script doesn't exist, the hook skips or warns. Projects are responsible for defining their own verification.

---

## Convention

Every project has two scripts in `.claude/`:

| File | Called When | Purpose |
|------|-------------|---------|
| `.claude/check.sh` | After each file edit (PostToolUse) | Quick lint/typecheck on changed file |
| `.claude/verify.sh` | Before Claude finishes (Stop) | Full test suite, lint, compile |

Both scripts should:
- Exit 0 on success
- Exit non-zero on failure
- Output errors to stdout (Claude sees them)

---

## Global Hook Config

Add to `~/.claude/settings.json`:

```json
{
  "hooks": {
    "PostToolUse": [
      {
        "matcher": "Edit|Write",
        "hooks": [{
          "type": "command",
          "command": "if [[ -x .claude/check.sh ]]; then .claude/check.sh \"$CLAUDE_FILE_PATH\"; fi",
          "timeout": 30
        }]
      }
    ],
    "Stop": [
      {
        "hooks": [{
          "type": "command",
          "command": "if [[ -x .claude/verify.sh ]]; then .claude/verify.sh || echo '{\"decision\": \"block\", \"reason\": \"Verification failed. Fix errors before completing.\"}'; fi",
          "timeout": 120
        }]
      }
    ]
  }
}
```

---

## Project Scripts

### npm/Node.js Project

`.claude/check.sh` (quick, after each edit):
```bash
#!/bin/bash
set -e
npx tsc --noEmit 2>&1 | head -10
```

`.claude/verify.sh` (full, before completion):
```bash
#!/bin/bash
set -e
npm run lint
npm run typecheck
npm test
```

---

### Python Project

`.claude/check.sh`:
```bash
#!/bin/bash
set -e
ruff check "$1" 2>&1 | head -10
```

`.claude/verify.sh`:
```bash
#!/bin/bash
set -e
ruff check .
pytest
```

---

### Docker-based Project

`.claude/check.sh`:
```bash
#!/bin/bash
set -e
docker compose run --rm app ruff check "$1" 2>&1 | head -10
```

`.claude/verify.sh`:
```bash
#!/bin/bash
set -e
docker compose run --rm app ruff check .
docker compose run --rm app pytest
```

---

### Multi-service Project

`.claude/verify.sh`:
```bash
#!/bin/bash
set -e

echo "=== Frontend ==="
cd frontend && npm run lint && npm run typecheck && npm test
cd ..

echo "=== Backend ==="
docker compose run --rm api pytest

echo "=== All checks passed ==="
```

---

## Behavior

### PostToolUse (check.sh)

- Runs after every Edit/Write
- Non-blocking (just shows output to Claude)
- Fast (single file check, 30s timeout)
- Claude sees errors immediately, can fix before moving on

### Stop (verify.sh)

- Runs when Claude is about to finish responding
- Blocking if it fails (Claude can't claim "done")
- Full verification (tests, lint, compile)
- Longer timeout (120s)

---

## Setup Integration

The `/setup` skill should scaffold these files when initializing a project:

```
.claude/
├── check.sh      # Quick verification (edit to fit project)
└── verify.sh     # Full verification (edit to fit project)
```

Default templates detect common patterns:
- `package.json` exists → npm scripts
- `pyproject.toml` exists → Python tools
- `docker-compose.yml` exists → Docker commands

User edits scripts to match their project's actual commands.

---

## Why This Works

| Problem | Solution |
|---------|----------|
| "Claude claims done when not done" | verify.sh blocks completion until tests pass |
| "Buggy code gets committed" | check.sh catches errors immediately after edits |
| "Too project-specific" | Project defines its own scripts, not the hook |
| "Too complex" | Hook is 1 line: call script if exists |

---

## What This Doesn't Do

- Auto-detect project type (project defines its scripts)
- Run verification when scripts don't exist (skips silently)
- LLM-based judgment calls (deterministic pass/fail only)
- Replace good CLAUDE.md instructions (complements them)
