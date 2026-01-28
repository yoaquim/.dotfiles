# Practices Index

Coding practices to embed in task descriptions. Read this index to select relevant practices per task, then read only those files.

| Practice | File | Use When |
|----------|------|----------|
| TDD | `tdd.md` | **MANDATORY** for all implementation tasks. Always inlined unless the task is pure setup or E2E tests. |
| Django Patterns | `django-patterns.md` | Any Django code: views, models, templates, forms |
| Tailwind Utilities | `tailwind-utilities.md` | UI/CSS work, frontend styling, component layout |
| Permission Checks | `permission-checks.md` | Features involving auth, roles, RBAC, access control |
| Bug Analysis | `bug_analysis.md` | Bug investigation and fix tasks |
| Code Refactoring | `code_refactoring.md` | Restructuring or improving existing code |
| Docker Compose | `docker-compose.md` | Dockerized projects, compose services, test/init containers, volumes |
| Plan Feature | `plan-feature.md` | Full planning reference for breaking features into tasks |
| Testing Principles | `testing-principles.md` | Testing strategy, coverage targets, test structure |
| Documentation Standards | `documentation-standards.md` | Doc formatting, README structure, inline comments |

## How to Use

1. Analyze the task requirements
2. Select practices that match the task type (a task can have multiple)
3. Read selected practice files from `~/.claude/practices/`
4. Inline the full content into the task description

## Common Combinations

- **Backend endpoint**: `django-patterns` + `tdd` + `permission-checks`
- **UI component**: `tailwind-utilities` + `django-patterns`
- **Business logic**: `tdd`
- **Bug fix**: `bug_analysis`
- **Refactor**: `code_refactoring` + `tdd`
- **Dockerized service**: `docker-compose` + relevant stack practice
- **New project setup**: `docker-compose` + `testing-principles` + `documentation-standards`
