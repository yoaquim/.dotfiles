# Criterion: `cloudflare-workers`

## What it says

Workers diffs get checked for the platform's execution-model traps: global state across requests, waitUntil misuse, storage-consistency assumptions, and binding/config drift.

## How to spot

**Execution model**
- Mutable module-scope state (caches, counters, request context) — isolates are REUSED across requests and users; a per-request value in global scope leaks between users.
- Work after the response that isn't wrapped in `ctx.waitUntil()` — the isolate can be frozen the moment the response returns; the work silently never runs.
- Promise created but not awaited AND not passed to `waitUntil` — same silent drop.
- Long CPU-bound work on the request path — CPU-time limits kill it under load even when it works in dev.

**Storage semantics**
- KV read-after-write treated as consistent — KV is eventually consistent across colos; a write then immediate read of the same key from another request can be stale. D1/DO is where read-after-write belongs.
- D1 multi-statement writes without `batch()` — no transaction, partial-write state on failure.
- Durable Object treated as parallel — a DO instance is single-threaded; an `await` inside a handler yields to OTHER queued requests unless the critical section uses `blockConcurrencyWhile`/state gates.
- Cache API used for per-user responses without varying the cache key.

**Config / bindings**
- `process.env.X` instead of the `env` binding parameter — undefined at runtime on Workers.
- New binding used in code (`env.MY_KV`, `env.DB`) with no matching entry in `wrangler.toml`/`wrangler.jsonc` in the same diff — deploys then 500s.
- Compatibility date/flags changed without a note on what behavior it flips.
- Secret referenced in code but committed as a plain `[vars]` entry instead of a secret.

## When NOT to apply

- Diff touches no worker code or wrangler config.
- Module-scope CONSTANTS (config objects, compiled regexes) — only mutable/request-derived state is the bug.

## Severity guidance

- **Blocker** — per-request/user state at module scope; post-response work not in `waitUntil`; binding used but not declared.
- **Concern** — KV consistency assumptions on read-after-write paths; unbatched D1 multi-writes; DO interleaving on awaited critical sections.
- **Nit** — compatibility-date hygiene; cache-key breadth where blast radius is low.
