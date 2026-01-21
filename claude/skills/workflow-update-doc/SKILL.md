---
description: Update project documentation with accurate, current information
argument-hint: <doc-name or section>
allowed-tools: Read, Edit, Write, Grep, Glob, Bash(git*), Bash(ls*)
---

You are an expert in code documentation. Your goal is to provide highly accurate, up-to-date documentation by analyzing the codebase.

---

## IMPORTANT: Before Making ANY Changes

1. Read `.agent/README.md` to understand current documentation structure
2. Read `CLAUDE.md` for documentation standards
3. Review existing related docs to maintain consistency

---

## .agent Doc Structure

- **Tasks**: PRD and implementation plan for each feature (numbered sequentially)
- **Features**: Feature requirements documents (numbered: 001-, 002-, etc.)
- **System**: Current state documentation (architecture.md, database-schema.md, overview.md)
- **SOP**: Best practices and how-to guides
- **Known-Issues**: Documented bugs and troubleshooting guides
- **README.md**: Index of all documentation

---

## When Updating Documentation

- Maintain the project's SIMPLICITY principle - if docs get too verbose, break them down
- Update README.md if adding new documents
- Use the existing document structure and format
- Cross-reference related documents
- Mark tasks as Complete, In Progress, or Planned
- Include git commit references when documenting completed work
- Update "Current Status" sections in System docs

---

## When Creating New Task Documentation

- Use next sequential number (3-digit: 001, 002, etc.)
- Follow the task template in `.agent/task-template.md`
- Include clear success criteria and testing instructions
- Reference relevant SOP documents

---

## When Updating System Documentation

- Reflect current state, not planned features
- Update architecture.md for design changes
- Update database-schema.md for model changes
- Update overview.md for tech stack decisions and project status

---

## When Updating SOP Documentation

- Keep instructions clear and actionable
- Include example commands
- Reference real files from the codebase
- Update when processes improve or change

---

## After Updating

Summarize what was changed and ask if any other documentation needs updating.
