Ensure all features respect Django RBAC permissions.

## Permission System

RIMAS DAM uses Django groups for role-based access control:

### Roles
| Role   | add_* | change_* | delete_* | view_* | Admin |
|--------|-------|----------|----------|--------|-------|
| Viewer | ❌     | ❌        | ❌        | ✅      | ❌     |
| Editor | ✅     | ✅        | ❌        | ✅      | ❌     |
| Admin  | ✅     | ✅        | ✅        | ✅      | ✅     |

### Server-Side Protection (Views)
```python
from django.contrib.auth.decorators import login_required, permission_required

@login_required
@permission_required("assets.add_asset", raise_exception=True)
def asset_upload(request):
    # Only users with add_asset permission can access
    pass
```

### Template-Side Visibility (UI)
```django
{% if perms.assets.add_asset %}
  <a href="{% url 'asset_upload' %}">Upload Asset</a>
{% endif %}
```

### Common Permission Checks

#### View Permissions
```django
{% if perms.assets.view_asset %}
  <!-- Show content list -->
{% endif %}
```

#### Add Permissions
```django
{% if perms.assets.add_asset %}
  <button>Add New</button>
{% endif %}
```

#### Change Permissions
```django
{% if perms.assets.change_asset %}
  <button>Edit</button>
{% endif %}
```

#### Delete Permissions
```django
{% if perms.assets.delete_asset %}
  <button>Delete</button>
{% endif %}
```

#### Admin Access
```django
{% if user.is_staff %}
  <a href="{% url 'admin:index' %}">Admin Panel</a>
{% endif %}
```

## Checklist for New Features
- [ ] Views protected with `@permission_required`
- [ ] Templates hide UI elements based on permissions
- [ ] Server-side enforcement (never trust client-side only)
- [ ] Proper error messages for unauthorized access
- [ ] Test with different user roles

See Task 06 and Task 08 documentation for implementation details.
