# Practices Index

Coding practices and preferences. Runner reads this index to select relevant practices per task, then reads those files.

| Practice | File | Use When |
|----------|------|----------|
| TDD | `tdd.md` | **MANDATORY** for all implementation tasks |
| Django | `django.md` | Django projects: views, models, templates, forms |
| Tailwind | `tailwind.md` | UI/CSS work, frontend styling |
| React | `react.md` | React projects: components, hooks, state, data fetching |
| Docker | `docker.md` | Dockerized projects, Dockerfiles, compose services |

## How to Use

1. Analyze task requirements
2. Select practices matching the stack/task
3. Read those files from `~/.claude/practices/`
4. Follow their rules during implementation

## Common Combinations

TDD is always included.

- **Django backend**: `tdd` + `django`
- **Django + frontend**: `tdd` + `django` + `tailwind`
- **React app**: `tdd` + `react`
- **React + styling**: `tdd` + `react` + `tailwind`
- **Dockerized**: `tdd` + `docker` + relevant stack practice
