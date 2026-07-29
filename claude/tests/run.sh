#!/usr/bin/env bash
# Run the hook test suite.
#
#   claude/tests/run.sh            # everything
#   claude/tests/run.sh guard      # only files matching "guard"
#
# These hooks fail open by design: a bug disables enforcement silently rather
# than erroring. That makes them exactly the kind of code that needs tests —
# nothing else will tell you they stopped working. They also parse Claude Code's
# transcript and tool-input shapes, which are not a stable API, so run this
# after a CC upgrade.

set -uo pipefail

cd "$(dirname "${BASH_SOURCE[0]}")" || exit 1

FILTER="${1:-}"
TOTAL_FAIL=0
RAN=0

for t in *.test.sh; do
  [[ -e "$t" ]] || continue
  [[ -n "$FILTER" && "$t" != *"$FILTER"* ]] && continue
  RAN=$((RAN + 1))
  bash "$t" || TOTAL_FAIL=$((TOTAL_FAIL + 1))
  echo
done

if (( RAN == 0 )); then
  echo "No test files matched${FILTER:+ \"$FILTER\"}."
  exit 1
fi

if (( TOTAL_FAIL > 0 )); then
  echo "$TOTAL_FAIL of $RAN test file(s) FAILED"
  exit 1
fi

echo "all $RAN test file(s) passed"
