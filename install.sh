#!/usr/bin/env bash

# ───────────────────────────────────────────────────
# Dotfiles Installation Script
# ───────────────────────────────────────────────────

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
            brew install "${package}" || error_exit "Failed to install package '${package}'"
            ;;
        "cask")
            if brew_cask_exists "${package}"; then
                print_debug "Cask '${package}' already installed"
                return 0
            fi
            print_info "Installing cask '${package}'"
            brew install --cask "${package}" || error_exit "Failed to install cask '${package}'"
            ;;
        *)
            error_exit "Invalid package type: ${package_type}"
            ;;
    esac
    
    print_success "Successfully installed '${package}'"
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
        git clone https://github.com/tmux-plugins/tpm "${tpm_dir}" || error_exit "Failed to clone tpm"
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
    
    git clone https://github.com/chriskempson/base16-shell.git "${base16_dir}" || error_exit "Failed to clone base16-shell"
    
    print_success "Base16 shell themes installed successfully"
}

# ───────────────────────────────────────────────────
# Hammerspoon Setup
# ───────────────────────────────────────────────────

setup_hammerspoon() {
    print_info "Setting up Hammerspoon configuration"
    
    # Link hammerspoon configuration directory
    local hammerspoon_dir="$HOME/.config/hammerspoon"
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
        "nvm"
        "pyenv"
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
        "slack"
        "kitty"
        "todoist"
        "claude"
        "adobe-creative-cloud"
        "google-chrome"
        "rectangle"
        "hammerspoon"
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
    print_info "Setting up language environments"
    
    # Setup Node.js via nvm
    setup_node
    
    # Setup Python via pyenv
    setup_python
    
    print_success "Language environments setup complete"
}

setup_node() {
    print_info "Setting up Node.js prerequisites"
    
    # Create NVM directory
    export NVM_DIR="$HOME/.nvm"
    mkdir -p "$NVM_DIR"
    
    print_success "Node.js prerequisites installed (nvm available via Homebrew)"
}

setup_python() {
    print_info "Setting up Python prerequisites"
    
    print_success "Python prerequisites installed (pyenv available via Homebrew)"
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
    git clone --depth 1 https://github.com/AstroNvim/template "${nvim_config_dir}" || error_exit "Failed to clone AstroNvim"
    
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
    
    # Install Claude Code via npm
    if command -v npm &> /dev/null; then
        print_info "Installing Claude Code via npm"
        npm install -g @anthropic-ai/claude-code || error_exit "Failed to install Claude Code via npm"
    else
        print_error "npm not found. Please install Node.js first or run full installation."
        return 1
    fi
    
    # Verify installation
    if command -v claude &> /dev/null; then
        local version
        version=$(claude --version 2>/dev/null || echo "unknown")
        print_success "Claude Code installed successfully (version: ${version})"
    else
        error_exit "Claude Code installation verification failed"
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
        "$HOME/.config/hammerspoon"
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
    setup_tmux_plugins
    setup_base16
    setup_hammerspoon
    
    # Setup language environments
    post_brew_install_setup
    
    # Setup AstroNvim
    setup_astronvim
    
    # Install and setup Claude Code
    install_claude_code
    setup_claude_code
    
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
    setup_tmux_plugins
    setup_base16
    setup_hammerspoon
    setup_astronvim
    
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
# Final Instructions
# ───────────────────────────────────────────────────

show_final_instructions() {
    if supports_color; then
        echo -e "\n\e[1;36m╔══════════════════════════════════════════════════════════════════════════════╗\e[0m"
        echo -e "\e[1;36m║                           SETUP COMPLETE!                                   ║\e[0m"
        echo -e "\e[1;36m╚══════════════════════════════════════════════════════════════════════════════╝\e[0m"
        echo -e "\n\e[1;33mNext Steps:\e[0m"
        echo -e "\n\e[1;34m1. Restart your terminal or run:\e[0m"
        echo -e "   \e[32msource ~/.bash_profile\e[0m"
        echo -e "\n\e[1;34m2. Set up Node.js:\e[0m"
        echo -e "   \e[32m# Load nvm\e[0m"
        echo -e "   \e[32msource /opt/homebrew/opt/nvm/nvm.sh\e[0m"
        echo -e "   \e[32m# Install latest LTS Node.js\e[0m"
        echo -e "   \e[32mnvm install --lts\e[0m"
        echo -e "   \e[32mnvm alias default node\e[0m"
        echo -e "\n\e[1;34m3. Set up Python:\e[0m"
        echo -e "   \e[32m# Install latest Python\e[0m"
        echo -e "   \e[32mpyenv install 3.12.0  # or latest version\e[0m"
        echo -e "   \e[32mpyenv global 3.12.0\e[0m"
        echo -e "\n\e[1;34m4. Configure Claude Code:\e[0m"
        echo -e "   \e[32mclaude auth login\e[0m"
        echo -e "\n\e[1;34m5. Launch applications:\e[0m"
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
        echo "2. Set up Node.js:"
        echo "   # Load nvm"
        echo "   source /opt/homebrew/opt/nvm/nvm.sh"
        echo "   # Install latest LTS Node.js"
        echo "   nvm install --lts"
        echo "   nvm alias default node"
        echo ""
        echo "3. Set up Python:"
        echo "   # Install latest Python"
        echo "   pyenv install 3.12.0  # or latest version"
        echo "   pyenv global 3.12.0"
        echo ""
        echo "4. Configure Claude Code:"
        echo "   claude auth login"
        echo ""
        echo "5. Launch applications:"
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
    
    # Show final setup instructions
    show_final_instructions
}

# Run main function with all arguments
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi

