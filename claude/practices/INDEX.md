# Practices Index

Coding practices and preferences. Used by `inject-practices.sh` to auto-detect and inject relevant practices at runner startup.

| Practice | File | Use When | Detect |
|----------|------|----------|--------|
| TDD | `tdd.md` | **MANDATORY** for all implementation tasks | always |
| Django | `django.md` | Django projects: views, models, templates, forms | manage.py |
| Tailwind | `tailwind.md` | UI/CSS work, frontend styling | tailwind.config.* |
| React | `react.md` | React projects: components, hooks, state, data fetching | package.json:react |
| Docker | `docker.md` | Dockerized projects, Dockerfiles, compose services | Dockerfile,compose.yml |

## Detect Rules

- `always` — inject unconditionally
- `filename` — inject if file exists in project root
- `filename:string` — inject if file exists AND contains that string
- `glob.*` — inject if any file matches the glob
- `file1,file2` — inject if any of the listed files exist
- _(empty)_ — listed in fallback for runner to decide

## Common Combinations

TDD is always included.

- **Django backend**: `tdd` + `django`
- **Django + frontend**: `tdd` + `django` + `tailwind`
- **React app**: `tdd` + `react`
- **React + styling**: `tdd` + `react` + `tailwind`
- **Dockerized**: `tdd` + `docker` + relevant stack practice
