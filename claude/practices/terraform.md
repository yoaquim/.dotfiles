# Terraform / Terragrunt

## State & safety

- Never edit state by hand; use `state mv`/`import` and say so in the PR
- Always `plan` and read the diff before `apply`; paste the plan summary into the PR's Testing section
- Destructive changes (replace, delete) called out explicitly — never buried in a big plan

## Code

- Pin everything: `required_version`, provider versions, module sources (tag or SHA, never a branch)
- Variables typed with descriptions; no `any` types
- Data sources over hardcoded IDs/ARNs
- `for_each` over `count` for collections — count reorders on removal
- No secrets in `.tf`, `.tfvars`, or state-visible outputs; mark sensitive outputs `sensitive = true`

## Terragrunt

- DRY via `terragrunt.hcl` includes — repeated blocks across units belong in the parent
- One unit = one state = one blast radius; don't merge unrelated resources into a unit
- `dependency` blocks with `mock_outputs` so `run-all plan` works from clean

## Hygiene

- `terraform fmt -recursive` and `terraform validate` before any commit
- Terragrunt: `terragrunt hclfmt` to format `terragrunt.hcl`, and `terragrunt validate` (or `run-all validate`) — `terraform fmt`/`validate` don't touch HCL config
- Module changes need a consumer plan to prove no unintended diff
