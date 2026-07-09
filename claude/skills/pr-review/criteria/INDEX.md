# Criteria Index

Used by `resolve-criteria.sh` to select which criteria apply to a given review
checkout. Detect rule semantics are identical to `practices/INDEX.md`
(`always` / `file` / `file:string` / glob / comma = any-of).

House-rules criteria are `always`. Stack criteria load only when the checkout
matches — they extend the bug pass with stack-specific failure modes that
`bug-checklist.md` (which is language-generic) can't cover.

| Criterion | File | Use When | Detect |
|-----------|------|----------|--------|
| Spec Compliance | `spec-compliance.md` | Every PR with a resolvable spec | always |
| Doc Audit | `doc-audit.md` | Concrete counts/claims in PR body or docs | always |
| Slice Size | `slice-size.md` | PRs adding new modules/infrastructure | always |
| Rules Source of Truth | `rules-source-of-truth.md` | Repos with a load-bearing spec doc | always |
| Django | `django.md` | Django views, models, migrations, queries | manage.py |
| React | `react.md` | React components, hooks, effects, state | package.json:react |
| Rails | `rails.md` | Rails models, controllers, migrations, jobs | Gemfile:rails |
| Shell | `shell.md` | Bash scripts, hooks, CLI automation | *.sh,scripts/*.sh,bin/*.sh,hooks/*.sh |
| Terraform | `terraform.md` | Terraform/Terragrunt IaC changes | *.tf,terragrunt.hcl |
| Docker | `docker.md` | Dockerfiles, compose services, images | Dockerfile,compose.yml,compose.yaml,docker-compose.yml,docker-compose.yaml |
| Cloudflare Workers | `cloudflare-workers.md` | Workers, D1/KV/DO, wrangler config | wrangler.toml,wrangler.jsonc |
