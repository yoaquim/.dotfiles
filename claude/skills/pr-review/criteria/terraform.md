# Criterion: `terraform`

## What it says

Terraform diffs get checked for plan-time surprises the code alone hides: resource replacement, state identity churn, secret exposure, and missing lifecycle guards.

## How to spot

**Destroy / replace risk**
- Changed attribute that forces replacement (name changes, immutable fields like `availability_zone`, engine versions on some resources) on a stateful resource (DB, volume, bucket) — the diff looks like an edit, the plan is destroy-create.
- `count` ↔ `for_each` conversion, or reordering a `count` list — shifts indices, so existing resources get destroyed/recreated under new addresses.
- Renamed resource block without a matching `moved {}` block — same thing: destroy + create.
- Stateful resources without `lifecycle { prevent_destroy = true }` where the repo's convention uses it.

**Secrets / state**
- Secrets in plain attributes or `output` without `sensitive = true` — they land in state and CI logs.
- `data` sources fetching secrets into state.

**Correctness**
- Implicit dependency expressed as a hardcoded string (an ARN/ID typed out) instead of a reference — breaks ordering and drifts.
- Unpinned or loosely pinned provider/module versions in a repo that pins (check `versions.tf` convention).
- Conditional resource (`count = var.x ? 1 : 0`) referenced elsewhere without the `[0]` / `one()` guard for the zero case.
- `depends_on` papering over a reference that should be an attribute dependency.

## Mechanical check

If the checkout has usable credentials/backend config, the plan is the truth:

```bash
terraform plan -no-color 2>/dev/null | grep -E 'must be replaced|destroy'
```

No credentials → reason from the diff, and say the plan wasn't run.

## When NOT to apply

- `.tf` files that are pure formatting/comment changes (`terraform fmt` diffs).
- Ephemeral/stateless resources (null_resource, data-only changes) for the replace-risk checks.

## Severity guidance

- **Blocker** — silent destroy/replace of a stateful resource; secret written to state or output un-marked.
- **Concern** — count/for_each identity churn; rename without `moved`; zero-case reference errors.
- **Nit** — pinning style drift; `depends_on` that's redundant but harmless.
