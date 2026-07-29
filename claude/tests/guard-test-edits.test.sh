#!/usr/bin/env bash
# guard-test-edits.sh — blocks mechanical weakening of an existing test.
#
# The false-positive cases matter as much as the blocking ones: this hook stops
# real edits, so a bad match costs work. Two of them (pendingWrites, onlyDigits)
# are regressions against a draft that matched those bare words.

set -uo pipefail
# shellcheck source=/dev/null
. "$(dirname "${BASH_SOURCE[0]}")/lib.sh"

H="$HOOKS/guard-test-edits.sh"
echo "guard-test-edits.sh"

# --- blocks: test switched off ---
expect_exit 2 "js .skip added" "$H" \
  "$(edit_json 'src/foo.test.ts' "it('w', () => { expect(a).toBe(1) })" "it.skip('w', () => { expect(a).toBe(1) })")"
expect_exit 2 "pytest skip marker added" "$H" \
  "$(edit_json 'tests/test_api.py' $'def test_x():\n    assert a == 1' $'@pytest.mark.skip\ndef test_x():\n    assert a == 1')"
expect_exit 2 "go t.Skip added" "$H" \
  "$(edit_json 'api/handler_test.go' $'func TestX(t *testing.T){\n if a!=1 {t.Error("no")}\n}' $'func TestX(t *testing.T){\n t.Skip("flaky")\n if a!=1 {t.Error("no")}\n}')"
expect_exit 2 "rspec pending added" "$H" \
  "$(edit_json 'spec/user_spec.rb' $'it "x" do\n expect(a).to eq 1\nend' $'it "x" do\n pending("flaky")\n expect(a).to eq 1\nend')"
expect_exit 2 ".only focuses one, disables siblings" "$H" \
  "$(edit_json 'spec/user_spec.rb' $'describe "x" do\n expect(a).to eq 1\nend' $'describe.only "x" do\n expect(a).to eq 1\nend')"
expect_exit 2 "test commented out" "$H" \
  "$(edit_json 'tests/test_api.py' $'def test_x():\n    assert a == 1' $'# def test_x():\n#     assert a == 1')"

# --- blocks: assertions removed ---
expect_exit 2 "assertions dropped 3 to 1" "$H" \
  "$(edit_json 'tests/test_api.py' $'assert a == 1\nassert b == 2\nassert c == 3' 'assert a == 1')"
expect_exit 2 "behavioral assertion to existence check" "$H" \
  "$(edit_json 'src/a.test.ts' $'expect(r.id).toBe(7)\nexpect(r.name).toBe("x")' 'expect(r).toBeDefined()')"

# --- blocks: timeout raised ---
expect_exit 2 "timeout raised to mask a race" "$H" \
  "$(edit_json 'e2e/login.spec.ts' 'await page.waitFor(1000)' 'await page.waitFor(30000)')"

# --- allows ---
expect_exit 0 "assertions added" "$H" \
  "$(edit_json 'tests/test_api.py' 'assert a == 1' $'assert a == 1\nassert b == 2')"
expect_exit 0 "rewrite keeping assertion count" "$H" \
  "$(edit_json 'tests/test_api.py' $'assert a == 1\nassert b == 2' $'assert a == 5\nassert b == 9')"
expect_exit 0 "timeout lowered" "$H" \
  "$(edit_json 'e2e/login.spec.ts' 'await page.waitFor(30000)' 'await page.waitFor(500)')"
expect_exit 0 "escape hatch clears the block" "$H" \
  "$(edit_json 'tests/test_api.py' $'assert a == 1\nassert b == 2' 'assert a == 1  # test-weakening-ok')"
expect_exit 0 "non-test file untouched" "$H" \
  "$(edit_json 'src/api.ts' $'expect(a).toBe(1)\nexpect(b).toBe(2)' 'return null')"
expect_exit 0 "conftest.py is support code" "$H" \
  "$(edit_json 'tests/conftest.py' $'assert a\nassert b' 'pass')"
expect_exit 0 "unrelated line added" "$H" \
  "$(edit_json 'tests/test_api.py' $'assert a == 1\nassert b == 2' $'assert a == 1\nassert b == 2\nprint("hi")')"

# --- false positives: bare words inside identifiers ---
expect_exit 0 "fp: pendingWrites identifier" "$H" \
  "$(edit_json 'tests/test_db.py' 'assert a == 1' $'pendingWrites = 3\nassert a == 1')"
expect_exit 0 "fp: onlyDigits identifier" "$H" \
  "$(edit_json 'tests/test_db.py' 'assert a == 1' $'onlyDigits = True\nassert a == 1')"
expect_exit 0 "fp: 'only' in a comment" "$H" \
  "$(edit_json 'spec/u_spec.rb' 'expect(a).to eq 1' $'# only checks the id\nexpect(a).to eq 1')"
expect_exit 0 "fp: contest.py is not a test file" "$H" \
  "$(edit_json 'src/lib/contest.py' $'assert a\nassert b' 'pass')"

# --- new files are never weakenings ---
expect_exit 0 "Write to a brand new test file" "$H" \
  "$(jq -n '{tool_name:"Write",tool_input:{file_path:"/nonexistent/tests/test_new.py",content:"assert True"}}')"

summarize
