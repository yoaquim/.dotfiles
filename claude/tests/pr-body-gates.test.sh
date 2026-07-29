#!/usr/bin/env bash
# classify-diff.sh + validate-pr-body.sh — the PR-time disclosure gates.
#
# Three gates, all driven by facts read off the real diff: test changes need a
# classification, source-without-tests needs a justification, and an escape
# hatch must be named in the body. Each verifies that a disclosure was WRITTEN,
# never that it is true — that stays a reviewer's job.

set -uo pipefail
# shellcheck source=/dev/null
. "$(dirname "${BASH_SOURCE[0]}")/lib.sh"

CD="$SCRIPTS/classify-diff.sh"
VP="$SCRIPTS/validate-pr-body.sh"
IT="$SCRIPTS/is-test-path.sh"
echo "is-test-path.sh / classify-diff.sh / validate-pr-body.sh"

# --- is-test-path ---
expect_cmd 0 "detects tests/ in a file list" bash -c "printf 'src/api.ts\ntests/test_api.py\n' | $IT"
expect_cmd 0 "detects a rails spec" bash -c "printf 'spec/models/user_spec.rb\n' | $IT"
expect_cmd 0 "detects a go test" bash -c "printf 'internal/api/handler_test.go\n' | $IT"
expect_cmd 1 "ignores a non-test list" bash -c "printf 'src/api.ts\nREADME.md\n' | $IT"
expect_cmd 1 "contest.py is not a test" bash -c "printf 'src/lib/contest.py\n' | $IT"

# --- classify-diff ---
DIFF_TESTS='--- a/tests/test_api.py
+++ b/tests/test_api.py
@@ -1 +1 @@
-assert a == 1
+assert a == 2'
DIFF_SRC='--- a/src/api.ts
+++ b/src/api.ts
@@ -1 +1 @@
-const x = 1
+const x = 2'
DIFF_DOCS='--- a/README.md
+++ b/README.md
@@ -1 +1 @@
-old
+new'
DIFF_HATCH='--- a/tests/test_api.py
+++ b/tests/test_api.py
@@ -1 +1 @@
-assert a == 1
+assert a == 1  # test-weakening-ok'

facts() { printf '%s' "$1" | "$CD"; }

expect_cmd 0 "test diff sets tests_changed" \
  bash -c "[ \"\$(printf '%s' '$DIFF_TESTS' | $CD | jq -r .tests_changed)\" = 1 ]"
expect_cmd 0 "source diff sets source_changed" \
  bash -c "[ \"\$(printf '%s' '$DIFF_SRC' | $CD | jq -r .source_changed)\" = 1 ]"
expect_cmd 0 "docs-only diff sets neither" \
  bash -c "[ \"\$(printf '%s' '$DIFF_DOCS' | $CD | jq -r '.tests_changed + .source_changed')\" = 0 ]"
expect_cmd 0 "added hatch token is collected" \
  bash -c "[ \"\$(printf '%s' '$DIFF_HATCH' | $CD | jq -r '.hatches[0]')\" = 'test-weakening-ok' ]"
expect_cmd 0 "a test file is not also source" \
  bash -c "[ \"\$(printf '%s' '$DIFF_TESTS' | $CD | jq -r .source_changed)\" = 0 ]"

# A hatch already in the file — context line, not an added one — is not this
# PR's to justify.
DIFF_HATCH_CONTEXT='--- a/tests/test_api.py
+++ b/tests/test_api.py
@@ -1,2 +1,2 @@
 assert a == 1  # test-weakening-ok
-assert b == 2
+assert b == 3'
expect_cmd 0 "pre-existing hatch on a context line is ignored" \
  bash -c "[ \"\$(printf '%s' '$DIFF_HATCH_CONTEXT' | $CD | jq -r '.hatches | length')\" = 0 ]"

# --- validate-pr-body ---
PREAMBLE='Rework the retry path so a 429 backs off instead of failing outright.

**Testing:** full suite green locally.'

F_TESTS=$(facts "$DIFF_TESTS")
F_SRC=$(facts "$DIFF_SRC")
F_HATCH=$(facts "$DIFF_HATCH")

expect_cmd 0 "tests changed + valid classification passes" \
  "$VP" "$PREAMBLE

Test changes: contract moved — retries now cap at 3 (per RIM-40)." "" "$F_TESTS"
expect_cmd 1 "tests changed + no classification fails" \
  "$VP" "$PREAMBLE" "" "$F_TESTS"
expect_cmd 1 "tests changed + off-vocabulary classification fails" \
  "$VP" "$PREAMBLE

Test changes: whatever felt right." "" "$F_TESTS"

expect_cmd 0 "source without tests + justification passes" \
  "$VP" "$PREAMBLE

No new tests: pure rename, existing suite covers every call site." "" "$F_SRC"
expect_cmd 1 "source without tests + no justification fails" \
  "$VP" "$PREAMBLE" "" "$F_SRC"
expect_cmd 1 "source without tests + empty justification fails" \
  "$VP" "$PREAMBLE

No new tests: n/a" "" "$F_SRC"

expect_cmd 0 "hatch named in the body passes" \
  "$VP" "$PREAMBLE

Test changes: test was wrong — it asserted the old cap.
Used test-weakening-ok: the assertions moved into a shared helper." "" "$F_HATCH"
expect_cmd 1 "hatch not named in the body fails" \
  "$VP" "$PREAMBLE

Test changes: test was wrong — it asserted the old cap." "" "$F_HATCH"

# No facts at all (older call sites, or a diff we could not read) → the three
# gates go quiet rather than inventing a requirement.
expect_cmd 0 "absent diff facts skip the new gates" "$VP" "$PREAMBLE" "" ""
expect_cmd 0 "malformed diff facts skip the new gates" "$VP" "$PREAMBLE" "" "not json"

summarize
