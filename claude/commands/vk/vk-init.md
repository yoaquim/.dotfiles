---
description: Initialize project with Vibe Kanban integration and Claude Code documentation
allowed-tools: Read, Write, Bash(ls*), Bash(git*), Bash(mkdir*), Bash(grep*), AskUserQuestion, Glob
---

You are initializing a project with the Vibe Kanban + Claude Code workflow system.

**This command:**
- Detects if project is new or existing
- Gathers product vision and context through interactive questions
- Uses VK-specific templates from `~/.claude/workflow/templates/vibe-kanban/`
- Creates `.agent/` directory structure WITHOUT `tasks/` directory (VK is source of truth for tasks)
- Creates `.agent/.vk-enabled` marker file
- Generates documentation from templates
- Suggests running `/vk-feature` to define first feature

**Key Difference from `/init-project`:**
- NO `.agent/tasks/` directory (VK manages tasks)
- Creates `.agent/.vk-enabled` marker
- References VK workflow in documentation

---

## Step 1: Detect Project State

Check what already exists in the current directory:

```bash
# Check for existing .agent directory
ls -la .agent/ 2>/dev/null

# Check for VK marker
ls -la .agent/.vk-enabled 2>/dev/null

# Check for existing CLAUDE.md
ls -la CLAUDE.md 2>/dev/null

# Check for existing README.md
ls -la README.md 2>/dev/null

# Check if git repo
git rev-parse --is-inside-work-tree 2>/dev/null
```

**Determine state:**
- **New Project**: No `.agent/`, no `CLAUDE.md`, minimal files
- **Existing Project (No Docs)**: Has code but no `.agent/` or `CLAUDE.md`
- **Already VK-Initialized**: Has `.agent/.vk-enabled`
- **Standard Workflow Exists**: Has `.agent/tasks/` directory

**Report findings:**
```
🔍 PROJECT STATE DETECTION

Current directory: [pwd]
Project state: [New / Existing without docs / Already VK-initialized / Standard workflow detected]

Found:
- .agent/: [Yes/No]
- .agent/.vk-enabled: [Yes/No]
- .agent/tasks/: [Yes/No]
- CLAUDE.md: [Yes/No]
- README.md: [Yes/No]
- Git repo: [Yes/No]
- Code files: [Yes/No - list languages detected]

[If already VK-initialized]
⚠️ This project appears to be already initialized with VK workflow.

Would you like to:
A) Reinitialize (backup existing, start fresh)
B) Update/repair existing documentation
C) Cancel

Choose: (A/B/C)

[If standard workflow detected (.agent/tasks/ exists)]
⚠️ This project uses standard Claude Code workflow (local tasks).

VK workflow is incompatible with local task management.

Would you like to:
A) Migrate to VK workflow (backup .agent/tasks/, remove it)
B) Keep standard workflow (cancel VK init)
C) Learn more about differences

Choose: (A/B/C)
```

If already initialized and user chooses B, proceed to update mode.
If user chooses A, backup `.agent/` and `CLAUDE.md` with timestamp.
If user chooses C (or B in migration scenario), exit.

---

## Step 2: Detect Technology Stack (Auto-Detection)

**Scan project for clues:**

```bash
# Check for framework indicators
ls package.json 2>/dev/null        # Node.js/JavaScript
ls requirements.txt 2>/dev/null    # Python
ls pyproject.toml 2>/dev/null      # Modern Python
ls manage.py 2>/dev/null           # Django
ls Gemfile 2>/dev/null             # Ruby/Rails
ls go.mod 2>/dev/null              # Go
ls Cargo.toml 2>/dev/null          # Rust
ls composer.json 2>/dev/null       # PHP
ls pom.xml 2>/dev/null             # Java/Maven
ls build.gradle 2>/dev/null        # Java/Gradle

# Check for database indicators
grep -r "postgresql\|postgres" . 2>/dev/null | head -1
grep -r "mysql" . 2>/dev/null | head -1
grep -r "mongodb" . 2>/dev/null | head -1
grep -r "sqlite" . 2>/dev/null | head -1

# Check for containerization
ls Dockerfile 2>/dev/null
ls docker-compose.yml 2>/dev/null

# Check for testing frameworks
grep -r "pytest\|unittest" . 2>/dev/null | head -1
grep -r "jest\|mocha\|vitest" . 2>/dev/null | head -1
```

**Build detection report:**
```
🔎 AUTO-DETECTED TECH STACK

Language: [Python/JavaScript/Go/etc. or "Unknown"]
Framework: [Django/React/Express/etc. or "Unknown"]
Database: [PostgreSQL/MySQL/etc. or "Unknown"]
Container: [Docker/None]
Testing: [pytest/Jest/etc. or "Unknown"]

[If nothing detected]
Unable to auto-detect technology stack.
```

---

## Step 3: Gather Product Vision

**Ask user for high-level product context:**

Use the AskUserQuestion tool to gather product vision:

```
question: "What is your product/project about?"
header: "Product Vision"
options:
  - label: "Provide detailed description"
    description: "I'll explain the product, users, and goals"
  - label: "Simple/small project"
    description: "Quick description for small/personal project"
  - label: "Not sure yet"
    description: "Still exploring, minimal setup for now"

question: "Do you have mockups, designs, or documentation?"
header: "Assets"
options:
  - label: "Yes, I'll provide files"
    description: "I have images, docs, or URLs to share"
  - label: "No, just starting"
    description: "Working from ideas/requirements only"
```

**Prompt for detailed product context:**

```
Please provide:

1. **Product Description**: What does this product do? What problem does it solve?

2. **Target Users**: Who will use this? What are their needs?

3. **Key Goals**: What are the main objectives? What defines success?

4. **Additional Context**:
   - Any mockups, wireframes, or design docs? (paths or URLs)
   - Any existing documentation to reference?
   - Any specific technical constraints or requirements?
   - Timeline or priorities?

Take your time - this context will guide the entire development process.
```

**Capture comprehensive product vision.**

---

## Step 4: Interactive Technology Questions

**Ask user for information to populate templates:**

Use the AskUserQuestion tool to gather technology details:

```
question: "What is your project name?"
header: "Project"
options:
  - label: "[Auto-detected from directory name]"
    description: "Use current directory name"
  - label: "Custom name"
    description: "I'll specify a different name"

question: "What programming language?"
header: "Language"
options:
  - label: "[Auto-detected]" (if detected)
  - label: "Python"
  - label: "JavaScript/TypeScript"
  - label: "Go"

question: "What framework?"
header: "Framework"
options:
  - label: "[Auto-detected]" (if detected)
  - label: "Django"
  - label: "React"
  - label: "Express"
  - label: "None/Other"

question: "What database?"
header: "Database"
options:
  - label: "[Auto-detected]" (if detected)
  - label: "PostgreSQL"
  - label: "MySQL"
  - label: "MongoDB"
  - label: "SQLite"
```

**After user answers, ask for any "Other" clarifications:**
- If they selected "Other" for any field, prompt for custom value

**Gather additional details:**
```
Testing framework: [Auto-detected or ask]
Container platform: [Docker/None]
Development command: [e.g., "docker compose up", "npm start"]
Test command: [e.g., "pytest", "npm test"]
Build command: [e.g., "npm run build", "N/A"]
```

**Confirm with user:**
```
📋 PROJECT CONFIGURATION

Project Name: [name]
Language: [language]
Framework: [framework]
Database: [database]
Testing: [test framework]
Container: [docker/none]

Commands:
- Dev: [dev command]
- Test: [test command]
- Build: [build command]

Is this correct? (yes/no/edit)
```

If "edit", allow modifications.
If "no", restart questions.
If "yes", proceed.

---

## Step 5: Prepare Template Variables

Create a map of template variables from user responses:

```
{{PROJECT_NAME}} = [user's project name]
{{PRODUCT_VISION}} = [user's product description]
{{TARGET_USERS}} = [user's target users]
{{KEY_GOALS}} = [user's key goals]
{{LANGUAGE}} = [Python/JavaScript/etc.]
{{FRAMEWORK}} = [Django/React/etc.]
{{FRAMEWORK_LOWER}} = [django/react/etc.]
{{DATABASE}} = [PostgreSQL/etc.]
{{TEST_FRAMEWORK}} = [pytest/Jest/etc.]
{{CONTAINER_PLATFORM}} = [Docker/None]
{{DEV_COMMAND}} = [docker compose up/npm start/etc.]
{{TEST_COMMAND}} = [pytest/npm test/etc.]
{{BUILD_COMMAND}} = [npm run build/N/A]
{{INIT_DATE}} = [Today's date: YYYY-MM-DD]
```

---

## Step 6: Create Directory Structure

Create directories with lowercase naming (NO tasks/ directory):

```bash
mkdir -p .agent/features
mkdir -p .agent/system
mkdir -p .agent/sops
mkdir -p .agent/known-issues
```

**Report:**
```
📁 Creating VK-enabled directory structure...
  ✓ .agent/
  ✓ .agent/features/      (Feature requirements)
  ✓ .agent/system/        (System docs)
  ✓ .agent/sops/          (SOPs)
  ✓ .agent/known-issues/  (Known issues)

  📝 Note: No .agent/tasks/ directory
  → Vibe Kanban manages tasks and execution
```

---

## Step 7: Generate Files from Templates

Read each template from `~/.claude/workflow/templates/vibe-kanban/` and replace `{{VARIABLES}}`:

### 7.1 CLAUDE.md (Project Root)
- Read: `~/.claude/workflow/templates/vibe-kanban/CLAUDE.md.template`
- Replace all `{{VARIABLES}}` with values
- Write to: `./CLAUDE.md`

### 7.2 .agent/README.md
- Read: `~/.claude/workflow/templates/vibe-kanban/README.md.template`
- Replace all `{{VARIABLES}}` with values
- Write to: `./.agent/README.md`

### 7.3 .agent/.vk-enabled (Marker File)
- Copy: `~/.claude/workflow/templates/vibe-kanban/.vk-enabled`
- Write to: `./.agent/.vk-enabled`

### 7.4 .agent/system/overview.md
- Create comprehensive overview with product vision:

```markdown
# Project Overview

**Project**: {{PROJECT_NAME}}
**Initialized**: {{INIT_DATE}}
**Workflow**: Vibe Kanban + Claude Code

---

## Product Vision

{{PRODUCT_VISION}}

### Target Users
{{TARGET_USERS}}

### Key Goals
{{KEY_GOALS}}

---

## Technology Stack

- **Language**: {{LANGUAGE}}
- **Framework**: {{FRAMEWORK}}
- **Database**: {{DATABASE}}
- **Testing**: {{TEST_FRAMEWORK}}
- **Container**: {{CONTAINER_PLATFORM}}

---

## Development Commands

### Run Development Server
\`\`\`bash
{{DEV_COMMAND}}
\`\`\`

### Run Tests
\`\`\`bash
{{TEST_COMMAND}}
\`\`\`

### Build
\`\`\`bash
{{BUILD_COMMAND}}
\`\`\`

---

## Current State

**Status**: Initial Setup

**Decisions Complete**:
- Technology stack selected
- Development environment configured

**Decisions TBD**:
- Feature prioritization
- Implementation roadmap

---

## Next Steps

1. Define features with `/vk-feature <description>`
2. Plan implementation with `/vk-plan`
3. Let Vibe Kanban orchestrate development
4. Monitor progress with `/vk-status`
```

### 7.5 .agent/system/architecture.md
- Create placeholder architecture doc:

```markdown
# Technical Architecture

**Project**: {{PROJECT_NAME}}
**Last Updated**: {{INIT_DATE}}

---

## Overview

[To be updated as architecture evolves]

## Technology Stack

- **Backend**: {{FRAMEWORK}}
- **Database**: {{DATABASE}}
- **Testing**: {{TEST_FRAMEWORK}}

## File Structure

\`\`\`
[To be documented as project grows]
\`\`\`

## Key Components

[To be documented as features are implemented]

## Data Flow

[To be documented as features are implemented]

## Security Considerations

[To be documented during implementation]
```

### 7.6 .agent/sops/README.md
- Create SOPs index:

```markdown
# Standard Operating Procedures (SOPs)

This project uses Vibe Kanban workflow with Claude Code.

---

## Universal SOPs

These apply to ALL projects and live in `~/.claude/workflow/sops/`:

- [Git Workflow](~/.claude/workflow/sops/git-workflow.md)
- [Testing Principles](~/.claude/workflow/sops/testing-principles.md)
- [Documentation Standards](~/.claude/workflow/sops/documentation-standards.md)
- [VK Integration](~/.claude/workflow/sops/vk-integration.md)

---

## Project-Specific SOPs

(Add project-specific SOPs here as they're created)

---

## Vibe Kanban Workflow

### Core Principles

1. **Separation of Concerns**
   - VK manages tasks and orchestration
   - `.agent/` provides project context

2. **1-Point Rule**
   - Every subtask must be 1 point (1-2 hours)
   - If >1pt, break down further

3. **Documentation as First-Class**
   - Every epic gets a documentation subtask
   - System docs updated as features complete

4. **TDD-Friendly**
   - Tests are separate subtasks
   - Can be created before implementation

### Workflow Commands

- `/vk-feature <description>` - Define feature requirements
- `/vk-plan [feature]` - Create agile plan and VK tasks
- `/vk-status` - Check progress
- `/vk-sync-docs` - Sync documentation

For detailed guidance, see: `~/.claude/guides/vk-product-workflow.md`
```

### 7.7 .agent/known-issues/README.md
- Create known issues index:

```markdown
# Known Issues

This directory tracks known issues, bugs, and troubleshooting insights.

---

## Active Issues

(No issues documented yet)

---

## Resolved Issues

(No resolved issues yet)

---

## Adding Issues

Use `/document-issue` command to document known issues.

Issues are numbered 01-99 with format: `NN-issue-name.md`
```

**Report progress:**
```
📝 Generating documentation from VK templates...
  ✓ CLAUDE.md
  ✓ .agent/README.md
  ✓ .agent/.vk-enabled (marker file)
  ✓ .agent/system/overview.md (with product vision)
  ✓ .agent/system/architecture.md
  ✓ .agent/sops/README.md (VK workflow reference)
  ✓ .agent/known-issues/README.md
```

---

## Step 8: Handle README.md

**If README.md doesn't exist:**
Create a basic one:

```markdown
# {{PROJECT_NAME}}

{{PRODUCT_VISION}}

## Technology Stack

- **Language**: {{LANGUAGE}}
- **Framework**: {{FRAMEWORK}}
- **Database**: {{DATABASE}}
- **Testing**: {{TEST_FRAMEWORK}}

## Development

### Run Development Server
\`\`\`bash
{{DEV_COMMAND}}
\`\`\`

### Run Tests
\`\`\`bash
{{TEST_COMMAND}}
\`\`\`

### Build
\`\`\`bash
{{BUILD_COMMAND}}
\`\`\`

## Workflow

This project uses **Vibe Kanban + Claude Code** workflow:

- `/vk-feature <description>` - Define feature requirements
- `/vk-plan` - Create agile plan and VK tasks
- `/vk-status` - Show project status
- `/vk-sync-docs` - Sync documentation

For detailed workflow guide, see: `~/.claude/guides/vk-product-workflow.md`

## Documentation

See `.agent/README.md` for complete documentation index.

Task management handled by Vibe Kanban (no local `.agent/tasks/` directory).
```

**If README.md exists:**
```
⚠️ README.md already exists.

Would you like to:
A) Keep existing README.md
B) Backup and replace with generated README
C) Append VK workflow section to existing README

Choose: (A/B/C)
```

---

## Step 9: Create .gitignore (if needed)

**If .gitignore doesn't exist:**

Create basic `.gitignore`:

```
# Claude Code
.agent/.last-feature

# Vibe Kanban
.vibe/

# OS
.DS_Store

# Environment
.env
.env.local
.env.*.local

# IDE
.vscode/
.idea/
*.swp
*.swo
*~

# Logs
*.log
npm-debug.log*
yarn-debug.log*
yarn-error.log*

# Dependencies
node_modules/
__pycache__/
*.pyc
.pytest_cache/
```

**If .gitignore exists:**
Check if it has `.agent/.last-feature` and `.vibe/`. If not, offer to append:
```
# Claude Code
.agent/.last-feature

# Vibe Kanban
.vibe/
```

---

## Step 10: Git Integration

**If NOT a git repository:**

```
📦 This is not a git repository.

Would you like to initialize git? (yes/no)
```

If yes:
```bash
git init
git add .
git commit -m "Initial VK-Claude Code setup

- Add .agent/ documentation structure (VK-enabled)
- Add CLAUDE.md project instructions
- Configure {{FRAMEWORK}} project
- Reference VK workflow integration

🤖 Generated with Claude Code + Vibe Kanban"
```

**If IS a git repository:**

```
📦 Git repository detected.

Would you like to commit the new documentation? (yes/no)
```

If yes:
```bash
git add .agent/ CLAUDE.md [README.md if created]
git commit -m "Add VK-Claude Code documentation

- Initialize .agent/ directory (VK-enabled)
- Add CLAUDE.md instructions
- Reference VK workflow
- No local tasks/ directory (VK manages tasks)

🤖 Generated with Claude Code + Vibe Kanban"
```

---

## Step 11: Offer Complete Kickoff

```
✨ PROJECT SETUP COMPLETE!

Would you like to complete feature planning now?

Options:

A) **FULL KICKOFF** (/vk-kickoff)
   → I'll identify ALL features needed
   → Gather requirements for each (interactive)
   → Create VK tasks for everything
   → Complete project setup in one go
   → Time: ~15-20 min per feature

B) **MANUAL** (/vk-feature, /vk-plan)
   → Define features one at a time yourself
   → More control, slower
   → Use /vk-feature then /vk-plan per feature

C) **LATER**
   → Skip for now
   → Run /vk-kickoff or /vk-feature when ready

Recommended: Option A (Full Kickoff)

Choose: (A/B/C)
```

**If A (Full Kickoff):**
```
🚀 Starting full project kickoff...

This will:
1. Identify all features needed
2. Gather requirements for each (interactive)
3. Create all VK tasks

Note: This takes time but sets up entire project.

Ready? (yes/no)
```

If yes:
- Run `/vk-kickoff` workflow inline
- When complete, show final summary

If no:
- Proceed to final summary with note about /vk-kickoff

**If B (Manual):**
- Proceed to final summary
- Mention /vk-feature and /vk-plan commands

**If C (Later):**
- Proceed to final summary
- Mention /vk-kickoff as recommended next step

---

## Step 12: Final Summary

```
╔═══════════════════════════════════════════════╗
║   🎉 VK-CLAUDE CODE PROJECT INITIALIZED       ║
╚═══════════════════════════════════════════════╝

📋 PROJECT: {{PROJECT_NAME}}
🔧 FRAMEWORK: {{FRAMEWORK}}
🎯 WORKFLOW: Vibe Kanban + Claude Code
📅 DATE: {{INIT_DATE}}

📁 STRUCTURE CREATED:

Root:
  ✓ CLAUDE.md - Core project instructions (VK-aware)
  ✓ README.md - Project overview [created/existing]
  ✓ .gitignore - [created/existing]

.agent/ (VK-Enabled Documentation):
  ✓ README.md - Documentation index
  ✓ .vk-enabled - VK workflow marker
  ✓ features/
    (Empty - define with /vk-feature)
  ✓ system/
    ✓ overview.md - Product vision & tech stack
    ✓ architecture.md - Technical architecture
  ✓ sops/
    ✓ README.md - SOPs index (references VK workflow)
  ✓ known-issues/
    ✓ README.md - Known issues index

📝 NO .agent/tasks/ directory
  → Vibe Kanban is source of truth for tasks

📚 UNIVERSAL RESOURCES:
  → ~/.claude/workflow/sops/vk-integration.md (Technical VK SOP)
  → ~/.claude/guides/vk-product-workflow.md (Human workflow guide)

✅ VK WORKFLOW ENABLED:
  ✓ Feature-driven development
  ✓ Agile task breakdown (Epics → 1-point subtasks)
  ✓ Auto-generated documentation subtasks
  ✓ TDD-friendly (separate test subtasks)
  ✓ 1-point rule enforcement
  ✓ VK orchestration ready

🚀 NEXT STEPS:

**RECOMMENDED: Complete Project Kickoff**
   /vk-kickoff

   This will:
   → Identify all features needed
   → Gather requirements for each
   → Create all VK tasks
   → Complete setup in one command

**OR Manual Approach:**

1. **Define Features** (WHAT to build):
   /vk-feature "Your first feature description"
   /vk-feature "Another feature"

2. **Plan Implementation** (HOW to build):
   /vk-plan

   This breaks features into VK epics and 1-point subtasks.

3. **Let VK Orchestrate**:
   VK spawns Claude Code instances per subtask.
   Each instance has access to .agent/ context and slash commands.

4. **Monitor Progress**:
   /vk-status - Check VK progress and doc health
   /vk-sync-docs - Sync system docs (if needed)

📖 LEARNING RESOURCES:

For humans:
  → Read ~/.claude/guides/vk-product-workflow.md
    (Complete guide with examples)

For technical details:
  → Read ~/.claude/workflow/sops/vk-integration.md
    (1-point rule, task structure, patterns)

For project context:
  → Read CLAUDE.md
  → Read .agent/README.md

🎯 WORKFLOW COMMANDS:

  /vk-kickoff                   - Complete project kickoff (RECOMMENDED)
  /vk-feature <description>     - Define feature requirements (manual)
  /vk-plan [feature]            - Create VK task hierarchy (manual)
  /vk-status                    - Show progress and next steps
  /vk-sync-docs                 - Sync documentation

  [Standard commands still available:]
  /fix-bug <description>        - Quick bug fix
  /document-issue               - Document known issue

🎯 READY TO BUILD WITH VK + CLAUDE CODE!

[If user didn't define first feature]
Suggestion: Start by defining your first feature!
  → /vk-feature "your feature description"
```

---

## Special Cases

### Migrating from Standard Workflow

If `.agent/tasks/` exists:

```
📦 MIGRATION FROM STANDARD WORKFLOW

Found existing .agent/tasks/ directory.

VK workflow manages tasks externally. You have options:

A) **Archive tasks/**
   - Backup to .agent/tasks-archive-YYYY-MM-DD/
   - Remove .agent/tasks/
   - Fresh start with VK

B) **Complete existing tasks first**
   - Finish current tasks with standard workflow
   - Then migrate to VK for new features

C) **Hybrid approach** (Advanced)
   - Keep tasks/ for specific work
   - Use VK for new features
   - Requires manual coordination

Recommended: **Option A** for clean VK adoption

Choose: (A/B/C)
```

If A:
```bash
mv .agent/tasks/ .agent/tasks-archive-$(date +%Y-%m-%d)/
```

### Existing Project with Code

If project has existing code but no `.agent/`:

```
📦 EXISTING PROJECT DETECTED

Found:
- [X] files in [Y] directories
- Git history: [Z] commits
- Framework: {{FRAMEWORK}}

This appears to be an existing project.

I'll initialize VK-Claude Code documentation without disturbing your code.

Continue? (yes/no)
```

Create all documentation, capture current state in overview.md.

---

## Error Handling

### Template Files Missing

```
❌ ERROR: VK template files not found

Expected location: ~/.claude/workflow/templates/vibe-kanban/

Please ensure ~/.claude/ is properly set up.

Check that symlink exists:
  ls -la ~/.claude

Verify templates exist:
  ls ~/.claude/workflow/templates/vibe-kanban/
```

### Permission Errors

```
❌ ERROR: Cannot create .agent/ directory

Permission denied. Try:
  sudo chown -R $USER:$USER .
```

### Git Errors

```
⚠️ WARNING: Git operation failed

The documentation was created successfully, but git commit failed.
You can manually commit later:

  git add .agent/ CLAUDE.md
  git commit -m "Add VK-Claude Code documentation"
```

---

## Template Variable Replacement

**Implementation note**: When reading templates and replacing variables:

```python
# Pseudocode for variable replacement
content = read_template_file()

replacements = {
    "{{PROJECT_NAME}}": project_name,
    "{{PRODUCT_VISION}}": product_vision,
    "{{TARGET_USERS}}": target_users,
    "{{KEY_GOALS}}": key_goals,
    "{{LANGUAGE}}": language,
    "{{FRAMEWORK}}": framework,
    "{{FRAMEWORK_LOWER}}": framework.lower(),
    "{{DATABASE}}": database,
    "{{TEST_FRAMEWORK}}": test_framework,
    "{{CONTAINER_PLATFORM}}": container_platform,
    "{{DEV_COMMAND}}": dev_command,
    "{{TEST_COMMAND}}": test_command,
    "{{BUILD_COMMAND}}": build_command,
    "{{INIT_DATE}}": today_date_YYYY_MM_DD,
}

for variable, value in replacements.items():
    content = content.replace(variable, value)

write_file(target_path, content)
```

---

## Best Practices

1. **Gather comprehensive product vision** - This guides all future work
2. **Auto-detect when possible** - Reduce user friction
3. **Confirm before proceeding** - Show what will be created
4. **Report progress clearly** - User should see what's happening
5. **Handle errors gracefully** - Don't fail completely on minor issues
6. **Provide next steps** - User should know what to do next
7. **Reference VK resources** - Point to guides and SOPs
8. **No tasks/ directory** - Emphasize VK manages tasks
9. **Suggest first feature** - Help user get started immediately
