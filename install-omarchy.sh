#!/bin/bash

# ───────────────────────────────────────────────────
# OMARCHY Linux Dotfiles Installation Script
# ───────────────────────────────────────────────────

if [[ -z "${BASH_VERSION}" ]]; then
    echo "Switching to bash..."
    exec /usr/bin/bash "$0" "$@"
fi

set -uo pipefail

# Global variables
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
OS="$(uname -s)"
FORCE_REINSTALL=false

# ───────────────────────────────────────────────────
# Logging Functions
# ───────────────────────────────────────────────────

log() {
    local level="${1}"
    local message="${2}"

    if command -v tput &> /dev/null; then
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
            "INFO") printf "\n[INFO] %s...\n" "${message}" ;;
            "SUCCESS") printf "\n[SUCCESS] %s\n" "${message}" ;;
            "ERROR") printf "\n[ERROR] %s\n" "${message}" >&2 ;;
            "WARNING") printf "\n[WARNING] %s\n" "${message}" ;;
        esac
    fi
}

print_info() { log "INFO" "${1}"; }
print_success() { log "SUCCESS" "${1}"; }
print_error() { log "ERROR" "${1}"; }
print_warning() { log "WARNING" "${1}"; }

error_exit() {
    print_error "${1:-Unknown error occurred}"
    exit 1
}

# ───────────────────────────────────────────────────
# Environment Validation
# ───────────────────────────────────────────────────

validate_environment() {
    print_info "Validating environment"

    if [[ "${OS}" != "Linux" ]]; then
        error_exit "This script is for Linux only. Current OS: ${OS}"
    fi

    if [[ ! -f /etc/arch-release ]]; then
        print_warning "This script is designed for Arch Linux (OMARCHY)"
        print_warning "Detected different Linux distribution"
        read -rp "Continue anyway? (y/N): " response
        if [[ ! "${response}" =~ ^[Yy]$ ]]; then
            exit 0
        fi
    fi

    # Check for required commands
    if ! command -v curl &> /dev/null; then
        error_exit "curl is required but not installed"
    fi

    if ! command -v git &> /dev/null; then
        error_exit "git is required but not installed"
    fi

    if ! command -v sudo &> /dev/null; then
        error_exit "sudo is required but not installed"
    fi

    print_success "Environment validation complete"
}

# ───────────────────────────────────────────────────
# yay Installation (AUR Helper)
# ───────────────────────────────────────────────────

install_yay() {
    if command -v yay &> /dev/null; then
        print_info "yay already installed"
        return 0
    fi

    print_info "Installing yay (AUR helper)"

    # Install base-devel if not present
    if ! pacman -Qg base-devel &> /dev/null; then
        print_info "Installing base-devel"
        sudo pacman -S --needed --noconfirm base-devel || print_warning "Failed to install base-devel"
    fi

    local yay_dir="$HOME/.cache/yay-install"
    rm -rf "${yay_dir}"
    mkdir -p "${yay_dir}"

    git clone https://aur.archlinux.org/yay.git "${yay_dir}" || error_exit "Failed to clone yay repository"

    cd "${yay_dir}" || error_exit "Failed to enter yay directory"
    makepkg -si --noconfirm || error_exit "Failed to install yay"
    cd - > /dev/null || true

    rm -rf "${yay_dir}"

    if command -v yay &> /dev/null; then
        print_success "yay installed successfully"
    else
        error_exit "yay installation failed"
    fi
}

# ───────────────────────────────────────────────────
# Package Installation
# ───────────────────────────────────────────────────

install_packages() {
    print_info "Installing packages"

    # Update system first
    print_info "Updating system packages"
    sudo pacman -Syu --noconfirm || print_warning "System update had issues"

    # Core development tools (pacman)
    local core_packages=(
        "git"
        "neovim"
        "tmux"
        "bash"
        "bash-completion"
        "fzf"
        "ripgrep"
        "fd"
        "bat"
        "git-delta"
        "jq"
        "wget"
        "curl"
        "rsync"
        "unzip"
        "htop"
        "lazygit"
        "wl-clipboard"  # Wayland clipboard
        "fuse3"         # For rclone mounting
        "github-cli"    # gh
        "python"
        "go"
        "rust"
        "direnv"
        "tree-sitter"
    )

    print_info "Installing core packages via pacman"
    for package in "${core_packages[@]}"; do
        if pacman -Q "${package}" &> /dev/null; then
            print_info "${package} already installed"
        else
            print_info "Installing ${package}"
            sudo pacman -S --needed --noconfirm "${package}" || print_warning "Failed to install ${package}"
        fi
    done

    # Nice-to-have CLI tools (may be AUR)
    local nice_packages=(
        "bottom"    # System monitor
        "gdu"       # Disk usage
        "eza"       # Modern ls
        "zoxide"    # Smart cd
    )

    print_info "Installing nice-to-have packages"
    for package in "${nice_packages[@]}"; do
        if pacman -Q "${package}" &> /dev/null || yay -Q "${package}" &> /dev/null; then
            print_info "${package} already installed"
        else
            print_info "Installing ${package}"
            # Try pacman first, fall back to yay
            sudo pacman -S --needed --noconfirm "${package}" 2>/dev/null || \
                yay -S --needed --noconfirm "${package}" || \
                print_warning "Failed to install ${package}"
        fi
    done

    # AUR packages (require yay)
    local aur_packages=(
        "kitty"         # Terminal emulator (may be in AUR or community)
        "aws-cli-v2"    # AWS CLI
        "rclone"        # Cloud storage
        "tldr"          # Simplified man pages
    )

    print_info "Installing AUR packages via yay"
    for package in "${aur_packages[@]}"; do
        if yay -Q "${package}" &> /dev/null || pacman -Q "${package}" &> /dev/null; then
            print_info "${package} already installed"
        else
            print_info "Installing ${package}"
            yay -S --needed --noconfirm "${package}" || print_warning "Failed to install ${package}"
        fi
    done

    # Nerd Fonts
    local fonts=(
        "ttf-cascadia-code-nerd"
        "ttf-fira-code-nerd"
        "ttf-jetbrains-mono-nerd"
        "ttf-hack-nerd"
        "ttf-iosevka-nerd"
        "ttf-meslo-nerd"
    )

    print_info "Installing Nerd Fonts"
    for font in "${fonts[@]}"; do
        if pacman -Q "${font}" &> /dev/null || yay -Q "${font}" &> /dev/null; then
            print_info "${font} already installed"
        else
            print_info "Installing ${font}"
            yay -S --needed --noconfirm "${font}" || print_warning "Failed to install ${font}"
        fi
    done

    print_success "Package installation complete"
}

# ───────────────────────────────────────────────────
# Utility Functions
# ───────────────────────────────────────────────────

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

# ───────────────────────────────────────────────────
# Configuration Setup
# ───────────────────────────────────────────────────

setup_bash_config() {
    print_info "Setting up bash configuration"

    # Symlink entire bash config directory
    create_symlink "${SCRIPT_DIR}/config/bash" "$HOME/.config/bash" true

    # Create bash profile symlink
    create_symlink "${SCRIPT_DIR}/config/bash/bash_profile" "$HOME/.bash_profile" true

    # Source bash profile in .bashrc if not already present
    if [[ ! -f "$HOME/.bashrc" ]]; then
        echo "source ~/.bash_profile" > "$HOME/.bashrc"
        print_success "Created .bashrc"
    elif ! grep -q "source ~/.bash_profile" "$HOME/.bashrc"; then
        echo "source ~/.bash_profile" >> "$HOME/.bashrc"
        print_success "Updated .bashrc to source .bash_profile"
    fi

    print_success "Bash configuration complete"
}

setup_git_config() {
    print_info "Setting up git configuration"

    create_symlink "${SCRIPT_DIR}/config/gitconfig" "$HOME/.gitconfig" true

    print_success "Git configuration complete"
}

setup_tmux_config() {
    print_info "Setting up tmux configuration"

    create_symlink "${SCRIPT_DIR}/config/tmux/tmux.conf" "$HOME/.config/tmux/tmux.conf" true

    # Install TPM (Tmux Plugin Manager) if not present
    local tpm_dir="$HOME/.tmux/plugins/tpm"
    if [[ ! -d "${tpm_dir}" ]]; then
        print_info "Installing Tmux Plugin Manager"
        git clone https://github.com/tmux-plugins/tpm "${tpm_dir}" || print_warning "Failed to install TPM"
    fi

    print_success "Tmux configuration complete"
}

setup_kitty_config() {
    print_info "Setting up kitty configuration"

    create_symlink "${SCRIPT_DIR}/config/kitty/kitty.conf" "$HOME/.config/kitty/kitty.conf" true

    # Create kitty-shell.conf for Linux
    local kitty_shell_conf="$HOME/.config/kitty/kitty-shell.conf"
    if [[ ! -f "${kitty_shell_conf}" ]]; then
        echo "shell /usr/bin/bash" > "${kitty_shell_conf}"
        print_success "Created kitty-shell.conf with Linux shell path"
    fi

    print_success "Kitty configuration complete"
}

# ───────────────────────────────────────────────────
# Main Installation Flow
# ───────────────────────────────────────────────────

main() {
    print_info "Starting OMARCHY dotfiles installation"
    echo ""

    validate_environment
    install_yay
    install_packages

    echo ""
    setup_bash_config
    setup_git_config
    setup_tmux_config
    setup_kitty_config

    echo ""
    print_success "Installation complete!"
    echo ""
    print_info "Next step: Run 'source ~/.bash_profile' to reload bash configuration"
    echo ""
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
