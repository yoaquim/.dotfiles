#!/bin/bash

# ───────────────────────────────────────────────────
# AstroNvim Setup Script
# ───────────────────────────────────────────────────
# This script must be run AFTER SSH keys are configured
# because AstroNvim clone uses SSH (git@github.com)
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

set -uo pipefail

# Global variables
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
OS="$(uname -s)"
FORCE_REINSTALL="${FORCE_REINSTALL:-false}"

# ───────────────────────────────────────────────────
# Logging Functions
# ───────────────────────────────────────────────────

supports_color() {
    return 0
}

log() {
    local level="${1}"
    local message="${2}"

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

print_info() { log "INFO" "${1}"; }
print_success() { log "SUCCESS" "${1}"; }
print_error() { log "ERROR" "${1}"; }
print_warning() { log "WARNING" "${1}"; }

# ───────────────────────────────────────────────────
# Error Handling Functions
# ───────────────────────────────────────────────────

error_exit() {
    local message="${1:-"Unknown error occurred"}"
    print_error "${message}"
    exit 1
}

check_os() {
    if [[ "${OS}" != "Darwin" ]]; then
        error_exit "This script is designed for macOS only. Current OS: ${OS}"
    fi
}

# ───────────────────────────────────────────────────
# SSH Key Check
# ───────────────────────────────────────────────────

check_ssh_keys() {
    print_info "Checking for SSH keys required for GitHub access"

    local ssh_private_key="$HOME/.ssh/git"
    local ssh_public_key="$HOME/.ssh/git.pub"
    local missing_keys=()

    if [[ ! -f "${ssh_private_key}" ]]; then
        missing_keys+=("${ssh_private_key}")
    fi

    if [[ ! -f "${ssh_public_key}" ]]; then
        missing_keys+=("${ssh_public_key}")
    fi

    if [[ ${#missing_keys[@]} -gt 0 ]]; then
        print_error "SSH keys not found. AstroNvim setup requires SSH access to GitHub."
        echo ""
        echo "Missing files:"
        for key in "${missing_keys[@]}"; do
            echo "  - ${key}"
        done
        echo ""
        echo "To set up SSH keys:"
        echo "  1. Generate keys: ssh-keygen -t ed25519 -f ~/.ssh/git -C \"your_email@example.com\""
        echo "  2. Add public key to GitHub: https://github.com/settings/keys"
        echo "  3. Start ssh-agent: eval \"\$(ssh-agent -s)\""
        echo "  4. Add key to agent: ssh-add ~/.ssh/git"
        echo "  5. Test connection: ssh -T git@github.com"
        echo ""
        echo "After setting up SSH keys, run this script again:"
        echo "  bash ./setup-astronvim.sh"
        exit 1
    fi

    print_success "SSH keys found"

    # Test SSH connection to GitHub
    print_info "Testing SSH connection to GitHub"
    if ssh -T git@github.com 2>&1 | grep -q "successfully authenticated"; then
        print_success "SSH connection to GitHub verified"
    else
        print_warning "Could not verify SSH connection to GitHub"
        print_info "Make sure your SSH key is added to your GitHub account"
        print_info "You can test manually with: ssh -T git@github.com"

        # Ask user if they want to continue
        if [[ "${FORCE_REINSTALL}" != "true" ]]; then
            printf "\n\033[1;33m[CONFIRM]\033[0m Continue anyway? (y/N): "
            read -r response
            if [[ ! "${response}" =~ ^[Yy]$ ]]; then
                print_info "Exiting. Please verify your SSH setup and try again."
                exit 0
            fi
        fi
    fi
}

# ───────────────────────────────────────────────────
# Utility Functions
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

    if [[ "${FORCE_REINSTALL}" == "true" ]]; then
        return 0
    fi

    printf "\n\033[1;33m[CONFIRM]\033[0m %s (y/N): " "${message}"
    read -r response

    if [[ "${response}" =~ ^[Yy]$ ]]; then
        return 0
    else
        return 1
    fi
}

# ───────────────────────────────────────────────────
# AstroNvim Compatibility Check
# ───────────────────────────────────────────────────

check_astronvim_compatibility() {
    print_info "Checking AstroNvim compatibility with language environments"

    # Check Node.js availability
    if command -v node &> /dev/null; then
        local node_version="$(node --version)"
        print_success "Node.js ${node_version} is available for AstroNvim"
    else
        print_warning "Node.js not available. Some AstroNvim features (LSP, formatters) may not work."
        print_info "Run post-setup.sh to install Node.js via nvm"
    fi

    # Check Python availability
    if command -v python &> /dev/null; then
        local python_version="$(python --version)"
        print_success "Python ${python_version} is available for AstroNvim"
    else
        print_warning "Python not available. Some AstroNvim features may not work."
        print_info "Run post-setup.sh to install Python via pyenv"
    fi

    # Check Neovim availability
    if command -v nvim &> /dev/null; then
        local nvim_version="$(nvim --version | head -1)"
        print_success "Neovim found: ${nvim_version}"
    else
        print_error "Neovim not found. Please run install.sh first."
        exit 1
    fi

    print_info "AstroNvim compatibility check complete"
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
        print_error "Failed to clone AstroNvim"
        print_info "This may be due to SSH key issues. Please verify:"
        print_info "  1. Your SSH keys are set up: ls -la ~/.ssh/git*"
        print_info "  2. SSH agent is running: ssh-add -l"
        print_info "  3. GitHub connection works: ssh -T git@github.com"
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

    # Check if AstroNvim was installed
    if [[ ! -d "${nvim_config_dir}" ]]; then
        print_warning "AstroNvim directory not found. Skipping config setup."
        return 1
    fi

    # Create lua directory if it doesn't exist
    mkdir -p "${lua_dir}"
    mkdir -p "${lua_dir}/plugins"

    # Link polish.lua and user.lua from dotfiles
    create_symlink "${SCRIPT_DIR}/config/nvim/polish.lua" "${lua_dir}/polish.lua" true
    create_symlink "${SCRIPT_DIR}/config/nvim/user.lua" "${lua_dir}/plugins/user.lua" true

    print_success "AstroNvim configuration setup complete"
}

setup_astronvim() {
    install_astronvim && setup_astronvim_config

    if [[ $? -eq 0 ]]; then
        print_info "AstroNvim setup complete. Run 'nvim' to finish plugin installation."
        return 0
    else
        return 1
    fi
}

# ───────────────────────────────────────────────────
# Final Instructions
# ───────────────────────────────────────────────────

show_final_instructions() {
    if supports_color; then
        printf "\n\033[1;36m╔══════════════════════════════════════════════════════════════════════════════╗\033[0m\n"
        printf "\033[1;36m║                      ASTRONVIM SETUP COMPLETE!                               ║\033[0m\n"
        printf "\033[1;36m╚══════════════════════════════════════════════════════════════════════════════╝\033[0m\n"
        printf "\n\033[1;33mNext Steps:\033[0m\n"
        printf "\n\033[1;34m1. Launch Neovim to complete plugin installation:\033[0m\n"
        printf "   \033[32mnvim\033[0m\n"
        printf "\n\033[1;34m2. Inside Neovim, wait for plugins to install, then:\033[0m\n"
        printf "   \033[32m:Mason\033[0m  # Verify language servers\n"
        printf "   \033[32m:Copilot auth\033[0m  # (Optional) Set up GitHub Copilot\n"
        printf "\n\033[1;35mYour Neovim configuration is ready!\033[0m\n\n"
    else
        echo ""
        echo "=============================================================================="
        echo "                      ASTRONVIM SETUP COMPLETE!"
        echo "=============================================================================="
        echo ""
        echo "Next Steps:"
        echo ""
        echo "1. Launch Neovim to complete plugin installation:"
        echo "   nvim"
        echo ""
        echo "2. Inside Neovim, wait for plugins to install, then:"
        echo "   :Mason  # Verify language servers"
        echo "   :Copilot auth  # (Optional) Set up GitHub Copilot"
        echo ""
        echo "Your Neovim configuration is ready!"
        echo ""
    fi
}

# ───────────────────────────────────────────────────
# Usage
# ───────────────────────────────────────────────────

show_usage() {
    cat << EOF
Usage: $0 [OPTIONS]

AstroNvim Setup Script - Installs and configures AstroNvim for Neovim

This script requires SSH keys to be configured for GitHub access.
Required files: ~/.ssh/git and ~/.ssh/git.pub

Options:
    -h, --help          Show this help message
    -f, --force         Force reinstall without prompts

Prerequisites:
    1. Run install.sh first (installs Neovim and dependencies)
    2. Run post-setup.sh (optional but recommended - installs Node.js/Python)
    3. Configure SSH keys for GitHub

Examples:
    $0                  # Normal installation
    $0 --force          # Force reinstall

EOF
}

# ───────────────────────────────────────────────────
# Argument Parsing
# ───────────────────────────────────────────────────

parse_arguments() {
    while [[ $# -gt 0 ]]; do
        case $1 in
            -h|--help)
                show_usage
                exit 0
                ;;
            -f|--force)
                FORCE_REINSTALL=true
                shift
                ;;
            *)
                print_error "Unknown option: $1"
                show_usage
                exit 1
                ;;
        esac
    done
}

# ───────────────────────────────────────────────────
# Main Execution
# ───────────────────────────────────────────────────

main() {
    print_info "Starting AstroNvim setup"

    # Validate environment
    check_os

    # Check for SSH keys (critical for git clone)
    check_ssh_keys

    # Check language environment compatibility
    check_astronvim_compatibility

    # Setup AstroNvim
    if setup_astronvim; then
        print_success "AstroNvim setup complete"
        show_final_instructions
    else
        print_error "AstroNvim setup failed"
        exit 1
    fi
}

# Run main function
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    parse_arguments "$@"
    main
fi
