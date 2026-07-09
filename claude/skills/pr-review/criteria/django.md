# Criterion: `django`

## What it says

Django diffs get checked for the failure modes the generic bug checklist can't see: ORM query behavior, migration/model drift, signal and save-path bypasses, and request-layer safety.

## How to spot

**Queries**
- Loop over a queryset that accesses a related object per iteration → N+1. Look for a missing `select_related` / `prefetch_related` on the queryset the loop consumes.
- Queryset evaluated more than once (list(), len(), iteration) without caching — each evaluation re-hits the DB.
- `.filter()` on an unindexed column in a hot path; new model fields queried by lookup without `db_index=True`.
- `.count()` vs `len()`, `.exists()` vs truthiness — wrong one on a large table.

**Write paths**
- `.update()` / `bulk_create` / `bulk_update` / `update_or_create` on models that rely on `save()` overrides or signals — those paths skip them silently.
- `update_fields` lists missing a field the method body actually mutates.
- Multi-model writes without `transaction.atomic()` — partial-write state on failure.
- Signals with side effects (emails, external calls) fired inside a transaction — they run even if the transaction rolls back, or run mid-transaction against uncommitted state.

**Migrations**
- Model change in the diff with no matching migration (or vice versa).
- Data migration mixed into a schema migration; `RunPython` without a reverse function.
- Non-nullable field added without a default on a populated table.

**Request layer**
- `csrf_exempt`, `login_required` missing on a mutating view, permission checks in the template but not the view.
- Raw SQL (`.raw()`, `cursor.execute`) with string interpolation instead of params.
- `naive datetime` (`datetime.now()` instead of `timezone.now()`) with `USE_TZ`.
- Form/serializer validation bypassed by reading `request.POST`/`request.data` directly after validation ran.

## When NOT to apply

- Diff touches no Python under a Django app (pure frontend/docs change in a Django repo).
- Test-only diffs, unless the test asserts ORM behavior incorrectly (that's a `Tests` finding).

## Severity guidance

- **Blocker** — writes that skip `save()`/signals the codebase depends on; missing transaction around multi-model writes; validation/auth bypass; SQL injection.
- **Concern** — N+1 on a request path; migration/model drift; naive datetimes.
- **Nit** — `.count()`/`.exists()` misuse off the hot path; missing `db_index` on a rarely-queried field.
