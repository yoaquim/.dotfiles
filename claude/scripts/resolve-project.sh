#!/usr/bin/env bash
# resolve-project.sh — Deterministically resolve the current repo to Linear project(s) and team.
# Called by /issue and /spec skills before any Linear API calls.
#
# Usage: resolve-project.sh [repo-projects.json-path]
# Output: JSON object with repo, team, projects, and whether confirmation is needed.
# Exit 0: mapping found (may still need confirmation if multiple projects)
# Exit 1: no mapping found — skill must ask the user

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MAPPING_FILE="${1:-$SCRIPT_DIR/repo-projects.json}"

if [[ ! -f "$MAPPING_FILE" ]]; then
  echo '{"error": "repo-projects.json not found", "repo": null, "team": null, "projects": []}' >&2
  exit 1
fi

# Extract repo name from git remote
REMOTE_URL=$(git remote get-url origin 2>/dev/null || echo "")
if [[ -z "$REMOTE_URL" ]]; then
  echo '{"error": "not a git repo or no origin remote", "repo": null, "team": null, "projects": []}' >&2
  exit 1
fi

# Normalize: strip .git suffix, extract last path component
REPO_NAME=$(basename "$REMOTE_URL" .git)

# Look up in mapping file using jq (or python as fallback)
if command -v jq &>/dev/null; then
  RESULT=$(jq -r --arg repo "$REPO_NAME" '
    .repos[$repo] // empty
    | {repo: $repo, team: .team, projects: .projects, needs_confirmation: ((.projects | length) > 1)}
  ' "$MAPPING_FILE" 2>/dev/null || echo "")
elif command -v python3 &>/dev/null; then
  RESULT=$(python3 -c "
import json, sys
with open('$MAPPING_FILE') as f:
    data = json.load(f)
repo = '$REPO_NAME'
entry = data.get('repos', {}).get(repo)
if entry:
    print(json.dumps({
        'repo': repo,
        'team': entry['team'],
        'projects': entry['projects'],
        'needs_confirmation': len(entry['projects']) > 1
    }))
else:
    sys.exit(1)
" 2>/dev/null || echo "")
else
  echo '{"error": "jq or python3 required", "repo": null, "team": null, "projects": []}' >&2
  exit 1
fi

if [[ -z "$RESULT" ]]; then
  echo "{\"error\": \"repo '$REPO_NAME' not in repo-projects.json\", \"repo\": \"$REPO_NAME\", \"team\": null, \"projects\": []}"
  exit 1
fi

echo "$RESULT"
