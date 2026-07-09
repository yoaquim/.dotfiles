# Criterion: `docker`

## What it says

Dockerfile and compose diffs get checked for build-cache correctness, secret leakage into layers, and runtime safety.

## How to spot

**Layers / cache**
- `COPY . .` before dependency install — every source edit busts the dependency cache. Lockfile copy + install should precede source copy.
- Cache-sensitive command order changed in a way that silently stops layer reuse (or worse, keeps STALE cache: `apt-get update` in a separate layer from `apt-get install`).
- Multi-stage build copying more than the built artifact from the builder stage (node_modules, .git, src).

**Secrets**
- `ARG`/`ENV` carrying tokens or passwords — build args are visible in `docker history`; ENV persists into the image.
- Secret files COPY'd in and `rm`'d in a LATER layer — still present in the earlier layer.
- Missing/weak `.dockerignore` when the diff adds `COPY . .` — `.env`, `.git`, credentials ride along.

**Runtime**
- No `USER` directive — container runs as root; new service in compose without `user:` where the repo's convention sets one.
- Base image on `:latest` or unpinned major — builds are non-reproducible (match the repo's pinning convention).
- `CMD`/`ENTRYPOINT` in shell form for a long-running process — PID 1 is a shell, signals (SIGTERM) never reach the app, graceful shutdown breaks.
- Healthcheck removed or missing on a service others `depends_on` with `condition: service_healthy`.
- Compose volume mount shadowing a path the image build populated (mounting `./src` over installed deps).

## When NOT to apply

- Diff touches no Dockerfile/compose/`.dockerignore`.
- Dev-only compose overrides (`docker-compose.override.yml`) for the root-user and pinning checks — flag only if it's the production path.

## Severity guidance

- **Blocker** — secret baked into a layer or build arg; signals not reaching PID 1 on a service that needs graceful shutdown.
- **Concern** — cache-busting dependency installs; stale apt cache pattern; root user on a production service; broad COPY without `.dockerignore`.
- **Nit** — `:latest` in dev-only images; layer-count golf.
