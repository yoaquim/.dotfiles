#!/usr/bin/env bash

# Claude Code Setup Script
# Symlinks skills, agents, practices, and hooks to ~/.claude/

set -e -o pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

info()    { echo -e "${BLUE}i${NC} $1"; }
success() { echo -e "${GREEN}+${NC} $1"; }
warning() { echo -e "${YELLOW}!${NC} $1"; }
error()   { echo -e "${RED}x${NC} $1"; }

echo ""
echo "Claude Code Setup"
echo "=================="
echo ""

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
info "Source: $SCRIPT_DIR"

# Verify source structure
if [[ ! -d "$SCRIPT_DIR/skills" ]]; then
    error "skills/ not found in $SCRIPT_DIR"
    exit 1
fi

# Verify ~/.claude exists
if [[ ! -d "$HOME/.claude" ]]; then
    error "~/.claude doesn't exist. Run Claude Code once first."
    exit 1
fi

# Symlink helper
symlink_directory() {
    local SOURCE="$1"
    local TARGET="$2"
    local NAME="$3"

    if [[ ! -d "$SOURCE" ]]; then
        warning "$NAME source not found: $SOURCE (skipping)"
        return 0
    fi

    if [[ -L "$TARGET" ]]; then
        CURRENT_TARGET="$(readlink "$TARGET")"
        if [[ "$CURRENT_TARGET" == "$SOURCE" ]]; then
            success "$NAME (already linked)"
            return 0
        fi
        warning "$NAME linked to $CURRENT_TARGET"
        read -p "  Replace? (y/n) " -n 1 -r; echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            rm "$TARGET"
            ln -s "$SOURCE" "$TARGET"
            success "$NAME (replaced)"
        fi
    elif [[ -d "$TARGET" ]]; then
        warning "$NAME exists as directory"
        read -p "  Backup and replace? (y/n) " -n 1 -r; echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            mv "$TARGET" "$TARGET.backup.$(date +%Y%m%d_%H%M%S)"
            ln -s "$SOURCE" "$TARGET"
            success "$NAME (backed up + linked)"
        fi
    else
        ln -s "$SOURCE" "$TARGET"
        success "$NAME"
    fi
}

# Symlink directories
echo ""
symlink_directory "$SCRIPT_DIR/skills"    "$HOME/.claude/skills"    "skills/"
symlink_directory "$SCRIPT_DIR/agents"    "$HOME/.claude/agents"    "agents/"
symlink_directory "$SCRIPT_DIR/practices" "$HOME/.claude/practices" "practices/"
symlink_directory "$SCRIPT_DIR/hooks"     "$HOME/.claude/hooks"     "hooks/"

# Remove stale symlinks from deprecated directories
for stale in adapters guides scaffolds; do
    if [[ -L "$HOME/.claude/$stale" ]]; then
        warning "Removing stale $stale/ symlink (deprecated)"
        rm "$HOME/.claude/$stale"
    fi
done

# Verify
echo ""
info "Verifying..."
for dir in skills agents practices hooks; do
    if [[ -L "$HOME/.claude/$dir" ]]; then
        echo "  + $dir/"
    else
        echo "  - $dir/ (not linked)"
    fi
done

echo ""
echo "Done."
echo ""
echo "Skills:  /setup, /deck, /dispatch"
echo "Agents:  deck-runner, linear-runner"
echo ""
echo "Workflow (deck — bottom-up):"
echo "  /setup                           — init project (CLAUDE.md, git, hooks, deps)"
echo "  /deck epic <name>                — plan a milestone"
echo "  /deck plan <name>                — plan a feature"
echo "  /deck dispatch <name>            — spawn runner"
echo "  /deck status                     — check progress"
echo "  /deck accept <name>              — E2E test acceptance criteria (optional)"
echo "  /deck close <name>               — merge, teardown, done"
echo ""
echo "Workflow (dispatch — top-down from Linear):"
echo "  /dispatch ENG-142                — fetch ticket, discover, spawn runner"
echo "  /dispatch status                 — check all runners"
echo "  /dispatch attach eng-142         — interactive session in worktree"
echo ""
