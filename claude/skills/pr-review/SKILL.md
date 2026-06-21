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
  Stop:
    - hooks:
        - type: command
          command: "$HOME/.claude/skills/pr-review/hooks/enforce-watch.sh"
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
  SESSION_NAME="review-${PROJECT}-${TICKET}-pr-${PR}"
else
  SESSION_NAME="review-${PROJECT}-pr-${PR}"
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

## 4. Compose output — templates only, no freehand

Every surface is a fixed template in `templates/`. Fill the placeholders; never restyle, reorder, or improvise wording. This is what stops reviews from drifting.

Severity emoji — use the SAME ones everywhere (body breakdown and finding titles):
🔴 Blocker · 🟡 Concern · 🔵 Nit

**(a) Top-level review body** — the single review comment every finding threads under.
- **Zero findings → `templates/approved.md`.** Post it byte-for-byte. No substitutions, no extra prose. The point: the approved review is identical every time.
- **Findings exist → `templates/changes-requested.md`.** Substitute only:
  - `{count}` — total findings
  - `{criteria}` — `general` plus any criteria slugs that fired (comma-separated)
  - `{breakdown}` — severity tally with emoji, e.g. `🔴 2 Blockers · 🟡 3 Concerns · 🔵 1 Nit` (drop any zero tier)

**(b) Inline comment per finding** — one resolvable thread on the cited `file:line`, from `templates/finding.md`. Substitute:
  - `{sev_emoji}` — 🔴 / 🟡 / 🔵 matching severity
  - `{title}` — see Title rules below
  - `{severity}` — Blocker | Concern | Nit
  - `{confidence}` — High | Med | Low
  - `{criterion}` — general | <slug>
  - `{issue}` — plain English, no jargon
  - `{fix}` — concrete action
  - `{diff}` — a `- current` / `+ proposed` hunk

**Title rules** (same spirit as `/issue`):
- Concise noun phrase, 2-7 words, Title Case
- No verb prefixes ("Add", "Fix", "Update", "Implement", "Refactor")
- No ticket ID prefix ("PER-83", "ABC-123") — the PR already carries it
- Area prefix with colon when it adds clarity

Good: `Null Check: user.email`, `Race Condition: Stale Cache Read`, `Missing Await: fetchUser`
Bad: `Fix null check on user.email`, `PER-83: Null Check`, `Update error handling`

(No `**Where:**` line — `path` and `line` are structural on the comment itself.)

Findings without a usable `file:line` (rare — cross-cutting issues) → fold into the top-level body under a `## Cross-cutting` section instead of the comments array.

Zero findings → post `templates/approved.md` verbatim. It carries the hook-required `_No bug-class findings` line and the `✅ APPROVED` block. Don't reword it — dispatch doesn't parse the text, it watches GitHub's `reviewDecision == APPROVED` event, and the value of a template is that it's always the same.

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
# One entry per finding; each body filled from templates/finding.md.
# Use start_line + line for multi-line ranges (e.g. file:380-383).
INLINE_COMMENTS_JSON='[
  {"path": "src/foo.ts", "line": 42, "body": "<templates/finding.md, filled>"},
  ...
]'

# Body comes straight from a template — never hand-composed.
if [[ "$FINDING_COUNT" -eq 0 ]]; then
  BODY="$(cat templates/approved.md)"            # static — post as-is
else
  BODY="$(cat templates/changes-requested.md)"   # then substitute placeholders
  BODY="${BODY//\{count\}/$FINDING_COUNT}"
  BODY="${BODY//\{criteria\}/$CRITERIA}"         # general + fired slugs
  BODY="${BODY//\{breakdown\}/$BREAKDOWN}"       # e.g. 🔴 2 Blockers · 🟡 3 Concerns
fi

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

## 6. Watch loop (default; `--once` skips)

**You do not run the loop — the Stop hook (`enforce-watch.sh`) does.** Never spin a `while true` bash loop: bash can `sleep` but it can't re-review (steps 1–5 are model turns, not shell), so an infinite loop just wedges the session on a single pass. That's the old bug.

The model is dead simple: after delivering, **just try to end.** Every time you do, the hook decides:

- **Stop allowed** — PR is MERGED/CLOSED, you've APPROVED *and* all GitHub checks are green, `--once` was set, or the 8hr cap passed. Done. (Approved but CI still pending/red → keep watching; a failing check may push a fix to re-review.)
- **Stop blocked** — the hook compares the PR's current HEAD to the SHA you last reviewed and injects exactly one next action:
  - **HEAD changed** → redo steps 1–5 on the fresh diff, post, then try to end again.
  - **HEAD unchanged** → `sleep 60`, re-poll `~/.claude/scripts/check-pr-state.sh $PR`, then try to end again.

So the loop is: review → try to end → do what the hook says → try to end. Repeat. The reviewed SHA is stamped for you when you post (`check-post.sh`) — you don't track it yourself, and you must not re-review the same SHA. Terminal exit is always the hook's call, never yours.

## Extending

- Broaden the primary pass → add to `bug-checklist.md`.
- New optional gate → drop a file at `criteria/<slug>.md` (What / Why / How to spot / When NOT / Severity).
- New mechanical check on the posted output → extend `hooks/check-post.sh`.
- Change review wording/emoji/layout → edit `templates/` (`approved.md`, `changes-requested.md`, `finding.md`). Keep the `👾 Reviewed by Claude` header line and, in `approved.md`, the `_No bug-class findings` line — both are hook-enforced.
