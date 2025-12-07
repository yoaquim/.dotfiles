Follow the feature branch workflow for all changes.

## Branch Workflow

### 1. Create Feature Branch
```bash
git checkout main
git pull origin main
git checkout -b feature/feature-name
```

### 2. Make Changes & Commit
```bash
# Make your changes
git add .
git commit -m "Description of changes"
```

### 3. Test Before Merging
```bash
docker compose exec web pytest
# Ensure all tests pass
```

### 4. Merge to Main
```bash
git checkout main
git merge feature/feature-name
git push origin main
```

### 5. Clean Up
```bash
git branch -d feature/feature-name
```

## Commit Message Format
- Use imperative mood: "Add feature" not "Added feature"
- Be descriptive: "Fix: Admin CSS conflicts" not "Fix bug"
- Reference tasks: "Task 11: Implement collapsible sidebar"

## Important Rules
- **Never commit to main directly**
- **Always test before merging**
- **Delete feature branches after merge**
- **Pull before creating new branches**
- **Use meaningful branch names**: `feature/`, `bugfix/`, `hotfix/`

## Files to Never Commit
- `.env` (contains secrets)
- `*.pyc` (Python bytecode)
- `__pycache__/` (Python cache)
- `static/css/tailwind.css` (generated file)
- `db.sqlite3` (local database)

See `.agent/SOP/branching-workflow.md` for details.
