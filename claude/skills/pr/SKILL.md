---
name: pr
description: Review code, fix issues, and create a pull request. Use when ready to open a PR for the current branch.
version: 1.0.0
argument-hint: "[--draft]"
allowed-tools: Bash(git*), Bash(gh*), Read, Edit, Write, AskUserQuestion
hooks:
  PreToolUse:
    - matcher: "Bash"
      hooks:
        - type: command
          if: "Bash(gh pr create*)"
          command: "$HOME/.claude/hooks/validate-pr.sh"
          timeout: 10
---

# Create Pull Request

Review diff, fix issues, push, create PR. `--draft` for draft PRs.

## 1. Preflight

- Verify not on main/master
- Uncommitted changes → commit (imperative mood, capitalized, no period, max 75 chars)
- PR already exists for branch → show URL and stop

## 2. Gather Context

- Extract ticket ID from branch name (e.g., `eng-142-feature`)
- `git log main..HEAD --oneline` + `git diff main...HEAD`
- If ticket ID found + Linear MCP available → fetch ticket details

## 3. Smell-check

Quick pass for obvious problems only:
- Secrets / credentials in the diff
- Commented-out code, leftover debug prints / `console.log`
- Obvious typos that break runtime

Anything deeper is `/pr-review`'s job — don't duplicate it here. Fix and recommit if needed, then proceed.

## 4. Create PR

`--draft` → draft. Default → ready for review.

### Title

- **Title Case**, 2-7 words, **noun phrase** (WHAT, not HOW)
- **No verb prefixes** ("Add", "Fix", "Update")
- Area prefix with colon when it adds clarity

Good: `Stripe Payment Integration`, `Auth: Token Renewal Fallback`
Bad: `Add payment feature`, `fix the auth bug`

### Description

Explain **WHY** — business context, user impact. The diff shows what; the description explains why.

```markdown
<1-2 sentence summary of WHY>

<paragraph: problem solved, what changes for users/system>

**Testing:**
- How tested
- Edge cases covered
```

- Link ticket if found (e.g., `Closes ENG-142`)
- No checklists, no implementation details

### Push + Create

```bash
git push -u origin <branch>
gh pr create --title "..." --body "..." [--draft]
```

Ticket ID but no Linear MCP → `Closes <TICKET-ID>` in description, move on.

Report: PR URL, draft status, review fixes (if any).
