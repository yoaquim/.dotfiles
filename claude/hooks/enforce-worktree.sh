#!/usr/bin/env bash
# PreToolUse hook for the runner agent: block runner writes into the SHARED
# main checkout. This is the isolation guarantee — concurrent runners (and the
# operator) share one main checkout, so a runner must never modify it.
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
# Runner identity comes from the CLAUDE_DISPATCH_* env vars that spawn.sh injects
# into the runner process. These are IMMUTABLE — a runner that `cd`s into the
# main checkout cannot change them, so enforcement holds regardless of cwd.
# Sessions launched without those vars fall back to cwd-derived detection (best
# effort: it cannot see a runner that has cd'd away from its worktree).
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

# --- Resolve runner identity (immutable env, else cwd fallback) ---
if [[ -n "${CLAUDE_DISPATCH_WORKTREE:-}" ]]; then
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

# True if the command contains an UNQUOTED `{` — brace expansion can build a
# main-checkout path (`touch {/main/,}repo/x`) that the literal substring scan
# below would miss. Quoted braces aren't expanded by the shell, so ignore them.
has_unquoted_brace() {
    local s="$1"
    local n=${#s} i=0 c sq=0 dq=0
    while [[ $i -lt $n ]]; do
        c=${s:i:1}
        if [[ $sq -eq 0 && "$c" == "\\" ]]; then i=$((i+2)); continue; fi
        if [[ $sq -eq 0 && "$c" == '"' ]]; then dq=$((1-dq)); i=$((i+1)); continue; fi
        if [[ $dq -eq 0 && "$c" == "'" ]]; then sq=$((1-sq)); i=$((i+1)); continue; fi
        if [[ $sq -eq 0 && $dq -eq 0 && "$c" == '{' ]]; then return 0; fi
        i=$((i+1))
    done
    return 1
}

case "$TOOL" in
  Edit|Write|MultiEdit)
    FILE=$(jq -r '.tool_input.file_path // ""' <<<"$INPUT")
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
    # Always allow a pure `cd` (it writes nothing) so a runner whose cwd has
    # drifted into the main checkout can recover by cd'ing back to its worktree —
    # the next command runs under the new cwd and is re-checked. Reject if it
    # chains another command or uses substitution.
    # shellcheck disable=SC2016  # '$(' / '<(' are literals to match, not expansions
    if [[ "$CMD" =~ ^[[:space:]]*cd([[:space:]]|$) ]]; then
      case "$CMD" in
        *'&&'*|*'||'*|*';'*|*'|'*|*'&'*|*'$('*|*'`'*|*'<('*|*$'\n'*) : ;;
        *) exit 0 ;;
      esac
    fi
    # Unquoted brace expansion can build a main-checkout path the substring scan
    # can't see; we can't safely expand it here, so block and have the runner
    # write the path explicitly.
    if has_unquoted_brace "$CMD"; then
      block_msg "this command uses unquoted brace expansion, which can't be checked against the worktree boundary. Write the path(s) out explicitly."
      exit 2
    fi
    # cwd inside the shared checkout (runner cd'd out of its worktree) → block.
    # A relative write like `sed -i README.md` from there hits the main checkout
    # and would not appear in the text scan below.
    if [[ -n "$CWD" ]]; then
      C_CWD=$(canon "$CWD")
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
    # Strip shell backslash-escapes first: the shell dequotes `/work\/repo` to
    # `/work/repo`, so without this `touch /main\/repo/x` would smuggle a write
    # past the literal substring match. Aggressive de-escaping only ever makes
    # MORE paths match the protected root (fail-safe for a guard).
    DCMD=$(printf '%s' "$CMD" | sed 's#\\\(.\)#\1#g')
    re_escape() { sed 's#[^a-zA-Z0-9/_-]#\\&#g' <<<"$1"; }
    BOUND='(/|[[:space:]]|["'"'"':;,&|]|$)'
    SED_PROG=""
    for p in "$WORKTREE" "$C_WT" "$STATUS_FILE" "$C_SF"; do
      [[ -z "$p" ]] && continue
      SED_PROG+="s#$(re_escape "$p")${BOUND}#\\1#g;"
    done
    MASKED=$(printf '%s' "$DCMD" | sed -E "$SED_PROG")
    # Block the literal/canonical main-checkout path OR a reference to the
    # CLAUDE_DISPATCH_ROOT env var (the shell expands it to that path) — otherwise
    # `git -C "$CLAUDE_DISPATCH_ROOT" ...` slips past the literal check.
    # CLAUDE_DISPATCH_WORKTREE / _STATUS_FILE refs stay allowed.
    if [[ "$MASKED" == *"$DISPATCH_ROOT"* || "$MASKED" == *"$C_ROOT"* || "$DCMD" == *CLAUDE_DISPATCH_ROOT* ]]; then
      block_msg "this command references the shared main checkout at '$DISPATCH_ROOT'."
      exit 2
    fi
    ;;
esac

exit 0
