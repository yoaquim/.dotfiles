#!/usr/bin/env bash
# classify-diff.sh — extract the facts a PR-body gate needs from a unified diff.
#
# Usage: gh pr diff 42 | classify-diff.sh
#        git diff "$MERGE_BASE" HEAD | classify-diff.sh
#
# Output: JSON on stdout —
#   {"tests_changed":0|1,"source_changed":0|1,"hatches":["token",...]}
#
#   tests_changed  — the diff touches a test file (is-test-path.sh decides)
#   source_changed — the diff touches code that is NOT a test file. Docs, JSON,
#                    YAML and lockfiles don't count; a PR that only edits those
#                    is not ducking test coverage.
#   hatches        — escape-hatch tokens introduced on ADDED lines. A token
#                    already present before the change is not this PR's to
#                    justify, so removed and context lines are ignored.
#
# One parse, three consumers (test-integrity declaration, missing-test
# declaration, hatch disclosure) — see dry.md.

set -uo pipefail

DIFF=$(cat 2>/dev/null || true)

HATCH_TOKENS='route-scope-ok|test-weakening-ok'

# `+++ b/path` lines name the post-image file. /dev/null is a deletion.
FILES=$(grep -E '^\+\+\+ ' <<<"$DIFF" 2>/dev/null | sed -E 's@^\+\+\+ (b/)?@@' | grep -v '^/dev/null$' || true)

TESTS_CHANGED=0
SOURCE_CHANGED=0

if [[ -n "$FILES" ]]; then
  TEST_FILES=$(printf '%s\n' "$FILES" | "$HOME/.claude/scripts/is-test-path.sh" 2>/dev/null || true)
  [[ -n "$TEST_FILES" ]] && TESTS_CHANGED=1

  while IFS= read -r f; do
    [[ -n "$f" ]] || continue
    # Already counted as a test file → not "source" for this purpose.
    if [[ -n "$TEST_FILES" ]] && grep -qxF "$f" <<<"$TEST_FILES"; then
      continue
    fi
    case "$f" in
      *.ts|*.tsx|*.js|*.jsx|*.mjs|*.cjs|*.vue|*.svelte) SOURCE_CHANGED=1 ;;
      *.py|*.rb|*.go|*.rs|*.java|*.kt|*.swift|*.scala) SOURCE_CHANGED=1 ;;
      *.c|*.h|*.cpp|*.hpp|*.cs|*.php|*.ex|*.exs|*.erl|*.clj) SOURCE_CHANGED=1 ;;
      *.sh|*.bash|*.sql|*.tf|*.hcl) SOURCE_CHANGED=1 ;;
    esac
  done <<<"$FILES"
fi

# Added lines only: `^+` but not the `+++` file header.
HATCHES=$(grep -E '^\+' <<<"$DIFF" 2>/dev/null | grep -v '^+++ ' \
  | grep -oE "$HATCH_TOKENS" 2>/dev/null | sort -u || true)

HATCH_JSON=$(printf '%s' "$HATCHES" | jq -R -s -c 'split("\n") | map(select(length > 0))' 2>/dev/null || echo '[]')

jq -n -c \
  --argjson tests "$TESTS_CHANGED" \
  --argjson source "$SOURCE_CHANGED" \
  --argjson hatches "$HATCH_JSON" \
  '{tests_changed: $tests, source_changed: $source, hatches: $hatches}'
