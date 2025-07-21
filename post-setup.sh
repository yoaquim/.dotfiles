#!/bin/bash

# ───────────────────────────────────────────────────
# Post-Setup Script for Language Environments
# ───────────────────────────────────────────────────

set -euo pipefail

# Global variables
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
OS="$(uname -s)"

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
        
        # Add nvm to bash profile if not already present
        local bash_profile="$HOME/.bash_profile"
        if [[ -f "${bash_profile}" ]] && ! grep -q "NVM_DIR" "${bash_profile}"; then
            print_info "Adding nvm configuration to bash profile"
            cat >> "${bash_profile}" << 'EOF'

# NVM Configuration
export NVM_DIR="$HOME/.nvm"
[ -s "/opt/homebrew/opt/nvm/nvm.sh" ] && \. "/opt/homebrew/opt/nvm/nvm.sh"
[ -s "/opt/homebrew/opt/nvm/etc/bash_completion.d/nvm" ] && \. "/opt/homebrew/opt/nvm/etc/bash_completion.d/nvm"
EOF
            print_success "nvm configuration added to bash profile"
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
        
        # Add pyenv to bash profile if not already present
        local bash_profile="$HOME/.bash_profile"
        if [[ -f "${bash_profile}" ]] && ! grep -q "pyenv init" "${bash_profile}"; then
            print_info "Adding pyenv configuration to bash profile"
            cat >> "${bash_profile}" << 'EOF'

# Pyenv Configuration
export PATH="$HOME/.pyenv/bin:$PATH"
eval "$(pyenv init -)"
eval "$(pyenv virtualenv-init -)"
EOF
            print_success "pyenv configuration added to bash profile"
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
# Final Instructions
# ───────────────────────────────────────────────────

show_final_instructions() {
    if supports_color; then
        echo -e "\n\e[1;36m╔══════════════════════════════════════════════════════════════════════════════╗\e[0m"
        echo -e "\e[1;36m║                     LANGUAGE SETUP COMPLETE!                                ║\e[0m"
        echo -e "\e[1;36m╚══════════════════════════════════════════════════════════════════════════════╝\e[0m"
        echo -e "\n\e[1;33mNext Steps:\e[0m"
        echo -e "\n\e[1;34m1. Restart your terminal or run:\e[0m"
        echo -e "   \e[32msource ~/.bash_profile\e[0m"
        echo -e "\n\e[1;34m2. Verify installations:\e[0m"
        echo -e "   \e[32mnode --version && npm --version\e[0m"
        echo -e "   \e[32mpython --version && pip --version\e[0m"
        echo -e "\n\e[1;34m3. Configure Claude Code (if not done already):\e[0m"
        echo -e "   \e[32mclaude auth login\e[0m"
        echo -e "\n\e[1;34m4. You can now safely run nvim to complete AstroNvim setup\e[0m"
        echo -e "\n\e[1;35mEnjoy your complete development environment! 🚀\e[0m\n"
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
        echo "3. Configure Claude Code (if not done already):"
        echo "   claude auth login"
        echo ""
        echo "4. You can now safely run nvim to complete AstroNvim setup"
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
    
    # Check AstroNvim compatibility
    check_astronvim_compatibility
    
    print_success "Language environment setup complete"
    
    # Show final setup instructions
    show_final_instructions
}

# Ensure we're running in bash, not zsh
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

# Run main function
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi