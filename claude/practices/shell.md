# Shell

Bash scripts that survive contact with reality. shellcheck-clean at `--severity=warning` is the bar (a PostToolUse hook runs it on every edit).

## Structure

- Shebang `#!/usr/bin/env bash`; `set -uo pipefail` minimum — add `-e` only when every command's failure should abort (and you've audited `grep`/arithmetic exits)
- Usage check + `exit 1` to stderr when required args are missing
- `local` for all function variables; UPPER_CASE only for globals/exports

## Robustness

- Quote every expansion: `"$var"`, `"$@"`, `"$(cmd)"` — unquoted is a bug until proven otherwise
- `[[ ]]` over `[ ]`; `$(...)` over backticks
- Don't parse `ls`; use globs with `nullglob` or `find -print0 | while IFS= read -r -d ''`
- Temp files via `mktemp` + `trap '...' EXIT` cleanup
- Check command existence with `command -v`, not `which`
- macOS vs GNU: BSD `sed`/`awk`/`date` differ — prefer constructs that work on both, or use `awk` over `sed -i`

## Output

- Machine-readable output (key:value, JSON via `jq -n`) when another script/skill consumes it
- Errors to stderr, data to stdout — callers parse stdout
- Hooks: fail open (`trap 'exit 0' ERR`) unless the hook's whole purpose is to block
