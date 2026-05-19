---
name: pr-review
description: Review a GitHub PR or current branch primarily for bugs (correctness, null/undefined, async/race, error handling, security, resource leaks, test rigor). Cites file:line per finding. House-rules criteria run as additive extras.
version: 2.2.0
argument-hint: "[--fg] [<PR-number>]"
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

**Primary job: find bugs.** Apply `bug-checklist.md` to every change. Cite `file:line` for every finding. Tag severity AND confidence.

`criteria/` are additive extras. They may or may not fire. They never replace the bug pass.

## 0. Dispatch (default background)

Parse `$ARGUMENTS` for three things in this order:

1. **`--fg` flag** anywhere → strip it; proceed to step 1 in this session. Done.
2. **PR identifier**, accepting any of:
   - Bare integer (e.g. `18`) — current repo
   - Full URL (e.g. `https://github.com/owner/repo/pull/18`) — extracts `owner/repo` and PR number
   - PR number + `-R owner/repo` — uses the explicit repo
3. **Nothing identifiable** → foreground branch review (skip dispatch entirely).

### Resolve PROJECT name (in order)

1. If a URL or `-R owner/repo` was provided → `PROJECT` = the repo segment (e.g. URL `…/nullbreaker/pull/21` → `nullbreaker`).
2. Else, if `git rev-parse --show-toplevel` succeeds → `PROJECT` = its basename.
3. Else → stop with the literal message: `Cannot derive project name. Pass a PR URL, use -R owner/repo, or re-run with --fg.` **Do not silently fall back to foreground.**

### Dispatch command

`$PR_ARG` below is whatever preserves repo context for the child: the full URL if a URL was passed, or `-R owner/repo <PR>` if `-R` was passed, or the bare integer if neither.

```bash
SESSION_OUTPUT=$(claude --bg \
    --name "$PROJECT-review-$PR" \
    --permission-mode bypassPermissions \
    "/pr-review --fg $PR_ARG" 2>&1)
SESSION_ID=$(echo "$SESSION_OUTPUT" | grep 'backgrounded' | grep -oE '[a-f0-9]{8}' | head -1)
```

Report: `Dispatched as $PROJECT-review-$PR (session $SESSION_ID). Open claude agents to watch.`

### Failure handling — read carefully

If `SESSION_ID` is empty, the dispatch failed. **Surface `SESSION_OUTPUT` verbatim to the user and stop.** Do not paraphrase. Do not invent reasons (e.g. "the --bg flag isn't available"). The `--bg` flag DOES exist on Claude Code; it is hidden from `claude --help` but valid. If the literal bash output says something else, report exactly what it says. **Do not fall back to running in foreground.** The user can re-run with `--fg` if they want that.

## 1. Read the diff

`gh pr diff <n>` (or `git diff main...HEAD`). End-to-end. >3k lines → one Explore subagent per logical module, synthesize.

## 2. Apply `bug-checklist.md` (primary)

Read the sibling file `bug-checklist.md`. Apply every section to every changed file. Every concrete bug → finding with `file:line`. Uncertain → `**Confidence:** Low`. Do not silently skip.

## 3. Apply criteria (additive)

Read every file in `criteria/`. Apply each. If a criterion doesn't apply, omit it from the `Criteria applied` header line. Citation goes on the relevant finding(s).

## 4. Compose output

Prefix with `header.md`. Substitute `{criteria}` with `general` plus any criteria slugs that fired (e.g. `general, doc-audit`).

Per finding:

```
### <Verb-first title — what to fix>

**Severity:** Blocker | Concern | Nit
**Confidence:** High | Med | Low
**Criterion:** general | <slug>
**Where:** `<file:line>`
**Issue:** <plain English, no jargon>
**Suggested fix:** <concrete action>

```diff
- current
+ proposed
```
```

If step 2 finds nothing, include this literal line in `## Findings`:

```
_No bug-class findings — diff reviewed line by line._
```

The hook requires either a `file:line` in the body or this exact line. A review with neither is blocked.

Sort: Blockers → Concerns → Nits. Within tier, `general` first, then criteria.

## 5. Deliver

Chat first. If PR# given, post via `gh pr review <n> --comment -b "$(cat <<'EOF' … EOF)"`. Hook blocks on missing header or missing engagement — fix and retry.

## Extending

- Broaden the primary pass → add to `bug-checklist.md`.
- New optional gate → drop a file at `criteria/<slug>.md` (What / Why / How to spot / When NOT / Severity).
- New mechanical check on the posted output → extend `hooks/check-post.sh`.
