# Cloudflare Workers

Runtime is workerd, not Node — assume nothing from Node core is available unless `nodejs_compat` is enabled and the API is on the supported list.

## Bindings & config

- All bindings (D1, KV, R2, DO, queues, secrets) declared in `wrangler.toml`/`wrangler.jsonc` and accessed via `env` — never global state
- Secrets via `wrangler secret put`, never in config or code
- Type the `Env` interface; keep it in one place

## Handlers

- No work outside the request lifecycle — global scope runs once per isolate, not per request
- Use `ctx.waitUntil()` for fire-and-forget work (logging, analytics); never block the response on it
- CPU time is capped — push heavy work to queues or Durable Objects

## D1 / Drizzle

- Schema changes only through migrations (`wrangler d1 migrations` / drizzle-kit) — never ad-hoc DDL
- Batch related statements with `db.batch()` — D1 has no interactive transactions
- Parameterized queries always (Drizzle does this; never interpolate into raw SQL)

## Durable Objects

- One DO = one consistency domain; keep them small and single-purpose
- DO storage is the source of truth — don't cache DO state in the Worker
- Use `blockConcurrencyWhile()` for init; remember I/O gates serialize storage ops, not your async logic

## Dev & tests

- `wrangler dev` for local; `--remote` only when a binding can't be emulated
- Tests with `@cloudflare/vitest-pool-workers` so code runs in workerd, not Node
