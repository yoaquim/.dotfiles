#!/usr/bin/env bash
# resolve-repo.sh — Resolve a /dispatch --repo argument to an absolute git repo root.
#
# Accepts either:
#   - a path (absolute, relative, or ~-expanded) that lives inside a git repo
#   - a bare repo name, searched under $DISPATCH_REPO_ROOTS (default ~/Projects)
#
# Usage: resolve-repo.sh <name-or-path>
# Output: absolute repo root on stdout. Exit 0 on unique resolution, 1 otherwise.

set -uo pipefail

ARG="${1:-}"
if [[ -z "$ARG" ]]; then
  echo "usage: resolve-repo.sh <name-or-path>" >&2
  exit 1
fi

# Expand a leading ~ to $HOME.
ARG="${ARG/#\~/$HOME}"

git_top() { git -C "$1" rev-parse --show-toplevel 2>/dev/null; }

# 1. Existing path → must resolve to a git repo.
if [[ -e "$ARG" ]]; then
  if ROOT=$(git_top "$ARG"); then
    printf '%s\n' "$ROOT"; exit 0
  fi
  echo "error: '$ARG' is not inside a git repository" >&2
  exit 1
fi

# A path-looking arg that doesn't exist is an error — don't fall through to a
# name search and silently resolve something unexpected.
if [[ "$ARG" == */* ]]; then
  echo "error: path does not exist: $ARG" >&2
  exit 1
fi

# 2. Bare name → search the configured roots for a git repo with that basename.
ROOTS="${DISPATCH_REPO_ROOTS:-$HOME/Projects}"
IFS=':' read -ra ROOT_DIRS <<< "$ROOTS"

FOUND=""
for base in "${ROOT_DIRS[@]}"; do
  [[ -d "$base" ]] || continue
  # -type d -name .git finds main checkouts; worktree .git files are skipped.
  while IFS= read -r gitdir; do
    parent=$(dirname "$gitdir")
    if top=$(git_top "$parent") && [[ "$(basename "$top")" == "$ARG" ]]; then
      FOUND+="$top"$'\n'
    fi
  done < <(find "$base" -maxdepth 4 -type d -name .git 2>/dev/null)
done

UNIQUE=$(printf '%s' "$FOUND" | awk 'NF' | sort -u)
COUNT=$(printf '%s' "$UNIQUE" | awk 'NF' | wc -l | tr -d ' ')

if [[ "$COUNT" -eq 1 ]]; then
  printf '%s\n' "$UNIQUE"; exit 0
elif [[ "$COUNT" -eq 0 ]]; then
  echo "error: no git repo named '$ARG' under $ROOTS. Pass an explicit path instead." >&2
  exit 1
else
  echo "error: multiple repos named '$ARG' found; pass an explicit path:" >&2
  printf '%s\n' "$UNIQUE" | sed 's/^/  /' >&2
  exit 1
fi
