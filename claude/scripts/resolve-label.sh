#!/usr/bin/env bash
# resolve-label.sh — Deterministically resolve the issue label from subject text.
# Called by /issue before save_issue.
#
# Usage: resolve-label.sh "subject text"
# Output: JSON with label and confidence.
# Exit 0 always — defaults to Feature if no signal found.

set -euo pipefail

SUBJECT="${1:-}"
LOWER_SUBJECT=$(echo "$SUBJECT" | tr '[:upper:]' '[:lower:]')

# Check for explicit type prefixes
if [[ "$LOWER_SUBJECT" =~ ^bug[[:space:]]*: ]] || [[ "$LOWER_SUBJECT" =~ ^bug[[:space:]] ]]; then
  echo '{"label": "Bug", "confidence": "explicit", "signal": "bug: prefix"}'
  exit 0
fi

if [[ "$LOWER_SUBJECT" =~ ^improvement[[:space:]]*: ]] || [[ "$LOWER_SUBJECT" =~ ^improve[[:space:]] ]]; then
  echo '{"label": "Improvement", "confidence": "explicit", "signal": "improvement: prefix"}'
  exit 0
fi

if [[ "$LOWER_SUBJECT" =~ ^feature[[:space:]]*: ]] || [[ "$LOWER_SUBJECT" =~ ^feat[[:space:]]*: ]]; then
  echo '{"label": "Feature", "confidence": "explicit", "signal": "feature: prefix"}'
  exit 0
fi

# Check for bug-signal keywords
BUG_KEYWORDS="broken crash error fail 500 404 regression timeout nil null undefined"
for KW in $BUG_KEYWORDS; do
  if [[ "$LOWER_SUBJECT" =~ (^|[[:space:]])$KW($|[[:space:]]) ]]; then
    echo "{\"label\": \"Bug\", \"confidence\": \"inferred\", \"signal\": \"keyword: $KW\"}"
    exit 0
  fi
done

# Check for improvement-signal keywords
IMPROVE_KEYWORDS="refactor cleanup optimize performance speed slow reduce"
for KW in $IMPROVE_KEYWORDS; do
  if [[ "$LOWER_SUBJECT" =~ (^|[[:space:]])$KW($|[[:space:]]) ]]; then
    echo "{\"label\": \"Improvement\", \"confidence\": \"inferred\", \"signal\": \"keyword: $KW\"}"
    exit 0
  fi
done

# Default to Feature
echo '{"label": "Feature", "confidence": "default", "signal": "no signal found"}'
