---
name: pr-review
description: Review a GitHub PR or current branch primarily for bugs (correctness, null/undefined, async/race, error handling, security, resource leaks, test rigor). Posts findings as resolvable inline review comments. Auto-APPROVES when nothing's wrong. House-rules criteria run as additive extras.
version: 3.1.0
argument-hint: "[--inline] [--once] [<PR-number-or-URL>]"
allowed-tools: Bash(gh*), Bash(git*), Bash(claude*), Bash(jq*), Bash(mktemp*), Bash(*check-pr-state.sh*), Bash(*spawn-reviewer.sh*), Bash(sleep*), Bash(date*), Read, Glob, Grep
hooks:
  PreToolUse:
    - matcher: "Bash"
      hooks:
        - type: command
          command: "$HOME/.claude/skills/pr-review/hooks/check-post.sh"
          timeout: 10
# NOTE: there is no PostToolUse stamp hook. record-sha.sh used to write
# last-reviewed-sha/last-approved-sha here, but enforce-watch.sh reads HEAD
# coverage/approval straight from GitHub (check-pr-state.sh) now — the local
# stamps proved fragile (silently unwritten) and nothing reads them, so the hook
# was removed rather than left writing dead files to the wrong job dir.
# NOTE: the watch-loop Stop hook (enforce-watch.sh) is registered ONLY in global
# settings.json, NOT here. A skill-frontmatter Stop hook double-fired alongside the
# global one for the bg pr-reviewer agent (the only session whose template passes
# enforce-watch's gate), double-incrementing watch.attempts; for any other session
# it's a no-op exit. The global registration fires for every session, so this one
# was pure redundancy.
---

# PR Review

**Primary job: find bugs.** Apply `bug-checklist.md` to every change. Cite `file:line` for every finding. Tag severity AND confidence.

`criteria/` are additive extras. They may or may not fire. They never replace the bug pass.

## 0. Dispatch (default background)

Parse `$ARGUMENTS` for these in order:

1. **`--inline` flag** (alias: `--fg`) anywhere → strip it and review in THIS session instead of dispatching a *new* background watcher. This is exactly how the dispatch reviewer is launched (`claude --bg "/pr-review --inline <url>"`): the background session already exists, so `--inline` means only "don't dispatch another one." It does **NOT** make this a one-shot — proceed to step 1, and the watch loop (step 6) still runs unless `--once` is also set. Done.
2. **`--once` flag** → strip it and remember; passed to step 6 to skip the watch loop after delivery. This is the ONLY flag that disables watching.
3. **PR identifier**, accepting any of:
   - Bare integer (e.g. `18`) — current repo
   - Full URL (e.g. `https://github.com/owner/repo/pull/18`) — extracts `owner/repo` and PR number
   - PR number + `-R owner/repo` — uses the explicit repo
4. **Nothing identifiable** → foreground branch review (skip dispatch entirely; `--once` is implied for branch mode since there's no PR to watch).

### Dispatch command — delegate to `spawn-reviewer.sh`

Do **not** build the session name or spawn here. `spawn-reviewer.sh` is the
single, idempotent entry point: it derives the name (`review-<repo>[-<ticket>]-pr-<n>`)
and guards against spawning a second watcher when one is already live. Building
the name in two places is exactly how the PR ends up double-reviewed — one
builder, one guard.

`$PR_ARG` below is whatever preserves repo context: the full URL if a URL was
passed, or `<PR> -R owner/repo` if `-R` was passed, or the bare integer if neither.

```bash
SESSION_OUTPUT=$(bash ~/.claude/skills/dispatch/spawn-reviewer.sh $PR_ARG 2>&1)
STATUS=$(grep '^reviewer_status:' <<<"$SESSION_OUTPUT" | cut -d: -f2)
SESSION_ID=$(grep '^session_id:' <<<"$SESSION_OUTPUT" | cut -d: -f2)
SESSION_NAME=$(grep '^name:' <<<"$SESSION_OUTPUT" | cut -d: -f2)
```

Report based on `reviewer_status`:
- `already-reviewed` → the PR's current HEAD already has a review (approve or findings); there is nothing to spawn. Say so and stop — this is success, NOT a failed dispatch (there's no `session_id` because no session was spawned, which is correct).
- `already-running` → say it reused the live reviewer instead of spawning a new one.
- `spawned` → `Dispatched as $SESSION_NAME (session $SESSION_ID). Open claude agents to watch.`

**The watch loop runs for EVERY PR review** — a freshly-dispatched background
session AND an `--inline` review inside an already-background session (the dispatch
reviewer). `--inline` does **not** skip it; do not treat an `--inline` review as a
one-shot. The ONLY way to skip the watch loop is `--once` (or branch mode, where
there's no PR to watch). A one-shot is `--once` / `--inline --once`; plain
`--inline` watches and re-reviews every new commit until the PR is approved+green
or merged/closed.

### Failure handling — read carefully

If `SESSION_ID` is empty AND `reviewer_status` is neither `already-reviewed` nor `already-running`, the dispatch failed. **Surface `SESSION_OUTPUT` verbatim to the user and stop.** Do not paraphrase. Do not invent reasons (e.g. "the --bg flag isn't available"). The `--bg` flag DOES exist on Claude Code; it is hidden from `claude --help` but valid. If the literal bash output says something else, report exactly what it says. **Do not fall back to running in foreground.** The user can re-run with `--inline` if they want that.

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

Zero findings → post `templates/approved.md` verbatim. It carries the `👾 Reviewed by Claude` header and the `# ✅ APPROVED ✅` headline. **Keep that headline intact** — it's the approval sentinel: on a self-authored PR GitHub's `reviewDecision` can never become `APPROVED`, so both this watcher (`enforce-watch.sh`) and the dispatch runner detect approval by finding that exact line in a review whose `commit_id` is the current HEAD. The single source of truth is `scripts/lib/pr-review-markers.sh`, which reads the line back from this template — so don't reword it.

Sort findings: Blockers → Concerns → Nits. Within tier, `general` first, then criteria.

## 5. Deliver

Chat first. Then post via `gh api .../reviews` — in **two separate Bash calls**.
The PreToolUse hook (`check-post.sh`) validates the payload file named by
`--input` from the command text at call time: the file must already exist
(written by a PREVIOUS call), and the path must be spelled out literally —
the hook cannot expand `$PAYLOAD`-style variables. Building and posting in
one call is always blocked.

**Call 1 — build the payload.** Write it to the deterministic path
`/tmp/pr-review-payload-<pr-number>.json`:

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

jq -n \
  --arg body "$BODY" \
  --arg event "$EVENT" \
  --argjson comments "$INLINE_COMMENTS_JSON" \
  '{event: $event, body: $body, comments: $comments}' \
  > "/tmp/pr-review-payload-$PR.json"
```

**Call 2 — post it.** A NEW Bash call, with the payload path written out
literally (e.g. `/tmp/pr-review-payload-137.json`, not `$PAYLOAD`):

```bash
# Resolve owner/repo (works for current repo or via -R/URL context)
OWNER_REPO=$(gh repo view $REPO_FLAG --json nameWithOwner -q .nameWithOwner)

# Post the review. On a dispatch PR the reviewer IS the PR author, and GitHub
# 422s an author's own APPROVE/REQUEST_CHANGES — fall back to a COMMENT review
# carrying the SAME body+comments. The approved.md sentinel still lands against
# this commit_id, which is what the loop detects; it does NOT need reviewDecision.
ERR=$(mktemp)
if ! gh api "repos/${OWNER_REPO}/pulls/137/reviews" -X POST --input /tmp/pr-review-payload-137.json 2>"$ERR"; then
  if grep -qiE 'on your own pull request|422|unprocessable' "$ERR"; then
    jq '.event = "COMMENT"' /tmp/pr-review-payload-137.json > /tmp/pr-review-payload-137.c.json \
      && mv /tmp/pr-review-payload-137.c.json /tmp/pr-review-payload-137.json
    gh api "repos/${OWNER_REPO}/pulls/137/reviews" -X POST --input /tmp/pr-review-payload-137.json
  else
    cat "$ERR" >&2; exit 1
  fi
fi
```

Event semantics — choose by finding count, but expect the self-authored fallback:
- Zero findings → `APPROVE`; findings exist → `REQUEST_CHANGES`.
- On a dispatch PR the reviewer is the author, so that event 422s; re-post the
  same payload as `COMMENT`. The verdict is carried by the **body**, not the
  event: an approve still includes the `# ✅ APPROVED ✅` sentinel, and both this
  watcher (`enforce-watch.sh`) and the runner detect approval by finding that
  sentinel in a review whose `commit_id` is the current HEAD. So a COMMENTED
  approval ends the loop exactly like an APPROVED one — `reviewDecision` is never
  required (and can't move on a self-authored PR anyway).
- An external (non-author) reviewer's APPROVE/REQUEST_CHANGES posts normally and
  also moves `reviewDecision`, which the runner treats as terminal too.

The hook (`hooks/check-post.sh`) reads the payload file and blocks on: missing header in body, or zero engagement (empty `comments[]` AND the body is not an approve per `templates/approved.md`). Fix the body/comments and retry — do not bypass.

## 6. Watch loop (default; `--once` skips)

**You do not run the loop — the Stop hook (`enforce-watch.sh`) does.** Never spin a `while true` bash loop: bash can `sleep` but it can't re-review (steps 1–5 are model turns, not shell), so an infinite loop just wedges the session on a single pass. That's the old bug.

The model is dead simple: after delivering, **just try to end.** Every time you do, the hook decides:

- **Stop allowed** — PR is MERGED/CLOSED; OR the current HEAD is approved (your `approved.md` review is on it, or an external `reviewDecision == APPROVED`) *and* all GitHub checks are green; OR `--once` was set; OR the 8hr cap passed. (You can't APPROVE your own PR, so the hook detects approval from your posted `approved.md` review at the current commit — not a GitHub APPROVE event. Approved but CI pending/red → keep watching; a failing check may push a fix to re-review.)
- **Stop blocked** — the hook reads from GitHub whether the **current HEAD has been reviewed** (`check-pr-state.sh` → `reviewed_at_head`, by `commit_id`) and injects one next action:
  - **HEAD unreviewed** (a new commit was pushed) → redo steps 1–5 on the fresh diff, post, then try to end again.
  - **HEAD already reviewed** → `sleep 60`, re-poll, then try to end again.

So the loop is: review → try to end → do what the hook says → try to end. Repeat. Coverage is read from GitHub (a review whose `commit_id` is the current HEAD), not a local stamp — so you don't track SHAs yourself, and you must not re-review a commit that's already reviewed. Terminal exit is always the hook's call, never yours.

## Extending

- Broaden the primary pass → add to `bug-checklist.md`.
- New optional gate → drop a file at `criteria/<slug>.md` (What / Why / How to spot / When NOT / Severity).
- New mechanical check on the posted output → extend `hooks/check-post.sh`.
- Change review wording/emoji/layout → edit `templates/` (`approved.md`, `changes-requested.md`, `finding.md`). Two lines in `approved.md` are load-bearing — keep both: the `# 👾 Reviewed by Claude …` header (matched by `^# .*Reviewed by Claude`) and the `# ✅ APPROVED ✅` headline (matched by `^# .*APPROVED`). `scripts/lib/pr-review-markers.sh` reads them back from the template as the single source of truth for `check-post.sh` and `check-pr-state.sh`; reword either line and approval detection silently breaks. (`spawn-reviewer.sh`'s reviewed-at-HEAD gate counts any review at HEAD via REST and doesn't use the sentinel.)
