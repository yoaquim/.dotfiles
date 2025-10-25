You are initializing a project with the Claude Code documentation system.

**This command:**
- Detects if project is new or existing
- Asks interactive questions to gather context
- Uses templates from `~/.claude/workflow/templates/`
- Creates `.agent/` directory structure with lowercase naming
- Generates all documentation from templates
- Supports both fresh projects and existing codebases

---

## Step 1: Detect Project State

Check what already exists in the current directory:

```bash
# Check for existing .agent directory
ls -la .agent/ 2>/dev/null

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
- **Existing Project (Partial Docs)**: Has some docs but incomplete
- **Already Initialized**: Has `.agent/` and `CLAUDE.md`

**Report findings:**
```
🔍 PROJECT STATE DETECTION

Current directory: [pwd]
Project state: [New / Existing without docs / Partial docs / Already initialized]

Found:
- .agent/: [Yes/No]
- CLAUDE.md: [Yes/No]
- README.md: [Yes/No]
- Git repo: [Yes/No]
- Code files: [Yes/No - list languages detected]

[If already initialized]
⚠️ This project appears to be already initialized.

Would you like to:
A) Reinitialize (backup existing, start fresh)
B) Update/repair existing documentation
C) Cancel

Choose: (A/B/C)
```

If already initialized and user chooses B, proceed to update mode.
If user chooses A, backup `.agent/` and `CLAUDE.md` with timestamp.
If user chooses C, exit.

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

## Step 3: Interactive Questions

**Ask user for information to populate templates:**

Use the AskUserQuestion tool to gather ALL required information in ONE call:

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

## Step 4: Prepare Template Variables

Create a map of template variables from user responses:

```
{{PROJECT_NAME}} = [user's project name]
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

## Step 5: Create Directory Structure

Create all directories with lowercase naming:

```bash
mkdir -p .agent/tasks
mkdir -p .agent/system
mkdir -p .agent/sops
mkdir -p .agent/known-issues
```

**Report:**
```
📁 Creating directory structure...
  ✓ .agent/
  ✓ .agent/tasks/
  ✓ .agent/system/
  ✓ .agent/sops/
  ✓ .agent/known-issues/
```

---

## Step 6: Generate Files from Templates

Read each template from `~/.claude/workflow/templates/` and replace `{{VARIABLES}}`:

### 6.1 CLAUDE.md (Project Root)
- Read: `~/.claude/workflow/templates/CLAUDE.md.template`
- Replace all `{{VARIABLES}}` with values
- Write to: `./CLAUDE.md`

### 6.2 .agent/README.md
- Read: `~/.claude/workflow/templates/agent/README.md.template`
- Replace all `{{VARIABLES}}` with values
- Write to: `./.agent/README.md`

### 6.3 .agent/task-template.md
- Read: `~/.claude/workflow/templates/agent/task-template.md`
- Replace all `{{VARIABLES}}` with values
- Write to: `./.agent/task-template.md`

### 6.4 .agent/system/overview.md
- Read: `~/.claude/workflow/templates/agent/system/overview.md.template`
- Replace all `{{VARIABLES}}` with values
- Write to: `./.agent/system/overview.md`

### 6.5 .agent/system/architecture.md
- Read: `~/.claude/workflow/templates/agent/system/architecture.md.template`
- Replace all `{{VARIABLES}}` with values
- Write to: `./.agent/system/architecture.md`

### 6.6 .agent/sops/README.md
- Read: `~/.claude/workflow/templates/agent/sops/README.md.template`
- Replace all `{{VARIABLES}}` with values
- Write to: `./.agent/sops/README.md`

### 6.7 .agent/known-issues/README.md
- Read: `~/.claude/workflow/templates/agent/known-issues/README.md.template`
- Replace all `{{VARIABLES}}` with values
- Write to: `./.agent/known-issues/README.md`

### 6.8 .agent/tasks/000-initial-setup.md

**Create Task 000** (always for new projects):

```markdown
# Task 000: Initial Setup

**Status**: ✅ Complete (created by /init-project)
**Branch**: `main`
**Priority**: High
**Planned**: {{INIT_DATE}}
**Completed**: {{INIT_DATE}}

## Problem

Starting a new project requires:
- Documentation structure
- Development workflow
- Technology stack setup
- Initial environment configuration

## Solution

Initialize {{PROJECT_NAME}} with:
- `.agent/` documentation structure (lowercase directories)
- Claude Code workflow integration
- Universal SOPs referenced from `~/.claude/workflow/sops/`
- Project-specific documentation templates

## Implementation Plan

### Phase 1: Documentation Setup ✅
1. ✅ Create `.agent/` directory structure
2. ✅ Generate CLAUDE.md with project instructions
3. ✅ Create README.md with project overview
4. ✅ Generate system documentation (overview, architecture)
5. ✅ Create SOPs structure (references universal SOPs)
6. ✅ Create known-issues structure
7. ✅ Create task template

### Phase 2: Technology Setup
[Framework-specific setup steps]

**For {{FRAMEWORK}}:**
1. [ ] [Technology-specific setup step 1]
2. [ ] [Technology-specific setup step 2]
3. [ ] [Technology-specific setup step 3]

### Phase 3: Development Environment
1. [ ] Configure development environment
2. [ ] Set up testing framework ({{TEST_FRAMEWORK}})
3. [ ] Verify all commands work (dev, test, build)
4. [ ] Create initial git commit

## Success Criteria

- [x] Documentation structure complete
- [x] CLAUDE.md created
- [x] .agent/ directory initialized
- [x] Universal SOPs referenced
- [ ] Development environment functional
- [ ] All tests passing
- [ ] Initial commit pushed

## Implementation Summary

**Completed**: {{INIT_DATE}}

### Deliverables
- ✅ Complete `.agent/` documentation structure
- ✅ CLAUDE.md with project instructions
- ✅ System documentation (overview, architecture)
- ✅ SOPs structure (references universal)
- ✅ Known issues structure ready
- ✅ Task template for future tasks

### Files Created
- `CLAUDE.md` - Project instructions
- `.agent/README.md` - Documentation index
- `.agent/task-template.md` - Task template
- `.agent/system/overview.md` - Project overview
- `.agent/system/architecture.md` - Architecture docs
- `.agent/sops/README.md` - SOPs index
- `.agent/known-issues/README.md` - Known issues index
- `.agent/tasks/000-initial-setup.md` - This task

### Configuration
- **Language**: {{LANGUAGE}}
- **Framework**: {{FRAMEWORK}}
- **Database**: {{DATABASE}}
- **Testing**: {{TEST_FRAMEWORK}}
- **Commands**:
  - Dev: {{DEV_COMMAND}}
  - Test: {{TEST_COMMAND}}
  - Build: {{BUILD_COMMAND}}

### Next Steps

1. Complete Phase 2: Technology-specific setup
2. Configure development environment
3. Set up testing framework
4. Plan first feature with `/plan-task`

### Notes

- All directories use lowercase naming (tasks, system, sops, known-issues)
- Tasks are numbered 000-999 (3-digit)
- Known issues are numbered 01-99 (2-digit)
- Universal SOPs are referenced from `~/.claude/workflow/sops/`
- Cross-project known-issues search is enabled
```

**Report progress:**
```
📝 Generating documentation from templates...
  ✓ CLAUDE.md
  ✓ .agent/README.md
  ✓ .agent/task-template.md
  ✓ .agent/system/overview.md
  ✓ .agent/system/architecture.md
  ✓ .agent/sops/README.md
  ✓ .agent/known-issues/README.md
  ✓ .agent/tasks/000-initial-setup.md
```

---

## Step 7: Handle README.md

**If README.md doesn't exist:**
Create a basic one:

```markdown
# {{PROJECT_NAME}}

[Brief project description]

## Quick Start

[To be filled in with specific commands]

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

## Documentation

See `.agent/README.md` for complete documentation index.

## Workflow

Use Claude Code slash commands for streamlined development:
- `/plan-task <description>` - Plan a new feature
- `/implement-task [XXX]` - Implement a task
- `/fix-bug <description>` - Quick bug fix workflow
- `/status` - Show project status
```

**If README.md exists:**
```
⚠️ README.md already exists.

Would you like to:
A) Keep existing README.md
B) Backup and replace with generated README
C) Append Claude Code workflow section to existing README

Choose: (A/B/C)
```

---

## Step 8: Create .gitignore (if needed)

**If .gitignore doesn't exist:**

Create basic `.gitignore`:

```
# Claude Code
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

# OS
.DS_Store
Thumbs.db

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
Check if it has Claude Code patterns. If not, offer to append them.

---

## Step 9: Git Integration

**If NOT a git repository:**

```
📦 This is not a git repository.

Would you like to initialize git? (yes/no)
```

If yes:
```bash
git init
git add .
git commit -m "Initial setup with Claude Code documentation

- Add .agent/ documentation structure
- Add CLAUDE.md project instructions
- Add Task 000: Initial Setup
- Configure {{FRAMEWORK}} project

🤖 Generated with Claude Code"
```

**If IS a git repository:**

```
📦 Git repository detected.

Would you like to commit the new documentation? (yes/no)
```

If yes:
```bash
git add .agent/ CLAUDE.md [README.md if created]
git commit -m "Add Claude Code documentation structure

- Initialize .agent/ directory
- Add CLAUDE.md instructions
- Add Task 000: Initial Setup
- Reference universal SOPs from ~/.claude/workflow/sops/

🤖 Generated with Claude Code"
```

---

## Step 10: Final Summary

```
╔════════════════════════════════════════╗
║   🎉 PROJECT INITIALIZED SUCCESSFULLY  ║
╚════════════════════════════════════════╝

📋 PROJECT: {{PROJECT_NAME}}
🔧 FRAMEWORK: {{FRAMEWORK}}
📅 DATE: {{INIT_DATE}}

📁 STRUCTURE CREATED:

Root:
  ✓ CLAUDE.md - Core project instructions
  ✓ README.md - Project overview [created/existing]
  ✓ .gitignore - [created/existing]

.agent/ (Documentation):
  ✓ README.md - Documentation index
  ✓ task-template.md - Task template
  ✓ tasks/
    ✓ 000-initial-setup.md - Initial setup task ✅
  ✓ system/
    ✓ overview.md - Project overview
    ✓ architecture.md - Architecture docs
  ✓ sops/
    ✓ README.md - SOPs index (references universal)
  ✓ known-issues/
    ✓ README.md - Known issues index

📚 UNIVERSAL SOPs (Referenced):
  → ~/.claude/workflow/sops/git-workflow.md
  → ~/.claude/workflow/sops/testing-principles.md
  → ~/.claude/workflow/sops/documentation-standards.md

✅ FEATURES ENABLED:
  ✓ Lowercase directory naming (tasks, system, sops, known-issues)
  ✓ 3-digit task numbering (000-999)
  ✓ 2-digit issue numbering (01-99)
  ✓ Cross-project known-issues search
  ✓ Universal SOPs referenced
  ✓ Task template ready for use

🚀 NEXT STEPS:

1. Review generated documentation:
   - Read CLAUDE.md for core instructions
   - Read .agent/README.md for documentation index
   - Read .agent/tasks/000-initial-setup.md

2. Complete Task 000 Phase 2:
   - Set up {{FRAMEWORK}} environment
   - Configure {{DATABASE}} connection
   - Verify development commands work

3. Start building:
   /plan-task <your first feature>

📖 QUICK REFERENCE:

Commands available:
  /plan-task <description>  - Plan a new feature
  /implement-task [XXX]     - Implement a task
  /fix-bug <description>    - Quick bug fix
  /document-issue           - Document known issue
  /status                   - Show project status

Documentation:
  CLAUDE.md                 - Start here!
  .agent/README.md          - Full documentation index
  ~/.claude/workflow/sops/           - Universal SOPs

🎯 READY TO CODE!

Would you like to:
A) Review the generated documentation
B) Start planning your first feature (/plan-task)
C) Complete Task 000 Phase 2 (technology setup)
D) Just start coding

Choose: (A/B/C/D) or continue as needed
```

---

## Special Cases

### Existing Project with Code

If project has existing code but no `.agent/`:

```
📦 EXISTING PROJECT DETECTED

Found:
- [X] files in [Y] directories
- Git history: [Z] commits
- Framework: {{FRAMEWORK}}

This appears to be an existing project.

I'll initialize documentation without disturbing your code.

Continue? (yes/no)
```

Create all documentation, but don't create Task 000. Instead create:

**Task 001: Documentation Integration**
```markdown
# Task 001: Documentation Integration

**Status**: ✅ Complete
**Type**: Documentation

## Problem

Existing project needs documentation structure and workflow integration.

## Solution

Added Claude Code documentation system to existing {{PROJECT_NAME}} project.

## Implementation Summary

- Added .agent/ documentation structure
- Created CLAUDE.md instructions
- Documented current architecture in system/
- Referenced universal SOPs
- Ready for future task planning

## Next Steps

1. Review generated docs and update with project-specific details
2. Plan next feature with /plan-task
```

### Partial Documentation Exists

If `.agent/` exists but incomplete:

```
📦 PARTIAL DOCUMENTATION DETECTED

Found:
  [✓/✗] .agent/README.md
  [✓/✗] CLAUDE.md
  [✓/✗] .agent/tasks/
  [✓/✗] .agent/system/
  [✓/✗] .agent/sops/
  [✓/✗] .agent/known-issues/

Would you like to:
A) Fill in missing pieces only
B) Backup and reinitialize completely
C) Cancel

Choose: (A/B/C)
```

If A, only create missing files.
If B, backup and start fresh.

---

## Error Handling

### Template Files Missing

```
❌ ERROR: Template files not found

Expected location: ~/.claude/workflow/templates/

Please ensure ~/.claude/ is properly set up:
  cd ~/.dotfiles/config/claude/
  ./setup.sh

Or check that symlink exists:
  ls -la ~/.claude
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
  git commit -m "Add Claude Code documentation"
```

---

## Template Variable Replacement

**Implementation note**: When reading templates and replacing variables:

```python
# Pseudocode for variable replacement
content = read_template_file()

replacements = {
    "{{PROJECT_NAME}}": project_name,
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

1. **Always detect before creating** - Don't overwrite existing work
2. **Backup before replacing** - If reinitializing, backup old docs
3. **Auto-detect when possible** - Reduce user friction
4. **Confirm before proceeding** - Show what will be created
5. **Report progress clearly** - User should see what's happening
6. **Handle errors gracefully** - Don't fail completely on minor issues
7. **Provide next steps** - User should know what to do next
8. **Use lowercase consistently** - All `.agent/` subdirs are lowercase
9. **Reference universal SOPs** - Don't copy, just reference
10. **Enable cross-project search** - Mention it in final summary
