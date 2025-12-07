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
- Use Tailwind utility classes (no custom CSS)
- Follow Rimas design system (see @tailwind-utilities)

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
