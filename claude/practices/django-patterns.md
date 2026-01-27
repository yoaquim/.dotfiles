Follow Django best practices and patterns from RIMAS DAM project.

## Project Structure
- Apps: `core/`, `users/`, `assets/`
- Templates: Use Django template inheritance with `base.html`
- Static files: Managed by Django, built with Tailwind CSS v4

## Key Patterns to Follow

### 1. Views
- Use `@login_required` decorator on all views
- Use `@permission_required` for permission checks
- Follow REST-like URL patterns
- Return proper HTTP status codes

### 2. Models
- Use UUIDs for primary keys
- Add `created_at` and `updated_at` timestamps
- Use `related_name` on ForeignKeys
- Add `__str__` methods for admin display

### 3. Templates
- Extend `base.html` for all pages
- Use permission checks: `{% if perms.assets.add_asset %}`
- **⛔ NO CUSTOM CSS** - Use Tailwind utility classes ONLY (no `<style>` blocks, no custom classes)
- See @tailwind-utilities for patterns

### 4. Forms
- Use Django ModelForms
- Add CSRF tokens: `{% csrf_token %}`
- Use `method="post"` for mutations
- Validate on server-side always

## SOP Documents
Reference these for detailed patterns:
- `.agent/SOP/tailwind-development.md` - Frontend patterns
- `.agent/SOP/testing.md` - Testing patterns
- `.agent/SOP/branching-workflow.md` - Git workflow

## Tech Stack
- Django 5.0 + PostgreSQL 15
- HTMX for dynamic interactions
- Tailwind CSS v4 (standalone CLI)
- Docker Compose for development

## ⛔ CRITICAL: Dependency Management

**When adding ANY new library:**

1. **Add to `requirements.txt`** - Never assume it's already there
2. **System dependencies** → Update `Dockerfile` with `apt-get install`
3. **Test in Docker** - Run `docker compose build && docker compose up` and verify it works
4. **Never use lazy imports to hide missing deps** - Fix the root cause

**Examples:**
```bash
# Python package
echo "weasyprint>=60.0" >> requirements.txt

# System deps in Dockerfile
RUN apt-get update && apt-get install -y \
    libpango-1.0-0 \
    libpangocairo-1.0-0 \
    && rm -rf /var/lib/apt/lists/*
```

**Common system deps:**
- `weasyprint`: libcairo2, libpango-1.0-0, libpangocairo-1.0-0, libgdk-pixbuf-2.0-0
- `pillow`: libjpeg-dev, zlib1g-dev
- `psycopg2`: libpq-dev
