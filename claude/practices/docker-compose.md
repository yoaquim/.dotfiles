# Docker Compose

All projects use `docker compose` (not `docker-compose`) with everything fully dockerized.

## Compose File Structure

Use `compose.yml` (not `docker-compose.yml`).

**No `version:` key** — it was deprecated and is ignored by modern Docker Compose. Never add it.

```yaml
services:
  app:
    build: .
    ports:
      - "8000:8000"
    volumes:
      - .:/app
    depends_on:
      db:
        condition: service_healthy
    env_file: .env

  db:
    image: postgres:15
    volumes:
      - db-data:/var/lib/postgresql/data
    environment:
      POSTGRES_DB: ${DB_NAME}
      POSTGRES_USER: ${DB_USER}
      POSTGRES_PASSWORD: ${DB_PASSWORD}
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U ${DB_USER}"]
      interval: 5s
      timeout: 5s
      retries: 5

  db-init:
    build: .
    command: ["python", "manage.py", "migrate"]
    depends_on:
      db:
        condition: service_healthy
    env_file: .env
    profiles:
      - init

  test:
    build: .
    command: ["pytest", "--tb=short"]
    depends_on:
      db:
        condition: service_healthy
    env_file: .env
    profiles:
      - test

volumes:
  db-data:
```

## Key Principles

### Everything Dockerized
- No local installs required — all dependencies live in containers
- Dev, test, and init all run inside Docker
- The host machine only needs Docker

### Database Init Container
- Separate `db-init` service for migrations and seed data
- Uses a profile so it doesn't run on every `docker compose up`
- Run explicitly: `docker compose --profile init run db-init`

### Test Container
- Dedicated `test` service with its own entrypoint
- Uses a profile: `docker compose --profile test run test`
- Can override command for specific tests: `docker compose --profile test run test pytest tests/test_auth.py`

### Escape Hatch (Shell Access)
- SSH into any running container: `docker compose exec app bash`
- Or start a one-off shell: `docker compose run --rm app bash`
- Use this for debugging, running one-off commands, inspecting state

### Volumes
- **Named volumes** for persistent data (databases, caches)
- **Bind mounts** for source code (enables live reload in dev)
- Never bind-mount over a named volume

### Entrypoints
- Use entrypoint scripts for startup logic (wait for DB, run migrations in dev, etc.)
- Keep `CMD` for the actual process
- Entrypoint should be idempotent — safe to run multiple times

```dockerfile
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh
ENTRYPOINT ["/entrypoint.sh"]
CMD ["python", "manage.py", "runserver", "0.0.0.0:8000"]
```

### Health Checks
- Always add health checks to services other containers depend on
- Use `depends_on` with `condition: service_healthy`
- Never use `sleep` hacks to wait for services

## Common Commands

```bash
# Start dev environment
docker compose up

# Run migrations
docker compose --profile init run db-init

# Run tests
docker compose --profile test run test

# Shell into app container
docker compose exec app bash

# Rebuild after Dockerfile changes
docker compose build

# Full reset (nuke volumes)
docker compose down -v
```

## Common Mistakes
- **Adding `version:`** — Deprecated and ignored. Never include it.
- **Using `docker-compose`** — Use `docker compose` (v2 plugin, no hyphen)
- **Using `docker-compose.yml`** — Use `compose.yml`

## Checklist for New Services
- [ ] Added to `compose.yml`
- [ ] Health check defined (if other services depend on it)
- [ ] Volume for persistent data (if applicable)
- [ ] Environment variables via `.env` (not hardcoded)
- [ ] Profile assigned if not part of default `up` (test, init, tooling)
