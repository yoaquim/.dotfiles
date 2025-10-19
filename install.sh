#!/bin/bash

# ───────────────────────────────────────────────────
# Dotfiles Installation Script
# ───────────────────────────────────────────────────

# CRITICAL: Ensure we're running in bash BEFORE any other operations
# This MUST be the first thing that happens for colors to work properly
if [[ -z "${BASH_VERSION}" ]]; then
    echo "Switching to bash for proper color support..."
    # Try different bash locations in order of preference
    if [[ -f "/opt/homebrew/bin/bash" ]]; then
        exec /opt/homebrew/bin/bash "$0" "$@"
    elif [[ -f "/usr/local/bin/bash" ]]; then
        exec /usr/local/bin/bash "$0" "$@"
    elif [[ -f "/bin/bash" ]]; then
        exec /bin/bash "$0" "$@"
    else
        echo "Error: No suitable bash found. Please install bash and try again."
        exit 1
    fi
fi

# Force color support - we're definitely in bash now
export FORCE_COLOR=true

# Note: Not using set -e because we want to handle errors gracefully
set -uo pipefail

# Global variables
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
OS="$(uname -s)"
FORCE_REINSTALL=false

# ───────────────────────────────────────────────────
# Logging Functions
# ───────────────────────────────────────────────────

# Check if terminal supports colors
supports_color() {
    # Check if we're in tmux and handle accordingly
    if [[ -n "${TMUX:-}" ]]; then
        # In tmux, use tput for colors
        return 0
    else
        # Not in tmux, enable colors
        return 0
    fi
}

log() {
    local level="${1}"
    local message="${2}"
    local timestamp="$(date '+%Y-%m-%d %H:%M:%S')"
    
    if supports_color; then
        case "${level}" in
            "INFO")
                printf "\n%s[INFO]%s %s...\n" "$(tput bold; tput setaf 4)" "$(tput sgr0)" "${message}"
                ;;
            "SUCCESS")
                printf "\n%s[SUCCESS]%s %s\n" "$(tput bold; tput setaf 2)" "$(tput sgr0)" "${message}"
                ;;
            "ERROR")
                printf "\n%s[ERROR]%s %s\n" "$(tput bold; tput setaf 1)" "$(tput sgr0)" "${message}" >&2
                ;;
            "WARNING")
                printf "\n%s[WARNING]%s %s\n" "$(tput bold; tput setaf 3)" "$(tput sgr0)" "${message}"
                ;;
            "DEBUG")
                if [[ "${DEBUG:-false}" == "true" ]]; then
                    printf "\n%s[DEBUG]%s %s\n" "$(tput bold; tput setaf 5)" "$(tput sgr0)" "${message}"
                fi
                ;;
        esac
    else
        # Fallback to plain text without colors
        case "${level}" in
            "INFO")
                printf "\n[INFO] %s...\n" "${message}"
                ;;
            "SUCCESS")
                printf "\n[SUCCESS] %s\n" "${message}"
                ;;
            "ERROR")
                printf "\n[ERROR] %s\n" "${message}" >&2
                ;;
            "WARNING")
                printf "\n[WARNING] %s\n" "${message}"
                ;;
            "DEBUG")
                if [[ "${DEBUG:-false}" == "true" ]]; then
                    printf "\n[DEBUG] %s\n" "${message}"
                fi
                ;;
        esac
    fi
}

print_info() {
    log "INFO" "${1}"
}

print_success() {
    log "SUCCESS" "${1}"
}

print_error() {
    log "ERROR" "${1}"
}

print_warning() {
    log "WARNING" "${1}"
}

print_debug() {
    log "DEBUG" "${1}"
}

# ───────────────────────────────────────────────────
# Error Handling Functions
# ───────────────────────────────────────────────────

error_exit() {
    local message="${1:-"Unknown error occurred"}"
    print_error "${message}"
    exit 1
}

check_command() {
    local cmd="${1}"
    if ! command -v "${cmd}" &> /dev/null; then
        error_exit "Command '${cmd}' not found. Please install it first."
    fi
}

check_os() {
    if [[ "${OS}" != "Darwin" ]]; then
        error_exit "This script is designed for macOS only. Current OS: ${OS}"
    fi
}

check_directory() {
    local dir="${1}"
    if [[ ! -d "${dir}" ]]; then
        error_exit "Directory '${dir}' does not exist"
    fi
}

check_file() {
    local file="${1}"
    if [[ ! -f "${file}" ]]; then
        error_exit "File '${file}' does not exist"
    fi
}

validate_environment() {
    print_info "Validating environment"
    
    check_os
    check_directory "${SCRIPT_DIR}"
    check_directory "${SCRIPT_DIR}/config"
    
    # Check for required commands
    check_command "curl"
    check_command "git"
    
    # Check for Xcode Command Line Tools (required for Homebrew)
    if ! xcode-select -p &> /dev/null; then
        print_warning "Xcode Command Line Tools not found"
        print_info "Installing Xcode Command Line Tools..."
        print_info "You may be prompted to install them - please accept and wait for completion"
        xcode-select --install || print_warning "Failed to trigger Xcode Command Line Tools installation"
        print_info "Please run this script again after installing Xcode Command Line Tools"
        exit 1
    fi
    
    print_success "Environment validation complete"
}

# ───────────────────────────────────────────────────
# Utility Functions
# ───────────────────────────────────────────────────

backup_file() {
    local file="${1}"
    if [[ -f "${file}" ]]; then
        local backup="${file}.backup.$(date +%Y%m%d_%H%M%S)"
        cp "${file}" "${backup}"
        print_info "Backed up '${file}' to '${backup}'"
    fi
}

backup_directory() {
    local dir="${1}"
    if [[ -d "${dir}" ]]; then
        local backup="${dir}.backup.$(date +%Y%m%d_%H%M%S)"
        cp -r "${dir}" "${backup}"
        print_info "Backed up '${dir}' to '${backup}'"
    fi
}

confirm_action() {
    local message="${1}"
    local response
    
    if [[ "${FORCE_REINSTALL}" == "true" ]]; then
        return 0
    fi
    
    if supports_color; then
        printf "\n\033[1;33m[CONFIRM]\033[0m %s (y/N): " "${message}"
    else
        printf "\n[CONFIRM] %s (y/N): " "${message}"
    fi
    read -r response
    
    if [[ "${response}" =~ ^[Yy]$ ]]; then
        return 0
    else
        return 1
    fi
}

# ───────────────────────────────────────────────────
# Homebrew Functions
# ───────────────────────────────────────────────────

install_homebrew() {
    if command -v brew &> /dev/null; then
        print_info "Homebrew already installed"
        return 0
    fi
    
    print_info "Installing Homebrew"
    if /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"; then
        # Add Homebrew to PATH for current session (Apple Silicon)
        eval "$(/opt/homebrew/bin/brew shellenv)"
        
        # Verify installation
        if command -v brew &> /dev/null; then
            print_success "Homebrew installed successfully"
            return 0
        else
            print_warning "Homebrew installation completed but brew command not found - may need to restart terminal"
            return 1
        fi
    else
        print_warning "Homebrew installation failed - some packages may not be available"
        return 1
    fi
}

brew_package_exists() {
    local package="${1}"
    brew list --formula "${package}" &> /dev/null
}

brew_cask_exists() {
    local cask="${1}"
    brew list --cask "${cask}" &> /dev/null
}

brew_install_if_missing() {
    local package="${1}"
    local package_type="${2:-formula}"
    
    case "${package_type}" in
        "formula")
            if brew_package_exists "${package}"; then
                print_debug "Package '${package}' already installed"
                return 0
            fi
            print_info "Installing package '${package}'"
            if brew install "${package}"; then
                print_success "Successfully installed '${package}'"
            else
                print_warning "Failed to install package '${package}' - continuing with other packages"
                return 1
            fi
            ;;
        "cask")
            if brew_cask_exists "${package}"; then
                print_debug "Cask '${package}' already installed"
                return 0
            fi
            print_info "Installing cask '${package}'"
            if brew install --cask "${package}"; then
                print_success "Successfully installed '${package}'"
            else
                print_warning "Failed to install cask '${package}' - continuing with other packages"
                return 1
            fi
            ;;
        *)
            print_error "Invalid package type: ${package_type}"
            return 1
            ;;
    esac
}

# ───────────────────────────────────────────────────
# Symlink Functions
# ───────────────────────────────────────────────────

create_symlink() {
    local source="${1}"
    local target="${2}"
    local force="${3:-false}"
    
    if [[ ! -e "${source}" ]]; then
        print_error "Source '${source}' does not exist"
        return 1
    fi
    
    # Create parent directory if it doesn't exist
    local parent_dir="$(dirname "${target}")"
    if [[ ! -d "${parent_dir}" ]]; then
        mkdir -p "${parent_dir}"
        print_debug "Created directory '${parent_dir}'"
    fi
    
    # Handle existing file/symlink
    if [[ -e "${target}" || -L "${target}" ]]; then
        if [[ "${force}" == "true" ]] || [[ "${FORCE_REINSTALL}" == "true" ]]; then
            if [[ -f "${target}" && ! -L "${target}" ]]; then
                backup_file "${target}"
            fi
            rm -f "${target}"
        elif [[ -L "${target}" ]]; then
            local current_target="$(readlink "${target}")"
            if [[ "${current_target}" == "${source}" ]]; then
                print_debug "Symlink '${target}' already points to '${source}'"
                return 0
            fi
        else
            print_warning "Target '${target}' exists. Use --force to overwrite"
            return 1
        fi
    fi
    
    ln -sf "${source}" "${target}" || error_exit "Failed to create symlink '${target}' -> '${source}'"
    print_debug "Created symlink '${target}' -> '${source}'"
}

link_symlinks() {
    print_info "Creating symlinks"
    
    # Create .config directory if it doesn't exist
    mkdir -p "$HOME/.config"
    
    # Link shell configuration for bash
    create_symlink "${SCRIPT_DIR}/config/bash/bash_profile" "$HOME/.bash_profile"
    create_symlink "${SCRIPT_DIR}/config/bash/bash_profile" "$HOME/.bashrc"
    create_symlink "${SCRIPT_DIR}/config/bash" "$HOME/.config/bash"
    
    # Also link for zsh users (if they want to use the same configs)
    setup_zsh_compatibility
    
    # Link application configurations
    create_symlink "${SCRIPT_DIR}/config/tmux" "$HOME/.config/tmux"
    create_symlink "${SCRIPT_DIR}/config/kitty" "$HOME/.config/kitty"
    create_symlink "${SCRIPT_DIR}/config/gitconfig" "$HOME/.gitconfig"
    create_symlink "${SCRIPT_DIR}/config/rclone" "$HOME/.config/rclone"

    print_success "Symlinks created successfully"
}

setup_zsh_compatibility() {
    print_info "Setting up zsh compatibility"
    
    # Check if user is currently using zsh
    local current_shell="$(echo $SHELL)"
    if [[ "${current_shell}" == *"zsh"* ]]; then
        print_info "Detected zsh as current shell - adding bash profile sourcing to zsh config"
        
        # Add sourcing of bash_profile to zshrc if not already present
        local zshrc="$HOME/.zshrc"
        if [[ ! -f "${zshrc}" ]] || ! grep -q "bash_profile" "${zshrc}"; then
            cat >> "${zshrc}" << 'EOF'

# Homebrew PATH setup (Apple Silicon)
eval "$(/opt/homebrew/bin/brew shellenv)"

# Source bash configuration for dotfiles compatibility
if [ -f ~/.bash_profile ]; then
    source ~/.bash_profile
fi
EOF
            print_success "Added Homebrew PATH and bash profile sourcing to ~/.zshrc"
        else
            print_debug "Bash profile sourcing already present in ~/.zshrc"
        fi
    else
        print_debug "Not using zsh, skipping zsh compatibility setup"
    fi
}

# ───────────────────────────────────────────────────
# Tmux Setup Functions
# ───────────────────────────────────────────────────

setup_tmux_plugins() {
    print_info "Setting up tmux plugins"
    
    local tpm_dir="$HOME/.config/tmux/plugins/tpm"
    
    if [[ ! -d "${tpm_dir}" ]]; then
        print_info "Installing tmux plugin manager (tpm)"
        mkdir -p "$(dirname "${tpm_dir}")"
        if ! git clone https://github.com/tmux-plugins/tpm "${tpm_dir}"; then
            print_warning "Failed to clone tpm - tmux plugins may not work"
            return 1
        fi
        print_success "tpm installed successfully"
    else
        print_debug "tpm already installed"
    fi
    
    # Link tmux-powerline configuration
    create_symlink "${SCRIPT_DIR}/config/tmux-powerline" "$HOME/.config/tmux-powerline"
    
    print_success "Tmux plugins setup complete"
}

# ───────────────────────────────────────────────────
# Base16 Theme Setup
# ───────────────────────────────────────────────────

setup_base16() {
    print_info "Setting up Base16 shell themes"
    
    local base16_dir="$HOME/.config/base16-shell"
    
    if [[ -d "${base16_dir}" ]]; then
        if [[ "${FORCE_REINSTALL}" == "true" ]] || confirm_action "Base16 already exists. Reinstall?"; then
            rm -rf "${base16_dir}"
        else
            print_info "Base16 already installed, skipping"
            return 0
        fi
    fi
    
    if ! git clone https://github.com/chriskempson/base16-shell.git "${base16_dir}"; then
        print_warning "Failed to clone base16-shell - color themes may not work"
        return 1
    fi
    
    print_success "Base16 shell themes installed successfully"
}

# ───────────────────────────────────────────────────
# Hammerspoon Setup
# ───────────────────────────────────────────────────

setup_hammerspoon() {
    print_info "Setting up Hammerspoon configuration"

    # Link hammerspoon configuration directory
    local hammerspoon_dir="$HOME/.hammerspoon"
    create_symlink "${SCRIPT_DIR}/config/hammerspoon" "${hammerspoon_dir}"

    print_success "Hammerspoon configuration setup complete"
    print_info "Note: Launch Hammerspoon and grant accessibility permissions to enable Alt+Space hotkey"
}

# ───────────────────────────────────────────────────
# rclone Configuration and LaunchAgent Setup
# ───────────────────────────────────────────────────

setup_rclone() {
    print_info "Setting up rclone configuration and LaunchAgent"

    # Create Cave mount point directory
    local mount_point="$HOME/Cave"
    if [[ ! -d "${mount_point}" ]]; then
        mkdir -p "${mount_point}"
        print_success "Created Cave mount point at ${mount_point}"
    fi

    # Create cache directory for rclone logs
    mkdir -p "$HOME/.cache/rclone"

    # Link LaunchAgent
    local launch_agent_dir="$HOME/Library/LaunchAgents"
    mkdir -p "${launch_agent_dir}"
    create_symlink "${SCRIPT_DIR}/config/rclone/com.rclone.cave.plist" "${launch_agent_dir}/com.rclone.cave.plist"

    # Check if AWS credentials are configured in bash_profile_local
    local bash_local="${SCRIPT_DIR}/config/bash/bash_profile_local"
    if [[ -f "${bash_local}" ]] && grep -q "CAVE_AWS_ACCESS_KEY_ID" "${bash_local}" 2>/dev/null; then
        print_success "AWS credentials found in bash_profile_local"
    else
        print_warning "AWS credentials not configured yet"
        echo
        echo "  Add these to ~/.config/bash/bash_profile_local:"
        echo "    export CAVE_AWS_ACCESS_KEY_ID=\"your-access-key-id\""
        echo "    export CAVE_AWS_SECRET_ACCESS_KEY=\"your-secret-access-key\""
        echo
        echo "  Then reload: source ~/.bash_profile"
        echo
    fi

    # Check if rclone and macfuse are installed
    if ! command -v rclone &> /dev/null; then
        print_warning "rclone not found - will be installed by Homebrew"
    fi

    if ! brew list --cask macfuse &> /dev/null 2>&1; then
        print_warning "macfuse not found - will be installed by Homebrew"
    fi

    # Auto-load LaunchAgent if credentials are configured
    local plist_path="$HOME/Library/LaunchAgents/com.rclone.cave.plist"
    if [[ -f "${bash_local}" ]] && grep -q "CAVE_AWS_ACCESS_KEY_ID" "${bash_local}" 2>/dev/null; then
        # Check if already loaded
        if launchctl list | grep -q "com.rclone.cave"; then
            print_success "Cave LaunchAgent already loaded"
        else
            print_info "Loading Cave LaunchAgent (will auto-start on future logins)"
            if launchctl load "${plist_path}" 2>/dev/null; then
                print_success "Cave LaunchAgent loaded - mounting in background"
                print_info "Use 'cave' command to open in Finder or check mount status"
            else
                print_warning "Failed to load LaunchAgent - you may need to load it manually:"
                print_info "  launchctl load ~/Library/LaunchAgents/com.rclone.cave.plist"
            fi
        fi
    else
        print_info "Cave LaunchAgent will auto-load after credentials are configured"
        print_info "After adding credentials to bash_profile_local, run:"
        print_info "  launchctl load ~/Library/LaunchAgents/com.rclone.cave.plist"
    fi

    print_success "rclone configuration setup complete"
    print_info "See ${SCRIPT_DIR}/config/rclone/README.md for full documentation"
}

# ───────────────────────────────────────────────────
# Homebrew Package Installation
# ───────────────────────────────────────────────────

install_brew_list() {
    print_info "Installing Homebrew packages"
    
    local packages=(
        "awscli"
        "bash"
        "bash-completion"
        "coreutils"
        "diff-so-fancy"
        "git"
        "jq"
        "neovim"
        "pipx"
        "tmux"
        "lazygit"
        "vim"
        "tldr"
        "gh"
        "rclone"
    )
    
    for package in "${packages[@]}"; do
        brew_install_if_missing "${package}" "formula"
    done
    
    print_success "Homebrew packages installed successfully"
}

install_xcode() {
    print_info "Checking for full Xcode installation"
    
    # Check if Xcode is already installed
    if [[ -d "/Applications/Xcode.app" ]]; then
        print_success "Xcode is already installed"
        return 0
    fi
    
    # Ask if user wants to install full Xcode (it's huge!)
    if confirm_action "Install full Xcode IDE? (This is ~15GB and takes a while)"; then
        print_info "Installing Xcode via Homebrew (this will take a long time...)"
        if brew install --cask xcode; then
            print_success "Xcode installed successfully"
            print_info "You may need to launch Xcode and accept the license agreement"
        else
            print_warning "Xcode installation failed - you can install it manually from the App Store"
            return 1
        fi
    else
        print_info "Skipping full Xcode installation - Command Line Tools are sufficient for most development"
    fi
}

install_brew_casks() {
    print_info "Installing Homebrew casks"
    
    local casks=(
        "alfred"
        "spotify"
        "whatsapp"
        # "docker" # skipping Docker for now, due to bug in package install
        "postman"
        "1password"
        "slack"
        "kitty"
        "todoist-app"
        "claude"
        "adobe-creative-cloud"
        "google-chrome"
        "rectangle"
        "hammerspoon"
        "notion"
        "calibre"
        "quarto"
        "folx"
    )
    
    for cask in "${casks[@]}"; do
        brew_install_if_missing "${cask}" "cask"
    done
    
    print_success "Homebrew casks installed successfully"
}

install_brew_fonts() {
    print_info "Installing Homebrew fonts"
    
    local fonts=(
        "font-source-code-pro"
        "font-fantasque-sans-mono"
        "font-inconsolata"
        "font-hack"
        "font-fira-code"
        "font-jetbrains-mono"
        "font-ubuntu-mono"
        "font-space-mono"
        "font-hack-nerd-font"
        "font-fira-code-nerd-font"
        "font-jetbrains-mono-nerd-font"
        "font-ubuntu-mono-nerd-font"
        "font-space-mono-nerd-font"
    )
    
    for font in "${fonts[@]}"; do
        brew_install_if_missing "${font}" "cask"
    done
    
    print_success "Homebrew fonts installed successfully"
}

# ───────────────────────────────────────────────────
# Post-Installation Setup
# ───────────────────────────────────────────────────

post_brew_install_setup() {
    print_info "Post-installation setup complete"
    print_info "Language environments (Node.js and Python) can be configured using the post-setup script"
    
    print_success "Basic installation complete - run post-setup.sh for language environments"
}

# ───────────────────────────────────────────────────
# Neovim Dependencies
# ───────────────────────────────────────────────────

install_nvim_deps() {
    print_info "Installing Neovim dependencies"
    
    local nvim_deps=(
        "ripgrep"
        "lazygit"
        "fd"
        "tree-sitter"
        "go"
        "bottom"
        "gdu"
    )
    
    for dep in "${nvim_deps[@]}"; do
        brew_install_if_missing "${dep}" "formula"
    done
    
    print_success "Neovim dependencies installed successfully"
}

# ───────────────────────────────────────────────────
# Claude Code Installation
# ───────────────────────────────────────────────────

install_claude_code() {
    print_info "Installing Claude Code CLI"
    
    if command -v claude &> /dev/null; then
        print_debug "Claude Code already installed"
        return 0
    fi
    
    # Check if npm is available (Node.js installed)
    if command -v npm &> /dev/null; then
        print_info "Installing Claude Code via npm"
        if npm install -g @anthropic-ai/claude-code; then
            # Verify installation
            if command -v claude &> /dev/null; then
                local version
                version=$(claude --version 2>/dev/null || echo "unknown")
                print_success "Claude Code installed successfully (version: ${version})"
            else
                print_warning "Claude Code installation verification failed"
                return 1
            fi
        else
            print_warning "Failed to install Claude Code via npm"
            return 1
        fi
    else
        print_warning "npm not found. Claude Code will be available after running post-setup.sh to install Node.js"
        return 1
    fi
}

setup_claude_code() {
    print_info "Setting up Claude Code configuration"
    
    # Create Claude Code config directory
    local claude_config_dir="$HOME/.config/claude-code"
    mkdir -p "${claude_config_dir}"
    
    # Check if API key is already configured
    if [[ -f "${claude_config_dir}/config.json" ]]; then
        print_info "Claude Code configuration already exists"
        return 0
    fi
    
    print_info "Claude Code configuration setup complete"
    print_info "To configure Claude Code, run: claude auth login"
}


# ┌─────────────────────────────────────────────────────────────────────────────┐
# │                                  Install                                    │
# └─────────────────────────────────────────────────────────────────────────────┘

# This section is handled by the main() function now

# ───────────────────────────────────────────────────
# Uninstall Functions
# ───────────────────────────────────────────────────

uninstall_symlinks() {
    print_info "Removing symlinks"
    
    local symlinks=(
        "$HOME/.bash_profile"
        "$HOME/.bashrc"
        "$HOME/.config/bash"
        "$HOME/.config/tmux"
        "$HOME/.config/kitty"
        "$HOME/.gitconfig"
        "$HOME/.config/tmux-powerline"
        "$HOME/.config/nvim/lua/polish.lua"
        "$HOME/.config/nvim/lua/plugins/user.lua"
        "$HOME/.hammerspoon"
    )
    
    for symlink in "${symlinks[@]}"; do
        if [[ -L "${symlink}" ]]; then
            rm -f "${symlink}"
            print_debug "Removed symlink '${symlink}'"
        fi
    done
    
    print_success "Symlinks removed successfully"
}

uninstall_directories() {
    print_info "Removing installed directories"
    
    local directories=(
        "$HOME/.config/base16-shell"
        "$HOME/.config/tmux/plugins/tpm"
    )
    
    for dir in "${directories[@]}"; do
        if [[ -d "${dir}" ]]; then
            if confirm_action "Remove directory '${dir}'?"; then
                rm -rf "${dir}"
                print_debug "Removed directory '${dir}'"
            fi
        fi
    done
    
    print_success "Directories removed successfully"
}

uninstall_astronvim() {
    print_info "Removing AstroNvim"
    
    local nvim_config_dir="$HOME/.config/nvim"
    
    if [[ -d "${nvim_config_dir}" ]]; then
        if confirm_action "Remove AstroNvim configuration?"; then
            backup_directory "${nvim_config_dir}"
            rm -rf "${nvim_config_dir}"
            print_success "AstroNvim removed successfully"
        else
            print_info "Keeping AstroNvim configuration"
        fi
    else
        print_info "AstroNvim not found, skipping"
    fi
}

# ───────────────────────────────────────────────────
# Main Installation Functions
# ───────────────────────────────────────────────────

full_install() {
    print_info "Starting full installation"
    
    # Validate environment
    validate_environment
    
    # Install Homebrew if not present
    if ! install_homebrew; then
        print_warning "Homebrew installation failed - some features may not work"
        print_info "You can install Homebrew manually later and re-run this script"
        return 1
    fi
    
    # Update Homebrew
    print_info "Updating Homebrew"
    brew update || print_warning "Failed to update Homebrew"
    
    # Install packages
    install_brew_list
    install_brew_casks
    install_brew_fonts
    
    # Optional: Install full Xcode
    install_xcode
    
    # Install Neovim dependencies
    install_nvim_deps
    
    # Setup configurations
    link_symlinks
    setup_tmux_plugins || print_warning "Tmux plugin setup failed - continuing"
    setup_base16 || print_warning "Base16 setup failed - continuing"
    setup_hammerspoon
    setup_rclone
    setup_git_ssh
    
    # Complete basic setup
    post_brew_install_setup
    
    # Install and setup Claude Code (requires Node.js from post-setup)
    if install_claude_code; then
        setup_claude_code
    else
        print_info "Claude Code installation skipped - run post-setup.sh first to install Node.js, then install Claude Code manually with: npm install -g @anthropic-ai/claude-code"
    fi
    
    print_success "Full installation complete."
}

reinstall() {
    print_info "Starting reinstallation"
    
    # Force reinstall mode
    FORCE_REINSTALL=true
    
    # Validate environment
    validate_environment
    
    # Reinstall configurations
    link_symlinks
    setup_tmux_plugins || print_warning "Tmux plugin setup failed - continuing"
    setup_base16 || print_warning "Base16 setup failed - continuing"
    setup_hammerspoon
    setup_rclone
    
    # Reinstall Claude Code if not present
    if ! command -v claude &> /dev/null; then
        install_claude_code
        setup_claude_code
    fi
    
    print_success "Reinstallation complete."
}

uninstall_all() {
    print_info "Starting uninstallation"
    
    if ! confirm_action "Are you sure you want to uninstall all dotfiles configurations?"; then
        print_info "Uninstallation cancelled"
        return 0
    fi
    
    uninstall_symlinks
    uninstall_directories
    uninstall_astronvim
    
    # Uninstall Claude Code if requested
    if command -v claude &> /dev/null; then
        if confirm_action "Uninstall Claude Code CLI?"; then
            if command -v npm &> /dev/null; then
                npm uninstall -g @anthropic-ai/claude-code || print_warning "Failed to uninstall Claude Code"
                print_success "Claude Code uninstalled successfully"
            else
                print_warning "npm not found, cannot uninstall Claude Code"
            fi
        fi
    fi
    
    print_success "Uninstallation complete."
}

# ───────────────────────────────────────────────────
# Git Configuration
# ───────────────────────────────────────────────────

setup_git_ssh() {
    print_info "Configuring Git to use SSH for GitHub"
    
    # Set GitHub to always use SSH instead of HTTPS
    git config --global url."git@github.com:".insteadOf "https://github.com/"
    
    # If this is the dotfiles repo, update its remote to SSH
    if [[ "$(git remote get-url origin 2>/dev/null)" == "https://github.com/"* ]]; then
        local current_url="$(git remote get-url origin)"
        local ssh_url="${current_url/https:\/\/github.com\//git@github.com:}"
        git remote set-url origin "${ssh_url}"
        print_success "Updated dotfiles repo remote to SSH"
    fi
    
    print_success "Git SSH configuration complete"
}

# ───────────────────────────────────────────────────
# Shell Configuration
# ───────────────────────────────────────────────────

change_default_shell() {
    print_info "Checking default shell configuration"
    
    local bash_path="/opt/homebrew/bin/bash"
    
    # Check if homebrew bash exists
    if [[ ! -f "${bash_path}" ]]; then
        print_warning "Homebrew bash not found at ${bash_path}. Shell change not needed."
        return 0
    fi
    
    # Check current shell
    local current_shell="$(dscl . -read /Users/$(whoami) UserShell 2>/dev/null | cut -d' ' -f2 || echo '/bin/zsh')"
    
    if [[ "${current_shell}" != "${bash_path}" ]]; then
        print_info "Current shell: ${current_shell}"
        print_info "To change your default shell to Homebrew bash, run these commands manually:"
        if supports_color; then
            printf "   \033[32msudo sh -c 'echo %s >> /etc/shells'\033[0m\n" "${bash_path}"
            printf "   \033[32mchsh -s %s\033[0m\n" "${bash_path}"
        else
            echo "   sudo sh -c 'echo ${bash_path} >> /etc/shells'"
            echo "   chsh -s ${bash_path}"
        fi
        print_info "This is optional - your dotfiles will work with any shell"
    else
        print_success "Default shell is already set to homebrew bash"
    fi
}

# ───────────────────────────────────────────────────
# Final Instructions
# ───────────────────────────────────────────────────

show_final_instructions() {
    if supports_color; then
        printf "\n\033[1;36m╔══════════════════════════════════════════════════════════════════════════════╗\033[0m\n"
        printf "\033[1;36m║                             SETUP COMPLETE                                   ║\033[0m\n"
        printf "\033[1;36m╚══════════════════════════════════════════════════════════════════════════════╝\033[0m\n"
        printf "\n\033[1;33mNext Steps:\033[0m\n"
        printf "\n\033[1;34m1. Restart your terminal or run:\033[0m\n"
        printf "   \033[32msource ~/.bash_profile\033[0m\n"
        printf "\n\033[1;34m2. Set up language environments:\033[0m\n"
        printf "   \033[32mbash ./post-setup.sh\033[0m\n"
        printf "\n\033[1;34m3. Configure Claude Code (installed with post-setup.sh):\033[0m\n"
        printf "   \033[32mclaude auth login\033[0m\n"
        printf "\n\033[1;34m4. Change default shell to bash (recommended for tmux/kitty):\033[0m\n"
        printf "   \033[32m./change-shell.sh\033[0m\n"
        printf "\n\033[1;34m5. If using zsh (and configurations not auto-added), add to ~/.zshrc:\033[0m\n"
        printf "   \033[32meval \"\$(/opt/homebrew/bin/brew shellenv)\"\033[0m\n"
        printf "   \033[32msource ~/.bash_profile\033[0m\n"
        printf "\n\033[1;34m6. Launch applications:\033[0m\n"
        printf "   \033[32m• Hammerspoon - Grant accessibility permissions\033[0m\n"
        printf "   \033[32m• Kitty - Set as default terminal\033[0m\n"
        printf "   \033[32m• AstroNvim will be set up automatically in post-setup.sh\033[0m\n"
        printf "\n\033[1;35mEnjoy your new development environment! 🚀\033[0m\n\n"
    else
        echo ""
        echo "=============================================================================="
        echo "                            SETUP COMPLETE                                    "
        echo "=============================================================================="
        echo ""
        echo "Next Steps:"
        echo ""
        echo "1. Restart your terminal or run:"
        echo "   source ~/.bash_profile"
        echo ""
        echo "2. Set up language environments:"
        echo "   ./post-setup.sh"
        echo ""
        echo "3. Configure Claude Code (installed with post-setup.sh):"
        echo "   claude auth login"
        echo ""
        echo "4. Change default shell to bash (recommended for tmux/kitty):"
        echo "   ./change-shell.sh"
        echo ""
        echo "5. If using zsh (and configurations not auto-added), add to ~/.zshrc:"
        echo "   eval \"\$(/opt/homebrew/bin/brew shellenv)\""
        echo "   source ~/.bash_profile"
        echo ""
        echo "6. Launch applications:"
        echo "   • Hammerspoon - Grant accessibility permissions"
        echo "   • Kitty - Set as default terminal"
        echo "   • AstroNvim will be set up automatically in post-setup.sh"
        echo ""
        echo "Enjoy your new development environment!"
        echo ""
    fi
}

# ───────────────────────────────────────────────────
# Usage and Argument Parsing
# ───────────────────────────────────────────────────

show_usage() {
    cat << EOF
Usage: $0 [OPTIONS]

Options:
    -h, --help          Show this help message
    -i, --install       Perform full installation (default)
    -r, --reinstall     Reinstall configurations (preserves packages)
    -u, --uninstall     Uninstall all dotfiles configurations
    -f, --force         Force reinstall without prompts
    -d, --debug         Enable debug logging
    -v, --verbose       Enable verbose output

Examples:
    $0                  # Full installation
    $0 --reinstall      # Reinstall configurations only
    $0 --force          # Force reinstall without prompts
    $0 --uninstall      # Uninstall all configurations

EOF
}

parse_arguments() {
    local action="install"
    
    while [[ $# -gt 0 ]]; do
        case $1 in
            -h|--help)
                show_usage
                exit 0
                ;;
            -i|--install)
                action="install"
                shift
                ;;
            -r|--reinstall)
                action="reinstall"
                shift
                ;;
            -u|--uninstall)
                action="uninstall"
                shift
                ;;
            -f|--force)
                FORCE_REINSTALL=true
                shift
                ;;
            -d|--debug)
                DEBUG=true
                shift
                ;;
            -v|--verbose)
                set -x
                shift
                ;;
            *)
                print_error "Unknown option: $1"
                show_usage
                exit 1
                ;;
        esac
    done
    
    echo "${action}"
}

# ───────────────────────────────────────────────────
# Main Execution
# ───────────────────────────────────────────────────

main() {
    local action
    action="$(parse_arguments "$@")"
    
    print_info "Starting dotfiles setup - Action: ${action}"
    
    case "${action}" in
        "install")
            full_install
            ;;
        "reinstall")
            reinstall
            ;;
        "uninstall")
            uninstall_all
            ;;
        *)
            print_error "Invalid action: ${action}"
            show_usage
            exit 1
            ;;
    esac
    
    print_success "Dotfiles setup complete."
    
    # Change default shell to homebrew bash
    change_default_shell
    
    # Show final setup instructions
    show_final_instructions
}

# Bash check already done at top of script

# Run main function with all arguments
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi

