#!/usr/bin/env bash
# PreToolUse hook (Edit|Write|MultiEdit): block catch-all Playwright route
# interceptors in test files. A route glob that matches EVERYTHING ('**',
# '**/*') also intercepts Vite's module requests in dev-server-backed e2e
# runs — specs then fail on module loads, far from the real cause (a runner
# shipped exactly this). Narrow the glob to the endpoint being mocked,
# e.g. '**/api/session/**'.
#
# Escape hatch: `route-scope-ok` anywhere in the edit chunk allows it, for the
# rare spec that genuinely must intercept all traffic. It blesses the whole
# chunk, not a line — route calls legitimately span lines, so same-line-only
# semantics would be uncheckable for the multiline case.
#
# Exit 0 → allow the edit. Exit 2 → block; stderr is fed back to the model.

set -uo pipefail

# Never break editing because of a bug in this hook.
trap 'exit 0' ERR

INPUT=$(cat 2>/dev/null || echo '{}')
FILE=$(jq -r '.tool_input.file_path // ""' <<<"$INPUT")

# Only test files register Playwright routes worth guarding.
case "$FILE" in
  *.spec.ts|*.spec.tsx|*.test.ts|*.test.tsx|*/e2e/*|*/playwright/*) ;;
  *) exit 0 ;;
esac

# Write carries `content`, Edit carries `new_string`, MultiEdit an `edits[]`
# array of replacements; absent fields are empty.
CONTENT=$(jq -r '[
    (.tool_input.content // ""),
    (.tool_input.new_string // ""),
    ((.tool_input.edits // []) | map(.new_string // "") | join("\n"))
  ] | join("\n")' <<<"$INPUT")
[[ -n "${CONTENT//[[:space:]]/}" ]] || exit 0

grep -q 'route-scope-ok' <<<"$CONTENT" && exit 0

# `.route(` and its glob argument are commonly on different lines and grep is
# line-oriented — flatten newlines to spaces before matching.
FLAT=$(tr '\n\t' '  ' <<<"$CONTENT")
BAD=$(grep -oE "\.route\([[:space:]]*['\"](\*\*(/\*{1,2})?)['\"]" <<<"$FLAT" || true)
[[ -z "$BAD" ]] && exit 0

{
  echo "Blocked: catch-all Playwright route glob in $FILE:"
  echo
  echo "$BAD"
  echo
  echo "A route matching everything ('**', '**/*') also intercepts Vite module"
  echo "requests in dev-server-backed e2e runs — specs then fail on module loads,"
  echo "far from the real cause. Scope the glob to the endpoint being mocked,"
  echo "e.g. page.route('**/api/session/**', ...)."
  echo
  echo "If this spec genuinely must intercept ALL traffic, add route-scope-ok"
  echo "in a comment and re-apply the edit."
} >&2
exit 2
