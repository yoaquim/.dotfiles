---
name: pr-review
description: Review a GitHub PR or the current branch against Yoaquim's curated review criteria. Cites which criteria fired per finding and posts to the PR when given a PR number.
version: 1.0.0
argument-hint: "[<PR-number>]  (omit for current branch vs main)"
allowed-tools: Bash(gh*), Bash(git*), Read, Glob, Grep
hooks:
  PreToolUse:
    - matcher: "Bash"
      hooks:
        - type: command
          command: "$HOME/.claude/skills/pr-review/hooks/check-post.sh"
          timeout: 10
---

# PR Review

Review a GitHub PR (by number) or the current branch diff against `criteria/` files, then post the result if a PR number was provided.

## 1. Resolve scope

- **Arg is a PR number** (e.g. `/pr-review 18`) → `gh pr view <n>` and `gh pr diff <n>` from the current repo. If `-R owner/repo` is needed, infer from the working directory or ask once.
- **No arg** → `git diff main...HEAD` (or `master`, whichever is the default branch). No auto-post — output stays in chat.

## 2. Load criteria

Read every file in `criteria/`. Each file is one criterion:
- **What it says** — the rule.
- **Why** — the reason / incident.
- **How to spot** — concrete signals in a diff.

Apply *all* loaded criteria to the diff. If a criterion plainly doesn't apply (e.g. `doc-audit` on a PR with no body claims), say so explicitly in the chat output and omit it from the `Criteria applied` header line.

## 3. Walk the checklist

Follow `checklist.md` in order. Don't reorder, don't skip. If a step doesn't apply, write "n/a — <one-line reason>" and continue.

## 4. Compose the output

Use `header.md` as the literal prefix (substitute `{criteria}` with the comma-separated list of criteria that actually produced findings or were affirmatively checked).

Each finding follows this block:

```
### <Verb-first title — what to do, not what's wrong>

**Severity:** Blocker | Concern | Nit
**Criterion:** `<criterion-slug>`
**Where:** `<file:line>` (or file path if line isn't meaningful)
**Issue:** <one paragraph, plain English, no jargon>
**Suggested fix:** <concrete action — what to change>

```diff
- current shape
+ proposed shape
```
```

Sort findings: Blockers first, then Concerns, then Nits. Within each tier, group by criterion.

If there are zero findings, still emit the header and a single `## Findings` section with `_No findings — all loaded criteria passed._`

## 5. Deliver

- **Always** write the full review in chat first.
- **If a PR number was given**: after the user has seen the chat output, post via `gh pr review <n> --comment -b "$(cat <<'EOF' … EOF)"`. The post-validation hook will block if the header or citations are missing — don't bypass it; fix and retry.
- **No PR number**: stop after chat output.

## Adding a new criterion later

1. Drop a new file in `criteria/<slug>.md` following the existing shape (What / Why / How to spot).
2. No edits to `SKILL.md` needed — step 2 globs `criteria/`.
3. If the criterion is mechanically enforceable on the *posted* output, extend `hooks/check-post.sh` (sibling to this file) with the new check.

Keep criteria files tight: one rule, one example, one sentence on when *not* to apply. Sprawl makes the skill slow and noisy.
