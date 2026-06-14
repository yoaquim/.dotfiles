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
# Recognized read-only commands:
#   - flagless-safe utilities: ls cat head tail wc grep rg which file jq diff shellcheck
#   - git status / diff / log / show   (excluded if --output, which writes a file)
# Pipelines of these are fine. Command chaining, substitution, backgrounding, and
# any file-writing redirect disqualify (fall through to a prompt).

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

# Disqualify on a file-writing redirect, command substitution, chaining,
# backgrounding, or a newline. Only the `|` pipe separator survives to splitting.
# shellcheck disable=SC2016  # the '$(' pattern is a literal to match, not an expansion
case "$STRIPPED" in
  *'>'*|*'&'*|*';'*|*'`'*|*'$('*|*$'\n'*) exit 0 ;;
esac

SAFE='ls|cat|head|tail|wc|grep|rg|which|file|jq|diff|shellcheck'

ok=1
IFS='|' read -ra SEGS <<<"$STRIPPED"
for seg in "${SEGS[@]}"; do
  # Trim surrounding whitespace.
  seg="${seg#"${seg%%[![:space:]]*}"}"
  seg="${seg%"${seg##*[![:space:]]}"}"
  [[ -z "$seg" ]] && { ok=0; break; }
  # Strip leading VAR=val env assignments.
  while [[ "$seg" =~ ^[A-Za-z_][A-Za-z0-9_]*=[^[:space:]]*[[:space:]]+(.*)$ ]]; do
    seg="${BASH_REMATCH[1]}"
  done
  word=${seg%%[[:space:]]*}
  if [[ "$word" =~ ^($SAFE)$ ]]; then
    continue
  fi
  # Read-only git subcommands — but not with --output (writes a file).
  if [[ "$seg" =~ ^git[[:space:]]+(status|diff|log|show)([[:space:]]|$) && "$seg" != *--output* ]]; then
    continue
  fi
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
