# Criterion: `shell`

## What it says

Shell diffs get checked for the classic bash failure modes: quoting, `set -e` semantics, destructive commands on unvalidated paths, and portability (macOS ships bash 3.2).

## How to spot

**Quoting / expansion**
- Unquoted variable in a path or argument position — breaks on spaces, empty values, globs. Especially `rm`, `mv`, `cp` targets.
- `rm -rf "$VAR/"` where `$VAR` can be empty → `rm -rf /`. Look for a guard (`:?` expansion or explicit test) before any destructive use.
- Word splitting relied on implicitly (`for f in $(ls ...)`).

**`set -e` semantics (the big one)**
- `set -e` does NOT fire for: commands in `if`/`while` conditions, left sides of `&&`/`||`, or failures inside `$(...)` assigned with `local`/`export` on the same line (`local x=$(fail)` succeeds).
- `cmd && other` as the LAST line of a function/loop body — returns 1 when `cmd` is false, which `set -e` treats as failure. Use `if`.
- Pipelines without `set -o pipefail` — only the last command's status counts.
- `grep -q` closing the pipe early under `pipefail` — upstream gets SIGPIPE and the pipeline "fails".

**Robustness**
- Unchecked `cd` before relative-path operations.
- `mktemp` without a `trap ... EXIT` cleanup; temp file predictable-name races.
- Reading a variable that may be unset without `set -u` or a `${VAR:-}` default.
- Exit codes swallowed: `func $(cmd)` — `$?` is `func`'s, not `cmd`'s.

**Portability**
- bash 4+ features on scripts that run on macOS default bash: associative arrays (`declare -A`), `${var,,}`, `mapfile`/`readarray`, `&>>`.
- GNU-only flags on BSD tools (`sed -i` without suffix arg is the famous one; `date -d`, `readlink -f`).

## When NOT to apply

- The script explicitly requires bash 4+ via shebang/env check — drop portability findings.
- One-off scratch scripts marked as such — keep only the destructive-command findings.

## Severity guidance

- **Blocker** — destructive command on an unguarded/empty-able variable; `set -e` assumption that silently doesn't hold on an error path that matters.
- **Concern** — missing `pipefail` where mid-pipe failure changes behavior; unchecked `cd`; missing trap cleanup.
- **Nit** — portability issues on scripts pinned to Linux; quoting on values that are provably safe.
