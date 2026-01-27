#!/usr/bin/env bash

# Claude Code Workflow Setup Script
# Symlinks skills and scaffolds files to ~/.claude/

set -e -o pipefail  # Exit on error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Helper functions
info() {
    echo -e "${BLUE}ℹ${NC} $1"
}

success() {
    echo -e "${GREEN}✅${NC} $1"
}

warning() {
    echo -e "${YELLOW}⚠${NC} $1"
}

error() {
    echo -e "${RED}❌${NC} $1"
}

# Banner
echo ""
echo "╔════════════════════════════════════════╗"
echo "║   Claude Code Workflow Setup           ║"
echo "╚════════════════════════════════════════╝"
echo ""

# Get script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
info "Script location: $SCRIPT_DIR"

# Verify we're in the right place
if [[ ! -d "$SCRIPT_DIR/skills" ]] || [[ ! -d "$SCRIPT_DIR/scaffolds" ]]; then
    error "Expected structure not found!"
    error "Make sure you're running this from ~/.dotfiles/claude/"
    error "Required directories: skills/, scaffolds/"
    exit 1
fi

# Check if ~/.claude exists
if [[ ! -d "$HOME/.claude" ]]; then
    error "~/.claude directory doesn't exist"
    error "This is the Claude Code application directory"
    error "Please run Claude Code at least once to create it"
    exit 1
fi

info "Found ~/.claude directory"

# ============================================================
# Helper function to symlink a directory
# ============================================================
symlink_directory() {
    local SOURCE="$1"
    local TARGET="$2"
    local NAME="$3"

    if [[ -L "$TARGET" ]]; then
        # It's a symlink
        CURRENT_TARGET="$(readlink "$TARGET")"
        if [[ "$CURRENT_TARGET" == "$SOURCE" ]]; then
            success "$NAME → $SOURCE (already linked)"
        else
            warning "$NAME is symlinked to: $CURRENT_TARGET"
            read -p "Replace with our version? (y/n) " -n 1 -r
            echo
            if [[ $REPLY =~ ^[Yy]$ ]]; then
                rm "$TARGET"
                ln -s "$SOURCE" "$TARGET"
                success "$NAME → $SOURCE (replaced)"
            else
                warning "Keeping existing $NAME symlink"
            fi
        fi
    elif [[ -d "$TARGET" ]]; then
        # It's a directory
        warning "$NAME exists as a directory"
        echo "Contents:"
        ls -la "$TARGET" | head -10
        echo ""
        read -p "Backup and replace with symlink? (y/n) " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            BACKUP_DIR="$TARGET.backup.$(date +%Y%m%d_%H%M%S)"
            mv "$TARGET" "$BACKUP_DIR"
            ln -s "$SOURCE" "$TARGET"
            success "Backed up to: $BACKUP_DIR"
            success "$NAME → $SOURCE"
        else
            error "Setup incomplete - $NAME not linked"
            return 1
        fi
    elif [[ -f "$TARGET" ]]; then
        error "$NAME exists as a file (unexpected)"
        return 1
    else
        # Doesn't exist - create symlink
        ln -s "$SOURCE" "$TARGET"
        success "$NAME → $SOURCE"
    fi
}

# ============================================================
# Step 1: Symlink skills directory
# ============================================================
echo ""
info "Symlinking skills directory..."

symlink_directory "$SCRIPT_DIR/skills" "$HOME/.claude/skills" "~/.claude/skills"

# ============================================================
# Step 2: Symlink practices directory
# ============================================================
echo ""
info "Symlinking practices..."

symlink_directory "$SCRIPT_DIR/practices" "$HOME/.claude/practices" "~/.claude/practices"

# ============================================================
# Step 3: Symlink scaffolds directory (SOPs and templates)
# ============================================================
echo ""
info "Symlinking scaffolds directory..."

symlink_directory "$SCRIPT_DIR/scaffolds" "$HOME/.claude/scaffolds" "~/.claude/scaffolds"

# ============================================================
# Step 4: Symlink adapters directory
# ============================================================
echo ""
info "Symlinking adapters directory..."

symlink_directory "$SCRIPT_DIR/adapters" "$HOME/.claude/adapters" "~/.claude/adapters"

# ============================================================
# Step 5: Verify setup
# ============================================================
echo ""
info "Verifying setup..."

# Check skills
if [[ -L "$HOME/.claude/skills" ]]; then
    SKILLS_COUNT=$(find "$SCRIPT_DIR/skills" -name "SKILL.md" -type f 2>/dev/null | wc -l | tr -d ' ')
    echo "  ✓ Skills directory symlinked ($SKILLS_COUNT skills)"
else
    error "Skills directory NOT symlinked"
fi

# Check practices
if [[ -L "$HOME/.claude/practices" ]]; then
    PRACTICES_COUNT=$(find "$SCRIPT_DIR/practices" -name "*.md" -type f 2>/dev/null | wc -l | tr -d ' ')
    echo "  ✓ Practices symlinked ($PRACTICES_COUNT practices)"
else
    warning "Practices NOT symlinked"
fi

# Check scaffolds
if [[ -L "$HOME/.claude/scaffolds" ]]; then
    echo "  ✓ Workflow directory symlinked"
else
    error "Workflow directory NOT symlinked"
fi

# Check adapters
if [[ -L "$HOME/.claude/adapters" ]]; then
    ADAPTER_COUNT=$(find "$SCRIPT_DIR/adapters" -name "*.md" -type f 2>/dev/null | wc -l | tr -d ' ')
    echo "  ✓ Adapters directory symlinked ($ADAPTER_COUNT adapters)"
else
    warning "Adapters directory NOT symlinked"
fi

# ============================================================
# Step 6: Display what's available
# ============================================================
echo ""
echo "╔════════════════════════════════════════╗"
echo "║          Setup Complete! 🎉            ║"
echo "╚════════════════════════════════════════╝"
echo ""

info "Structure created:"
echo ""
echo "~/.claude/"
echo "├── skills/               → Slash command skills"
echo "│   ├── setup/SKILL.md"
echo "│   ├── feature/SKILL.md"
echo "│   ├── plan/SKILL.md"
echo "│   ├── bug/SKILL.md"
echo "│   ├── roadmap/SKILL.md"
echo "│   └── test-plan/SKILL.md"
echo "├── adapters/             → Task management adapters"
echo "│   ├── vk.md"
echo "│   ├── local.md"
echo "│   └── linear.md"
echo "├── practices/            → Coding practices (TDD, patterns, etc.)"
echo "├── scaffolds/"
echo "│   ├── sops/             → Universal SOPs"
echo "│   ├── templates/        → Project templates"
echo "│   └── README.md"
echo "└── ... (Claude Code app data)"
echo ""

info "Available skills:"
echo ""
echo "  /setup               - Initialize .agent/ for new/existing project"
echo "  /feature             - Define WHAT to build (feature requirements)"
echo "  /plan vk 001         - Plan feature in Vibe Kanban"
echo "  /plan local 001      - Plan feature with local task files"
echo "  /bug                  - Document bugs"
echo "  /roadmap             - Create/update project roadmap"
echo "  /test-plan 001       - Generate test plan with Playwright"
echo ""

info "Typical workflow:"
echo ""
echo "  /setup → /feature → /plan local 001 → implement → test → done"
echo ""

success "Setup complete! Happy coding!"
echo ""
