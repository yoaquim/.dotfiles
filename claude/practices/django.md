# Django Patterns

Preferred patterns for Django projects.

## Views

- Function-based views by default — class-based only when inheritance genuinely helps (e.g. mixins for common permission patterns)
- `@login_required` on all views unless explicitly public
- `@permission_required` for RBAC — server-side enforcement always, never trust client-side only
- Return proper HTTP status codes
- REST-like URL patterns: `/resources/`, `/resources/<id>/`

## Models

- UUIDs for primary keys
- `created_at` and `updated_at` timestamps on every model
- `related_name` on all ForeignKeys
- `__str__` method on every model
- Fat models, thin views — business logic belongs on the model or in a service layer, not in views

## Templates

- Template inheritance: all pages extend `base.html`
- Permission checks in templates: `{% if perms.app.action_model %}`
- No custom CSS — Tailwind utility classes only (see tailwind.md)
- CSRF tokens on all forms: `{% csrf_token %}`

## Forms

- ModelForms for CRUD
- Server-side validation always — client-side is UX only
- `method="post"` for all mutations

## Dependencies

When adding any library:
1. Add to `requirements.txt`
2. System deps → update `Dockerfile` with `apt-get install`
3. Test in Docker: `docker compose build && docker compose up`
4. Never use lazy imports to hide missing deps

## Testing

- `pytest` + `pytest-django`
- Factory Boy for model fixtures
- Test views via Django test client
- Test permissions with different user roles
