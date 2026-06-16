#!/usr/bin/env bash
# PreToolUse (Bash): auto-approve known read-only commands so they don't prompt,
# WITHOUT the redirect-write hole of a static permissions.allow list.
#
# Why a hook instead of allow rules:
#   - Claude Code does not treat `>`/`>>` as special operators, so an allow rule
#     like `Bash(cat:*)` ALSO auto-approves `cat x > file` (a write).
#   - A PreToolUse hook returning "ask" cannot override an allow rule (only an
#     exit-2 block can). So we keep NO read allow rules and grant approval HERE,
#     gated on "contains no file-writing redirect".
#
# Safe-by-default: emit "allow" only when every pipeline segment is positively
# recognized as read-only. Anything else stays silent → normal permission prompt.
#
# Recognized read-only commands: ls, cat, head, tail, wc, grep, rg, which, diff,
# and the shellcheck binary. Pipelines of these are fine. Excluded: git (repo
# config can execute helpers), file (`-C` writes a .mgc), jq (`env` reads the
# process environment). Command chaining, substitution, backgrounding,
# env-assignment prefixes, and any file-writing redirect disqualify (→ prompt).
# Auto-approval is also scoped to the project: home refs (~/$), parent escapes
# (..), and absolute paths outside the cwd disqualify, so a prompt-injected repo
# can't silently read secrets (e.g. ~/.ssh/id_rsa) without a prompt.

set -uo pipefail
trap 'exit 0' ERR

INPUT=$(cat)
CMD=$(jq -r '.tool_input.command // ""' <<<"$INPUT")
CWD=$(jq -r '.cwd // ""' <<<"$INPUT")
[[ -z "$CMD" ]] && exit 0

# Remove harmless redirect forms (fd dups, /dev sinks) so the disqualifier checks
# below only fire on real writes / separators.
STRIPPED=$(printf '%s' "$CMD" | sed -E '
  s/[0-9]*>&[0-9-]+//g;                                       # fd dups: 2>&1, >&2, >&-
  s/[0-9]*&?>>?[[:space:]]*\/dev\/(null|stdout|stderr)([[:space:];|]|$)/\2/g;  # >/dev/null, 2>>/dev/null, &>/dev/null — boundary-anchored so >/dev/nullX is not partially stripped
')

# Disqualify on a redirect (output `>` OR input `<`, incl. `<(`/`<<`), command
# substitution, chaining, backgrounding, or a newline. `<` matters because
# `cat </etc/passwd` reads a file the token scan below wouldn't flag as absolute.
# Only the `|` pipe separator survives to splitting.
# shellcheck disable=SC2016  # the '$(' pattern is a literal to match, not an expansion
case "$STRIPPED" in
  *'>'*|*'<'*|*'&'*|*';'*|*'`'*|*'$('*|*$'\n'*) exit 0 ;;
esac

# Excluded on purpose: `file` (`-C` writes a .mgc) and `jq` (its `env`/`$ENV`
# builtins read process environment — i.e. inherited secrets — with no operand).
SAFE='ls|cat|head|tail|wc|grep|rg|which|diff|shellcheck'

ok=1
IFS='|' read -ra SEGS <<<"$STRIPPED"
for seg in "${SEGS[@]}"; do
  # Trim surrounding whitespace.
  seg="${seg#"${seg%%[![:space:]]*}"}"
  seg="${seg%"${seg##*[![:space:]]}"}"
  [[ -z "$seg" ]] && { ok=0; break; }
  # An env-assignment prefix can hijack execution of an otherwise-safe command —
  # LD_PRELOAD=evil.so cat, PATH=/tmp/evil grep, GIT_EXTERNAL_DIFF=... git diff,
  # GIT_PAGER=..., etc. Never auto-allow an env-prefixed command.
  if [[ "$seg" =~ ^[A-Za-z_][A-Za-z0-9_]*= ]]; then
    ok=0; break
  fi
  word=${seg%%[[:space:]]*}
  # rg can execute a command via --pre / --pre-glob (preprocessor) or
  # --hostname-bin (hostname helper). Never auto-allow those. Trailing (=|space|
  # end) so lookalikes such as --pretty do NOT match.
  if [[ "$word" == "rg" && "$seg" =~ (^|[[:space:]])(--pre(-glob)?|--hostname-bin)(=|[[:space:]]|$) ]]; then
    ok=0; break
  fi
  # Recursive descent that FOLLOWS symlinks can read outside the project via a
  # symlink in a subdirectory (operand-only path checks don't see those). Block
  # the symlink-following recursive flags; non-following recursion (grep -r, rg's
  # default) is fine. Short-flag clusters like `-ru` are matched.
  case "$word" in
    diff) [[ "$seg" =~ (^|[[:space:]])(-[A-Za-z]*r[A-Za-z]*|--recursive)([[:space:]]|$) ]] && { ok=0; break; } ;;
    grep) [[ "$seg" =~ (^|[[:space:]])(-[A-Za-z]*R[A-Za-z]*|--dereference-recursive)([[:space:]]|$) ]] && { ok=0; break; } ;;
    rg)   [[ "$seg" =~ (^|[[:space:]])(-[A-Za-z]*L[A-Za-z]*|--follow)([[:space:]]|$) ]] && { ok=0; break; } ;;
  esac
  if [[ "$word" =~ ^($SAFE)$ ]]; then
    continue
  fi
  # NOTE: git is deliberately NOT auto-allowed. Even `git status`/`diff`/`log`
  # execute repo-local config helpers (core.fsmonitor, diff.external, .gitattributes
  # textconv) that a cloned repo can set with no env/-c and no setup command — an
  # arbitrary-exec vector. git commands fall through to the normal prompt.
  ok=0; break
done

# Path-exfil guard: a read-only command is still dangerous if it reads SECRETS.
# Auto-approve only when the command stays inside the current project (cwd) — so
# a prompt-injected repo can't silently `cat ~/.ssh/id_rsa` or `rg TOKEN ~/.config`
# into the transcript without a prompt. Reject:
#   - ~ or $ (home reference / variable expansion → unknown or out-of-project target)
#   - .. (parent-directory escape)
#   - any absolute path token not under the cwd
# Relative, in-project reads (the common case) still auto-approve.
if [[ $ok -eq 1 ]]; then
  case "$CMD" in
    *'~'*|*'$'*|*'..'*) ok=0 ;;
  esac
fi
# An UNQUOTED brace can expand to an out-of-project path (`cat {/,}etc/passwd` →
# /etc/passwd) that the token scan wouldn't see. Quoted braces (e.g. jq '{a:1}')
# are NOT expanded by the shell, so only reject unquoted ones.
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
if [[ $ok -eq 1 ]] && has_unquoted_brace "$CMD"; then ok=0; fi
if [[ $ok -eq 1 && -n "$CWD" ]]; then
  C_CWD=$(cd "$CWD" 2>/dev/null && pwd -P) || C_CWD="$CWD"
  # Resolve as much of an operand as exists (from cwd), following symlinks on the
  # existing prefix, and re-attach the missing tail — so `sshlink/missing` where
  # sshlink -> /etc resolves to /etc/missing. Empty output = nothing path-like.
  real_prefix() {
    local q="$1" sfx="" r
    while [[ -n "$q" && "$q" != "." && "$q" != "/" ]]; do
      if r=$(cd "$CWD" 2>/dev/null && realpath -- "$q" 2>/dev/null); then
        printf '%s%s' "$r" "$sfx"; return 0
      fi
      sfx="/$(basename "$q")$sfx"
      q=$(dirname "$q")
    done
    return 1
  }
  # Tokenize respecting quotes/escapes so an operand with spaces (`cat "leak file"`)
  # is ONE token, not several. By here the disqualifiers have removed $(), backticks,
  # $vars, ~, unquoted braces and redirects, so what remains is plain words/quotes/
  # globs that xargs splits the same way the shell will. A parse failure (e.g.
  # unbalanced quote) → decline.
  if ! toks=$(printf '%s' "$CMD" | xargs printf '%s\n' 2>/dev/null); then
    ok=0
  fi
  while [[ $ok -eq 1 ]] && IFS= read -r tok; do
    [[ -z "$tok" ]] && continue
    # A token with glob metacharacters is expanded by the real shell; expand it
    # here against the cwd and validate every match's real target — `cat *` must
    # not silently read a `leak -> ~/.ssh/id_rsa` match. No match → literal → the
    # checks below handle it.
    case "$tok" in
      *'*'*|*'?'*|*'['*)
        # shellcheck disable=SC2086  # $tok is unquoted on purpose: glob-expand it against the cwd
        matches=$(cd "$CWD" 2>/dev/null && set +f && printf '%s\n' $tok 2>/dev/null)
        while IFS= read -r m; do
          [[ -z "$m" ]] && continue
          rp=$(real_prefix "$m") || continue
          case "$rp" in
            "$CWD"|"$CWD"/*|"$C_CWD"|"$C_CWD"/*) : ;;  # match inside the project → ok
            *) ok=0; break ;;                          # match resolves outside → prompt
          esac
        done <<< "$matches"
        [[ $ok -eq 0 ]] && break
        continue
        ;;
    esac
    # Extract an absolute path even when attached to an option, so
    # `--from-file=/etc/passwd` and `-f/etc/passwd` are checked, not just bare /…
    cand="$tok"
    case "$cand" in *=*) cand=${cand#*=} ;; esac   # --from-file=/x -> /x
    case "$cand" in -*/*) cand="/${cand#*/}" ;; esac  # -f/etc/passwd -> /etc/passwd
    case "$cand" in
      /*)
        # Accept under the cwd in either its raw or canonical (symlink-resolved)
        # spelling, so /tmp vs /private/tmp doesn't cause a false prompt.
        case "$cand" in
          "$CWD"|"$CWD"/*|"$C_CWD"|"$C_CWD"/*) : ;;  # absolute path inside the project → ok
          *) ok=0; break ;;                          # outside the project → prompt
        esac
        ;;
    esac
    # Resolve the operand and check its REAL target: an in-cwd symlink can point
    # outside the project (`cat leak` where leak -> ~/.ssh/id_rsa, or a symlinked
    # dir `sshlink/x`). Skip flags; a non-path (pattern/missing) yields no prefix.
    case "$cand" in
      -*) ;;
      *)
        if rp=$(real_prefix "$cand"); then
          case "$rp" in
            "$CWD"|"$CWD"/*|"$C_CWD"|"$C_CWD"/*) : ;;  # resolves inside the project → ok
            *) ok=0; break ;;                          # resolves outside → prompt
          esac
        fi
        ;;
    esac
  done <<< "$toks"
fi

if [[ $ok -eq 1 ]]; then
  jq -n '{
    hookSpecificOutput: {
      hookEventName: "PreToolUse",
      permissionDecision: "allow",
      permissionDecisionReason: "read-only command scoped to the project, no file-writing redirect"
    }
  }'
fi
exit 0
