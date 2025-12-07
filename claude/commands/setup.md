---
description: Initialize a new project with scaffolding and documentation structure
allowed-tools: Read, Write, Edit, Bash, Glob, AskUserQuestion
---

You are setting up a new project with proper scaffolding and documentation.

**This command:**
1. Gathers project info through interactive questions
2. Creates project config files (package.json, requirements.txt, etc.)
3. Asks before running install commands
4. Creates `.agent/` documentation structure
5. Creates `docs/` directory for user context
6. Creates `CLAUDE.md` project instructions
7. Optionally initializes git

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

## Step 2: Interactive Questions

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
  - label: "MongoDB"
    description: "MongoDB document database"
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

**Question 6: Local Tasks**
```
question: "Use local task management?"
header: "Tasks"
options:
  - label: "Yes"
    description: "Create .agent/tasks/ for /workflow:plan-task"
  - label: "No"
    description: "Skip (I use VK or other task management)"
```

---

## Step 3: Gather Product Vision

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

## Step 4: Confirm Configuration

```
PROJECT CONFIGURATION

Project: [name]
Language: [language]
Framework: [framework]
Database: [database]
Docker: [Yes/No]
Local Tasks: [Yes/No]

Product Vision:
[captured description]

Proceed with setup? (yes/no/edit)
```

If "edit", go back to questions.
If "no", exit.
If "yes", proceed.

---

## Step 5: Create Project Files

Based on configuration, create the appropriate files.

### 5.1 TypeScript/JavaScript Projects

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

### 5.2 Python Projects

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

### 5.3 Go Projects

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

### 5.4 Database Configuration

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

For MongoDB:
```
DATABASE_URL=mongodb://localhost:27017/[project_name]
```

For SQLite:
```
DATABASE_URL=sqlite:///./[project_name].db
```

### 5.5 Docker Configuration

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

## Step 6: Ask to Run Install Commands

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

## Step 7: Create Documentation Structure

**Create directories:**
```bash
mkdir -p .agent/features
mkdir -p .agent/system
mkdir -p .agent/known-issues
mkdir -p docs
```

**If local tasks enabled:**
```bash
mkdir -p .agent/tasks
```

**Create `.agent/README.md`:**
```markdown
# [Project Name] Documentation

This directory contains project documentation for Claude Code.

## Structure

- `features/` - Feature requirements (created by /feature)
- `system/` - System documentation (overview, architecture)
- `known-issues/` - Documented issues and troubleshooting
[- `tasks/` - Task documents (created by /workflow:plan-task)] (if local tasks)

## Quick Links

- [Overview](./system/overview.md) - Project goals and tech stack
- [Architecture](./system/architecture.md) - Technical architecture

## Workflow

**Define a feature:**
```
/feature <description>
```

**For VK workflow:**
1. Create VK ticket referencing `.agent/features/NNN-feature-name/README.md`
2. VK breaks into subtasks and executes

**For local workflow:**
```
/workflow:plan-task      # Create implementation plan
/workflow:implement-task # Execute task
/workflow:test-task      # Test implementation
/workflow:complete-task  # Finalize
```

## Related Commands

- `/feature` - Define feature requirements
- `/workflow:status` - Project status
- `/workflow:fix-bug` - Quick bug fixes
- `/workflow:document-issue` - Document known issues
```

**Create `.agent/system/overview.md`:**
```markdown
# Project Overview

**Project**: [Project Name]
**Created**: [Today's date]

---

## Product Vision

[User's product description]

### Target Users

[User's target users]

### Problem Solved

[User's problem statement]

---

## Technology Stack

- **Language**: [Language]
- **Framework**: [Framework]
- **Database**: [Database]
- **Container**: [Docker/None]

---

## Development

### Run Development Server
```bash
[dev command based on language/framework]
```

### Run Tests
```bash
[test command]
```

### Build
```bash
[build command]
```

---

## Current State

**Status**: Initial Setup

The project has been scaffolded and is ready for feature development.

---

## Next Steps

1. Define your first feature with `/feature <description>`
2. Implement using VK or local workflow
3. Update this overview as the project evolves
```

**Create `.agent/system/architecture.md`:**
```markdown
# Technical Architecture

**Project**: [Project Name]
**Last Updated**: [Today's date]

---

## Overview

[To be documented as architecture evolves]

---

## Technology Stack

- **Language**: [Language]
- **Framework**: [Framework]
- **Database**: [Database]

---

## Directory Structure

```
[project-name]/
├── src/                 # Source code
├── .agent/              # Claude Code documentation
│   ├── features/        # Feature requirements
│   ├── system/          # System docs
│   ├── known-issues/    # Issue tracking
│   └── tasks/           # Task documents (if enabled)
├── docs/                # User documentation
└── [config files]
```

---

## Key Components

[To be documented as features are implemented]

---

## Data Flow

[To be documented as features are implemented]

---

## Security Considerations

[To be documented during implementation]
```

**Create `.agent/known-issues/README.md`:**
```markdown
# Known Issues

This directory tracks known issues, bugs, and troubleshooting insights.

## Active Issues

(No issues documented yet)

## Resolved Issues

(No resolved issues yet)

## Adding Issues

Use `/workflow:document-issue` to document known issues.

Issues are numbered 01-99 with format: `NN-issue-name.md`
```

**If local tasks, create `.agent/task-template.md`:**

Copy from `~/.claude/workflow/templates/agent/task-template.md` if it exists, otherwise create a basic template.

**Create `docs/README.md`:**
```markdown
# [Project Name] Documentation

This directory is for your project documentation, notes, and reference materials.

## Contents

Add your documentation here:
- Project specs
- Design documents
- API documentation
- User guides
- Reference materials

## Note

This `docs/` directory is for human documentation.
The `.agent/` directory is for Claude Code workflow documentation.
```

---

## Step 8: Create CLAUDE.md

**Create `CLAUDE.md` in project root:**

```markdown
# CLAUDE.md - [Project Name]

## Project Overview

[Product vision from user]

## Technology Stack

- **Language**: [Language]
- **Framework**: [Framework]
- **Database**: [Database]

## Development Commands

```bash
# Start development server
[dev command]

# Run tests
[test command]

# Build
[build command]
```

## Documentation

- `.agent/README.md` - Documentation index
- `.agent/system/overview.md` - Project overview
- `.agent/system/architecture.md` - Technical architecture
- `docs/` - User documentation

## Workflow

**Define features:**
```
/feature <description>
```

**Local task workflow:**
```
/workflow:plan-task
/workflow:implement-task
/workflow:test-task
/workflow:complete-task
```

**Utilities:**
```
/workflow:status         # Project status
/workflow:fix-bug        # Quick bug fix
/workflow:document-issue # Document issues
/workflow:review-docs    # Review documentation
/workflow:update-doc     # Update specific doc
```

## Principles

1. **Simplicity First** - Keep solutions simple and focused
2. **Read Before Writing** - Always read existing code before modifying
3. **Document As You Go** - Keep `.agent/` docs updated
4. **Test Your Work** - Verify changes work as expected
```

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
- Add .agent/ documentation structure
- Add CLAUDE.md project instructions
- Add docs/ directory

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
Local Tasks: [Yes/No]

FILES CREATED:

Project Files:
  [x] [package.json / requirements.txt / go.mod]
  [x] [src/index.ts / src/main.py / cmd/main.go]
  [x] [tsconfig.json] (if TypeScript)
  [x] [.env.example] (if database)
  [x] [Dockerfile] (if Docker)
  [x] [docker-compose.yml] (if Docker)

Documentation:
  [x] CLAUDE.md
  [x] .agent/README.md
  [x] .agent/system/overview.md
  [x] .agent/system/architecture.md
  [x] .agent/known-issues/README.md
  [x] .agent/features/ (empty, ready for /feature)
  [x] .agent/tasks/ (if local tasks enabled)
  [x] docs/README.md

Other:
  [x] .gitignore

NEXT STEPS:

1. Review generated files
2. Update .env.example with real values (if database)
3. Define your first feature:
   /feature <your feature description>

4. Then either:
   - Create VK ticket referencing the feature doc
   - Or run /workflow:plan-task for local workflow

Ready to build!
```

---

## Error Handling

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
