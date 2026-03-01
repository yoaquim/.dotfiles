#!/usr/bin/env bash
# status.sh — Check deck runner status
#
# Usage: status.sh <project-root> [name]
#
# With name:  structured header + full status file
# Without:    summary table of all runners

set -eo pipefail

ROOT="$1"
NAME="$2"
STATUS_DIR="$ROOT/.deck/status"
SPECS_DIR="$ROOT/.deck/specs"

if [[ -z "$ROOT" ]]; then
    echo "Usage: status.sh <project-root> [name]" >&2
    exit 1
fi

# --- Helpers ---

get_field() {
    local field="$1" file="$2"
    sed -n "s/^- \*\*${field}\*\*: //p" "$file" 2>/dev/null
}

get_meta() {
    local key="$1" file="$2"
    sed -n "s/^${key}: //p" "$file" 2>/dev/null
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
# Searches: local .deck, sibling repos, and child repos
find_status_file() {
    local name="$1"

    # 1. Local
    if [[ -f "$STATUS_DIR/$name.md" ]]; then
        echo "$STATUS_DIR/$name.md"
        return 0
    fi

    # 2. Sibling repos (parent/*/.deck/status/)
    local parent
    parent="$(dirname "$ROOT")"
    for f in "$parent"/*/.deck/status/"$name".md; do
        if [[ -f "$f" ]]; then
            echo "$f"
            return 0
        fi
    done

    # 3. Child repos (root/*/.deck/status/)
    for f in "$ROOT"/*/.deck/status/"$name".md; do
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

declare -A SPEC_STATUS

shopt -s nullglob

# Read spec metadata
if [[ -d "$SPECS_DIR" ]]; then
    for SFILE in "$SPECS_DIR"/*.md; do
        SNAME="$(basename "$SFILE" .md)"
        SPEC_STATUS["$SNAME"]="$(get_meta status "$SFILE")"
    done
fi

# Gather status info
declare -A RUNNER_ICON
declare -A RUNNER_LABEL
declare -A RUNNER_PROGRESS
declare -A RUNNER_WORKTREE

ACTIVE=0
COMPLETED=0
FAILED=0
HAS_OUTPUT=0

if [[ -d "$STATUS_DIR" ]]; then
    for FILE in "$STATUS_DIR"/*.md; do
        FNAME="$(basename "$FILE" .md)"
        STATUS="$(get_field status "$FILE")"
        PID="$(get_field pid "$FILE")"
        PID_START="$(get_field pid_start "$FILE")"
        PROGRESS="$(count_progress "$FILE")"
        WORKTREE="$(get_field worktree "$FILE")"

        if [[ "$STATUS" == "in_progress" ]]; then
            if check_alive "$PID" "$PID_START"; then
                RUNNER_ICON["$FNAME"]="●"
                RUNNER_LABEL["$FNAME"]="running"
            else
                RUNNER_ICON["$FNAME"]="⚠"
                RUNNER_LABEL["$FNAME"]="exited"
            fi
            ((ACTIVE++)) || true
        elif [[ "$STATUS" == "completed" ]]; then
            RUNNER_ICON["$FNAME"]="✓"
            RUNNER_LABEL["$FNAME"]="completed"
            ((COMPLETED++)) || true
        elif [[ "$STATUS" == "failed" ]]; then
            RUNNER_ICON["$FNAME"]="✗"
            RUNNER_LABEL["$FNAME"]="failed"
            ((FAILED++)) || true
        elif [[ "$STATUS" == "pr_open" ]]; then
            RUNNER_ICON["$FNAME"]="↑"
            RUNNER_LABEL["$FNAME"]="pr_open"
        elif [[ "$STATUS" == "closed" ]]; then
            RUNNER_ICON["$FNAME"]="✓"
            RUNNER_LABEL["$FNAME"]="closed"
        elif [[ "$STATUS" == "abandoned" ]]; then
            RUNNER_ICON["$FNAME"]="—"
            RUNNER_LABEL["$FNAME"]="abandoned"
        else
            RUNNER_ICON["$FNAME"]="?"
            RUNNER_LABEL["$FNAME"]="$STATUS"
        fi

        RUNNER_PROGRESS["$FNAME"]="$PROGRESS"
        RUNNER_WORKTREE["$FNAME"]="$WORKTREE"
        HAS_OUTPUT=1
    done
fi

# Include specs without status files (stubs, specced but not dispatched)
for SNAME in "${!SPEC_STATUS[@]}"; do
    if [[ -z "${RUNNER_ICON[$SNAME]}" ]]; then
        SSTATUS="${SPEC_STATUS[$SNAME]}"
        if [[ "$SSTATUS" == "stub" ]]; then
            RUNNER_ICON["$SNAME"]="○"
            RUNNER_LABEL["$SNAME"]="stub"
            RUNNER_PROGRESS["$SNAME"]="—"
            RUNNER_WORKTREE["$SNAME"]=""
            HAS_OUTPUT=1
        elif [[ "$SSTATUS" == "specced" ]]; then
            RUNNER_ICON["$SNAME"]="◻"
            RUNNER_LABEL["$SNAME"]="specced"
            RUNNER_PROGRESS["$SNAME"]="—"
            RUNNER_WORKTREE["$SNAME"]=""
            HAS_OUTPUT=1
        fi
    fi
done

shopt -u nullglob

if [[ $HAS_OUTPUT -eq 0 ]]; then
    echo "No specs or runners found."
    exit 0
fi

echo "DECK STATUS"
echo ""

for SNAME in "${!RUNNER_ICON[@]}"; do
    ICON="${RUNNER_ICON[$SNAME]}"
    LABEL="${RUNNER_LABEL[$SNAME]}"
    PROGRESS="${RUNNER_PROGRESS[$SNAME]}"
    WT="${RUNNER_WORKTREE[$SNAME]}"
    printf "  %-20s %s %-12s %-8s %s\n" "$SNAME" "$ICON" "$LABEL" "$PROGRESS" "$WT"
done

echo ""
echo "Runners: $ACTIVE active, $COMPLETED completed, $FAILED failed"
