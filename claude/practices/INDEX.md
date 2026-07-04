# Practices Index

Coding practices and preferences. Used by `inject-practices.sh` to auto-detect and inject relevant practices at runner startup.

| Practice | File | Use When | Detect |
|----------|------|----------|--------|
| TDD | `tdd.md` | **MANDATORY** for all implementation tasks | always |
| No Comments | `no-comments.md` | **MANDATORY** — default to zero comments | always |
| Receiving Review | `receiving-review.md` | **MANDATORY** — evaluate review feedback technically | always |
| Verification | `verification.md` | **MANDATORY** — show command output before claiming done | always |
| Django | `django.md` | Django projects: views, models, templates, forms | manage.py |
| Tailwind | `tailwind.md` | UI/CSS work, frontend styling | tailwind.config.*,package.json:tailwindcss |
| React | `react.md` | React projects: components, hooks, state, data fetching | package.json:react |
| npm Pinning | `npm-pinning.md` | **MANDATORY** for npm projects — lockfile, integrity hashes, immutable installs | package.json |
| Docker | `docker.md` | Dockerized projects, Dockerfiles, compose services | Dockerfile,compose.yml,compose.yaml,docker-compose.yml,docker-compose.yaml |
| Rails | `rails.md` | Rails apps: models, controllers, migrations, jobs | Gemfile:rails |
| Cloudflare Workers | `cloudflare-workers.md` | Workers, Hono, D1/Drizzle, Durable Objects | wrangler.toml,wrangler.jsonc |
| Terraform | `terraform.md` | Terraform/Terragrunt IaC | *.tf,terragrunt.hcl |
| Shell | `shell.md` | Bash scripting: hooks, automation, CLIs | *.sh,scripts/*.sh,bin/*.sh,hooks/*.sh |

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
