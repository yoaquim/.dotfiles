# Rails

## Models & queries

- Business logic in models or POROs (`app/services/`, `app/queries/`) — controllers stay thin
- Kill N+1s at write time: `includes`/`preload` where associations are iterated; prefer `strict_loading` on hot paths
- Scopes for reusable query fragments; no raw SQL strings in controllers/views
- Validations in the model AND a database constraint for anything that must hold (null, unique, FK)

## Controllers

- Strong params always — never `params.permit!`
- One resource per controller; custom actions are a smell, extract a new controller
- Respond with proper status codes: 422 for validation failures, 404 via `find` raising

## Migrations

- Schema migrations only — no data backfills inside schema migrations; separate task/migration
- Reversible (`change` with reversible ops, or explicit `up`/`down`)
- Index every foreign key and every column used in WHERE/ORDER on real data
- Never edit a merged migration; add a new one

## Jobs & callbacks

- Anything slow or external (mail, HTTP, exports) goes to a background job
- Jobs idempotent — retries happen
- Avoid callback chains that touch other models; prefer explicit service objects

## Tests

- Match the repo's framework (RSpec or Minitest) and existing factory/fixture style
- Request specs over controller specs; model specs for validations/scopes/logic
- One assertion concept per example; no `sleep` in tests
