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
if [[ ! -d "$SCRIPT_DIR/commands" ]] || [[ ! -d "$SCRIPT_DIR/workflow" ]]; then
    error "Expected structure not found!"
    error "Make sure you're running this from ~/.dotfiles/claude/"
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
# Step 1: Create ~/.claude/commands if needed
# ============================================================
if [[ ! -d "$HOME/.claude/commands" ]]; then
    info "Creating ~/.claude/commands/"
    mkdir -p "$HOME/.claude/commands"
fi

# ============================================================
# Step 2: Symlink each command individually
# ============================================================
echo ""
info "Symlinking commands to ~/.claude/commands/..."

COMMANDS=(
    "complete-task.md"
    "document-issue.md"
    "fix-bug.md"
    "implement-task.md"
    "init-project.md"
    "plan-task.md"
    "review-docs.md"
    "status.md"
    "test-task.md"
    "update-doc.md"
)

LINKED=0
SKIPPED=0

for cmd in "${COMMANDS[@]}"; do
    SOURCE="$SCRIPT_DIR/commands/$cmd"
    TARGET="$HOME/.claude/commands/$cmd"

    if [[ ! -f "$SOURCE" ]]; then
        warning "Source not found: $cmd"
        continue
    fi

    # Check if target exists
    if [[ -L "$TARGET" ]]; then
        # It's a symlink - check if it points to our source
        CURRENT_TARGET="$(readlink "$TARGET")"
        if [[ "$CURRENT_TARGET" == "$SOURCE" ]]; then
            echo "  ✓ $cmd (already linked)"
            SKIPPED=$((SKIPPED + 1))
        else
            warning "$cmd is symlinked to: $CURRENT_TARGET"
            read -p "  Replace with our version? (y/n) " -n 1 -r
            echo
            if [[ $REPLY =~ ^[Yy]$ ]]; then
                rm "$TARGET"
                ln -s "$SOURCE" "$TARGET"
                echo "  ✓ $cmd (replaced)"
                LINKED=$((LINKED + 1))
            else
                echo "  ✗ $cmd (skipped)"
                SKIPPED=$((SKIPPED + 1))
            fi
        fi
    elif [[ -f "$TARGET" ]]; then
        # It's a regular file
        warning "$cmd exists as a regular file"
        read -p "  Backup and replace with symlink? (y/n) " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            mv "$TARGET" "$TARGET.backup.$(date +%Y%m%d_%H%M%S)"
            ln -s "$SOURCE" "$TARGET"
            echo "  ✓ $cmd (backed up and linked)"
            LINKED=$((LINKED + 1))
        else
            echo "  ✗ $cmd (skipped)"
            SKIPPED=$((SKIPPED + 1))
        fi
    else
        # Doesn't exist - create symlink
        ln -s "$SOURCE" "$TARGET"
        echo "  ✓ $cmd"
        LINKED=$((LINKED + 1))
    fi
done

success "Commands: $LINKED linked, $SKIPPED skipped"

# ============================================================
# Step 3: Symlink workflow directory
# ============================================================
echo ""
info "Symlinking workflow directory to ~/.claude/workflow/..."

WORKFLOW_SOURCE="$SCRIPT_DIR/workflow"
WORKFLOW_TARGET="$HOME/.claude/workflow"

if [[ -L "$WORKFLOW_TARGET" ]]; then
    # It's a symlink
    CURRENT_TARGET="$(readlink "$WORKFLOW_TARGET")"
    if [[ "$CURRENT_TARGET" == "$WORKFLOW_SOURCE" ]]; then
        success "~/.claude/workflow → $WORKFLOW_SOURCE (already linked)"
    else
        warning "~/.claude/workflow is symlinked to: $CURRENT_TARGET"
        read -p "Replace with our version? (y/n) " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            rm "$WORKFLOW_TARGET"
            ln -s "$WORKFLOW_SOURCE" "$WORKFLOW_TARGET"
            success "~/.claude/workflow → $WORKFLOW_SOURCE (replaced)"
        else
            warning "Keeping existing workflow symlink"
        fi
    fi
elif [[ -d "$WORKFLOW_TARGET" ]]; then
    # It's a directory
    warning "~/.claude/workflow exists as a directory"
    echo "Contents:"
    ls -la "$WORKFLOW_TARGET"
    echo ""
    read -p "Backup and replace with symlink? (y/n) " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        BACKUP_DIR="$HOME/.claude/workflow.backup.$(date +%Y%m%d_%H%M%S)"
        mv "$WORKFLOW_TARGET" "$BACKUP_DIR"
        ln -s "$WORKFLOW_SOURCE" "$WORKFLOW_TARGET"
        success "Backed up to: $BACKUP_DIR"
        success "~/.claude/workflow → $WORKFLOW_SOURCE"
    else
        error "Setup incomplete - workflow not linked"
        exit 1
    fi
elif [[ -f "$WORKFLOW_TARGET" ]]; then
    error "~/.claude/workflow exists as a file (unexpected)"
    exit 1
else
    # Doesn't exist - create symlink
    ln -s "$WORKFLOW_SOURCE" "$WORKFLOW_TARGET"
    success "~/.claude/workflow → $WORKFLOW_SOURCE"
fi

# ============================================================
# Step 4: Verify setup
# ============================================================
echo ""
info "Verifying setup..."

# Check commands
VERIFIED=0
for cmd in "${COMMANDS[@]}"; do
    if [[ -L "$HOME/.claude/commands/$cmd" ]]; then
        ((VERIFIED++))
    fi
done

echo "  ✓ Commands: $VERIFIED/${#COMMANDS[@]} symlinked"

# Check workflow
if [[ -L "$HOME/.claude/workflow" ]]; then
    echo "  ✓ Workflow directory symlinked"
else
    error "Workflow directory NOT symlinked"
    exit 1
fi

# ============================================================
# Step 5: Display what's available
# ============================================================
echo ""
echo "╔════════════════════════════════════════╗"
echo "║          Setup Complete! 🎉            ║"
echo "╚════════════════════════════════════════╝"
echo ""

info "Structure created:"
echo ""
echo "~/.claude/"
echo "├── commands/              # Slash commands"
echo "│   ├── init-project.md → $SCRIPT_DIR/commands/init-project.md"
echo "│   ├── plan-task.md"
echo "│   ├── fix-bug.md"
echo "│   └── ... (${#COMMANDS[@]} total)"
echo "├── workflow/ → $SCRIPT_DIR/workflow"
echo "│   ├── sops/             # Universal SOPs"
echo "│   ├── templates/        # Project templates"
echo "│   └── README.md         # Documentation"
echo "└── ... (Claude Code app data)"
echo ""

info "Available slash commands:"
echo ""
echo "  /init-project      - Initialize .agent/ for new/existing project"
echo "  /plan-task         - Plan a new feature"
echo "  /implement-task    - Implement a task"
echo "  /fix-bug           - Quick bug fix (with cross-project search)"
echo "  /document-issue    - Document known issue (with cross-project search)"
echo "  /status            - Show project status"
echo ""

info "Workflow documentation:"
echo ""
echo "  ~/.claude/workflow/README.md          - Full documentation"
echo "  ~/.claude/workflow/sops/              - Universal SOPs"
echo "  ~/.claude/workflow/templates/         - Project templates"
echo ""

info "To use in a project:"
echo ""
echo "  1. Navigate to project directory"
echo "  2. Run: /init-project"
echo "  3. Answer the prompts"
echo "  4. Start coding!"
echo ""

success "Setup complete! Happy coding!"
echo ""
