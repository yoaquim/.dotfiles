#!/usr/bin/env bash
# validate-title.sh — Validate a Linear issue title against conventions.
# Called by /issue after generating the title, before save_issue.
#
# Usage: validate-title.sh "Title To Validate"
# Output: JSON with valid (bool) and errors (array of strings).
# Exit 0: valid. Exit 1: invalid.

set -euo pipefail

TITLE="${1:-}"

if [[ -z "$TITLE" ]]; then
  echo '{"valid": false, "errors": ["Title is empty"]}'
  exit 1
fi

ERRORS=()

# Word count: 2-7 words (relaxed from 3-5 for flexibility)
WORD_COUNT=$(echo "$TITLE" | wc -w | tr -d ' ')
if (( WORD_COUNT < 2 )); then
  ERRORS+=("Too short: $WORD_COUNT words (minimum 2)")
fi
if (( WORD_COUNT > 7 )); then
  ERRORS+=("Too long: $WORD_COUNT words (maximum 7)")
fi

# No verb prefixes
FIRST_WORD=$(echo "$TITLE" | awk '{print $1}' | sed 's/:$//')
VERB_PREFIXES="Add Fix Update Implement Create Remove Delete Refactor Migrate Move Change"
for VERB in $VERB_PREFIXES; do
  if [[ "$FIRST_WORD" == "$VERB" ]]; then
    ERRORS+=("Starts with verb prefix '$VERB' — use a noun phrase instead")
    break
  fi
done

# Title Case check: each major word should be capitalized
# Skip minor words (a, an, the, and, or, but, in, on, of, for, to, with, at, by)
MINOR_WORDS="a an the and or but in on of for to with at by"
WORD_INDEX=0
for WORD in $TITLE; do
  WORD_INDEX=$((WORD_INDEX + 1))
  CLEAN_WORD=$(echo "$WORD" | sed 's/[^a-zA-Z]//g')
  [[ -z "$CLEAN_WORD" ]] && continue

  # First word always capitalized
  if (( WORD_INDEX == 1 )); then
    FIRST_CHAR="${CLEAN_WORD:0:1}"
    if [[ "$FIRST_CHAR" != "$(echo "$FIRST_CHAR" | tr '[:lower:]' '[:upper:]')" ]]; then
      ERRORS+=("First word '$WORD' should be capitalized")
    fi
    continue
  fi

  # Skip minor words
  IS_MINOR=false
  LOWER_WORD=$(echo "$CLEAN_WORD" | tr '[:upper:]' '[:lower:]')
  for MW in $MINOR_WORDS; do
    if [[ "$LOWER_WORD" == "$MW" ]]; then
      IS_MINOR=true
      break
    fi
  done
  $IS_MINOR && continue

  # Major words should be capitalized
  FIRST_CHAR="${CLEAN_WORD:0:1}"
  if [[ "$FIRST_CHAR" != "$(echo "$FIRST_CHAR" | tr '[:lower:]' '[:upper:]')" ]]; then
    ERRORS+=("'$WORD' should be capitalized (Title Case)")
  fi
done

# Build JSON output
if (( ${#ERRORS[@]} == 0 )); then
  echo '{"valid": true, "errors": []}'
  exit 0
else
  # Build errors array
  JSON_ERRORS="["
  FIRST=true
  for ERR in "${ERRORS[@]}"; do
    $FIRST || JSON_ERRORS+=","
    ESCAPED=$(echo "$ERR" | sed 's/\\/\\\\/g; s/"/\\"/g')
    JSON_ERRORS+="\"$ESCAPED\""
    FIRST=false
  done
  JSON_ERRORS+="]"
  echo "{\"valid\": false, \"errors\": $JSON_ERRORS}"
  exit 1
fi
