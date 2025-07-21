#!/bin/bash

# ───────────────────────────────────────────────────
# Dotfiles Installation Script
# ───────────────────────────────────────────────────

# Ensure we're running in bash BEFORE any other operations
if [[ -z "${BASH_VERSION}" ]]; then
    echo "This script must be run with bash. Switching to bash..."
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

set -euo pipefail

# Global variables
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
OS="$(uname -s)"
FORCE_REINSTALL=false

# ───────────────────────────────────────────────────
# Logging Functions
# ───────────────────────────────────────────────────

# Check if terminal supports colors
supports_color() {
    # Force colors if FORCE_COLOR is set
    if [[ "${FORCE_COLOR:-false}" == "true" ]]; then
        return 0
    fi
    
    # Check if we have a terminal and it supports colors
    if [[ -t 1 ]] && command -v tput &> /dev/null; then
        local colors
        colors=$(tput colors 2>/dev/null || echo 0)
        [[ $colors -ge 8 ]]
    else
        false
    fi
}

log() {
    local level="${1}"
    local message="${2}"
    local timestamp="$(date '+%Y-%m-%d %H:%M:%S')"
    
    if supports_color; then
        case "${level}" in
            "INFO")
                echo -e "\n\e[1;34m[INFO]\e[0m ${message}..."
                ;;
            "SUCCESS")
                echo -e "\n\e[1;32m[SUCCESS]\e[0m ${message}"
                ;;
            "ERROR")
                echo -e "\n\e[1;31m[ERROR]\e[0m ${message}" >&2
                ;;
            "WARNING")
                echo -e "\n\e[1;33m[WARNING]\e[0m ${message}"
                ;;
            "DEBUG")
                if [[ "${DEBUG:-false}" == "true" ]]; then
                    echo -e "\n\e[1;35m[DEBUG]\e[0m ${message}"
                fi
                ;;
        esac
    else
        # Fallback to plain text without colors
        case "${level}" in
            "INFO")
                echo -e "\n[INFO] ${message}..."
                ;;
            "SUCCESS")
                echo -e "\n[SUCCESS] ${message}"
                ;;
            "ERROR")
                echo -e "\n[ERROR] ${message}" >&2
                ;;
            "WARNING")
                echo -e "\n[WARNING] ${message}"
                ;;
            "DEBUG")
                if [[ "${DEBUG:-false}" == "true" ]]; then
                    echo -e "\n[DEBUG] ${message}"
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
        echo -e "\n\e[1;33m[CONFIRM]\e[0m ${message} (y/N): "
    else
        echo -e "\n[CONFIRM] ${message} (y/N): "
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
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)" || error_exit "Failed to install Homebrew"
    
    # Add Homebrew to PATH for current session
    if [[ -f "/opt/homebrew/bin/brew" ]]; then
        eval "$(/opt/homebrew/bin/brew shellenv)"
    elif [[ -f "/usr/local/bin/brew" ]]; then
        eval "$(/usr/local/bin/brew shellenv)"
    fi
    
    print_success "Homebrew installed successfully"
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
    
    # Link shell configuration
    create_symlink "${SCRIPT_DIR}/config/bash/bash_profile" "$HOME/.bash_profile"
    create_symlink "${SCRIPT_DIR}/config/bash/bash_profile" "$HOME/.bashrc"
    create_symlink "${SCRIPT_DIR}/config/bash" "$HOME/.config/bash"
    
    # Link application configurations
    create_symlink "${SCRIPT_DIR}/config/tmux" "$HOME/.config/tmux"
    create_symlink "${SCRIPT_DIR}/config/kitty" "$HOME/.config/kitty"
    create_symlink "${SCRIPT_DIR}/config/gitconfig" "$HOME/.gitconfig"
    
    print_success "Symlinks created successfully"
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
        "pipx"
        "tmux"
        "vim"
        "tldr"
        "gh"
    )
    
    for package in "${packages[@]}"; do
        brew_install_if_missing "${package}" "formula"
    done
    
    print_success "Homebrew packages installed successfully"
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
        "todoist"
        "claude"
        "adobe-creative-cloud"
        "google-chrome"
        "rectangle"
        "hammerspoon"
        "notion"
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
# AstroNvim Installation
# ───────────────────────────────────────────────────

install_astronvim() {
    print_info "Installing AstroNvim"
    
    local nvim_config_dir="$HOME/.config/nvim"
    
    # Backup existing Neovim configuration
    if [[ -d "${nvim_config_dir}" ]]; then
        if [[ "${FORCE_REINSTALL}" == "true" ]] || confirm_action "Existing Neovim config found. Backup and replace?"; then
            backup_directory "${nvim_config_dir}"
            rm -rf "${nvim_config_dir}"
        else
            print_info "Keeping existing Neovim configuration"
            return 0
        fi
    fi
    
    # Install AstroNvim
    print_info "Cloning AstroNvim repository"
    if ! git clone --depth 1 https://github.com/AstroNvim/template "${nvim_config_dir}"; then
        print_warning "Failed to clone AstroNvim - Neovim setup incomplete"
        return 1
    fi
    
    # Remove the template's .git directory to make it your own
    rm -rf "${nvim_config_dir}/.git"
    
    print_success "AstroNvim installed successfully"
}

setup_astronvim_config() {
    print_info "Setting up AstroNvim configuration"
    
    local nvim_config_dir="$HOME/.config/nvim"
    local lua_dir="${nvim_config_dir}/lua"
    
    # Create lua directory if it doesn't exist
    mkdir -p "${lua_dir}"
    mkdir -p "${lua_dir}/plugins"
    
    # Link polish.lua and user.lua from dotfiles
    create_symlink "${SCRIPT_DIR}/config/nvim/polish.lua" "${lua_dir}/polish.lua" true
    create_symlink "${SCRIPT_DIR}/config/nvim/user.lua" "${lua_dir}/plugins/user.lua" true
    
    print_success "AstroNvim configuration setup complete"
}

setup_astronvim() {
    install_astronvim
    setup_astronvim_config
    
    print_info "AstroNvim setup complete. Run 'nvim' to finish installation."
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
    install_homebrew
    
    # Update Homebrew
    print_info "Updating Homebrew"
    brew update || print_warning "Failed to update Homebrew"
    
    # Install packages
    install_brew_list
    install_brew_casks
    install_brew_fonts
    
    # Install Neovim dependencies
    install_nvim_deps
    
    # Setup configurations
    link_symlinks
    setup_tmux_plugins || print_warning "Tmux plugin setup failed - continuing"
    setup_base16 || print_warning "Base16 setup failed - continuing"
    setup_hammerspoon
    setup_git_ssh
    
    # Complete basic setup
    post_brew_install_setup
    
    # Setup AstroNvim
    setup_astronvim || print_warning "AstroNvim setup failed - continuing"
    
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
    setup_astronvim || print_warning "AstroNvim setup failed - continuing"
    
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
    print_info "Changing default shell to homebrew bash"
    
    local bash_path="/opt/homebrew/bin/bash"
    
    # Check if homebrew bash exists
    if [[ ! -f "${bash_path}" ]]; then
        print_warning "Homebrew bash not found at ${bash_path}. Skipping shell change."
        return 1
    fi
    
    # Check if bash is already in /etc/shells
    if ! grep -q "${bash_path}" /etc/shells; then
        print_info "Adding homebrew bash to /etc/shells"
        echo "${bash_path}" | sudo tee -a /etc/shells > /dev/null
    fi
    
    # Change the user's default shell
    local current_shell="$(dscl . -read /Users/$(whoami) UserShell | cut -d' ' -f2)"
    if [[ "${current_shell}" != "${bash_path}" ]]; then
        print_info "Changing default shell from ${current_shell} to ${bash_path}"
        chsh -s "${bash_path}" || print_warning "Failed to change default shell. You may need to run 'chsh -s ${bash_path}' manually."
        print_success "Default shell changed to homebrew bash"
    else
        print_debug "Default shell is already set to homebrew bash"
    fi
}

# ───────────────────────────────────────────────────
# Final Instructions
# ───────────────────────────────────────────────────

show_final_instructions() {
    if supports_color; then
        echo -e "\n\e[1;36m╔══════════════════════════════════════════════════════════════════════════════╗\e[0m"
        echo -e "\e[1;36m║                            SETUP COMPLETE!                                   ║\e[0m"
        echo -e "\e[1;36m╚══════════════════════════════════════════════════════════════════════════════╝\e[0m"
        echo -e "\n\e[1;33mNext Steps:\e[0m"
        echo -e "\n\e[1;34m1. Restart your terminal or run:\e[0m"
        echo -e "   \e[32msource ~/.bash_profile\e[0m"
        echo -e "\n\e[1;34m2. Set up language environments:\e[0m"
        echo -e "   \e[32m./post-setup.sh\e[0m"
        echo -e "\n\e[1;34m3. Configure Claude Code:\e[0m"
        echo -e "   \e[32mclaude auth login\e[0m"
        echo -e "\n\e[1;34m4. Launch applications:\e[0m"
        echo -e "   \e[32m• Hammerspoon - Grant accessibility permissions\e[0m"
        echo -e "   \e[32m• Kitty - Set as default terminal\e[0m"
        echo -e "   \e[32m• Run 'nvim' to complete AstroNvim setup\e[0m"
        echo -e "\n\e[1;35mEnjoy your new development environment! 🚀\e[0m\n"
    else
        echo ""
        echo "=============================================================================="
        echo "                           SETUP COMPLETE!"
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
        echo "3. Configure Claude Code:"
        echo "   claude auth login"
        echo ""
        echo "4. Launch applications:"
        echo "   • Hammerspoon - Grant accessibility permissions"
        echo "   • Kitty - Set as default terminal"
        echo "   • Run 'nvim' to complete AstroNvim setup"
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

