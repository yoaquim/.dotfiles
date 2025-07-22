#!/bin/bash

# ───────────────────────────────────────────────────
# Post-Setup Script for Language Environments
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

# Note: Not using set -e because we want to handle errors gracefully
set -uo pipefail

# Global variables
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
OS="$(uname -s)"

# ───────────────────────────────────────────────────
# Logging Functions
# ───────────────────────────────────────────────────

# Check if terminal supports colors - ALWAYS return true for bash
supports_color() {
    # Always enable colors when running in bash
    return 0
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

# ───────────────────────────────────────────────────
# Language Environment Setup
# ───────────────────────────────────────────────────

install_language_managers() {
    print_info "Installing language managers via Homebrew"
    
    # Install nvm and pyenv if not already installed
    if ! command -v brew &> /dev/null; then
        error_exit "Homebrew not found. Please run the main install script first."
    fi
    
    # Install nvm if not present
    if ! brew list --formula nvm &> /dev/null; then
        print_info "Installing nvm"
        if ! brew install nvm; then
            print_warning "Failed to install nvm - continuing without Node.js setup"
            return 1
        fi
    fi
    
    # Install pyenv if not present
    if ! brew list --formula pyenv &> /dev/null; then
        print_info "Installing pyenv"
        if ! brew install pyenv; then
            print_warning "Failed to install pyenv - continuing without Python setup"
            return 1
        fi
    fi
    
    print_success "Language managers installed"
}

setup_nvm() {
    print_info "Setting up Node.js with nvm"
    
    # Create NVM directory
    export NVM_DIR="$HOME/.nvm"
    mkdir -p "$NVM_DIR"
    
    # Load nvm from homebrew for this script session
    if [[ -s "/opt/homebrew/opt/nvm/nvm.sh" ]]; then
        source "/opt/homebrew/opt/nvm/nvm.sh"
        
        # Install latest LTS Node.js
        print_info "Installing latest LTS Node.js"
        nvm install --lts
        nvm alias default node
        nvm use default
        
        # Verify installation
        local node_version="$(node --version 2>/dev/null || echo "unknown")"
        local npm_version="$(npm --version 2>/dev/null || echo "unknown")"
        
        print_success "Node.js ${node_version} and npm ${npm_version} installed via nvm"
        
        # Install Claude Code now that npm is available
        install_claude_code
        
        # Add nvm to local bash profile if not already present
        local bash_profile_local="$HOME/.config/bash/bash_profile_local"
        
        # Create bash_profile_local if it doesn't exist
        if [[ ! -f "${bash_profile_local}" ]]; then
            mkdir -p "$(dirname "${bash_profile_local}")"
            touch "${bash_profile_local}"
            print_info "Created bash_profile_local"
        fi
        
        if ! grep -q "NVM_DIR" "${bash_profile_local}"; then
            print_info "Adding nvm configuration to local bash profile"
            cat >> "${bash_profile_local}" << 'EOF'

# NVM Configuration
export NVM_DIR="$HOME/.nvm"
[ -s "/opt/homebrew/opt/nvm/nvm.sh" ] && \. "/opt/homebrew/opt/nvm/nvm.sh"
[ -s "/opt/homebrew/opt/nvm/etc/bash_completion.d/nvm" ] && \. "/opt/homebrew/opt/nvm/etc/bash_completion.d/nvm"
EOF
            print_success "nvm configuration added to local bash profile"
        else
            print_info "nvm configuration already exists in bash_profile_local"
        fi
        
    else
        print_warning "nvm script not found. Node.js setup incomplete."
        return 1
    fi
}

setup_pyenv() {
    print_info "Setting up Python with pyenv"
    
    # Add pyenv to PATH for this session
    export PATH="$HOME/.pyenv/bin:$PATH"
    
    # Initialize pyenv
    if command -v pyenv &> /dev/null; then
        eval "$(pyenv init -)"
        
        # Get the latest stable Python version
        print_info "Fetching latest Python versions"
        local latest_python
        latest_python=$(pyenv install --list | grep -E '^\s*3\.[0-9]+\.[0-9]+$' | tail -1 | xargs)
        
        if [[ -n "${latest_python}" ]]; then
            print_info "Installing Python ${latest_python}"
            pyenv install "${latest_python}" || print_warning "Failed to install Python ${latest_python}"
            pyenv global "${latest_python}" || print_warning "Failed to set Python ${latest_python} as global"
            
            # Verify installation
            local python_version="$(python --version 2>/dev/null || echo "unknown")"
            print_success "Python ${python_version} installed and set as global via pyenv"
        else
            print_warning "Could not determine latest Python version"
        fi
        
        # Add pyenv to local bash profile if not already present
        local bash_profile_local="$HOME/.config/bash/bash_profile_local"
        
        # Create bash_profile_local if it doesn't exist
        if [[ ! -f "${bash_profile_local}" ]]; then
            mkdir -p "$(dirname "${bash_profile_local}")"
            touch "${bash_profile_local}"
            print_info "Created bash_profile_local"
        fi
        
        if ! grep -q "pyenv init" "${bash_profile_local}"; then
            print_info "Adding pyenv configuration to local bash profile"
            cat >> "${bash_profile_local}" << 'EOF'

# Pyenv Configuration
export PATH="$HOME/.pyenv/bin:$PATH"
eval "$(pyenv init -)"
EOF
            print_success "pyenv configuration added to local bash profile"
        else
            print_info "pyenv configuration already exists in bash_profile_local"
        fi
        
    else
        print_warning "pyenv command not found. Python setup incomplete."
        return 1
    fi
}

# ───────────────────────────────────────────────────
# AstroNvim Compatibility Check
# ───────────────────────────────────────────────────

check_astronvim_compatibility() {
    print_info "Checking AstroNvim compatibility with language environments"
    
    # Check if AstroNvim is installed
    local nvim_config_dir="$HOME/.config/nvim"
    if [[ ! -d "${nvim_config_dir}" ]]; then
        print_warning "AstroNvim not found. This is fine - you can install it later."
        return 0
    fi
    
    # Check Node.js availability
    if command -v node &> /dev/null; then
        local node_version="$(node --version)"
        print_success "Node.js ${node_version} is available for AstroNvim"
    else
        print_warning "Node.js not available. Some AstroNvim features may not work."
    fi
    
    # Check Python availability
    if command -v python &> /dev/null; then
        local python_version="$(python --version)"
        print_success "Python ${python_version} is available for AstroNvim"
    else
        print_warning "Python not available. Some AstroNvim features may not work."
    fi
    
    print_info "AstroNvim compatibility check complete"
    print_info "Note: AstroNvim will automatically detect and use the language versions when you run nvim"
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
    
    # Install Claude Code via npm (npm should be available now)
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
        print_warning "npm not found - cannot install Claude Code"
        return 1
    fi
}

# ───────────────────────────────────────────────────
# Claude Code Installation
# ───────────────────────────────────────────────────

install_claude_code() {
    print_info "Installing Claude Code CLI"
    
    if command -v claude &> /dev/null; then
        print_info "Claude Code already installed"
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
        print_warning "npm not found. Cannot install Claude Code"
        return 1
    fi
}

# ───────────────────────────────────────────────────
# Utility Functions (needed for AstroNvim setup)
# ───────────────────────────────────────────────────

backup_directory() {
    local dir="${1}"
    if [[ -d "${dir}" ]]; then
        local backup="${dir}.backup.$(date +%Y%m%d_%H%M%S)"
        print_info "Backing up '${dir}' to '${backup}'"
        mv "${dir}" "${backup}"
        print_success "Backup created at '${backup}'"
    fi
}

create_symlink() {
    local source="${1}"
    local target="${2}"
    local force="${3:-false}"
    
    # Create parent directory if it doesn't exist
    local parent_dir="$(dirname "${target}")"
    if [[ ! -d "${parent_dir}" ]]; then
        mkdir -p "${parent_dir}"
    fi
    
    # Remove existing file/symlink if force is true
    if [[ "${force}" == "true" ]] && [[ -e "${target}" || -L "${target}" ]]; then
        rm -f "${target}"
    fi
    
    # Create symlink if it doesn't exist
    if [[ ! -e "${target}" ]]; then
        ln -s "${source}" "${target}"
        print_success "Created symlink: ${target} -> ${source}"
    else
        print_info "Symlink already exists: ${target}"
    fi
}

confirm_action() {
    local message="${1}"
    local response
    
    if [[ "${FORCE_REINSTALL:-false}" == "true" ]]; then
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
# AstroNvim Installation (moved from install.sh - requires Node.js/npm)
# ───────────────────────────────────────────────────

install_astronvim() {
    print_info "Installing AstroNvim"
    
    local nvim_config_dir="$HOME/.config/nvim"
    
    # Backup existing Neovim configuration
    if [[ -d "${nvim_config_dir}" ]]; then
        if [[ "${FORCE_REINSTALL:-false}" == "true" ]] || confirm_action "Existing Neovim config found. Backup and replace?"; then
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
    
    print_info "AstroNvim setup complete. Run 'nvim' to finish plugin installation."
}

# ───────────────────────────────────────────────────
# Final Instructions
# ───────────────────────────────────────────────────

show_final_instructions() {
    if supports_color; then
        printf "\n\033[1;36m╔══════════════════════════════════════════════════════════════════════════════╗\033[0m\n"
        printf "\033[1;36m║                     LANGUAGE SETUP COMPLETE!                                ║\033[0m\n"
        printf "\033[1;36m╚══════════════════════════════════════════════════════════════════════════════╝\033[0m\n"
        printf "\n\033[1;33mNext Steps:\033[0m\n"
        printf "\n\033[1;34m1. Restart your terminal or run:\033[0m\n"
        printf "   \033[32msource ~/.bash_profile\033[0m\n"
        printf "\n\033[1;34m2. Verify installations:\033[0m\n"
        printf "   \033[32mnode --version && npm --version\033[0m\n"
        printf "   \033[32mpython --version && pip --version\033[0m\n"
        printf "\n\033[1;34m3. Configure Claude Code:\033[0m\n"
        printf "   \033[32mclaude auth login\033[0m\n"
        printf "\n\033[1;34m4. AstroNvim is now set up - run 'nvim' to complete plugin installation\033[0m\n"
        printf "\n\033[1;35mEnjoy your complete development environment! 🚀\033[0m\n\n"
    else
        echo ""
        echo "=============================================================================="
        echo "                     LANGUAGE SETUP COMPLETE!"
        echo "=============================================================================="
        echo ""
        echo "Next Steps:"
        echo ""
        echo "1. Restart your terminal or run:"
        echo "   source ~/.bash_profile"
        echo ""
        echo "2. Verify installations:"
        echo "   node --version && npm --version"
        echo "   python --version && pip --version"
        echo ""
        echo "3. Configure Claude Code:"
        echo "   claude auth login"
        echo ""
        echo "4. AstroNvim is now set up - run 'nvim' to complete plugin installation"
        echo ""
        echo "Enjoy your complete development environment!"
        echo ""
    fi
}

# ───────────────────────────────────────────────────
# Main Execution
# ───────────────────────────────────────────────────

main() {
    print_info "Starting language environment setup"
    
    # Validate environment
    check_os
    
    # Install language managers
    if install_language_managers; then
        # Setup Node.js with nvm
        if command -v brew &> /dev/null && brew list --formula nvm &> /dev/null; then
            setup_nvm || print_warning "Node.js setup failed - continuing without Node.js"
        fi
        
        # Setup Python with pyenv
        if command -v brew &> /dev/null && brew list --formula pyenv &> /dev/null; then
            setup_pyenv || print_warning "Python setup failed - continuing without Python"
        fi
    else
        print_warning "Language manager installation failed - skipping language setup"
    fi
    
    # Setup AstroNvim now that Node.js/npm/Python are available
    setup_astronvim || print_warning "AstroNvim setup failed - continuing"
    
    # Check AstroNvim compatibility
    check_astronvim_compatibility
    
    print_success "Language environment setup complete"
    
    # Show final setup instructions
    show_final_instructions
}

# Bash check already done at top of script

# Run main function
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi