# Criterion: `rails`

## What it says

Rails diffs get checked for ActiveRecord and controller failure modes: query behavior, callback/validation bypasses, migration safety, and params handling.

## How to spot

**Queries**
- Iteration touching an association per record without `includes`/`preload`/`eager_load` → N+1.
- `.all.each` / unbatched iteration over a large table — should be `find_each`/`in_batches`.
- Scope or class method that can return `nil` where callers chain onto it (scopes must return a relation).

**Write paths**
- `update_column` / `update_all` / `insert_all` / `delete_all` — all skip validations AND callbacks. Flag unless the diff shows that's intended.
- `save(validate: false)` without justification.
- Multi-model writes without a wrapping `transaction`.
- Callbacks with external side effects (mailers, HTTP) inside transactions — use `after_commit`, not `after_save`.

**Migrations**
- Adding an index on a large table without `algorithm: :concurrently` (Postgres) — table lock.
- `change` method with operations that can't auto-reverse; data changes inside schema migrations.
- Column referenced by code in the same deploy that drops/renames it — old code runs against new schema during rollout.
- Non-nullable column added without default on a populated table.

**Controllers / params**
- Mass assignment: `params` passed to `new`/`update` without `permit` (or permitting `:admin`-ish fields).
- Authorization checked in the view but not the action; `before_action` skipped too broadly (`skip_before_action` with no `only:`).
- `Time.now` instead of `Time.current` / `Time.zone.now`.
- String-interpolated SQL in `where`/`order` instead of placeholders (`order` is a common injection vector).

## When NOT to apply

- Diff touches no Ruby under `app/`, `lib/`, or `db/`.
- `update_all`-style bulk writes in a data-repair rake task that's explicitly one-shot.

## Severity guidance

- **Blocker** — validation/callback bypass on models that depend on them; mass assignment of privileged fields; SQL injection; locking migration on a hot table.
- **Concern** — N+1 on request paths; `after_save` side effects that belong in `after_commit`; irreversible migrations.
- **Nit** — `Time.now` in non-user-facing code; unbatched iteration in a small-table admin task.
