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

Please ensure your dotfiles are properly installed with:
  ~/.claude/workflow/templates/agent/README.md.template
  ~/.claude/workflow/templates/agent/system/overview.md.template
  ~/.claude/workflow/templates/agent/system/architecture.md.template
  ~/.claude/workflow/templates/agent/known-issues/README.md.template
  ~/.claude/workflow/templates/agent/sops/README.md.template
  ~/.claude/workflow/templates/agent/task-template.md
  ~/.claude/workflow/templates/CLAUDE.md.template
```

---

## Step 3: Interactive Questions

Use AskUserQuestion to gather project configuration:

**Question 1: Project Name**
```
question: "What is your project name?"
header: "Project"
options:
  - label: "[Directory name]"
    description: "Use current directory name"
  - label: "Custom name"
    description: "I'll type a different name"
```

If "Custom name", ask for the name in follow-up.

**Question 2: Language**
```
question: "What programming language?"
header: "Language"
options:
  - label: "TypeScript"
    description: "Node.js with TypeScript"
  - label: "JavaScript"
    description: "Node.js with JavaScript"
  - label: "Python"
    description: "Python 3.x"
  - label: "Go"
    description: "Golang"
```

**Question 3: Framework** (based on language)

For TypeScript/JavaScript:
```
question: "What framework?"
header: "Framework"
options:
  - label: "Express"
    description: "Express.js REST API"
  - label: "React"
    description: "React frontend (Vite)"
  - label: "Next.js"
    description: "Next.js full-stack"
  - label: "None"
    description: "Vanilla Node.js"
```

For Python:
```
question: "What framework?"
header: "Framework"
options:
  - label: "Django"
    description: "Django web framework"
  - label: "FastAPI"
    description: "FastAPI REST framework"
  - label: "Flask"
    description: "Flask microframework"
  - label: "None"
    description: "Plain Python"
```

For Go:
```
question: "What framework?"
header: "Framework"
options:
  - label: "Gin"
    description: "Gin HTTP framework"
  - label: "Echo"
    description: "Echo HTTP framework"
  - label: "None"
    description: "Standard library"
```

**Question 4: Database**
```
question: "What database?"
header: "Database"
options:
  - label: "PostgreSQL"
    description: "PostgreSQL relational database"
  - label: "MySQL"
    description: "MySQL relational database"
  - label: "SQLite"
    description: "SQLite file database"
  - label: "None"
    description: "No database needed"
```

**Question 5: Docker**
```
question: "Use Docker?"
header: "Container"
options:
  - label: "Yes"
    description: "Include Dockerfile and docker-compose.yml"
  - label: "No"
    description: "No containerization"
```

**Question 6: Task Management Workflow**
```
question: "How will you manage tasks?"
header: "Workflow"
options:
  - label: "VK (Vibe Kanban)"
    description: "Use VK for task management - skip local .agent/tasks/"
  - label: "Local Tasks"
    description: "Use local .agent/tasks/ with /workflow commands"
  - label: "Both"
    description: "Create .agent/tasks/ but primarily use VK"
```

**Question 7: Initial Roadmap**
```
question: "Would you like to create an initial roadmap?"
header: "Roadmap"
options:
  - label: "Yes"
    description: "Create .agent/ROADMAP.md for planning features and phases"
  - label: "No"
    description: "Skip roadmap - can create later with /roadmap"
```

---

## Step 4: Gather Product Vision

Ask for product context:

```
Tell me about your project:

1. **What does it do?** (1-2 sentences)

2. **Who is it for?** (target users)

3. **What problem does it solve?**

(This will be captured in .agent/system/overview.md)
```

Store the responses for documentation.

---

## Step 5: Confirm Configuration

```
PROJECT CONFIGURATION

Project: [name]
Language: [language]
Framework: [framework]
Database: [database]
Docker: [Yes/No]
Task Management: [VK / Local Tasks / Both]
Create Roadmap: [Yes/No]

Product Vision:
[captured description]

Proceed with setup? (yes/no/edit)
```

If "edit", go back to questions.
If "no", exit.
If "yes", proceed.

---

## Step 6: Create Project Files

Based on configuration, create the appropriate files.

### 6.1 TypeScript/JavaScript Projects

**If package.json doesn't exist:**

Create `package.json`:
```json
{
  "name": "[project-name]",
  "version": "0.1.0",
  "description": "[product vision first sentence]",
  "main": "src/index.js",
  "scripts": {
    "start": "node src/index.js",
    "dev": "nodemon src/index.js",
    "test": "echo \"No tests configured\" && exit 0"
  },
  "keywords": [],
  "author": "",
  "license": "ISC"
}
```

**If TypeScript:**

Update package.json main to `dist/index.js` and add:
```json
{
  "scripts": {
    "start": "node dist/index.js",
    "dev": "ts-node-dev src/index.ts",
    "build": "tsc",
    "test": "echo \"No tests configured\" && exit 0"
  }
}
```

Create `tsconfig.json`:
```json
{
  "compilerOptions": {
    "target": "ES2020",
    "module": "commonjs",
    "lib": ["ES2020"],
    "outDir": "./dist",
    "rootDir": "./src",
    "strict": true,
    "esModuleInterop": true,
    "skipLibCheck": true,
    "forceConsistentCasingInFileNames": true,
    "resolveJsonModule": true
  },
  "include": ["src/**/*"],
  "exclude": ["node_modules", "dist"]
}
```

**Create entry file:**

For JavaScript: `src/index.js`
```javascript
// [Project Name]
// Generated by /setup

console.log('[Project Name] is running');

// TODO: Add your application code
```

For TypeScript: `src/index.ts`
```typescript
// [Project Name]
// Generated by /setup

console.log('[Project Name] is running');

// TODO: Add your application code
```

**If Express framework:**

Update entry file with Express boilerplate:
```typescript
import express from 'express';

const app = express();
const PORT = process.env.PORT || 3000;

app.use(express.json());

app.get('/', (req, res) => {
  res.json({ message: '[Project Name] API is running' });
});

app.get('/health', (req, res) => {
  res.json({ status: 'ok' });
});

app.listen(PORT, () => {
  console.log(`Server running on port ${PORT}`);
});
```

Add express to dependencies list.

### 6.2 Python Projects

**Create requirements.txt:**
```
# [Project Name] dependencies
# Generated by /setup

```

**If Django:**
Add to requirements.txt:
```
django>=4.2
```

**If FastAPI:**
Add to requirements.txt:
```
fastapi>=0.100.0
uvicorn[standard]>=0.23.0
```

**If Flask:**
Add to requirements.txt:
```
flask>=3.0.0
```

**Create entry file:**

For plain Python: `src/__init__.py`
```python
"""
[Project Name]
Generated by /setup
"""
__version__ = "0.1.0"
```

For FastAPI: `src/main.py`
```python
"""[Project Name] API"""
from fastapi import FastAPI

app = FastAPI(title="[Project Name]")

@app.get("/")
async def root():
    return {"message": "[Project Name] API is running"}

@app.get("/health")
async def health():
    return {"status": "ok"}
```

For Flask: `src/app.py`
```python
"""[Project Name] Application"""
from flask import Flask, jsonify

app = Flask(__name__)

@app.route('/')
def index():
    return jsonify({"message": "[Project Name] is running"})

@app.route('/health')
def health():
    return jsonify({"status": "ok"})

if __name__ == '__main__':
    app.run(debug=True)
```

### 6.3 Go Projects

**Create go.mod:**
```bash
go mod init [project-name]
```

**Create directory structure:**
```bash
mkdir -p cmd/[project-name]
mkdir -p internal
mkdir -p pkg
```

**Create entry file:** `cmd/[project-name]/main.go`
```go
package main

import "fmt"

func main() {
    fmt.Println("[Project Name] is running")
    // TODO: Add your application code
}
```

**If Gin framework:**
```go
package main

import (
    "net/http"
    "github.com/gin-gonic/gin"
)

func main() {
    r := gin.Default()

    r.GET("/", func(c *gin.Context) {
        c.JSON(http.StatusOK, gin.H{
            "message": "[Project Name] API is running",
        })
    })

    r.GET("/health", func(c *gin.Context) {
        c.JSON(http.StatusOK, gin.H{"status": "ok"})
    })

    r.Run(":8080")
}
```

### 6.4 Database Configuration

**If database selected, create `.env.example`:**

For PostgreSQL:
```
DATABASE_URL=postgresql://user:password@localhost:5432/[project_name]
POSTGRES_USER=user
POSTGRES_PASSWORD=password
POSTGRES_DB=[project_name]
```

For MySQL:
```
DATABASE_URL=mysql://user:password@localhost:3306/[project_name]
MYSQL_USER=user
MYSQL_PASSWORD=password
MYSQL_DATABASE=[project_name]
```

For SQLite:
```
DATABASE_URL=sqlite:///./[project_name].db
```

### 6.5 Docker Configuration

**If Docker selected, create `Dockerfile`:**

For Node.js:
```dockerfile
FROM node:20-alpine

WORKDIR /app

COPY package*.json ./
RUN npm install

COPY . .

EXPOSE 3000

CMD ["npm", "start"]
```

For Python:
```dockerfile
FROM python:3.12-slim

WORKDIR /app

COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

COPY . .

EXPOSE 8000

CMD ["uvicorn", "src.main:app", "--host", "0.0.0.0", "--port", "8000"]
```

For Go:
```dockerfile
FROM golang:1.22-alpine AS builder

WORKDIR /app
COPY go.* ./
RUN go mod download
COPY . .
RUN go build -o /app/main ./cmd/[project-name]

FROM alpine:latest
WORKDIR /root/
COPY --from=builder /app/main .
EXPOSE 8080
CMD ["./main"]
```

**Create `docker-compose.yml`:**

```yaml
version: '3.8'

services:
  app:
    build: .
    ports:
      - "[port]:[port]"
    environment:
      - NODE_ENV=development
    volumes:
      - .:/app
      - /app/node_modules
```

**If database, add database service:**

For PostgreSQL:
```yaml
  postgres:
    image: postgres:16-alpine
    ports:
      - "5432:5432"
    environment:
      POSTGRES_USER: user
      POSTGRES_PASSWORD: password
      POSTGRES_DB: [project_name]
    volumes:
      - postgres_data:/var/lib/postgresql/data

volumes:
  postgres_data:
```

---

## Step 7: Ask to Run Install Commands

**Present the commands that need to run:**

For Node.js:
```
Ready to install dependencies.

Commands to run:
  npm install
  [npm install express] (if Express)
  [npm install -D typescript ts-node-dev @types/node] (if TypeScript)

Run these commands now? (yes/no/skip)
```

For Python:
```
Ready to set up Python environment.

Commands to run:
  python3 -m venv venv
  source venv/bin/activate
  pip install -r requirements.txt

Run these commands now? (yes/no/skip)
```

For Go:
```
Ready to download dependencies.

Commands to run:
  go mod tidy
  [go get github.com/gin-gonic/gin] (if Gin)

Run these commands now? (yes/no/skip)
```

**If yes:** Execute the commands, show output.
**If no/skip:** Show the commands to run manually.

---

## Step 8: Create .agent/ Documentation Structure FROM TEMPLATES

**CRITICAL: This step uses the templates from `~/.claude/workflow/templates/`**

### 8.1 Create Directory Structure

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

### 8.2 Prepare Template Variables

Before copying templates, prepare the variable substitutions:

| Variable | Value |
|----------|-------|
| `{{PROJECT_NAME}}` | [User's project name] |
| `{{LANGUAGE}}` | [Selected language] |
| `{{FRAMEWORK}}` | [Selected framework or "None"] |
| `{{FRAMEWORK_LOWER}}` | [lowercase framework name, e.g., "django", "fastapi"] |
| `{{DATABASE}}` | [Selected database or "None"] |
| `{{CONTAINER_PLATFORM}}` | "Docker" or "None" |
| `{{TEST_FRAMEWORK}}` | [Appropriate test framework: pytest, jest, go test] |
| `{{DEV_COMMAND}}` | [Development command based on stack] |
| `{{TEST_COMMAND}}` | [Test command based on stack] |
| `{{BUILD_COMMAND}}` | [Build command based on stack] |
| `{{INIT_DATE}}` | [Today's date: YYYY-MM-DD] |

**Determine commands based on stack:**

For TypeScript/JavaScript:
- DEV_COMMAND: `npm run dev`
- TEST_COMMAND: `npm test`
- BUILD_COMMAND: `npm run build`
- TEST_FRAMEWORK: `jest`

For Python:
- DEV_COMMAND: `python manage.py runserver` (Django) or `uvicorn src.main:app --reload` (FastAPI) or `flask run` (Flask)
- TEST_COMMAND: `pytest`
- BUILD_COMMAND: `# No build step`
- TEST_FRAMEWORK: `pytest`

For Go:
- DEV_COMMAND: `go run cmd/[project]/main.go`
- TEST_COMMAND: `go test ./...`
- BUILD_COMMAND: `go build ./...`
- TEST_FRAMEWORK: `go test`

### 8.3 Copy and Process Templates

**Read each template, replace variables, and write to destination:**

1. **`.agent/README.md`** from `~/.claude/workflow/templates/agent/README.md.template`
   - Replace all `{{VARIABLE}}` placeholders
   - If VK-only workflow, remove/modify the tasks section references

2. **`.agent/system/overview.md`** from `~/.claude/workflow/templates/agent/system/overview.md.template`
   - Replace variables
   - Fill in the "Project Description" section with user's product vision
   - Fill in "Current State" with "Initial Setup - Project scaffolded"

3. **`.agent/system/architecture.md`** from `~/.claude/workflow/templates/agent/system/architecture.md.template`
   - Replace variables
   - Keep most sections as placeholders for future

4. **`.agent/known-issues/README.md`** from `~/.claude/workflow/templates/agent/known-issues/README.md.template`
   - Replace variables
   - Remove the example entries (01, 02) leaving just the structure

5. **`.agent/sops/README.md`** from `~/.claude/workflow/templates/agent/sops/README.md.template`
   - Replace variables
   - Note: This references universal SOPs in `~/.claude/workflow/sops/`

6. **`CLAUDE.md`** (project root) from `~/.claude/workflow/templates/CLAUDE.md.template`
   - Replace variables
   - Adjust workflow section based on VK vs Local choice

### 8.4 Copy Task Template (if Local Tasks enabled)

**If Local Tasks or Both workflow:**

Copy `~/.claude/workflow/templates/agent/task-template.md` to `.agent/task-template.md`

### 8.5 Create Initial Setup Task (if Local Tasks enabled)

**If Local Tasks or Both workflow:**

Create `.agent/tasks/000-initial-setup.md`:

```markdown
# Task 000: Initial Setup

**Status**: ✅ Complete
**Branch**: `main`
**Priority**: High
**Planned**: [Today's date]
**Completed**: [Today's date]

## Problem

Project needed initial scaffolding and documentation structure.

**Current State:**
- Empty or minimal project directory
- No standardized documentation
- No development environment configured

## Solution

Used `/setup` command to initialize project with:
- Project configuration files ([package.json/requirements.txt/go.mod])
- `.agent/` documentation structure
- `CLAUDE.md` project instructions
- [Docker configuration if selected]
- [Database configuration if selected]

## Implementation Summary

**Completed**: [Today's date]

### Deliverables
- ✅ Project configuration ([language] + [framework])
- ✅ `.agent/` documentation structure
- ✅ `CLAUDE.md` project instructions
- ✅ [Docker files] (if applicable)
- ✅ [Database configuration] (if applicable)

### Files Created
- `CLAUDE.md` - Project instructions
- `.agent/README.md` - Documentation index
- `.agent/system/overview.md` - Project overview
- `.agent/system/architecture.md` - Technical architecture
- `.agent/sops/README.md` - SOPs index
- `.agent/known-issues/README.md` - Known issues index
- `.agent/task-template.md` - Task document template
- `.agent/tasks/000-initial-setup.md` - This document
- [Other project files...]

### Configuration
- **Language**: [Language]
- **Framework**: [Framework]
- **Database**: [Database]
- **Docker**: [Yes/No]
- **Task Management**: [VK/Local/Both]

### Next Steps
1. Define first feature with `/feature <description>`
2. Plan implementation with `/workflow:plan-task`
3. Or create VK ticket referencing feature requirements

---

Generated by `/setup` command.
```

### 8.6 Adjust for VK-Only Workflow

**If VK-only workflow selected:**

1. Do NOT create `.agent/tasks/` directory
2. Do NOT copy task-template.md
3. Modify `.agent/README.md` to remove tasks section
4. Modify `CLAUDE.md` to emphasize VK workflow

Update the README.md to replace tasks references with:
```markdown
### Tasks & Features
Tasks are managed in **Vibe Kanban (VK)**.

- Features are defined locally in `.agent/features/`
- Implementation tasks are created and tracked in VK
- Use `/feature` to define requirements, then create VK ticket
```

### 8.7 Create Initial Roadmap (if selected)

**If "Create Roadmap: Yes" was selected:**

1. Copy and process `~/.claude/workflow/templates/agent/ROADMAP.md.template`
2. Replace `{{PROJECT_NAME}}` and `{{INIT_DATE}}`
3. Write to `.agent/ROADMAP.md`
4. Keep placeholder content for user to fill in later

**Initial roadmap will have:**
- Empty vision section (to be filled)
- Phase 1 structure with placeholder items
- Backlog section
- Instructions for using `/roadmap` to update

**If "Create Roadmap: No" was selected:**
- Skip roadmap creation
- User can create later with `/roadmap`

---

## Step 9: Create .gitignore

**If .gitignore doesn't exist, create it:**

```
# Environment
.env
.env.local
.env.*.local

# Dependencies
node_modules/
venv/
.venv/
__pycache__/
*.pyc

# Build
dist/
build/
*.egg-info/

# IDE
.vscode/
.idea/
*.swp
*.swo

# OS
.DS_Store
Thumbs.db

# Logs
*.log
npm-debug.log*

# Testing
coverage/
.pytest_cache/
htmlcov/

# Claude Code
.agent/.last-feature
```

**If .gitignore exists, ensure `.agent/.last-feature` is included.**

---

## Step 10: Git Integration (Optional)

```
Git Setup

Git repo detected: [Yes/No]

[If no git repo]
Would you like to initialize git? (yes/no)

[If yes, run:]
git init

[Then ask:]
Would you like to create initial commit? (yes/no)

[If yes, run:]
git add .
git commit -m "Initial project setup

- Add project scaffolding ([Language] + [Framework])
- Add .agent/ documentation structure from templates
- Add CLAUDE.md project instructions
- Configure [Docker/Database] (if applicable)

Generated by /setup"
```

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
Roadmap: [Yes/No]

FILES CREATED:

Project Files:
  [x] [package.json / requirements.txt / go.mod]
  [x] [src/index.ts / src/main.py / cmd/main.go]
  [x] [tsconfig.json] (if TypeScript)
  [x] [.env.example] (if database)
  [x] [Dockerfile] (if Docker)
  [x] [docker-compose.yml] (if Docker)

Documentation (from templates):
  [x] CLAUDE.md
  [x] .agent/README.md
  [x] .agent/system/overview.md
  [x] .agent/system/architecture.md
  [x] .agent/sops/README.md
  [x] .agent/known-issues/README.md
  [x] .agent/features/ (empty, ready for /feature)
  [x] .agent/ROADMAP.md (if roadmap selected)
  [x] .agent/task-template.md (if local tasks)
  [x] .agent/tasks/000-initial-setup.md (if local tasks)

Other:
  [x] .gitignore

WORKFLOW:

[If VK workflow]
Your project uses Vibe Kanban for task management.

  1. Define features locally:     /feature <description>
  2. Create VK ticket referencing: .agent/features/NNN-name/README.md
  3. VK handles task breakdown and execution

[If Local workflow]
Your project uses local task management.

  1. Define features:            /feature <description>
  2. Plan implementation:        /workflow:plan-task
  3. Implement:                  /workflow:implement-task
  4. Test:                       /workflow:test-task
  5. Complete:                   /workflow:complete-task

[If Both]
Your project supports both workflows.

  For VK:
    /feature → Create VK ticket → VK executes

  For local:
    /feature → /workflow:plan-task → /workflow:implement-task

[If Roadmap created]
ROADMAP:
  Your roadmap is at .agent/ROADMAP.md

  To add ideas or update the roadmap:
    /roadmap [your ideas or updates]

  To create a feature from a roadmap item:
    /feature [description referencing roadmap item, e.g., R1.1]

UNIVERSAL SOPs (referenced, not copied):
  [If NOT VK workflow] ~/.claude/workflow/sops/git-workflow.md
  ~/.claude/workflow/sops/testing-principles.md
  ~/.claude/workflow/sops/documentation-standards.md

[If VK workflow] Note: Git workflow handled by VK through worktrees.

NEXT STEPS:

1. Review generated files
2. Update .env.example with real values (if database)
[If Roadmap created]
3. Fill in your roadmap vision and phase items:
   /roadmap [your project ideas]
4. Define your first feature:
   /feature <description referencing roadmap item>
[If no Roadmap]
3. Define your first feature:
   /feature <your feature description>

Ready to build!
```

---

## Error Handling

### Templates Not Found
```
ERROR: Templates not found at ~/.claude/workflow/templates/

Please ensure your dotfiles are properly linked:
  ln -s ~/.dotfiles/claude ~/.claude

Required template files:
  ~/.claude/workflow/templates/agent/README.md.template
  ~/.claude/workflow/templates/agent/system/overview.md.template
  ~/.claude/workflow/templates/agent/system/architecture.md.template
  ~/.claude/workflow/templates/agent/known-issues/README.md.template
  ~/.claude/workflow/templates/agent/sops/README.md.template
  ~/.claude/workflow/templates/agent/task-template.md
  ~/.claude/workflow/templates/CLAUDE.md.template
```

### Permission Errors
```
Cannot create files in this directory.

Try: sudo chown -R $USER:$USER .
```

### Package Manager Not Found
```
[npm/pip/go] not found.

Please install [Node.js/Python/Go] and try again.
```

### Directory Not Empty Warning
```
This directory contains existing files.

Existing files will NOT be overwritten unless they conflict.

Continue? (yes/no)
```
