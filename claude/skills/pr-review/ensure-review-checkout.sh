#!/usr/bin/env bash
# ensure-review-checkout.sh — idempotent local checkout of a PR's HEAD, for review.
#
# The reviewer must judge real files, not just diff hunks — the guard three
# lines above a hunk and the caller two files over are invisible in
# `gh pr diff`, and they are exactly where false positives and misses come
# from. This script gives every review pass a synced checkout:
#
#   1. Find a local clone of the PR's repo (resolve-repo.sh by name, origin
#      verified against the PR's owner/repo so a basename collision can't pick
#      the wrong repo) — else keep a blobless clone under ~/.claude/review-clones/.
#   2. Fetch the PR head via refs/pull/<n>/head (works for fork PRs too).
#   3. Park it DETACHED in a dedicated worktree:
#      <repo>/.claude/worktrees/review-pr-<n>. Detached on purpose — the
#      dispatch runner has the PR *branch* checked out in its own worktree and
#      git forbids one branch in two worktrees; a detached SHA never collides.
#
# Idempotent: every call re-fetches and re-syncs the worktree to the CURRENT
# head, so the watch loop just re-runs it at the start of each pass.
#
# Usage: ensure-review-checkout.sh <pr-ref> [gh-args...]   # anything `gh pr view` accepts
# Output (key:value on stdout):
#   checkout:<abs path>
#   head_sha:<sha>
# Exit 1 with a reason on stderr if no checkout could be produced — the caller
# degrades to diff-only review and says so.

set -uo pipefail

if [[ $# -lt 1 ]]; then
  echo "usage: ensure-review-checkout.sh <pr-ref> [gh-args...]" >&2
  exit 1
fi

PR_JSON=$(gh pr view "$@" --json number,url,headRefOid 2>/dev/null)
if [[ -z "$PR_JSON" ]]; then
  echo "error: could not resolve PR from: $*" >&2
  exit 1
fi
PR=$(jq -r '.number // empty' <<<"$PR_JSON")
PR_URL=$(jq -r '.url // empty' <<<"$PR_JSON")
HEAD_SHA=$(jq -r '.headRefOid // empty' <<<"$PR_JSON")
if [[ -z "$PR" || -z "$PR_URL" || -z "$HEAD_SHA" ]]; then
  echo "error: PR lookup returned no number/url/head for: $*" >&2
  exit 1
fi

# owner/repo from the canonical url, host-agnostic (same parse as spawn-reviewer.sh).
REPO_PART=${PR_URL%/pull/*}
NO_SCHEME=${REPO_PART#*://}
OWNER_REPO=${NO_SCHEME#*/}
REPO_NAME=${OWNER_REPO##*/}

# Prefer the repo the caller is already standing in (foreground --inline runs,
# and repos living outside resolve-repo.sh's search roots).
ROOT=""
if CWD_ROOT=$(git rev-parse --show-toplevel 2>/dev/null); then
  ORIGIN=$(git -C "$CWD_ROOT" remote get-url origin 2>/dev/null || echo "")
  case "$ORIGIN" in
    *"$OWNER_REPO" | *"$OWNER_REPO.git") ROOT="$CWD_ROOT" ;;
  esac
fi

if [[ -z "$ROOT" ]]; then
  ROOT=$("$HOME/.claude/skills/dispatch/resolve-repo.sh" "$REPO_NAME" 2>/dev/null) || ROOT=""
  if [[ -n "$ROOT" ]]; then
    ORIGIN=$(git -C "$ROOT" remote get-url origin 2>/dev/null || echo "")
    case "$ORIGIN" in
      *"$OWNER_REPO" | *"$OWNER_REPO.git") ;;
      *) ROOT="" ;;
    esac
  fi
fi

if [[ -z "$ROOT" ]]; then
  CLONE_DIR="$HOME/.claude/review-clones/${OWNER_REPO//\//__}"
  if ! git -C "$CLONE_DIR" rev-parse --git-dir >/dev/null 2>&1; then
    mkdir -p "$(dirname "$CLONE_DIR")"
    if ! gh repo clone "$OWNER_REPO" "$CLONE_DIR" -- --filter=blob:none --quiet >&2; then
      echo "error: no local clone of $OWNER_REPO and clone failed" >&2
      exit 1
    fi
  fi
  ROOT="$CLONE_DIR"
fi

if ! git -C "$ROOT" fetch --quiet origin "pull/$PR/head" >&2; then
  echo "error: fetch of pull/$PR/head failed in $ROOT" >&2
  exit 1
fi

WT="$ROOT/.claude/worktrees/review-pr-$PR"
if git -C "$WT" rev-parse --git-dir >/dev/null 2>&1; then
  if ! git -C "$WT" checkout --quiet --detach "$HEAD_SHA" >&2; then
    echo "error: checkout of $HEAD_SHA failed in $WT" >&2
    exit 1
  fi
else
  git -C "$ROOT" worktree prune 2>/dev/null
  mkdir -p "$(dirname "$WT")"
  if ! git -C "$ROOT" worktree add --quiet --detach "$WT" "$HEAD_SHA" >&2; then
    echo "error: worktree add failed at $WT" >&2
    exit 1
  fi
fi

echo "checkout:$WT"
echo "head_sha:$HEAD_SHA"
