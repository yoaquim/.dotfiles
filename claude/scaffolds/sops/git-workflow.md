# Git Workflow

**Universal SOP** - This workflow applies to all projects.

---

## Branch Strategy

### Main Branches
- **`main`** - Production-ready code
- **`develop`** - Integration branch (optional, for GitFlow)

### Feature Branches
- **Pattern**: `feature/feature-name`
- **Purpose**: New features or enhancements
- **Base**: Branch from `main`
- **Merge**: Back to `main`

### Bugfix Branches
- **Pattern**: `fix/bug-name`
- **Purpose**: Bug fixes
- **Base**: Branch from `main`
- **Merge**: Back to `main`

### Hotfix Branches
- **Pattern**: `hotfix/issue-name`
- **Purpose**: Critical production fixes
- **Base**: Branch from `main`
- **Merge**: Back to `main` immediately

---

## Standard Workflow

### Starting New Work

```bash
# Ensure you're on main and up-to-date
git checkout main
git pull origin main

# Create feature branch
git checkout -b feature/your-feature-name

# Or for a bug fix
git checkout -b fix/bug-description
```

### During Development

```bash
# Stage and commit changes
git add path/to/file
git commit -m "feat: Add user authentication feature"

# Push to remote
git push -u origin feature/your-feature-name
```

### Completing Work

```bash
# Ensure tests pass
[run your tests]

# Merge into main
git checkout main
git pull origin main
git merge feature/your-feature-name

# Push to remote
git push origin main

# Delete feature branch
git branch -d feature/your-feature-name
git push origin --delete feature/your-feature-name
```

---

## Commit Message Guidelines

### Format
```
type: Brief description (50 chars or less)

Longer explanation if needed (wrap at 72 chars).
- Use bullet points for multiple changes
- Reference issue numbers when relevant
```

### Types
- **feat**: New feature
- **fix**: Bug fix
- **docs**: Documentation changes
- **style**: Code style changes (formatting)
- **refactor**: Code refactoring
- **test**: Adding or updating tests
- **chore**: Maintenance tasks

### Examples
```bash
git commit -m "feat: Add user login functionality"

git commit -m "fix: Resolve database connection timeout

- Increased timeout from 5s to 30s
- Added retry logic for transient failures
- Updated error messages"

git commit -m "docs: Update README with setup instructions"
```

---

## Best Practices

1. **Commit Often**: Small, focused commits are easier to review and revert
2. **Write Good Messages**: Future you will thank present you
3. **Test Before Committing**: Catch issues early
4. **Keep Branches Short-Lived**: Merge frequently to avoid conflicts
5. **Pull Before Push**: Stay synchronized
6. **Never Force Push to Main**: Protect shared branches
7. **Review Before Merging**: Even your own code deserves a second look

---

## Common Commands

### Checking Status
```bash
git status                    # Current status
git log --oneline --graph    # Commit history
git diff                     # Uncommitted changes
git diff --cached            # Staged changes
```

### Undoing Changes
```bash
git checkout -- file         # Discard changes to file
git reset HEAD file          # Unstage file
git commit --amend           # Amend last commit
git reset --soft HEAD~1      # Undo last commit (keep changes)
git reset --hard HEAD~1      # Undo last commit (discard changes)
```

### Stashing
```bash
git stash                    # Save changes temporarily
git stash pop                # Apply last stash
git stash list               # List stashes
```

---

## Troubleshooting

### Merge Conflicts
```bash
# 1. Open conflicted files
# 2. Look for markers: <<<<<<<, =======, >>>>>>>
# 3. Resolve manually
# 4. Stage resolved files
git add path/to/resolved/file

# 5. Continue merge
git merge --continue
```

### Accidentally Committed to Main
```bash
# Create branch from current state
git branch feature/accidental-work

# Reset main to origin
git reset --hard origin/main

# Switch to feature branch
git checkout feature/accidental-work
```

---

**Location**: `~/.claude/scaffolds/sops/git-workflow.md`
**Referenced By**: All projects via `.agent/sops/README.md`
**Last Updated**: 2025-10-25
