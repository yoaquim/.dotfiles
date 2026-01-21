---
description: Initialize a new project with scaffolding and documentation structure
allowed-tools: Read, Write, Edit, Bash, Glob, AskUserQuestion
---

You are setting up a new project with proper scaffolding and documentation.

**This command:**
1. Gathers project info through interactive questions
2. Creates project config files (package.json, requirements.txt, etc.)
3. Asks before running install commands
4. Creates `.agent/` documentation structure **from templates**
5. Creates `CLAUDE.md` project instructions
6. Optionally initializes git

**Templates Location:** `~/.claude/workflow/templates/`

---

## Step 1: Check Current State

**Check what exists:**

```bash
ls -la
ls -la .agent/ 2>/dev/null
ls -la package.json requirements.txt go.mod Cargo.toml 2>/dev/null
git rev-parse --is-inside-work-tree 2>/dev/null
```

**Report findings:**
```
PROJECT STATE

Directory: [current directory name]
Git repo: [Yes/No]

Found:
- .agent/: [Yes/No]
- CLAUDE.md: [Yes/No]
- package.json: [Yes/No]
- requirements.txt: [Yes/No]
- Other project files: [list]

[If .agent/ exists]
This project appears to already be initialized.

Would you like to:
A) Reinitialize (will backup existing .agent/)
B) Cancel

Choose: (A/B)
```

If already initialized and user chooses B, exit.
If user chooses A, backup `.agent/` to `.agent.backup.[timestamp]/`.

---

## Step 2: Verify Templates Exist

**CRITICAL: Check that templates are available:**

```bash
ls -la ~/.claude/workflow/templates/
ls -la ~/.claude/workflow/templates/agent/
```

If templates don't exist, show error:
```
ERROR: Templates not found at ~/.claude/workflow/templates/

The workflow templates are required for /setup.
```

---

## Step 3: Interactive Questions

Use AskUserQuestion to gather project configuration:

**Question 1: Project Name**
- Options: "[Directory name]" / "Custom name"

**Question 2: Language**
- Options: "TypeScript" / "JavaScript" / "Python" / "Go"

**Question 3: Framework** (based on language)
- TypeScript/JS: "Express" / "React" / "Next.js" / "None"
- Python: "Django" / "FastAPI" / "Flask" / "None"
- Go: "Gin" / "Echo" / "None"

**Question 4: Database**
- Options: "PostgreSQL" / "MySQL" / "SQLite" / "None"

**Question 5: Docker**
- Options: "Yes" / "No"

**Question 6: Task Management Workflow**
- Options: "VK (Vibe Kanban)" / "Local Tasks" / "Both"

**Question 7: Initial Roadmap**
- Options: "Yes" / "No"

---

## Step 4: Gather Product Vision

Ask for product context:

```
Tell me about your project:

1. **What does it do?** (1-2 sentences)
2. **Who is it for?** (target users)
3. **What problem does it solve?**
```

---

## Step 5: Confirm Configuration

Display summary and ask to proceed.

---

## Step 6: Create Project Files

Based on configuration, create appropriate files. See `stack-configs/` for language-specific configurations.

---

## Step 7: Ask to Run Install Commands

Present commands that need to run:
- For Node.js: `npm install`
- For Python: `python3 -m venv venv && pip install -r requirements.txt`
- For Go: `go mod tidy`

Ask before executing.

---

## Step 8: Create .agent/ Documentation Structure FROM TEMPLATES

**Create directories:**
```bash
mkdir -p .agent/features
mkdir -p .agent/system
mkdir -p .agent/sops
mkdir -p .agent/known-issues
```

**If Local Tasks or Both workflow:**
```bash
mkdir -p .agent/tasks
```

**Template Variables to Replace:**
| Variable | Value |
|----------|-------|
| `{{PROJECT_NAME}}` | User's project name |
| `{{LANGUAGE}}` | Selected language |
| `{{FRAMEWORK}}` | Selected framework |
| `{{DATABASE}}` | Selected database |
| `{{TEST_FRAMEWORK}}` | pytest, jest, go test |
| `{{DEV_COMMAND}}` | Development command |
| `{{TEST_COMMAND}}` | Test command |
| `{{BUILD_COMMAND}}` | Build command |
| `{{INIT_DATE}}` | Today's date |

**Copy and process templates** from `~/.claude/workflow/templates/` to `.agent/`.

---

## Step 9: Create .gitignore

If doesn't exist, create appropriate .gitignore for the stack.

---

## Step 10: Git Integration (Optional)

Offer to initialize git and create initial commit.

---

## Step 11: Final Report

```
PROJECT SETUP COMPLETE

Project: [Project Name]
Language: [Language]
Framework: [Framework]
Database: [Database]
Docker: [Yes/No]
Task Management: [VK / Local Tasks / Both]

FILES CREATED:
[List all created files]

NEXT STEPS:
1. Review generated files
2. Define your first feature: /feature <description>
```
