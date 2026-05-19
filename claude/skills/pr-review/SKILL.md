---
name: pr-review
description: Review a GitHub PR or the current branch against Yoaquim's curated review criteria. Cites which criteria fired per finding and posts to the PR when given a PR number.
version: 1.0.0
argument-hint: "[--fg] [<PR-number>]  (PR# auto-backgrounds as 'review-pr-N' unless --fg; omit PR# for current branch in foreground)"
allowed-tools: Bash(gh*), Bash(git*), Bash(claude*), Read, Glob, Grep
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

## 0. Dispatch as background agent (default)

This skill **defaults to backgrounding itself** as a named agent so reviews show up in `claude agents`. Foreground execution is opt-in via `--fg`.

Parse `$ARGUMENTS`:
- If `--fg` is present anywhere in the arguments → strip it and proceed to step 1 in the current session.
- If a PR number is present (a bare integer like `18`) and `--fg` is **not** present → dispatch a background and STOP. Do not perform the review in this session.
- If no PR number and no `--fg` → there's no name to derive (branch reviews use the working-directory context). Proceed to step 1 in the current session and skip the dispatch.

### Background dispatch

When dispatching, run exactly this:

```bash
SESSION_OUTPUT=$(claude --bg \
    --name "review-pr-<PR>" \
    --permission-mode default \
    "/pr-review --fg <PR>" 2>&1)
SESSION_ID=$(echo "$SESSION_OUTPUT" | grep 'backgrounded' | grep -oE '[a-f0-9]{8}' | head -1)
```

Substitute `<PR>` with the PR number. Then report to the user, plainly:

> Dispatched `/pr-review <PR>` as background agent **review-pr-<PR>** (session `<SESSION_ID>`). Open `claude agents` to watch or attach.

If `SESSION_ID` is empty, surface `SESSION_OUTPUT` to the user and stop — do not silently fall back to running in foreground.

Then STOP. The child session will execute the review with `--fg` set; this session has nothing more to do.

## 1. Resolve scope

- **Arg is a PR number** (e.g. `/pr-review --fg 18`) → `gh pr view <n>` and `gh pr diff <n>` from the current repo. If `-R owner/repo` is needed, infer from the working directory or ask once.
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
