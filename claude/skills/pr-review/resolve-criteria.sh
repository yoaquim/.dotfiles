#!/usr/bin/env bash
# resolve-criteria.sh — print the criteria files that apply to a checkout.
#
# Parses criteria/INDEX.md and evaluates each row's Detect rule against the
# target directory (the review checkout), using the SAME rule semantics as
# hooks/inject-practices.sh:
#   always        — applies to every repo
#   file          — applies if <target>/<file> exists
#   file:string   — applies if the file exists AND contains the string
#   glob (*.tf)   — applies if the glob matches; bare-filename globs are also
#                   searched up to 3 dirs deep (node_modules/.git excluded)
#   a,b,c         — applies if ANY rule in the list matches
#
# Usage: resolve-criteria.sh <checkout-dir>
# Output: one absolute criteria file path per line.

set -uo pipefail

TARGET="${1:-}"
if [[ -z "$TARGET" || ! -d "$TARGET" ]]; then
  echo "usage: resolve-criteria.sh <checkout-dir>" >&2
  exit 1
fi

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/criteria"
INDEX="$DIR/INDEX.md"
if [[ ! -f "$INDEX" ]]; then
  echo "error: $INDEX not found" >&2
  exit 1
fi

grep '^|' "$INDEX" | tail -n +3 | while IFS='|' read -r _ _name file _use detect _; do
  file=$(echo "$file" | xargs | tr -d '`')
  detect=$(echo "$detect" | xargs)
  if [[ -z "$file" || ! -f "$DIR/$file" ]]; then
    continue
  fi

  matched=false
  if [[ "$detect" == "always" ]]; then
    matched=true
  elif [[ -n "$detect" ]]; then
    IFS=',' read -ra RULES <<< "$detect"
    for rule in "${RULES[@]}"; do
      rule=$(echo "$rule" | xargs)
      if [[ "$rule" == *:* ]]; then
        CHECK_FILE="${rule%%:*}"
        CHECK_STRING="${rule#*:}"
        if [[ -f "$TARGET/$CHECK_FILE" ]] && grep -q "$CHECK_STRING" "$TARGET/$CHECK_FILE" 2>/dev/null; then
          matched=true
          break
        fi
      elif [[ "$rule" == *\** ]]; then
        if compgen -G "$TARGET/$rule" > /dev/null 2>&1; then
          matched=true
          break
        fi
        if [[ "$rule" != */* ]] \
          && [[ -n $(find "$TARGET" -maxdepth 3 -name "$rule" \
               -not -path '*/node_modules/*' -not -path '*/.git/*' \
               -print -quit 2>/dev/null) ]]; then
          matched=true
          break
        fi
      else
        if [[ -f "$TARGET/$rule" ]]; then
          matched=true
          break
        fi
      fi
    done
  fi

  if [[ "$matched" == true ]]; then
    echo "$DIR/$file"
  fi
done
