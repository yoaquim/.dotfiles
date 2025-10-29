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
echo "║   Claude Code Workflow Setup          ║"
echo "╚════════════════════════════════════════╝"
echo ""

# Get script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
info "Script location: $SCRIPT_DIR"

# Verify we're in the right place
if [[ ! -d "$SCRIPT_DIR/commands" ]] || [[ ! -d "$SCRIPT_DIR/workflow" ]] || [[ ! -d "$SCRIPT_DIR/guides" ]]; then
    error "Expected structure not found!"
    error "Make sure you're running this from ~/.dotfiles/claude/"
    error "Required directories: commands/, workflow/, guides/"
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
# Step 1: Ensure ~/.claude/commands exists
# ============================================================
if [[ ! -d "$HOME/.claude/commands" ]]; then
    info "Creating ~/.claude/commands/"
    mkdir -p "$HOME/.claude/commands"
fi

# ============================================================
# Step 2: Symlink command subdirectories
# ============================================================
echo ""
info "Symlinking command subdirectories..."

# Symlink workflow commands
symlink_directory "$SCRIPT_DIR/commands/workflow" "$HOME/.claude/commands/workflow" "~/.claude/commands/workflow"

# Symlink VK commands
symlink_directory "$SCRIPT_DIR/commands/vk" "$HOME/.claude/commands/vk" "~/.claude/commands/vk"

# ============================================================
# Step 3: Symlink workflow directory
# ============================================================
echo ""
info "Symlinking workflow directory to ~/.claude/workflow/..."

symlink_directory "$SCRIPT_DIR/workflow" "$HOME/.claude/workflow" "~/.claude/workflow"

# ============================================================
# Step 4: Symlink guides directory
# ============================================================
echo ""
info "Symlinking guides directory to ~/.claude/guides/..."

symlink_directory "$SCRIPT_DIR/guides" "$HOME/.claude/guides" "~/.claude/guides"

# ============================================================
# Step 5: Verify setup
# ============================================================
echo ""
info "Verifying setup..."

# Check command subdirectories
WORKFLOW_OK=false
VK_OK=false

if [[ -L "$HOME/.claude/commands/workflow" ]]; then
    WORKFLOW_COUNT=$(find "$SCRIPT_DIR/commands/workflow" -name "*.md" -type f | wc -l | tr -d ' ')
    echo "  ✓ Workflow commands symlinked ($WORKFLOW_COUNT commands)"
    WORKFLOW_OK=true
else
    error "Workflow commands NOT symlinked"
fi

if [[ -L "$HOME/.claude/commands/vk" ]]; then
    VK_COUNT=$(find "$SCRIPT_DIR/commands/vk" -name "*.md" -type f | wc -l | tr -d ' ')
    echo "  ✓ VK commands symlinked ($VK_COUNT commands)"
    VK_OK=true
else
    error "VK commands NOT symlinked"
fi

if [[ "$WORKFLOW_OK" != true ]] || [[ "$VK_OK" != true ]]; then
    error "Command symlinks incomplete"
    exit 1
fi

# Check workflow
if [[ -L "$HOME/.claude/workflow" ]]; then
    echo "  ✓ Workflow directory symlinked"
else
    error "Workflow directory NOT symlinked"
    exit 1
fi

# Check guides
if [[ -L "$HOME/.claude/guides" ]]; then
    echo "  ✓ Guides directory symlinked"
else
    warning "Guides directory NOT symlinked (optional)"
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
echo "├── commands/"
echo "│   ├── workflow/ → $SCRIPT_DIR/commands/workflow"
echo "│   │   ├── init-project.md"
echo "│   │   ├── feature.md"
echo "│   │   ├── plan-task.md"
echo "│   │   ├── implement-task.md"
echo "│   │   ├── test-task.md"
echo "│   │   ├── complete-task.md"
echo "│   │   ├── fix-bug.md"
echo "│   │   ├── document-issue.md"
echo "│   │   ├── review-docs.md"
echo "│   │   ├── status.md"
echo "│   │   └── update-doc.md"
echo "│   └── vk/ → $SCRIPT_DIR/commands/vk"
echo "│       ├── init.md"
echo "│       ├── kickoff.md"
echo "│       ├── feature.md"
echo "│       ├── plan.md"
echo "│       ├── prioritize.md"
echo "│       ├── execute.md"
echo "│       ├── start.md"
echo "│       ├── status.md"
echo "│       └── sync-docs.md"
echo "├── workflow/ → $SCRIPT_DIR/workflow"
echo "│   ├── sops/                  # Universal SOPs"
echo "│   ├── templates/             # Project templates"
echo "│   └── README.md"
echo "├── guides/ → $SCRIPT_DIR/guides"
echo "│   ├── vk-product-workflow.md # Complete VK guide"
echo "│   └── vk-execution-model.md  # Tasks vs Attempts"
echo "└── ... (Claude Code app data)"
echo ""

info "Available slash commands:"
echo ""
echo "Standard Workflow:"
echo "  /init-project      - Initialize .agent/ for new/existing project"
echo "  /feature           - Define WHAT to build (feature requirements)"
echo "  /plan-task         - Plan HOW to build it"
echo "  /implement-task    - Implement a task"
echo "  /test-task         - Test implementation"
echo "  /complete-task     - Finalize and document"
echo "  /fix-bug           - Quick bug fix"
echo "  /document-issue    - Document known issue"
echo "  /status            - Show project status"
echo ""
echo "VK Workflow (Vibe Kanban integration):"
echo "  /vk:init   - Initialize VK-enabled project"
echo "  /vk:kickoff        - Complete project kickoff (features → requirements → tasks)"
echo "  /vk:feature        - Define feature requirements"
echo "  /vk:plan           - Create VK tasks from feature"
echo "  /vk:prioritize     - Set dependencies and execution order"
echo "  /vk:start          - Start ready tasks (smart orchestration)"
echo "  /vk:execute        - Start single task manually"
echo "  /vk:status         - Check VK progress and readiness"
echo "  /vk:sync-docs      - Sync documentation"
echo ""

info "Documentation:"
echo ""
echo "  ~/.claude/guides/vk-product-workflow.md  - Complete VK workflow guide"
echo "  ~/.claude/guides/vk-execution-model.md   - Tasks vs Attempts explained"
echo "  ~/.claude/workflow/README.md             - Standard workflow docs"
echo "  ~/.claude/workflow/sops/                 - Universal SOPs"
echo ""

info "Typical workflows:"
echo ""
echo "Standard (manual):"
echo "  /init-project → /feature → /plan-task → /implement-task → /test-task → /complete-task"
echo ""
echo "VK (orchestrated):"
echo "  /vk:init → /vk:kickoff → /vk:prioritize → /vk:start --watch"
echo ""

success "Setup complete! Happy coding!"
echo ""
