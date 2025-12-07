All code changes must include tests with 80%+ coverage.

## Testing Standards

### Run Tests
```bash
docker compose exec web pytest
```

### Check Coverage
```bash
docker compose exec web pytest --cov=apps --cov-report=term
```

### Test Requirements
- **Coverage**: Minimum 80% for new code
- **Types**: Unit tests for models/utils, integration tests for views
- **Naming**: `test_<functionality>.py` in each app
- **Structure**: Arrange-Act-Assert pattern

### What to Test

#### Models
- Field validations
- Model methods
- Relationships (ForeignKeys)
- Custom managers/querysets

#### Views
- Authentication required
- Permission checks
- GET requests return proper templates
- POST requests create/update data
- Invalid data returns errors

#### Forms
- Valid data passes validation
- Invalid data fails with errors
- Required fields are enforced

### Example Test Structure
```python
import pytest
from django.contrib.auth import get_user_model
from apps.assets.models import Asset

@pytest.mark.django_db
def test_asset_creation():
    user = get_user_model().objects.create_user(email="test@example.com")
    asset = Asset.objects.create(
        title="Test Asset",
        uploaded_by=user
    )
    assert asset.title == "Test Asset"
    assert str(asset) == "Test Asset"
```

## Before Completing Tasks
- Run full test suite: `pytest`
- Check coverage: `pytest --cov`
- Fix any failing tests
- Add tests for new functionality

See `.agent/SOP/testing.md` for detailed patterns.
