# Docker

Everything dockerized. No local installs — host machine only needs Docker.

## Dockerfile

- Multi-stage builds for production (build stage + runtime stage)
- Pin base image versions: `python:3.12-slim`, not `python:latest`
- Copy dependency files first, install, then copy source (layer caching)
- Use `.dockerignore` to exclude `.git`, `node_modules`, `__pycache__`, `.env`
- Entrypoint scripts for startup logic — keep `CMD` for the actual process
- Entrypoints must be idempotent

## Compose

Use `compose.yml` (not `docker-compose.yml`). Use `docker compose` (not `docker-compose`).

No `version:` key — deprecated and ignored.

```yaml
services:
  app:
    build: .
    ports: ["8000:8000"]
    volumes: [".:/app"]
    depends_on:
      db: { condition: service_healthy }
    env_file: .env

  db:
    image: postgres:15
    volumes: [db-data:/var/lib/postgresql/data]
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
      db: { condition: service_healthy }
    env_file: .env
    profiles: [init]

  test:
    build: .
    command: ["pytest", "--tb=short"]
    depends_on:
      db: { condition: service_healthy }
    env_file: .env
    profiles: [test]

volumes:
  db-data:
```

## Principles

- Health checks on services others depend on — `depends_on` with `condition: service_healthy`
- Never use `sleep` hacks to wait for services
- Named volumes for persistent data, bind mounts for source code
- Profiles for non-default services: `docker compose --profile test run test`
- Environment variables via `.env`, never hardcoded

## Commands

```bash
docker compose up                              # dev
docker compose --profile init run db-init      # migrations
docker compose --profile test run test         # tests
docker compose exec app bash                   # shell into container
docker compose build                           # rebuild
docker compose down -v                         # full reset
```
