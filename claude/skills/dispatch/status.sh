#!/usr/bin/env bash
# status.sh — Check dispatch runner status
#
# Usage: status.sh <project-root> [name]
#
# With name:  structured header + full status file
# Without:    summary table of all runners

set -eo pipefail

ROOT="$1"
NAME="$2"
STATUS_DIR="$ROOT/.dispatch/status"

if [[ -z "$ROOT" ]]; then
    echo "Usage: status.sh <project-root> [name]" >&2
    exit 1
fi

# --- Helpers ---

get_field() {
    local field="$1" file="$2"
    sed -n "s/^- \*\*${field}\*\*: //p" "$file" 2>/dev/null
}

check_alive() {
    local pid="$1" expected_start="$2"
    [[ -z "$pid" || "$pid" == "pending" ]] && return 1
    ps -p "$pid" >/dev/null 2>&1 || return 1
    local actual_start
    actual_start="$(ps -p "$pid" -o lstart= 2>/dev/null | xargs)"
    [[ "$actual_start" == "$expected_start" ]]
}

count_progress() {
    local file="$1"
    local done total
    done=$(grep -c '^\- \[x\]' "$file" 2>/dev/null) || done=0
    total=$(grep -c '^\- \[' "$file" 2>/dev/null) || total=0
    if [[ $total -eq 0 ]]; then
        echo "—"
    else
        echo "$done/$total"
    fi
}

# --- Find status file for a named runner ---
# Searches: local .dispatch, sibling repos, and child repos
find_status_file() {
    local name="$1"

    # 1. Local
    if [[ -f "$STATUS_DIR/$name.md" ]]; then
        echo "$STATUS_DIR/$name.md"
        return 0
    fi

    # 2. Sibling repos (parent/*/.dispatch/status/)
    local parent
    parent="$(dirname "$ROOT")"
    for f in "$parent"/*/.dispatch/status/"$name".md; do
        if [[ -f "$f" ]]; then
            echo "$f"
            return 0
        fi
    done

    # 3. Child repos (root/*/.dispatch/status/) — for when root is a parent dir, not a git repo
    for f in "$ROOT"/*/.dispatch/status/"$name".md; do
        if [[ -f "$f" ]]; then
            echo "$f"
            return 0
        fi
    done

    return 1
}

# --- Single runner ---
if [[ -n "$NAME" ]]; then
    FILE="$(find_status_file "$NAME")" || true
    if [[ -z "$FILE" || ! -f "$FILE" ]]; then
        echo "No status file for '$NAME'."
        exit 1
    fi

    STATUS="$(get_field status "$FILE")"
    PID="$(get_field pid "$FILE")"
    PID_START="$(get_field pid_start "$FILE")"
    WORKTREE="$(get_field worktree "$FILE")"

    if [[ "$STATUS" == "in_progress" ]]; then
        if check_alive "$PID" "$PID_START"; then
            echo "state:alive"
        else
            echo "state:dead"
        fi
    else
        echo "state:$STATUS"
    fi

    echo "worktree:$WORKTREE"
    echo "---"
    cat "$FILE"
    exit 0
fi

# --- All runners ---
if [[ ! -d "$STATUS_DIR" ]]; then
    echo "No dispatched runners found."
    exit 0
fi

ACTIVE=0
COMPLETED=0
FAILED=0

shopt -s nullglob
FILES=("$STATUS_DIR"/*.md)
shopt -u nullglob

if [[ ${#FILES[@]} -eq 0 ]]; then
    echo "No dispatched runners found."
    exit 0
fi

echo "DISPATCH STATUS"
echo ""

for FILE in "${FILES[@]}"; do
    FNAME="$(basename "$FILE" .md)"
    TITLE="$(get_field title "$FILE")"
    STATUS="$(get_field status "$FILE")"
    PID="$(get_field pid "$FILE")"
    PID_START="$(get_field pid_start "$FILE")"
    PROGRESS="$(count_progress "$FILE")"

    if [[ "$STATUS" == "in_progress" ]]; then
        if check_alive "$PID" "$PID_START"; then
            ICON="●"
            LABEL="running"
        else
            ICON="⚠"
            LABEL="exited"
        fi
        ((ACTIVE++)) || true
    elif [[ "$STATUS" == "completed" ]]; then
        ICON="✓"
        LABEL="completed"
        ((COMPLETED++)) || true
    elif [[ "$STATUS" == "failed" ]]; then
        ICON="✗"
        LABEL="failed"
        ((FAILED++)) || true
    else
        ICON="?"
        LABEL="$STATUS"
    fi

    printf "  %-16s %s %-12s %-8s %s\n" "$FNAME" "$ICON" "$LABEL" "$PROGRESS" "$TITLE"
done

echo ""
echo "Runners: $ACTIVE active, $COMPLETED completed, $FAILED failed"
