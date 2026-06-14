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
# Recognized read-only commands: ls cat head tail wc grep rg which file jq diff
# and shellcheck itself. Pipelines of these are fine. git is NOT included (its
# repo-local config can execute helpers). Command chaining, substitution,
# backgrounding, env-assignment prefixes, and any file-writing redirect
# disqualify (fall through to a prompt).

set -uo pipefail
trap 'exit 0' ERR

INPUT=$(cat)
CMD=$(jq -r '.tool_input.command // ""' <<<"$INPUT")
[[ -z "$CMD" ]] && exit 0

# Remove harmless redirect forms (fd dups, /dev sinks) so the disqualifier checks
# below only fire on real writes / separators.
STRIPPED=$(printf '%s' "$CMD" | sed -E '
  s/[0-9]*>&[0-9-]+//g;                                       # fd dups: 2>&1, >&2, >&-
  s/[0-9]*&?>>?[[:space:]]*\/dev\/(null|stdout|stderr)//g;    # >/dev/null, 2>>/dev/null, &>/dev/null
')

# Disqualify on a file-writing redirect, command/process substitution, chaining,
# backgrounding, or a newline. Only the `|` pipe separator survives to splitting.
# `<(` is input process substitution (runs a subprocess); `>(` and `>` are caught
# by the `>` arm.
# shellcheck disable=SC2016  # the '$(' / '<(' patterns are literals to match, not expansions
case "$STRIPPED" in
  *'>'*|*'&'*|*';'*|*'`'*|*'$('*|*'<('*|*$'\n'*) exit 0 ;;
esac

SAFE='ls|cat|head|tail|wc|grep|rg|which|file|jq|diff|shellcheck'

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
  # rg can execute a preprocessor command via --pre / --pre-glob — never allow it.
  # (`--pretty` etc. must NOT match, so require a =, space, or end after --pre.)
  if [[ "$word" == "rg" && "$seg" =~ (^|[[:space:]])--pre(-glob)?(=|[[:space:]]|$) ]]; then
    ok=0; break
  fi
  if [[ "$word" =~ ^($SAFE)$ ]]; then
    continue
  fi
  # NOTE: git is deliberately NOT auto-allowed. Even `git status`/`diff`/`log`
  # execute repo-local config helpers (core.fsmonitor, diff.external, .gitattributes
  # textconv) that a cloned repo can set with no env/-c and no setup command — an
  # arbitrary-exec vector. git commands fall through to the normal prompt.
  ok=0; break
done

if [[ $ok -eq 1 ]]; then
  jq -n '{
    hookSpecificOutput: {
      hookEventName: "PreToolUse",
      permissionDecision: "allow",
      permissionDecisionReason: "read-only command, no file-writing redirect"
    }
  }'
fi
exit 0
