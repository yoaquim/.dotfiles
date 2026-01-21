#!/usr/bin/env bash

# Claude Code Workflow Setup Script
# Symlinks commands and workflow files to ~/.claude/

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
if [[ ! -d "$SCRIPT_DIR/commands" ]] || [[ ! -d "$SCRIPT_DIR/workflow" ]]; then
    error "Expected structure not found!"
    error "Make sure you're running this from ~/.dotfiles/claude/"
    error "Required directories: commands/, workflow/"
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
# Helper function to symlink a file
# ============================================================
symlink_file() {
    local SOURCE="$1"
    local TARGET="$2"
    local NAME="$3"

    if [[ -L "$TARGET" ]]; then
        CURRENT_TARGET="$(readlink "$TARGET")"
        if [[ "$CURRENT_TARGET" == "$SOURCE" ]]; then
            success "$NAME (already linked)"
        else
            rm "$TARGET"
            ln -s "$SOURCE" "$TARGET"
            success "$NAME (replaced)"
        fi
    elif [[ -f "$TARGET" ]]; then
        warning "$NAME exists as a file, backing up..."
        mv "$TARGET" "$TARGET.backup.$(date +%Y%m%d_%H%M%S)"
        ln -s "$SOURCE" "$TARGET"
        success "$NAME (backed up and linked)"
    else
        ln -s "$SOURCE" "$TARGET"
        success "$NAME"
    fi
}

# ============================================================
# Step 1: Ensure ~/.claude/commands exists
# ============================================================
if [[ ! -d "$HOME/.claude/commands" ]]; then
    info "Creating ~/.claude/commands/"
    mkdir -p "$HOME/.claude/commands"
fi

# ============================================================
# Step 2: Symlink individual command files at root level
# ============================================================
echo ""
info "Symlinking root-level commands..."

for cmd_file in "$SCRIPT_DIR/commands"/*.md; do
    if [[ -f "$cmd_file" ]]; then
        filename=$(basename "$cmd_file")
        symlink_file "$cmd_file" "$HOME/.claude/commands/$filename" "$filename"
    fi
done

# ============================================================
# Step 3: Symlink workflow commands subdirectory
# ============================================================
echo ""
info "Symlinking workflow commands..."

symlink_directory "$SCRIPT_DIR/commands/workflow" "$HOME/.claude/commands/workflow" "~/.claude/commands/workflow"

# ============================================================
# Step 4: Symlink vk-tags directory
# ============================================================
echo ""
info "Symlinking vk-tags..."

symlink_directory "$SCRIPT_DIR/vk-tags" "$HOME/.claude/vk-tags" "~/.claude/vk-tags"

# ============================================================
# Step 5: Symlink workflow directory (SOPs and templates)
# ============================================================
echo ""
info "Symlinking workflow directory..."

symlink_directory "$SCRIPT_DIR/workflow" "$HOME/.claude/workflow" "~/.claude/workflow"

# ============================================================
# Step 5.5: Symlink skills directory
# ============================================================
echo ""
info "Symlinking skills directory..."

symlink_directory "$SCRIPT_DIR/skills" "$HOME/.claude/skills" "~/.claude/skills"

# ============================================================
# Step 6: Verify setup
# ============================================================
echo ""
info "Verifying setup..."

# Check workflow commands
if [[ -L "$HOME/.claude/commands/workflow" ]]; then
    WORKFLOW_COUNT=$(find "$SCRIPT_DIR/commands/workflow" -name "*.md" -type f 2>/dev/null | wc -l | tr -d ' ')
    echo "  ✓ Workflow commands symlinked ($WORKFLOW_COUNT commands)"
else
    error "Workflow commands NOT symlinked"
fi

# Check root commands
ROOT_CMD_COUNT=$(find "$HOME/.claude/commands" -maxdepth 1 -name "*.md" -type l 2>/dev/null | wc -l | tr -d ' ')
echo "  ✓ Root commands symlinked ($ROOT_CMD_COUNT commands)"

# Check vk-tags
if [[ -L "$HOME/.claude/vk-tags" ]]; then
    VK_TAG_COUNT=$(find "$SCRIPT_DIR/vk-tags" -name "*.md" -type f 2>/dev/null | wc -l | tr -d ' ')
    echo "  ✓ VK tags symlinked ($VK_TAG_COUNT tags)"
else
    warning "VK tags NOT symlinked"
fi

# Check workflow
if [[ -L "$HOME/.claude/workflow" ]]; then
    echo "  ✓ Workflow directory symlinked"
else
    error "Workflow directory NOT symlinked"
fi

# Check skills
if [[ -L "$HOME/.claude/skills" ]]; then
    SKILLS_COUNT=$(find "$SCRIPT_DIR/skills" -name "SKILL.md" -type f 2>/dev/null | wc -l | tr -d ' ')
    echo "  ✓ Skills directory symlinked ($SKILLS_COUNT skills)"
else
    warning "Skills directory NOT symlinked"
fi

# ============================================================
# Step 7: Display what's available
# ============================================================
echo ""
echo "╔════════════════════════════════════════╗"
echo "║          Setup Complete! 🎉            ║"
echo "╚════════════════════════════════════════╝"
echo ""

info "Structure created:"
echo ""
echo "~/.claude/"
echo "├── commands/             → Legacy slash commands (deprecated)"
echo "│   ├── feature.md"
echo "│   ├── setup.md"
echo "│   └── workflow/..."
echo "├── skills/               → NEW: Skills (recommended)"
echo "│   ├── feature/SKILL.md"
echo "│   ├── setup/SKILL.md"
echo "│   ├── plan/SKILL.md"
echo "│   ├── bug/SKILL.md"
echo "│   ├── roadmap/SKILL.md"
echo "│   ├── test-plan/SKILL.md"
echo "│   └── workflow-*/SKILL.md"
echo "├── vk-tags/              → Reusable task tags"
echo "├── workflow/"
echo "│   ├── sops/             → Universal SOPs"
echo "│   ├── templates/        → Project templates"
echo "│   └── README.md"
echo "└── ... (Claude Code app data)"
echo ""

info "Available slash commands:"
echo ""
echo "  /setup               - Initialize .agent/ for new/existing project"
echo "  /feature             - Define WHAT to build (feature requirements)"
echo "  /vk-plan             - Create VK Kanban planning tickets"
echo ""
echo "  /workflow:plan-task      - Plan HOW to build it"
echo "  /workflow:implement-task - Implement a task"
echo "  /workflow:test-task      - Test implementation"
echo "  /workflow:complete-task  - Finalize and document"
echo "  /workflow:fix-bug        - Quick bug fix"
echo "  /workflow:document-issue - Document known issue"
echo "  /workflow:status         - Show project status"
echo "  /workflow:review-docs    - Review documentation"
echo "  /workflow:update-doc     - Update documentation"
echo ""

info "Typical workflow:"
echo ""
echo "  /setup → /feature → /workflow:plan-task → /workflow:implement-task → /workflow:test-task → /workflow:complete-task"
echo ""

success "Setup complete! Happy coding!"
echo ""
