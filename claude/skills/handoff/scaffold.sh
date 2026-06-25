#!/usr/bin/env bash
# scaffold.sh — prep a /handoff: ensure the handoffs dir, exclude it locally, print
# git context to fill the template, and point at the prior handoff for chaining.
#
# Usage: scaffold.sh <slug>
# Output: key:value lines (dir, file, prev, branch) + ## blocks (commits, status, diffstat).
#
# Handoffs live in <repo>/.claude/handoffs and are ignored via .git/info/exclude
# (local, never committed) — durable on disk, zero repo footprint. The exclude rule
# itself is never tracked either.
#
# Exit 1 on any error (not a git repo, etc.) — the skill handles the message.

set -u

SLUG=$(printf '%s' "${1:-handoff}" | tr '[:upper:] ' '[:lower:]-' | tr -cd 'a-z0-9-' | tr -s '-')
[[ -n "$SLUG" ]] || SLUG=handoff

ROOT=$(git rev-parse --show-toplevel 2>/dev/null) || { echo "error: not a git repo" >&2; exit 1; }
DIR="$ROOT/.claude/handoffs"
mkdir -p "$DIR"

# Ignore locally — never tracked, never committed.
EXCLUDE="$ROOT/.git/info/exclude"
grep -qxF '.claude/handoffs/' "$EXCLUDE" 2>/dev/null || echo '.claude/handoffs/' >> "$EXCLUDE"

PREV=$(find "$DIR" -maxdepth 1 -name '*.md' 2>/dev/null | sort | tail -1)   # newest: timestamp prefix sorts chronologically
FILE="$DIR/$(date +%Y-%m-%d-%H%M%S)-$SLUG.md"

echo "dir:$DIR"
echo "file:$FILE"
echo "prev:${PREV:-none}"
echo "branch:$(git branch --show-current 2>/dev/null || true)"
echo "## commits"
git log --oneline -10 2>/dev/null || true
echo "## status"
git status --short 2>/dev/null || true
echo "## diffstat"
git diff --stat 2>/dev/null || true
