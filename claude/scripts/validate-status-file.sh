#!/usr/bin/env bash
# validate-status-file.sh — Validate a dispatch status file against the format
# the machinery actually parses (see scripts/lib/dispatch.sh — the sed regex is
# the spec). Catches silent drift: a renamed field or mangled timestamp returns
# empty from every consumer (status.sh, Stop-hook gates, watchdog/janitor
# resurrection, cyberdeck's fleet scanner) without a word.
#
# Usage: validate-status-file.sh <status-file>
# Output: {"valid": bool, "errors": [...]}   Exit 0 valid, 1 invalid.

set -uo pipefail

# shellcheck disable=SC1091
. "$HOME/.claude/scripts/lib/dispatch.sh"

FILE="${1:-}"
errors=()

emit() {
  local valid="true"
  [[ ${#errors[@]} -gt 0 ]] && valid="false"
  printf '{"valid": %s, "errors": [' "$valid"
  local i
  for i in "${!errors[@]}"; do
    [[ $i -gt 0 ]] && printf ', '
    printf '%s' "$(jq -Rn --arg e "${errors[$i]}" '$e')"
  done
  printf ']}\n'
  [[ "$valid" == "true" ]]
}

if [[ -z "$FILE" ]]; then
  errors+=("usage: validate-status-file.sh <status-file>")
  emit; exit 1
fi
if [[ ! -f "$FILE" || ! -r "$FILE" ]]; then
  errors+=("file not found or unreadable: $FILE")
  emit; exit 1
fi

for field in session_id branch worktree status started updated; do
  value=$(dispatch_status_field "$field" "$FILE")
  [[ -z "$value" ]] && errors+=("missing required field: $field")
done

STATUS=$(dispatch_status_field status "$FILE")
if [[ -n "$STATUS" ]] && ! dispatch_is_known_status "$STATUS"; then
  errors+=("unknown status '$STATUS' (known: $DISPATCH_KNOWN_STATUSES)")
fi

for tsfield in started updated; do
  ts=$(dispatch_status_field "$tsfield" "$FILE")
  if [[ -n "$ts" && "$(iso_to_epoch "$ts")" == "0" ]]; then
    errors+=("unparseable $tsfield timestamp: '$ts'")
  fi
done

emit
