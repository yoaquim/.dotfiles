#!/usr/bin/env bash
# is-test-path.sh — is any of these paths a test file?
#
# Usage: is-test-path.sh <path>...        # paths as arguments
#        git diff --name-only | is-test-path.sh   # or on stdin
#
# Exit 0: at least one path is a test file (and it is echoed).
# Exit 1: none are.
#
# One definition, two consumers: guard-test-edits.sh (per-edit) and the
# PR-body gate (per-diff). Test layouts vary by stack, so this covers the
# directory conventions (Rails spec/, pytest tests/, JS __tests__/) and the
# per-file suffixes (*_test.go, *.test.ts, *_spec.rb, test_*.py).

set -uo pipefail

if (( $# > 0 )); then
  PATHS=$(printf '%s\n' "$@")
else
  PATHS=$(cat 2>/dev/null || true)
fi

FOUND=1
while IFS= read -r p; do
  [[ -n "$p" ]] || continue
  base=${p##*/}
  match=false

  case "/$p" in
    */test/*|*/tests/*|*/spec/*|*/specs/*|*/__tests__/*) match=true ;;
  esac

  if [[ "$match" != true ]]; then
    case "$base" in
      *_test.*|*.test.*|*_spec.*|*.spec.*|test_*.py|Test*.java|*Test.java|*Tests.cs) match=true ;;
    esac
  fi

  if [[ "$match" == true ]]; then
    echo "$p"
    FOUND=0
  fi
done <<<"$PATHS"

exit $FOUND
