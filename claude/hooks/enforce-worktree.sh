#!/usr/bin/env bash
# PreToolUse hook for the runner agent: block runner writes into the SHARED
# main checkout. This is the isolation guarantee — concurrent runners (and the
# operator) share one main checkout, so a runner must never modify it.
#
# THREAT MODEL (deliberately bounded). This guards against a COOPERATIVE runner
# accidentally writing the shared checkout — typically by acting on an absolute
# main-checkout path handed to it by discovery. It is the only such guard in a
# `bypassPermissions` runner session, where no permission prompt fires. It is
# defense-in-depth on top of the spawn prompt, NOT an adversarial sandbox: a
# runner that is actively trying to evade isolation runs under bypassPermissions
# and has many avenues a command-string hook can't see (a path computed at
# runtime, an interpreter reading the root from elsewhere, etc.). We close the
# realistic accidental vectors below; we do not chase every adversarial bypass,
# because the runner is your own agent, not untrusted input.
#
# Scope (deliberate): only the shared main checkout is protected. Writes to the
# runner's own worktree, its status file, and anything OUTSIDE the checkout
# (/tmp scratch, tool/build caches, $HOME caches) are allowed — runners run real
# test suites and toolchains that need them. This is not a full filesystem
# sandbox; it is specifically "don't corrupt the shared checkout."
#
# Dispatch runners work in <repo>/.claude/worktrees/<name> but receive absolute
# paths into the main checkout from discovery. The spawn prompt instructs them
# to stay in the worktree; this hook enforces it for BOTH vectors:
#   - Edit|Write|MultiEdit — block a file_path inside the main checkout
#   - Bash                  — block a command that references the main checkout
#                             (covers sed -i, cat >, tee, git -C <main>, etc.,
#                             which never reach the Edit/Write tools)
#
# Runner identity resolves in three tiers:
#   1. the bg job's state file (template == "runner", cwd == the worktree
#      spawn.sh submitted from), keyed by this hook call's session_id —
#      daemon-written, immutable to the runner, PER-SESSION, and holds regardless
#      of where the runner has cd'd. AUTHORITATIVE, tried first: it is the only
#      source that can't be wrong for a real dispatched runner;
#   2. CLAUDE_DISPATCH_* env vars — a fallback for env-based dispatch, but NOT
#      trusted over tier 1. A reused `claude --bg` daemon leaks the FIRST
#      dispatch's CLAUDE_DISPATCH_WORKTREE to every later worker via inherited
#      process env (observed 2026-07-07: amp-16/amp-17 both resolved to amp-15),
#      so trusting env first locked concurrent runners out of their own worktrees;
#   3. cwd-derived detection (best effort: cannot see a runner that has cd'd
#      away from its worktree).
#
# The Bash check covers: the main checkout's absolute path (raw and canonical
# spellings, so /tmp vs /private/tmp or a symlinked checkout doesn't slip past),
# the CLAUDE_DISPATCH_ROOT env var that expands to it, and a cwd that has been
# moved into the shared checkout (catching relative writes). It still cannot see
# a path the runner *computes* without naming the root — deriving it from the
# worktree var, `../`-escaping from the worktree without cd, or going through an
# unrelated symlink whose target is the checkout — which the spawn prompt forbids.
# Defense-in-depth on that prompt, not an adversarial sandbox.
#
# Exit 0 → allow. Exit 2 → block; stderr is fed back to the agent.

set -uo pipefail

# Fail open on hook bugs — never trap the agent because of us.
trap 'exit 0' ERR

INPUT=$(cat)
TOOL=$(jq -r '.tool_name // ""' <<<"$INPUT")
CWD=$(jq -r '.cwd // ""' <<<"$INPUT")

# Shared lib for the job-derived identity tier. Missing lib → the resolver
# stays empty and the env/cwd tiers still work.
# shellcheck disable=SC1091
. "$HOME/.claude/scripts/lib/dispatch.sh" 2>/dev/null || true

# Per-session identity from the bg job state (session_id-keyed, daemon-written,
# immutable to the runner). Computed FIRST and preferred over the env tier below.
# Rationale: CLAUDE_DISPATCH_WORKTREE can be a STALE LEAK. A reused `claude --bg`
# daemon keeps the FIRST dispatch's CLAUDE_DISPATCH_* in its process env, so every
# later worker inherits it — the env then resolves ALL concurrent runners to the
# first one's worktree, locking them out of their own (observed 2026-07-07:
# amp-16 and amp-17 both resolved to amp-15). Job state is per-session and cannot
# leak, and it is the same source enforce-completion.sh trusts — so preferring it
# both fixes the lockout and keeps the two hooks agreeing on runner identity.
JOB_WORKTREE=""
if command -v dispatch_runner_worktree >/dev/null 2>&1; then
    SID=$(jq -r '.session_id // ""' <<<"$INPUT")
    JOB_WORKTREE=$(dispatch_runner_worktree "$SID" 2>/dev/null) || JOB_WORKTREE=""
fi

# --- Resolve runner identity (job state, else env, else cwd fallback) ---
if [[ -n "$JOB_WORKTREE" ]]; then
    WORKTREE="$JOB_WORKTREE"
    # Worktrees live at <root>/.claude/worktrees/<name> — derive the root
    # TEXTUALLY so it keeps the same raw spelling as the worktree path (the
    # canon() calls below add the symlink-resolved form; the scan must block
    # BOTH spellings). Fall back to git only when the layout doesn't hold.
    DISPATCH_ROOT=$(dirname "$(dirname "$(dirname "$WORKTREE")")")
    if ! git -C "$DISPATCH_ROOT" rev-parse --git-dir >/dev/null 2>&1; then
        COMMON_GIT_DIR=$(git -C "$WORKTREE" rev-parse --git-common-dir 2>/dev/null) || COMMON_GIT_DIR=""
        if [[ -n "$COMMON_GIT_DIR" ]]; then
            COMMON_GIT_DIR=$(cd "$COMMON_GIT_DIR" 2>/dev/null && pwd) || COMMON_GIT_DIR=""
        fi
        [[ -n "$COMMON_GIT_DIR" ]] && DISPATCH_ROOT=$(dirname "$COMMON_GIT_DIR")
    fi
    STATUS_FILE="$DISPATCH_ROOT/.dispatch/status/$(basename "$WORKTREE").md"
elif [[ -n "${CLAUDE_DISPATCH_WORKTREE:-}" ]]; then
    WORKTREE="$CLAUDE_DISPATCH_WORKTREE"
    DISPATCH_ROOT="${CLAUDE_DISPATCH_ROOT:-$(dirname "$(dirname "$(dirname "$WORKTREE")")")}"
    STATUS_FILE="${CLAUDE_DISPATCH_STATUS_FILE:-$DISPATCH_ROOT/.dispatch/status/$(basename "$WORKTREE").md}"
else
    # Legacy fallback: derive from cwd (same detection as enforce-completion.sh).
    [[ -z "$CWD" ]] && exit 0
    cd "$CWD" 2>/dev/null || exit 0
    WORKTREE=$(git rev-parse --show-toplevel 2>/dev/null) || exit 0
    COMMON_GIT_DIR=$(git rev-parse --git-common-dir 2>/dev/null) || exit 0
    COMMON_GIT_DIR=$(cd "$COMMON_GIT_DIR" 2>/dev/null && pwd) || exit 0
    DISPATCH_ROOT=$(dirname "$COMMON_GIT_DIR")
    STATUS_FILE="$DISPATCH_ROOT/.dispatch/status/$(basename "$WORKTREE").md"

    # Not a dispatch runner, or the worktree IS the main checkout → nothing to enforce.
    [[ -f "$STATUS_FILE" ]] || exit 0
    [[ "$WORKTREE" == "$DISPATCH_ROOT" ]] && exit 0
fi

[[ -z "$DISPATCH_ROOT" ]] && exit 0

# Resolve symlinks (e.g. /tmp → /private/tmp, AND a final symlinked file whose
# target is elsewhere) so prefix checks compare physical paths. realpath resolves
# every component including the last; for a not-yet-created path it fails, so we
# resolve the deepest EXISTING ancestor and re-attach the missing suffix.
canon() {
    local p="$1" suffix="" r
    [[ -z "$p" ]] && return
    # Fast path: the whole path exists — resolve it fully (final symlink included).
    if r=$(realpath "$p" 2>/dev/null); then
        printf '%s' "$r"; return
    fi
    # Missing trailing components: peel them off until an existing ancestor.
    while [[ ! -e "$p" && "$p" != "/" ]]; do
        suffix="/$(basename "$p")$suffix"
        p=$(dirname "$p")
    done
    if r=$(realpath "$p" 2>/dev/null); then
        printf '%s%s' "$r" "$suffix"; return
    fi
    r=$(cd "$p" 2>/dev/null && pwd -P) || { printf '%s' "$1"; return; }
    printf '%s%s' "$r" "$suffix"
}

block_msg() {
    {
      echo "Blocked: $1"
      echo
      echo "Your worktree is: $WORKTREE"
      echo "Use the SAME relative path inside the worktree instead. The only path"
      echo "you may touch outside it is your status file: $STATUS_FILE"
    } >&2
}

case "$TOOL" in
  Edit|Write|MultiEdit|NotebookEdit)
    # NotebookEdit carries the target in notebook_path, the others in file_path.
    FILE=$(jq -r '.tool_input.file_path // .tool_input.notebook_path // ""' <<<"$INPUT")
    [[ -z "$FILE" ]] && exit 0
    [[ "$FILE" != /* ]] && FILE="${CWD:-$WORKTREE}/$FILE"
    FILE=$(canon "$FILE")
    C_WORKTREE=$(canon "$WORKTREE")
    C_ROOT=$(canon "$DISPATCH_ROOT")
    C_STATUS=$(canon "$STATUS_FILE")
    case "$FILE" in
      "$C_WORKTREE"/*) exit 0 ;;
      "$C_STATUS") exit 0 ;;
      "$C_ROOT"/*)
        block_msg "'$FILE' is in the main checkout, not your worktree."
        exit 2
        ;;
    esac
    ;;
  Bash)
    CMD=$(jq -r '.tool_input.command // ""' <<<"$INPUT")
    [[ -z "$CMD" ]] && exit 0
    # De-escape shell backslashes once (the shell dequotes `/work\/repo` to
    # `/work/repo`); every path match below uses this normalized form so an
    # escaped separator can't smuggle a write past the literal scan.
    DCMD=$(printf '%s' "$CMD" | sed 's#\\\(.\)#\1#g')

    # SCAN is DCMD with heredoc BODIES removed. Heredoc content is data for
    # another program, not shell syntax: a `..` or a `cd /etc` line inside
    # `python - <<'PY' … PY` changes no directory and addresses no path, so it
    # must not trip the traversal / cd-drift scans below. SCAN is used ONLY for
    # those usability-sensitive scans; the authoritative absolute-root write
    # block still runs against the full DCMD, so stripping here can never relax
    # the isolation guarantee (at worst it under-strips and over-blocks).
    strip_heredocs() {
      local in_h=0 delim="" out="" line trimmed
      # Heredoc start: `<<` / `<<-` (not `<<<`), optional quote, a word delimiter.
      local hre='<<-?[[:space:]]*["'\'']?([A-Za-z_][A-Za-z0-9_]*)'
      while IFS= read -r line; do
        if (( in_h )); then
          trimmed="${line#"${line%%[![:space:]]*}"}"   # lstrip (covers <<- tabs)
          [[ "$line" == "$delim" || "$trimmed" == "$delim" ]] && in_h=0
          continue                                     # drop body + terminator
        fi
        if [[ "$line" != *'<<<'* && "$line" =~ $hre ]]; then
          delim="${BASH_REMATCH[1]}"
          in_h=1
        fi
        out+="$line"$'\n'                              # keep the start line itself
      done <<< "$1"
      printf '%s' "$out"
    }
    SCAN=$(strip_heredocs "$DCMD")

    cd_wt=$(canon "$WORKTREE")
    # Effective cwd: starts at the call's cwd and advances through leading `cd`s,
    # so the cwd check below sees where a write actually lands.
    EFFCWD="${CWD:-$WORKTREE}"

    # Resolve a `cd` target (quotes/env/home expanded) from a base cwd → canonical
    # destination, or empty.
    # shellcheck disable=SC2016  # the CLAUDE_DISPATCH/HOME patterns are LITERAL text to expand, not shell expansions
    resolve_cd() {
      local t="$1" base="$2"
      t=${t//[\"\']/}
      t=${t//'${CLAUDE_DISPATCH_WORKTREE}'/$WORKTREE}
      t=${t//'$CLAUDE_DISPATCH_WORKTREE'/$WORKTREE}
      if [[ -n "${HOME:-}" ]]; then t=${t//'~/'/$HOME/}; t=${t//'$HOME'/$HOME}; fi
      [[ -z "$t" || "$t" == '~' ]] && t="${HOME:-/}"
      (cd "$base" 2>/dev/null && cd "$t" 2>/dev/null && pwd -P) || true
    }

    # `cd`/`pushd` move the cwd, from which a later RELATIVE write could reach the
    # shared checkout without ever naming it. Inspect EVERY such segment (not just
    # a leading one — `set -e; cd /parent && touch repo/x` must be caught too),
    # tracking the effective cwd. `pushd <dir>` changes the cwd exactly like `cd`,
    # so it is handled identically; arg-less `pushd` (stack rotate) resolves to no
    # destination and is treated as leaving. Block any move whose destination
    # leaves the worktree (`cd ../../..`, `pushd /parent`, `cd ~`, ...); a move
    # that stays inside just advances EFFCWD, so a chained recovery
    # `cd "$CLAUDE_DISPATCH_WORKTREE" && git status` from a drifted cwd works.
    while IFS= read -r seg; do
      seg="${seg#"${seg%%[![:space:]]*}"}"
      [[ "$seg" =~ ^(cd|pushd)([[:space:]]|$) ]] || continue
      cd_tgt=$(printf '%s' "$seg" | sed -E 's/^(cd|pushd)[[:space:]]*//; s/[[:space:]].*//')
      cd_dest=$(resolve_cd "$cd_tgt" "$EFFCWD")
      case "$cd_dest" in
        "$cd_wt"|"$cd_wt"/*) EFFCWD="$cd_dest" ;;
        *)
          block_msg "this 'cd'/'pushd' leaves your worktree (destination resolves to '${cd_dest:-$cd_tgt}'), from which a relative path could reach the shared checkout. Stay in your worktree or use absolute worktree paths."
          exit 2
          ;;
      esac
    done < <(printf '%s' "$SCAN" | sed -E 's/(&&|\|\||;|\||&)/\n/g')

    # A pure cd/pushd (only that, nothing else) writes nothing → allow.
    # shellcheck disable=SC2016  # '$(' / '<(' are literals to match, not expansions
    case "$DCMD" in
      *'&&'*|*'||'*|*';'*|*'|'*|*'&'*|*'$('*|*'`'*|*'<('*|*$'\n'*) : ;;
      *) [[ "$DCMD" =~ ^[[:space:]]*(cd|pushd)([[:space:]]|$) ]] && exit 0 ;;
    esac

    # Parent traversal (..) in a NON-cd word (e.g. `touch ../x`) can escape the
    # worktree. Match `..` only as a standalone path component: EXACTLY two dots
    # bounded on both sides by /, whitespace, a quote, or string end — so Git
    # revspecs (`main..HEAD`) and Go's wildcard (`go test ./...`) are allowed.
    TRAV='(^|[[:space:]"'\''/])\.\.([[:space:]"'\''/]|$)'
    if [[ "$SCAN" =~ $TRAV ]]; then
      block_msg "a '..' path component can escape the worktree. Use an explicit path inside your worktree."
      exit 2
    fi
    # Effective cwd inside the shared checkout (cwd drifted in, or a leading cd
    # landed there) → block: a relative write would hit the main checkout and not
    # appear in the text scan below.
    if [[ -n "$EFFCWD" ]]; then
      C_CWD=$(canon "$EFFCWD")
      C_WT=$(canon "$WORKTREE")
      C_ROOT=$(canon "$DISPATCH_ROOT")
      case "$C_CWD" in
        "$C_WT"|"$C_WT"/*) : ;;                       # inside the worktree → fine
        "$C_ROOT"|"$C_ROOT"/*)                        # inside main checkout, outside worktree
          block_msg "your shell cwd ($C_CWD) is inside the shared main checkout. cd back into your worktree before running commands."
          exit 2
          ;;
      esac
    fi
    # Remove references to THIS worktree and the status file so only main-checkout
    # references remain. We mask BOTH the raw paths and their canonical (symlink-
    # resolved) spellings, then block if EITHER the raw or canonical main-checkout
    # path survives — so an alias like /tmp vs /private/tmp, or a symlinked
    # checkout, can't smuggle a write past a literal-only match.
    # Boundary-aware (the path must end at /, whitespace, a quote, a separator, or
    # end-of-string) so a sibling worktree like .../eng-10 is NOT erased by a
    # .../eng-1 prefix match. Paths are regex-escaped; sed uses # as the delimiter
    # (worktree paths never contain #). The negated class avoids BSD sed bracket
    # pitfalls; # is left unescaped (it is the delimiter, not regex-special).
    C_WT=$(canon "$WORKTREE")
    C_ROOT=$(canon "$DISPATCH_ROOT")
    C_SF=$(canon "$STATUS_FILE")
    # Expand ~/ and $HOME/${HOME} the way the shell will, so a home-dir checkout
    # (e.g. ~/.dotfiles) can't be referenced via a spelling the literal scan
    # misses. Aggressive (even inside single quotes) — over-expanding only makes
    # MORE paths match the protected root, which is fail-safe for a guard.
    EXPANDED="$DCMD"
    if [[ -n "${HOME:-}" ]]; then
      # shellcheck disable=SC2016  # the single-quoted patterns are LITERAL text to find in the command, not expansions
      EXPANDED=${EXPANDED//'${HOME}'/$HOME}
      # shellcheck disable=SC2016
      EXPANDED=${EXPANDED//'$HOME'/$HOME}
      EXPANDED=${EXPANDED//'~/'/$HOME/}
    fi
    re_escape() { sed 's#[^a-zA-Z0-9/_-]#\\&#g' <<<"$1"; }
    BOUND='(/|[[:space:]]|["'"'"':;,&|]|$)'
    SED_PROG=""
    for p in "$WORKTREE" "$C_WT" "$STATUS_FILE" "$C_SF"; do
      [[ -z "$p" ]] && continue
      SED_PROG+="s#$(re_escape "$p")${BOUND}#\\1#g;"
    done
    MASKED=$(printf '%s' "$EXPANDED" | sed -E "$SED_PROG")
    # Bare $CLAUDE_DISPATCH_WORKTREE / _STATUS_FILE refs are allowed, but the shell
    # can DERIVE the shared root from them. Block:
    #   - parameter manipulation `${CLAUDE_DISPATCH_*<op>}` (e.g. ${…_STATUS_FILE%/.dispatch/…})
    #   - a `..` traversal anywhere alongside such a reference (e.g. $CLAUDE_DISPATCH_WORKTREE/../x)
    #   - appending a path onto the status FILE ($CLAUDE_DISPATCH_STATUS_FILE/…)
    if printf '%s' "$DCMD" | grep -qE '\$\{CLAUDE_DISPATCH_(WORKTREE|STATUS_FILE|ROOT)[^}A-Za-z0-9_]'; then
      block_msg "parameter expansion on a CLAUDE_DISPATCH_* variable can derive the shared checkout. Use the worktree path directly."
      exit 2
    fi
    if printf '%s' "$DCMD" | grep -qE 'CLAUDE_DISPATCH_STATUS_FILE\}?/'; then
      block_msg "the status file is a file, not a directory — don't append a path to CLAUDE_DISPATCH_STATUS_FILE."
      exit 2
    fi
    # Block the main-checkout path (raw or canonical) when it appears as a PATH
    # COMPONENT — boundary-aware (same BOUND as the masking) so a sibling/cache
    # dir like `/repo-cache` that merely STARTS WITH `/repo` is NOT blocked; the
    # scope deliberately allows writes outside the checkout. Also block a
    # CLAUDE_DISPATCH_ROOT env-var ref (the shell expands it to the root).
    ROOT_RE="$(re_escape "$DISPATCH_ROOT")${BOUND}"
    [[ "$C_ROOT" != "$DISPATCH_ROOT" ]] && ROOT_RE="${ROOT_RE}|$(re_escape "$C_ROOT")${BOUND}"
    if printf '%s' "$MASKED" | grep -qE "$ROOT_RE" || [[ "$DCMD" == *CLAUDE_DISPATCH_ROOT* ]]; then
      block_msg "this command references the shared main checkout at '$DISPATCH_ROOT'."
      exit 2
    fi
    ;;
esac

exit 0
