#!/bin/bash

# ───────────────────────────────────────────────────
# Change Default Shell to Homebrew Bash
# ───────────────────────────────────────────────────

set -uo pipefail

# Colors for output
print_info() {
    printf "\n\033[1;34m[INFO]\033[0m %s\n" "$1"
}

print_success() {
    printf "\n\033[1;32m[SUCCESS]\033[0m %s\n" "$1"
}

print_error() {
    printf "\n\033[1;31m[ERROR]\033[0m %s\n" "$1" >&2
}

print_warning() {
    printf "\n\033[1;33m[WARNING]\033[0m %s\n" "$1"
}

# Check current shell
print_info "Current default shell: $(dscl . -read /Users/$USER UserShell | cut -d' ' -f2)"
print_info "Currently running shell: $0"

# Define paths
HOMEBREW_BASH="/opt/homebrew/bin/bash"
SHELLS_FILE="/etc/shells"

# Check if Homebrew bash exists
if [[ ! -f "$HOMEBREW_BASH" ]]; then
    print_error "Homebrew bash not found at $HOMEBREW_BASH"
    print_error "Please install bash with: brew install bash"
    exit 1
fi

print_info "Found Homebrew bash at $HOMEBREW_BASH"

# Check if bash is already in /etc/shells
if grep -q "$HOMEBREW_BASH" "$SHELLS_FILE"; then
    print_info "Homebrew bash is already in $SHELLS_FILE"
else
    print_info "Adding Homebrew bash to $SHELLS_FILE (requires sudo)"
    if sudo sh -c "echo '$HOMEBREW_BASH' >> '$SHELLS_FILE'"; then
        print_success "Added Homebrew bash to allowed shells"
    else
        print_error "Failed to add bash to $SHELLS_FILE"
        exit 1
    fi
fi

# Change default shell
print_info "Changing default shell to Homebrew bash"
print_info "You may be prompted for your password..."

# Try chsh first
if chsh -s "$HOMEBREW_BASH"; then
    print_success "Default shell changed to $HOMEBREW_BASH"
else
    print_warning "chsh failed, trying with sudo..."
    if sudo chsh -s "$HOMEBREW_BASH" "$USER"; then
        print_success "Default shell changed to $HOMEBREW_BASH (with sudo)"
    else
        print_error "Both chsh and sudo chsh failed"
        print_error "Manual commands to try:"
        print_error "  sudo dscl . -create /Users/$USER UserShell $HOMEBREW_BASH"
        exit 1
    fi
fi

print_info "Changes will take effect after you restart your terminal or log out/in"

# Verify the change
NEW_SHELL=$(dscl . -read /Users/$USER UserShell | cut -d' ' -f2)
if [[ "$NEW_SHELL" == "$HOMEBREW_BASH" ]]; then
    print_success "Verification: Default shell is now $NEW_SHELL"
    print_info "Restart your terminal or run 'exec $HOMEBREW_BASH' to start using the new shell"
else
    print_warning "Verification failed: Default shell is still $NEW_SHELL"
fi