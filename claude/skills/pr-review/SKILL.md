---
name: pr-review
description: Review a GitHub PR or current branch primarily for bugs (correctness, null/undefined, async/race, error handling, security, resource leaks, test rigor). Posts findings as resolvable inline review comments. Auto-APPROVES when nothing's wrong. House-rules criteria run as additive extras.
version: 3.1.0
argument-hint: "[--fg] [--once] [<PR-number-or-URL>]"
allowed-tools: Bash(gh*), Bash(git*), Bash(claude*), Bash(jq*), Bash(mktemp*), Bash(*check-pr-state.sh*), Bash(sleep*), Bash(date*), Read, Glob, Grep
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

Parse `$ARGUMENTS` for these in order:

1. **`--fg` flag** anywhere → strip it; proceed to step 1 in this session. Done.
2. **`--once` flag** → strip it and remember; passed to step 6 to skip the watch loop after delivery.
3. **PR identifier**, accepting any of:
   - Bare integer (e.g. `18`) — current repo
   - Full URL (e.g. `https://github.com/owner/repo/pull/18`) — extracts `owner/repo` and PR number
   - PR number + `-R owner/repo` — uses the explicit repo
4. **Nothing identifiable** → foreground branch review (skip dispatch entirely; `--once` is implied for branch mode since there's no PR to watch).

### Resolve PROJECT name (in order)

1. If a URL or `-R owner/repo` was provided → `PROJECT` = the repo segment (e.g. URL `…/nullbreaker/pull/21` → `nullbreaker`).
2. Else, if `git rev-parse --show-toplevel` succeeds → `PROJECT` = its basename.
3. Else → stop with the literal message: `Cannot derive project name. Pass a PR URL, use -R owner/repo, or re-run with --fg.` **Do not silently fall back to foreground.**

### Parse Linear ticket (best-effort)

Try to extract a ticket like `per-83` or `paracha-12` from the PR's branch name or title. If found, include it in the session name; if not, omit cleanly.

```bash
PR_META=$(gh pr view $PR_ARG --json headRefName,title 2>/dev/null || echo '{}')
TICKET=$(jq -r '"\(.headRefName // "") \(.title // "")"' <<<"$PR_META" \
  | grep -ioE '[a-z]+-[0-9]+' | head -1 | tr 'A-Z' 'a-z')

if [[ -n "$TICKET" ]]; then
  SESSION_NAME="${PROJECT}-review-${TICKET}-pr-${PR}"
else
  SESSION_NAME="${PROJECT}-review-pr-${PR}"
fi
```

### Dispatch command

`$PR_ARG` below is whatever preserves repo context for the child: the full URL if a URL was passed, or `-R owner/repo <PR>` if `-R` was passed, or the bare integer if neither.

```bash
SESSION_OUTPUT=$(claude --bg \
    --name "$SESSION_NAME" \
    --permission-mode bypassPermissions \
    "/pr-review --fg $PR_ARG" 2>&1)
SESSION_ID=$(echo "$SESSION_OUTPUT" | grep 'backgrounded' | grep -oE '[a-f0-9]{8}' | head -1)
```

Report: `Dispatched as $SESSION_NAME (session $SESSION_ID). Open claude agents to watch.`

### Failure handling — read carefully

If `SESSION_ID` is empty, the dispatch failed. **Surface `SESSION_OUTPUT` verbatim to the user and stop.** Do not paraphrase. Do not invent reasons (e.g. "the --bg flag isn't available"). The `--bg` flag DOES exist on Claude Code; it is hidden from `claude --help` but valid. If the literal bash output says something else, report exactly what it says. **Do not fall back to running in foreground.** The user can re-run with `--fg` if they want that.

## 1. Read the diff

`gh pr diff <n>` (or `git diff main...HEAD`). End-to-end. >3k lines → one Explore subagent per logical module, synthesize.

## 2. Apply `bug-checklist.md` (primary)

Read the sibling file `bug-checklist.md`. Apply every section to every changed file. Every concrete bug → finding with `file:line`. Uncertain → `**Confidence:** Low`. Do not silently skip.

## 3. Apply criteria (additive)

Read every file in `criteria/`. Apply each. If a criterion doesn't apply, omit it from the `Criteria applied` header line. Citation goes on the relevant finding(s).

## 4. Compose output

Two outputs to compose:

**(a) Top-level review body** — prefix with `header.md`, substitute `{criteria}` with `general` plus any criteria slugs that fired. Body is for cross-cutting notes, summary, and the `_No bug-class findings_` line when applicable. Per-finding details live in inline comments, not the body.

**(b) Inline comment per finding** — one resolvable thread on the cited `file:line`. Format each comment as:

```
### <Verb-first title — what to fix>

**Severity:** Blocker | Concern | Nit
**Confidence:** High | Med | Low
**Criterion:** general | <slug>
**Issue:** <plain English, no jargon>
**Suggested fix:** <concrete action>

```diff
- current
+ proposed
```
```

(No `**Where:**` line — `path` and `line` are structural on the comment itself.)

Findings without a usable `file:line` (rare — cross-cutting issues) → fold into the top-level body under a `## Cross-cutting` section instead of the comments array.

If step 2 finds nothing, the body is the **clean approval template**:

```
# 👾 Reviewed by Claude via the `/pr-review` skill 👾

✅ **Ready to merge** — _No bug-class findings; diff reviewed line by line._
```

(`_No bug-class findings` is required by the hook. The `✅ Ready to merge` line is human-facing — dispatch doesn't parse it; it watches GitHub's `reviewDecision == APPROVED` event.)

Sort findings: Blockers → Concerns → Nits. Within tier, `general` first, then criteria.

## 5. Deliver

Chat first. Then post via `gh api .../reviews`.

```bash
# Determine event from finding count
if [[ "$FINDING_COUNT" -eq 0 ]]; then
  EVENT="APPROVE"
else
  EVENT="REQUEST_CHANGES"
fi

# Build comments[] — JSON array of {path, line, body} entries.
# One entry per finding with a real file:line citation.
# Use start_line + line for multi-line ranges (e.g. file:380-383).
INLINE_COMMENTS_JSON='[
  {"path": "src/foo.ts", "line": 42, "body": "<finding markdown>"},
  ...
]'

# Compose body (header.md content + summary + any cross-cutting notes)
BODY="$(cat header.md)
... summary lines ...
"

# Write payload to a tempfile so the hook can read and validate it.
PAYLOAD=$(mktemp -t review-XXXXXX.json)
jq -n \
  --arg body "$BODY" \
  --arg event "$EVENT" \
  --argjson comments "$INLINE_COMMENTS_JSON" \
  '{event: $event, body: $body, comments: $comments}' > "$PAYLOAD"

# Resolve owner/repo (works for current repo or via -R/URL context)
OWNER_REPO=$(gh repo view $REPO_FLAG --json nameWithOwner -q .nameWithOwner)

gh api "repos/${OWNER_REPO}/pulls/${PR}/reviews" -X POST --input "$PAYLOAD"
```

Event semantics:
- `APPROVE` (zero findings) → `reviewDecision` becomes `APPROVED`. This is the runner's exit signal in the ping-pong loop.
- `REQUEST_CHANGES` (findings exist) → `reviewDecision` becomes `CHANGES_REQUESTED`. Runner picks up unresolved threads and fixes them.
- Never use `COMMENT` event — it doesn't move `reviewDecision`, breaks the loop.

The hook (`hooks/check-post.sh`) reads the payload file and blocks on: missing header in body, or zero engagement (empty `comments[]` AND no `_No bug-class findings_` line in body). Fix the body/comments and retry — do not bypass.

## 6. Watch loop (default; skipped when `--once`)

After delivering, stay alive and re-review on every new commit until terminal. Skip when: `--once` passed, branch mode (no PR), or initial review was `APPROVE`.

Record the reviewed SHA, then poll every 60s (8hr cap):

```bash
LAST_SHA=$(jq -r '.head_sha' <<<"$(~/.claude/scripts/check-pr-state.sh "$PR")")
START=$(date +%s)

while (( $(date +%s) - START < 28800 )); do
  sleep 60
  STATE=$(~/.claude/scripts/check-pr-state.sh "$PR")
  [[ "$(jq -r .pr_state <<<"$STATE")" != "OPEN" ]] && break       # merged/closed
  [[ "$(jq -r '.review_decision // ""' <<<"$STATE")" == "APPROVED" ]] && break
  SHA=$(jq -r .head_sha <<<"$STATE")
  if [[ -n "$SHA" && "$SHA" != "$LAST_SHA" ]]; then
    # New commit → redo steps 1–5 on the fresh diff. Update LAST_SHA after posting.
    LAST_SHA="$SHA"
    # If the post was APPROVE → break (exits the loop).
  fi
done
```

"Redo steps 1–5" = re-run `gh pr diff <pr>`, re-apply `bug-checklist.md`, compose, deliver. Fresh review of the new state, not a diff vs. last review.

## Extending

- Broaden the primary pass → add to `bug-checklist.md`.
- New optional gate → drop a file at `criteria/<slug>.md` (What / Why / How to spot / When NOT / Severity).
- New mechanical check on the posted output → extend `hooks/check-post.sh`.
