---
name: pr-review
description: Review a GitHub PR or current branch primarily for bugs, security issues, logic errors, edge cases, race conditions, and error-handling gaps. Cites specific code (file:line) per finding. House-rules criteria run as additive extras.
version: 2.0.0
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

**Primary job: find bugs.** Security issues, logic errors, off-by-ones, race conditions, error-handling gaps, edge cases, broken invariants. Cite `file:line` for every finding. Tag severity AND confidence.

Files in `criteria/` are **additive extras**, not the review. They may fire or not. They never replace the bug pass.

## 0. Dispatch (default background)

Parse `$ARGUMENTS`:
- `--fg` present → strip it; proceed to step 1 in current session.
- PR number present, no `--fg` → dispatch background and STOP.
- No PR number, no `--fg` → foreground branch review.

```bash
PROJECT=$(basename "$(git rev-parse --show-toplevel 2>/dev/null)" 2>/dev/null)
if [[ -z "$PROJECT" ]]; then
  echo "Not in a git repo — cannot derive project name. Re-run with --fg, or cd into the repo first." >&2
  exit 1
fi
SESSION_OUTPUT=$(claude --bg \
    --name "$PROJECT-review-<PR>" \
    --permission-mode bypassPermissions \
    "/pr-review --fg <PR>" 2>&1)
SESSION_ID=$(echo "$SESSION_OUTPUT" | grep 'backgrounded' | grep -oE '[a-f0-9]{8}' | head -1)
```

Report: `Dispatched as $PROJECT-review-<PR> (session <SESSION_ID>). Open claude agents to watch.` If `SESSION_ID` empty, surface `SESSION_OUTPUT` and stop. Do not fall back to foreground.

## 1. Read the diff end-to-end

`gh pr diff <n>` (or `git diff main...HEAD`). Read every changed line. If >3k lines, spawn one Explore subagent per logical module and synthesize.

## 2. Find bugs (primary pass)

For every changed file, ask:

- **Correctness**: Off-by-ones. Fence-post errors. Wrong operator (`<` vs `<=`, `&&` vs `||`). Inverted conditions. Mutation of caller's state.
- **Null/undefined**: Properties accessed on values that can be null/undefined. Optional chaining masking real bugs. Empty array/string assumptions.
- **Async/race**: Stale closures over mutable refs. Promise chains without `catch`. State writes after unmount. Concurrent reads of state being mutated. AbortController usage. Out-of-order delivery.
- **Error handling**: Silent `catch` that swallows real errors. Missing error paths in network/IO code. Errors thrown across realm/process boundaries.
- **Security**: Injection (SQL, command, prompt, XSS, template). Secrets in logs/responses. Auth checks missing or bypassed. Path traversal. Deserialization of untrusted input. Prototype pollution.
- **Resource/lifecycle**: Leaks (event listeners, timers, file handles, subscriptions). Cleanup missing on unmount/teardown. Unbounded growth (caches, logs, arrays).
- **Tests**: Asserting the wrong thing (smoke-test passes regardless of bug). Mocks that hide the bug being claimed fixed. Snapshots without semantic checks.

Every concrete bug → finding with `file:line`. If uncertain whether something is a bug, tag `**Confidence:** Low` rather than dropping it. Better to over-flag with explicit uncertainty than silently miss.

## 3. Apply criteria (additive extras)

For each file in `criteria/`: read it, check the diff against its rule. If it applies, add citing findings. If it doesn't apply, omit it from the `Criteria applied` header. **Criteria never replace step 2.**

## 4. Compose the output

Use `header.md` as the literal prefix. Substitute `{criteria}` with `general` plus any criteria slugs that fired (e.g. `general, doc-audit`). `general` is always listed since step 2 always runs.

Each finding:

```
### <Verb-first title — what to fix, not what's wrong>

**Severity:** Blocker | Concern | Nit
**Confidence:** High | Med | Low
**Criterion:** general | <criterion-slug>
**Where:** `<file:line>`
**Issue:** <one paragraph, plain English, no jargon>
**Suggested fix:** <concrete action>

```diff
- current
+ proposed
```
```

If step 2 turned up zero bug-class findings, say so explicitly:

```
_No bug-class findings — diff reviewed line by line._
```

The post-validation hook requires either a `file:line` citation in the body or this explicit no-findings line.

Sort findings: Blockers → Concerns → Nits. Within tier, group by criterion (`general` first).

## 5. Deliver

- Write the full review in chat first.
- If a PR number was given, post via `gh pr review <n> --comment -b "$(cat <<'EOF' … EOF)"`. The hook will block on missing header or missing engagement signal — fix the body and retry; do not bypass.
- No PR number → stop after chat.

## Adding a criterion later

1. Drop a new file at `criteria/<slug>.md` (What / Why / How to spot / When NOT / Severity).
2. No edits needed — step 3 globs `criteria/`.
3. If mechanically enforceable on the *posted* output, extend `hooks/check-post.sh`.

Criteria are gates, not the review. Keep each file tight.
