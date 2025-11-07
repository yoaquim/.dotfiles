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
- Suggests running `/vk:feature` to define first feature

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

## Step 6: Scaffold Project Structure

**CRITICAL**: Before creating documentation, scaffold the actual project based on tech stack.

Without this, VK tasks will fail because there's no foundation to build on.

---

### 6.1 Determine Scaffolding Strategy

Based on detected/confirmed tech stack, determine what needs to be created:

**Tech Stack Combinations:**

1. **Node.js/TypeScript (any framework)**
   - Need: `package.json`, `tsconfig.json` (if TS), `src/` directory, entry file
   - If Docker: `Dockerfile`, `docker-compose.yml`
   - If React/Next.js: Use framework CLI
   - If Express/vanilla: Manual scaffold

2. **Python (any framework)**
   - Need: `requirements.txt` or `pyproject.toml`, virtual env structure
   - If Django: `django-admin startproject`
   - If FastAPI/Flask: Manual scaffold with app structure
   - If Docker: `Dockerfile`, `docker-compose.yml` with Python base

3. **Go**
   - Need: `go.mod`, `main.go`, basic package structure
   - If Docker: `Dockerfile` with Go multi-stage build

4. **Rust**
   - Need: `Cargo.toml`, `src/main.rs` or `src/lib.rs`
   - If Docker: `Dockerfile` with Rust builder

5. **Java**
   - Need: `pom.xml` (Maven) or `build.gradle` (Gradle)
   - If Spring Boot: Use Spring Initializr structure
   - If Docker: `Dockerfile` with JDK

**Report scaffolding plan:**
```
🔧 PROJECT SCAFFOLDING PLAN

Tech Stack: {{LANGUAGE}} + {{FRAMEWORK}} + {{DATABASE}} + {{CONTAINER_PLATFORM}}

Will create:
- [X] Base project files (package.json, requirements.txt, etc.)
- [X] Directory structure (src/, tests/, etc.)
- [X] Container configuration (if Docker selected)
- [X] Database configuration (if database selected)
- [X] Development tooling (linters, formatters, etc.)

Proceed? (yes/no)
```

---

### 6.2 Scaffold Base Project

**CRITICAL: Actually execute the scaffolding based on tech stack.**

**Determine which scaffolding to execute:**
- If `{{LANGUAGE}}` = "JavaScript" or "TypeScript" → Execute Node.js scaffolding
- If `{{LANGUAGE}}` = "Python" → Execute Python scaffolding
- If `{{LANGUAGE}}` = "Go" → Execute Go scaffolding
- If `{{LANGUAGE}}` = "Rust" → Execute Rust scaffolding
- If `{{LANGUAGE}}` = "Java" → Execute Java scaffolding

---

#### For Node.js/TypeScript Projects:

**Use Bash tool to execute these commands:**

1. **Check for existing project:**
   ```bash
   ls -la package.json 2>/dev/null
   ```

2. **If package.json doesn't exist, initialize:**
   ```bash
   npm init -y
   ```

3. **Create directory structure:**
   ```bash
   mkdir -p src && mkdir -p tests
   ```

4. **Create entry file using Write tool:**
   - If NOT TypeScript: Create `src/index.js` with content:
     ```javascript
     // {{PROJECT_NAME}}
     // Generated by VK-Claude Code on {{INIT_DATE}}

     console.log('{{PROJECT_NAME}} is running!');

     // TODO: Implement application logic
     ```

   - If TypeScript: Create `src/index.ts` with content:
     ```typescript
     // {{PROJECT_NAME}}
     // Generated by VK-Claude Code on {{INIT_DATE}}

     console.log('{{PROJECT_NAME}} is running!');

     // TODO: Implement application logic
     ```

5. **If TypeScript, install TypeScript:**
   ```bash
   npm install --save-dev typescript @types/node && npx tsc --init
   ```

6. **If Framework = Express, set up Express:**
   ```bash
   npm install express && npm install --save-dev nodemon
   ```

   Then use Write tool to overwrite entry file with Express boilerplate:
   ```javascript
   const express = require('express');
   const app = express();
   const PORT = process.env.PORT || 3000;

   app.use(express.json());

   app.get('/', (req, res) => {
     res.json({ message: '{{PROJECT_NAME}} API is running' });
   });

   app.listen(PORT, () => {
     console.log(`Server running on port ${PORT}`);
   });
   ```

7. **Update package.json scripts:**
   ```bash
   npm pkg set scripts.start="node src/index.js" && npm pkg set scripts.dev="nodemon src/index.js" && npm pkg set scripts.test="echo \"Error: no test specified\" && exit 1"
   ```

**Report:**
```
✓ Node.js/TypeScript project scaffolded
  - package.json created
  - src/ directory created
  - Entry file created (src/index.js or src/index.ts)
  {{#if FRAMEWORK == "Express"}}
  - Express installed and configured
  {{/if}}
```

---

#### For Python Projects:

**Use Bash tool to check for existing project:**
```bash
ls -la requirements.txt pyproject.toml 2>/dev/null
```

**If no Python project files exist, scaffold based on framework:**

**For ALL Python projects:**
1. **Create requirements.txt using Write tool:**
   ```
   # {{PROJECT_NAME}} Dependencies
   # Generated by VK-Claude Code on {{INIT_DATE}}

   ```

**If Framework = Django:**
1. **Create virtual environment and install Django:**
   ```bash
   python3 -m venv venv && source venv/bin/activate && pip install django
   ```

2. **Start Django project:**
   ```bash
   django-admin startproject {{PROJECT_NAME_SNAKE}} .
   ```

3. **Create initial app:**
   ```bash
   python manage.py startapp core
   ```

4. **Update requirements.txt using Write tool:**
   Append "django" to requirements.txt

**If Framework = FastAPI:**
1. **Create virtual environment and install FastAPI:**
   ```bash
   python3 -m venv venv && source venv/bin/activate && pip install fastapi uvicorn
   ```

2. **Create directory:**
   ```bash
   mkdir -p src
   ```

3. **Create main.py using Write tool:**
   Write to `src/main.py`:
   ```python
   from fastapi import FastAPI

   app = FastAPI(title="{{PROJECT_NAME}}")

   @app.get("/")
   async def root():
       return {"message": "{{PROJECT_NAME}} API is running"}
   ```

4. **Update requirements.txt using Write tool:**
   Append "fastapi\nuvicorn[standard]" to requirements.txt

**If Framework = Flask:**
1. **Create virtual environment and install Flask:**
   ```bash
   python3 -m venv venv && source venv/bin/activate && pip install flask
   ```

2. **Create directory:**
   ```bash
   mkdir -p src
   ```

3. **Create app.py using Write tool:**
   Write to `src/app.py`:
   ```python
   from flask import Flask, jsonify

   app = Flask(__name__)

   @app.route('/')
   def index():
       return jsonify({"message": "{{PROJECT_NAME}} is running"})

   if __name__ == '__main__':
       app.run(debug=True)
   ```

4. **Update requirements.txt using Write tool:**
   Append "flask" to requirements.txt

**If Generic Python (no specific framework):**
1. **Create directories:**
   ```bash
   mkdir -p src && mkdir -p tests
   ```

2. **Create __init__.py using Write tool:**
   Write to `src/__init__.py`:
   ```python
   """
   {{PROJECT_NAME}}
   Generated by VK-Claude Code on {{INIT_DATE}}
   """
   __version__ = "0.1.0"
   ```

**Report:**
```
✓ Python project scaffolded
  - requirements.txt created
  {{#if FRAMEWORK == "Django"}}
  - Django project initialized
  - Core app created
  {{else if FRAMEWORK == "FastAPI"}}
  - FastAPI application created (src/main.py)
  {{else if FRAMEWORK == "Flask"}}
  - Flask application created (src/app.py)
  {{else}}
  - Basic Python package structure created
  {{/if}}
```

---

#### For Go Projects:

**Use Bash tool to check for existing project:**
```bash
ls -la go.mod 2>/dev/null
```

**If go.mod doesn't exist:**

1. **Initialize Go module:**
   ```bash
   go mod init {{PROJECT_NAME_LOWER}}
   ```

2. **Create directory structure:**
   ```bash
   mkdir -p cmd/{{PROJECT_NAME_LOWER}} && mkdir -p internal && mkdir -p pkg
   ```

3. **Create main.go using Write tool:**
   Write to `cmd/{{PROJECT_NAME_LOWER}}/main.go`:
   ```go
   package main

   import "fmt"

   func main() {
       fmt.Println("{{PROJECT_NAME}} is running!")
       // TODO: Implement application logic
   }
   ```

**Report:**
```
✓ Go project scaffolded
  - go.mod created
  - Standard Go project structure (cmd/, internal/, pkg/)
  - Entry point created (cmd/{{PROJECT_NAME_LOWER}}/main.go)
```

---

#### For Rust Projects:

**Use Bash tool to check for existing project:**
```bash
ls -la Cargo.toml 2>/dev/null
```

**If Cargo.toml doesn't exist:**

1. **Initialize Cargo project:**
   ```bash
   cargo init --name {{PROJECT_NAME_SNAKE}}
   ```

2. **Update src/main.rs using Write tool:**
   Write to `src/main.rs`:
   ```rust
   // {{PROJECT_NAME}}
   // Generated by VK-Claude Code on {{INIT_DATE}}

   fn main() {
       println!("{{PROJECT_NAME}} is running!");
       // TODO: Implement application logic
   }
   ```

**Report:**
```
✓ Rust project scaffolded
  - Cargo.toml created
  - src/main.rs created
```

---

#### For Java Projects:

**Use Bash tool to check for existing project:**
```bash
ls -la pom.xml build.gradle 2>/dev/null
```

**If no Java project files exist:**

1. **Create Maven directory structure:**
   ```bash
   mkdir -p src/main/java/com/{{PROJECT_NAME_LOWER}} && mkdir -p src/main/resources && mkdir -p src/test/java/com/{{PROJECT_NAME_LOWER}}
   ```

2. **Create pom.xml using Write tool:**
   Write to `pom.xml`:
   ```xml
   <?xml version="1.0" encoding="UTF-8"?>
   <project xmlns="http://maven.apache.org/POM/4.0.0"
            xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
            xsi:schemaLocation="http://maven.apache.org/POM/4.0.0
            http://maven.apache.org/xsd/maven-4.0.0.xsd">
       <modelVersion>4.0.0</modelVersion>

       <groupId>com.{{PROJECT_NAME_LOWER}}</groupId>
       <artifactId>{{PROJECT_NAME_LOWER}}</artifactId>
       <version>0.1.0</version>

       <properties>
           <maven.compiler.source>17</maven.compiler.source>
           <maven.compiler.target>17</maven.compiler.target>
       </properties>
   </project>
   ```

3. **Create Main.java using Write tool:**
   Write to `src/main/java/com/{{PROJECT_NAME_LOWER}}/Main.java`:
   ```java
   package com.{{PROJECT_NAME_LOWER}};

   public class Main {
       public static void main(String[] args) {
           System.out.println("{{PROJECT_NAME}} is running!");
           // TODO: Implement application logic
       }
   }
   ```

**Report:**
```
✓ Java project scaffolded
  - Maven structure created
  - pom.xml created
  - Main.java entry point created
```

---

### 6.3 Add Docker Configuration (if selected)

**Check if Docker is needed:**
- If `{{CONTAINER_PLATFORM}}` = "Docker" → Create Docker files
- Otherwise → Skip this section

**IMPORTANT: Use Write tool to create Docker files based on language.**

---

#### Docker for Node.js:

**Create Dockerfile using Write tool:**

Write to `Dockerfile`:
```dockerfile
# {{PROJECT_NAME}} Dockerfile
# Generated by VK-Claude Code on {{INIT_DATE}}

FROM node:18-alpine

WORKDIR /app

COPY package*.json ./
RUN npm install

COPY . .

EXPOSE 3000

CMD ["npm", "start"]
```

**Create docker-compose.yml using Write tool:**

Write to `docker-compose.yml` (adjust based on whether database is selected):

```yaml
version: '3.8'

services:
  app:
    build: .
    ports:
      - "3000:3000"
    volumes:
      - .:/app
      - /app/node_modules
    environment:
      - NODE_ENV=development
    command: npm run dev
```

If database selected, append database service to docker-compose.yml based on database type (see 6.4).

**Report:**
```
✓ Docker configuration created
  - Dockerfile (Node.js 18 Alpine)
  - docker-compose.yml
```

---

#### Docker for Python:

**Create Dockerfile using Write tool:**

Write to `Dockerfile`:
```dockerfile
# {{PROJECT_NAME}} Dockerfile
# Generated by VK-Claude Code on {{INIT_DATE}}

FROM python:3.11-slim

WORKDIR /app

COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

COPY . .

EXPOSE 8000

CMD ["uvicorn", "src.main:app", "--host", "0.0.0.0", "--reload"]
```

**Create docker-compose.yml using Write tool:**

Write to `docker-compose.yml`:
```yaml
version: '3.8'

services:
  app:
    build: .
    ports:
      - "8000:8000"
    volumes:
      - .:/app
    environment:
      - PYTHONUNBUFFERED=1
```

If database selected, append database service (see 6.4).

**Report:**
```
✓ Docker configuration created
  - Dockerfile (Python 3.11 slim)
  - docker-compose.yml
```

---

#### Docker for Go:

**Create Dockerfile using Write tool:**

Write to `Dockerfile`:
```dockerfile
# {{PROJECT_NAME}} Dockerfile
# Generated by VK-Claude Code on {{INIT_DATE}}

# Build stage
FROM golang:1.21-alpine AS builder
WORKDIR /app
COPY go.* ./
RUN go mod download
COPY . .
RUN go build -o /{{PROJECT_NAME_LOWER}} ./cmd/{{PROJECT_NAME_LOWER}}

# Run stage
FROM alpine:latest
WORKDIR /root/
COPY --from=builder /{{PROJECT_NAME_LOWER}} .
EXPOSE 8080
CMD ["./{{PROJECT_NAME_LOWER}}"]
```

**Create docker-compose.yml using Write tool:**

Write to `docker-compose.yml`:
```yaml
version: '3.8'

services:
  app:
    build: .
    ports:
      - "8080:8080"
    volumes:
      - .:/app
```

If database selected, append database service (see 6.4).

**Report:**
```
✓ Docker configuration created
  - Dockerfile (Go multi-stage build)
  - docker-compose.yml
```

---

### 6.4 Add Database Configuration (if selected)

**Check if database is needed:**
- If `{{DATABASE}}` is set → Create database configuration
- Otherwise → Skip this section

**Based on database type, use Write tool to create .env.example:**

#### For PostgreSQL:

Write to `.env.example`:
```
DATABASE_URL=postgresql://user:password@localhost:5432/{{PROJECT_NAME_LOWER}}
POSTGRES_USER=user
POSTGRES_PASSWORD=password
POSTGRES_DB={{PROJECT_NAME_LOWER}}
```

If Docker enabled, append to docker-compose.yml:
```yaml
  postgres:
    image: postgres:15-alpine
    ports:
      - "5432:5432"
    environment:
      - POSTGRES_USER=user
      - POSTGRES_PASSWORD=password
      - POSTGRES_DB={{PROJECT_NAME_LOWER}}
    volumes:
      - postgres_data:/var/lib/postgresql/data

volumes:
  postgres_data:
```

#### For MySQL:

Write to `.env.example`:
```
DATABASE_URL=mysql://user:password@localhost:3306/{{PROJECT_NAME_LOWER}}
MYSQL_ROOT_PASSWORD=rootpassword
MYSQL_USER=user
MYSQL_PASSWORD=password
MYSQL_DATABASE={{PROJECT_NAME_LOWER}}
```

If Docker enabled, append to docker-compose.yml:
```yaml
  mysql:
    image: mysql:8
    ports:
      - "3306:3306"
    environment:
      - MYSQL_ROOT_PASSWORD=rootpassword
      - MYSQL_USER=user
      - MYSQL_PASSWORD=password
      - MYSQL_DATABASE={{PROJECT_NAME_LOWER}}
    volumes:
      - mysql_data:/var/lib/mysql

volumes:
  mysql_data:
```

#### For MongoDB:

Write to `.env.example`:
```
DATABASE_URL=mongodb://localhost:27017/{{PROJECT_NAME_LOWER}}
MONGO_INITDB_ROOT_USERNAME=admin
MONGO_INITDB_ROOT_PASSWORD=password
MONGO_INITDB_DATABASE={{PROJECT_NAME_LOWER}}
```

If Docker enabled, append to docker-compose.yml:
```yaml
  mongodb:
    image: mongo:7
    ports:
      - "27017:27017"
    environment:
      - MONGO_INITDB_ROOT_USERNAME=admin
      - MONGO_INITDB_ROOT_PASSWORD=password
      - MONGO_INITDB_DATABASE={{PROJECT_NAME_LOWER}}
    volumes:
      - mongodb_data:/data/db

volumes:
  mongodb_data:
```

**Report:**
```
✓ Database configuration created
  - .env.example with {{DATABASE}} connection strings
  {{#if CONTAINER_PLATFORM == "Docker"}}
  - {{DATABASE}} service added to docker-compose.yml
  {{/if}}
```

---

### 6.5 Add Development Tooling

**Use Bash tool to create .env from example:**
```bash
if [ -f .env.example ] && [ ! -f .env ]; then cp .env.example .env; fi
```

**If Node.js/TypeScript, install linting tools:**
```bash
npm install --save-dev eslint prettier
```

**Report:**
```
✓ Development tooling configured
  - .env created from .env.example
  {{#if LANGUAGE == "JavaScript" or "TypeScript"}}
  - ESLint and Prettier installed
  {{/if}}
```

---

### 6.6 Report Scaffolding Complete

```
✅ PROJECT SCAFFOLDING COMPLETE

Created:
- ✓ Base project structure ({{LANGUAGE}} + {{FRAMEWORK}})
- ✓ Entry point and core files
- ✓ Docker configuration (Dockerfile, docker-compose.yml)
- ✓ Database configuration (.env.example)
- ✓ Development tooling

Project is ready for VK task execution!
```

---

## Step 7: Create Directory Structure

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

1. Define features with `/vk:feature <description>`
2. Plan implementation with `/vk:plan`
3. Let Vibe Kanban orchestrate development
4. Monitor progress with `/vk:status`
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

- `/vk:feature <description>` - Define feature requirements
- `/vk:plan [feature]` - Create agile plan and VK tasks
- `/vk:status` - Check progress
- `/vk:sync-docs` - Sync documentation

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

## Step 7.8: Generate VK Scripts

Create `.vk/` directory for VK-related project scripts:

```bash
mkdir -p .vk
```

Generate three essential scripts:
1. **`.vk/start.sh`** - Start the project (dev server, services)
2. **`.vk/dev.sh`** - Start VK workflow orchestration
3. **`.vk/cleanup.sh`** - Clean up VK artifacts and temp files

---

### Script 1: `.vk/start.sh` (Project Startup)

Based on detected/configured tech stack, generate project startup script:

### For Docker-based projects:

```bash
#!/bin/bash
# {{PROJECT_NAME}} Development Startup Script
# Generated by VK-Claude Code on {{INIT_DATE}}

set -e

echo "🚀 Starting {{PROJECT_NAME}}..."
echo ""

# Check if Docker is running
if ! docker info > /dev/null 2>&1; then
    echo "❌ Docker is not running. Please start Docker and try again."
    exit 1
fi

# Check for .env file
if [ ! -f .env ]; then
    echo "⚠️  No .env file found."
    if [ -f .env.example ]; then
        echo "📝 Copying .env.example to .env..."
        cp .env.example .env
        echo "✅ Created .env file. Please review and update with your values."
    else
        echo "ℹ️  Create a .env file if needed for environment variables."
    fi
    echo ""
fi

# Start services
echo "🐳 Starting Docker services..."
{{DEV_COMMAND}}

echo ""
echo "✅ {{PROJECT_NAME}} is running!"
echo ""
echo "📖 Common commands:"
echo "  docker compose logs -f     # View logs"
echo "  docker compose down        # Stop services"
echo "  {{TEST_COMMAND}}           # Run tests"
echo ""
echo "🎯 VK Workflow:"
echo "  /vk:status                 # Check project status"
echo "  /vk:feature \"desc\"         # Define new feature"
echo "  /vk:kickoff                # Complete project kickoff"
```

### For Node.js/npm projects:

```bash
#!/bin/bash
# {{PROJECT_NAME}} Development Startup Script
# Generated by VK-Claude Code on {{INIT_DATE}}

set -e

echo "🚀 Starting {{PROJECT_NAME}}..."
echo ""

# Check if node_modules exists
if [ ! -d "node_modules" ]; then
    echo "📦 Installing dependencies..."
    npm install
    echo ""
fi

# Check for .env file
if [ ! -f .env ]; then
    echo "⚠️  No .env file found."
    if [ -f .env.example ]; then
        echo "📝 Copying .env.example to .env..."
        cp .env.example .env
        echo "✅ Created .env file. Please review and update with your values."
    fi
    echo ""
fi

# Start development server
echo "🎯 Starting development server..."
{{DEV_COMMAND}}
```

### For Python projects:

```bash
#!/bin/bash
# {{PROJECT_NAME}} Development Startup Script
# Generated by VK-Claude Code on {{INIT_DATE}}

set -e

echo "🚀 Starting {{PROJECT_NAME}}..."
echo ""

# Check for virtual environment
if [ ! -d "venv" ] && [ ! -d ".venv" ]; then
    echo "📦 Creating virtual environment..."
    python3 -m venv venv
    echo "✅ Virtual environment created."
    echo ""
fi

# Activate virtual environment
if [ -d "venv" ]; then
    echo "🔧 Activating virtual environment..."
    source venv/bin/activate
elif [ -d ".venv" ]; then
    echo "🔧 Activating virtual environment..."
    source .venv/bin/activate
fi

# Install dependencies
if [ -f "requirements.txt" ]; then
    echo "📦 Installing dependencies..."
    pip install -r requirements.txt
    echo ""
elif [ -f "pyproject.toml" ]; then
    echo "📦 Installing dependencies..."
    pip install -e .
    echo ""
fi

# Check for .env file
if [ ! -f .env ]; then
    echo "⚠️  No .env file found."
    if [ -f .env.example ]; then
        echo "📝 Copying .env.example to .env..."
        cp .env.example .env
        echo "✅ Created .env file. Please review and update with your values."
    fi
    echo ""
fi

# Run migrations if Django
if [ -f "manage.py" ]; then
    echo "🗄️  Running database migrations..."
    python manage.py migrate
    echo ""
fi

# Start development server
echo "🎯 Starting development server..."
{{DEV_COMMAND}}
```

### For Go projects:

```bash
#!/bin/bash
# {{PROJECT_NAME}} Development Startup Script
# Generated by VK-Claude Code on {{INIT_DATE}}

set -e

echo "🚀 Starting {{PROJECT_NAME}}..."
echo ""

# Download dependencies
echo "📦 Downloading dependencies..."
go mod download
echo ""

# Check for .env file
if [ ! -f .env ]; then
    echo "⚠️  No .env file found."
    if [ -f .env.example ]; then
        echo "📝 Copying .env.example to .env..."
        cp .env.example .env
        echo "✅ Created .env file. Please review and update with your values."
    fi
    echo ""
fi

# Start development server
echo "🎯 Starting development server..."
{{DEV_COMMAND}}
```

### Generic fallback:

```bash
#!/bin/bash
# {{PROJECT_NAME}} Development Startup Script
# Generated by VK-Claude Code on {{INIT_DATE}}

set -e

echo "🚀 Starting {{PROJECT_NAME}}..."
echo ""

# Check for .env file
if [ ! -f .env ]; then
    echo "⚠️  No .env file found."
    if [ -f .env.example ]; then
        echo "📝 Copying .env.example to .env..."
        cp .env.example .env
        echo "✅ Created .env file. Please review and update with your values."
    fi
    echo ""
fi

# Start development server
echo "🎯 Starting development server..."
{{DEV_COMMAND}}

echo ""
echo "✅ {{PROJECT_NAME}} is running!"
```

**Selection logic:**
1. If `{{CONTAINER_PLATFORM}}` = "Docker" → Use Docker script
2. Else if `{{LANGUAGE}}` = "JavaScript" or "TypeScript" → Use Node.js script
3. Else if `{{LANGUAGE}}` = "Python" → Use Python script
4. Else if `{{LANGUAGE}}` = "Go" → Use Go script
5. Else → Use Generic fallback

---

### Script 2: `.vk/dev.sh` (VK Workflow Orchestration)

Universal script for starting VK workflow:

```bash
#!/bin/bash
# {{PROJECT_NAME}} VK Workflow Script
# Generated by VK-Claude Code on {{INIT_DATE}}

set -e

echo "🎯 VK Workflow for {{PROJECT_NAME}}"
echo ""

# Check if .agent/.vk-enabled exists
if [ ! -f .agent/.vk-enabled ]; then
    echo "❌ This project is not VK-enabled."
    echo ""
    echo "Run /vk:init to enable VK workflow."
    exit 1
fi

# Show current status
echo "📊 Current VK Status:"
echo ""

# Check if Claude Code is available
if ! command -v claude &> /dev/null; then
    echo "⚠️  Claude Code CLI not found in PATH."
    echo "Please ensure Claude Code is installed and configured."
    echo ""
    exit 1
fi

# Interactive menu
echo "What would you like to do?"
echo ""
echo "  1) Check VK status (/vk:status)"
echo "  2) Start ready tasks - one-shot (/vk:start)"
echo "  3) Start ready tasks - watch mode (/vk:start --watch)"
echo "  4) Prioritize tasks (/vk:prioritize)"
echo "  5) Define new feature (/vk:feature)"
echo "  6) Complete project kickoff (/vk:kickoff)"
echo "  7) Sync documentation (/vk:sync-docs)"
echo "  8) Exit"
echo ""
read -p "Choose (1-8): " choice

case $choice in
    1)
        echo ""
        echo "📊 Running /vk:status..."
        claude /vk:status
        ;;
    2)
        echo ""
        echo "🚀 Starting ready tasks (one-shot)..."
        claude /vk:start
        ;;
    3)
        echo ""
        echo "🚀 Starting ready tasks (watch mode)..."
        echo "This will continuously monitor and start tasks as they become ready."
        echo "Press Ctrl+C to stop."
        echo ""
        claude /vk:start --watch
        ;;
    4)
        echo ""
        echo "📋 Running /vk:prioritize..."
        claude /vk:prioritize
        ;;
    5)
        echo ""
        read -p "Feature description: " feature_desc
        claude /vk:feature "$feature_desc"
        ;;
    6)
        echo ""
        echo "🚀 Running complete project kickoff..."
        claude /vk:kickoff
        ;;
    7)
        echo ""
        echo "📝 Syncing documentation..."
        claude /vk:sync-docs
        ;;
    8)
        echo "👋 Goodbye!"
        exit 0
        ;;
    *)
        echo "❌ Invalid choice. Please run the script again."
        exit 1
        ;;
esac

echo ""
echo "✅ Done!"
echo ""
echo "Run .vk/dev.sh again for more VK commands."
```

---

### Script 3: `.vk/cleanup.sh` (Cleanup VK Artifacts)

Universal cleanup script:

```bash
#!/bin/bash
# {{PROJECT_NAME}} Cleanup Script
# Generated by VK-Claude Code on {{INIT_DATE}}

set -e

echo "🧹 Cleanup for {{PROJECT_NAME}}"
echo ""

# Warning
echo "⚠️  This will clean up VK artifacts and temporary files."
echo ""
read -p "Continue? (yes/no): " confirm

if [ "$confirm" != "yes" ]; then
    echo "Cancelled."
    exit 0
fi

echo ""
echo "🧹 Cleaning up..."

# Clean VK worktrees (if any exist)
if [ -d ".vk/worktrees" ]; then
    echo "  → Removing VK worktrees..."
    rm -rf .vk/worktrees
    echo "    ✓ Removed .vk/worktrees/"
fi

# Clean temporary files
if [ -f ".agent/.last-feature" ]; then
    echo "  → Removing .agent/.last-feature..."
    rm -f .agent/.last-feature
    echo "    ✓ Removed .agent/.last-feature"
fi

# Clean logs (if any)
if [ -d ".vk/logs" ]; then
    echo "  → Removing VK logs..."
    rm -rf .vk/logs
    echo "    ✓ Removed .vk/logs/"
fi

# Tech-stack specific cleanup
{{#if CONTAINER_PLATFORM == "Docker"}}
# Docker cleanup
echo "  → Cleaning Docker resources..."
docker compose down -v 2>/dev/null || true
echo "    ✓ Docker containers stopped"
{{/if}}

{{#if LANGUAGE == "JavaScript" || LANGUAGE == "TypeScript"}}
# Node.js cleanup
if [ -d "node_modules/.cache" ]; then
    echo "  → Cleaning node_modules cache..."
    rm -rf node_modules/.cache
    echo "    ✓ Removed node_modules/.cache"
fi
{{/if}}

{{#if LANGUAGE == "Python"}}
# Python cleanup
echo "  → Cleaning Python caches..."
find . -type d -name "__pycache__" -exec rm -rf {} + 2>/dev/null || true
find . -type d -name ".pytest_cache" -exec rm -rf {} + 2>/dev/null || true
find . -type f -name "*.pyc" -delete 2>/dev/null || true
echo "    ✓ Removed Python caches"
{{/if}}

# Clean common caches
if [ -d ".cache" ]; then
    echo "  → Removing .cache..."
    rm -rf .cache
    echo "    ✓ Removed .cache/"
fi

# Clean logs
if [ -f "npm-debug.log" ]; then
    rm -f npm-debug.log *.log
    echo "    ✓ Removed log files"
fi

echo ""
echo "✅ Cleanup complete!"
echo ""
echo "You can now:"
echo "  → .vk/start.sh  - Start the project"
echo "  → .vk/dev.sh    - Start VK workflow"
```

**Note**: The cleanup script template uses conditional blocks (`{{#if}}`) that should be replaced during generation based on the detected tech stack. If the conditional syntax isn't supported, generate a universal version that checks for existence before cleaning.

---

### Write all scripts and make executable

**Step-by-step file generation:**

1. **Generate and write `.vk/start.sh`:**
   - Use selection logic above to pick correct template (Docker/Node/Python/Go/Generic)
   - Replace all `{{VARIABLES}}` with values
   - Use Write tool to create `.vk/start.sh` with generated content

2. **Generate and write `.vk/dev.sh`:**
   - Use universal template above
   - Replace all `{{VARIABLES}}` with values
   - Use Write tool to create `.vk/dev.sh` with generated content

3. **Generate and write `.vk/cleanup.sh`:**
   - Use universal template above
   - Replace conditional blocks (`{{#if}}` sections) based on tech stack:
     - If Docker: Include Docker cleanup section
     - If Node.js/TypeScript: Include node_modules cache cleanup
     - If Python: Include Python cache cleanup
     - Always include VK artifacts, logs, and common cache cleanup
   - Replace all `{{VARIABLES}}` with values
   - Use Write tool to create `.vk/cleanup.sh` with generated content

4. **Make all scripts executable:**
   ```bash
   chmod +x .vk/start.sh .vk/dev.sh .vk/cleanup.sh
   ```

**Report after completion:**
```
📝 Generated VK scripts...
  ✓ .vk/start.sh (project startup - executable)
  ✓ .vk/dev.sh (VK workflow - executable)
  ✓ .vk/cleanup.sh (cleanup - executable)

  Quick start:
  → .vk/start.sh  - Start project dev environment
  → .vk/dev.sh    - VK workflow commands
  → .vk/cleanup.sh - Clean up VK artifacts
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

### Quick Start

\`\`\`bash
# Start project (dev server, services)
.vk/start.sh

# VK workflow commands (status, start tasks, etc.)
.vk/dev.sh

# Clean up VK artifacts
.vk/cleanup.sh
\`\`\`

### Manual Commands

\`\`\`bash
# Run development server
{{DEV_COMMAND}}

# Run tests
{{TEST_COMMAND}}

# Build
{{BUILD_COMMAND}}
\`\`\`

## Workflow

This project uses **Vibe Kanban + Claude Code** workflow:

**VK Commands** (via `.vk/dev.sh` or directly):
- `/vk:kickoff` - Complete project kickoff (all features)
- `/vk:feature <description>` - Define feature requirements
- `/vk:plan` - Create agile plan and VK tasks
- `/vk:prioritize` - Set task dependencies
- `/vk:start` - Start ready tasks
- `/vk:start --watch` - Continuous task execution
- `/vk:status` - Show project status
- `/vk:sync-docs` - Sync documentation

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
.vk/

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
Check if it has `.agent/.last-feature` and `.vk/`. If not, offer to append:
```
# Claude Code
.agent/.last-feature

# Vibe Kanban
.vk/
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

A) **FULL KICKOFF** (/vk:kickoff)
   → I'll identify ALL features needed
   → Gather requirements for each (interactive)
   → Create VK tasks for everything
   → Complete project setup in one go
   → Time: ~15-20 min per feature

B) **MANUAL** (/vk:feature, /vk:plan)
   → Define features one at a time yourself
   → More control, slower
   → Use /vk:feature then /vk:plan per feature

C) **LATER**
   → Skip for now
   → Run /vk:kickoff or /vk:feature when ready

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
- Run `/vk:kickoff` workflow inline
- When complete, show final summary

If no:
- Proceed to final summary with note about /vk:kickoff

**If B (Manual):**
- Proceed to final summary
- Mention /vk:feature and /vk:plan commands

**If C (Later):**
- Proceed to final summary
- Mention /vk:kickoff as recommended next step

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

🏗️  PROJECT SCAFFOLDED:

{{LANGUAGE}} + {{FRAMEWORK}} Project:
  ✓ Base project files (package.json/requirements.txt/go.mod/etc.)
  ✓ Entry point and core files (src/index.js, main.py, main.go, etc.)
  ✓ Directory structure (src/, tests/, etc.)
{{#if CONTAINER_PLATFORM == "Docker"}}
  ✓ Docker configuration (Dockerfile, docker-compose.yml)
{{/if}}
{{#if DATABASE}}
  ✓ Database configuration (.env.example with {{DATABASE}})
{{/if}}
  ✓ Development tooling

📁 DOCUMENTATION STRUCTURE:

Root:
  ✓ CLAUDE.md - Core project instructions (VK-aware)
  ✓ README.md - Project overview [created/existing]
  ✓ .gitignore - [created/existing]

.vk/ (VK Scripts):
  ✓ start.sh - Project startup script (executable)
  ✓ dev.sh - VK workflow orchestration (executable)
  ✓ cleanup.sh - Cleanup VK artifacts (executable)

.agent/ (VK-Enabled Documentation):
  ✓ README.md - Documentation index
  ✓ .vk-enabled - VK workflow marker
  ✓ features/
    (Empty - define with /vk:feature)
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

**Project is ready to run!**
   → .vk/start.sh to start development environment
   → Project has working foundation for VK tasks to build on

**RECOMMENDED: Complete Project Kickoff**
   /vk:kickoff

   This will:
   → Identify all features needed
   → Gather requirements for each
   → Create all VK tasks
   → Complete setup in one command

**OR Manual Approach:**

1. **Define Features** (WHAT to build):
   /vk:feature "Your first feature description"
   /vk:feature "Another feature"

2. **Plan Implementation** (HOW to build):
   /vk:plan

   This breaks features into VK epics and 1-point subtasks.

3. **Let VK Orchestrate**:
   VK spawns Claude Code instances per subtask.
   Each instance has access to .agent/ context and slash commands.

4. **Monitor Progress**:
   /vk:status - Check VK progress and doc health
   /vk:sync-docs - Sync system docs (if needed)

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

  /vk:kickoff                   - Complete project kickoff (RECOMMENDED)
  /vk:feature <description>     - Define feature requirements (manual)
  /vk:plan [feature]            - Create VK task hierarchy (manual)
  /vk:status                    - Show progress and next steps
  /vk:sync-docs                 - Sync documentation

  [Standard commands still available:]
  /fix-bug <description>        - Quick bug fix
  /document-issue               - Document known issue

🎯 READY TO BUILD WITH VK + CLAUDE CODE!

[If user didn't define first feature]
Suggestion: Start by defining your first feature!
  → /vk:feature "your feature description"
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
