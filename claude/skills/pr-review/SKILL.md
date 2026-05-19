---
name: pr-review
description: Review a GitHub PR or current branch primarily for bugs (correctness, null/undefined, async/race, error handling, security, resource leaks, test rigor). Cites file:line per finding. House-rules criteria run as additive extras.
version: 2.1.0
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

Parse `$ARGUMENTS`:
- `--fg` present → strip it; proceed to step 1 in this session.
- PR number, no `--fg` → dispatch background and STOP.
- No PR number, no `--fg` → foreground branch review.

```bash
PROJECT=$(basename "$(git rev-parse --show-toplevel 2>/dev/null)" 2>/dev/null)
if [[ -z "$PROJECT" ]]; then
  echo "Not in a git repo — re-run with --fg." >&2
  exit 1
fi
SESSION_OUTPUT=$(claude --bg \
    --name "$PROJECT-review-<PR>" \
    --permission-mode bypassPermissions \
    "/pr-review --fg <PR>" 2>&1)
SESSION_ID=$(echo "$SESSION_OUTPUT" | grep 'backgrounded' | grep -oE '[a-f0-9]{8}' | head -1)
```

Report `Dispatched as $PROJECT-review-<PR> (session <SESSION_ID>). Open claude agents to watch.` If `SESSION_ID` is empty, surface `SESSION_OUTPUT` and stop. Do not fall back to foreground.

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
