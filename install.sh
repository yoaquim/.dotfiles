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
REBOOT_REQUIRED=false

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
    case "${OS}" in
        "Darwin")
            print_debug "Detected macOS"
            ;;
        "Linux")
            print_debug "Detected Linux"
            ;;
        *)
            error_exit "Unsupported OS: ${OS}. This script supports macOS and Linux only."
            ;;
    esac
}

get_linux_distro() {
    if [[ -f /etc/os-release ]]; then
        source /etc/os-release
        echo "${ID}"
    else
        echo "unknown"
    fi
}

is_fedora() {
    local distro="$(get_linux_distro)"
    [[ "${distro}" == "fedora" ]]
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
    
    # OS-specific validation
    if [[ "${OS}" == "Darwin" ]]; then
        # Check for Xcode Command Line Tools (required for Homebrew on macOS)
        if ! xcode-select -p &> /dev/null; then
            print_warning "Xcode Command Line Tools not found"
            print_info "Installing Xcode Command Line Tools..."
            print_info "You may be prompted to install them - please accept and wait for completion"
            xcode-select --install || print_warning "Failed to trigger Xcode Command Line Tools installation"
            print_info "Please run this script again after installing Xcode Command Line Tools"
            exit 1
        fi
    elif [[ "${OS}" == "Linux" ]]; then
        # Check for Linux-specific requirements
        if is_fedora_atomic; then
            print_info "Detected Fedora Atomic - checking rpm-ostree and flatpak"
            check_command "rpm-ostree"
            check_command "flatpak"
        elif is_fedora; then
            print_info "Detected traditional Fedora - checking dnf"
            check_command "dnf"
        else
            print_warning "Unknown Linux distribution - proceeding with caution"
        fi
        
        # Check for sudo access
        if ! sudo -n true 2>/dev/null; then
            print_info "Note: sudo access required for package installation"
        fi
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
# Package Manager Functions
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
# Linux Package Manager Functions (Fedora Atomic)
# ───────────────────────────────────────────────────

is_fedora_atomic() {
    command -v rpm-ostree &> /dev/null
}

rpm_ostree_package_exists() {
    local package="${1}"
    rpm -q "${package}" &> /dev/null
}

flatpak_package_exists() {
    local package="${1}"
    flatpak list | grep -q "${package}"
}

rpm_ostree_install_if_missing() {
    local package="${1}"
    
    if rpm_ostree_package_exists "${package}"; then
        print_debug "Package '${package}' already installed"
        return 0
    fi
    
    print_info "Installing system package '${package}' (requires reboot)"
    if sudo rpm-ostree install "${package}"; then
        print_success "Successfully queued '${package}' for installation"
        REBOOT_REQUIRED=true
    else
        print_warning "Failed to install package '${package}' - continuing with other packages"
        return 1
    fi
}

flatpak_install_if_missing() {
    local package="${1}"
    local repo="${2:-flathub}"
    
    if flatpak_package_exists "${package}"; then
        print_debug "Flatpak '${package}' already installed"
        return 0
    fi
    
    print_info "Installing Flatpak app '${package}'"
    if flatpak install -y "${repo}" "${package}"; then
        print_success "Successfully installed '${package}'"
    else
        print_warning "Failed to install Flatpak '${package}' - continuing with other packages"
        return 1
    fi
}

install_package_manager() {
    if [[ "${OS}" == "Darwin" ]]; then
        install_homebrew
    elif [[ "${OS}" == "Linux" ]] && is_fedora_atomic; then
        print_info "Using rpm-ostree + Flatpak (Fedora Atomic detected)"
        # Ensure Flathub is enabled
        flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo
        # Update system
        sudo rpm-ostree upgrade
    elif [[ "${OS}" == "Linux" ]] && is_fedora; then
        print_info "Using dnf package manager (Fedora detected)"
        # dnf is pre-installed on Fedora, just update
        sudo dnf update -y
    else
        print_error "Unsupported Linux distribution. Only Fedora and Fedora Atomic are supported."
        return 1
    fi
}

install_package() {
    local package="${1}"
    local macos_name="${2:-$package}"
    local linux_name="${3:-$package}"
    
    if [[ "${OS}" == "Darwin" ]]; then
        brew_install_if_missing "${macos_name}" "formula"
    elif [[ "${OS}" == "Linux" ]] && is_fedora_atomic; then
        rpm_ostree_install_if_missing "${linux_name}"
    elif [[ "${OS}" == "Linux" ]] && is_fedora; then
        dnf_install_if_missing "${linux_name}"
    fi
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
    
    # Link application configurations (cross-platform)
    create_symlink "${SCRIPT_DIR}/config/tmux" "$HOME/.config/tmux"
    create_symlink "${SCRIPT_DIR}/config/kitty" "$HOME/.config/kitty"
    create_symlink "${SCRIPT_DIR}/config/gitconfig" "$HOME/.gitconfig"
    
    # Link OS-specific configurations
    if [[ "${OS}" == "Darwin" ]]; then
        # macOS specific
        setup_macos_symlinks
    elif [[ "${OS}" == "Linux" ]]; then
        # Linux specific  
        setup_linux_symlinks
    fi
    
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

setup_macos_symlinks() {
    print_info "Creating macOS-specific symlinks"
    
    # Hammerspoon automation
    create_symlink "${SCRIPT_DIR}/config/hammerspoon" "$HOME/.hammerspoon"
    
    print_success "macOS symlinks created"
}

setup_linux_symlinks() {
    print_info "Creating Linux-specific symlinks"
    
    # Hyprland compositor
    create_symlink "${SCRIPT_DIR}/config/hyprland" "$HOME/.config/hypr"
    
    # Waybar status bar
    create_symlink "${SCRIPT_DIR}/config/waybar" "$HOME/.config/waybar"
    
    # Rofi launcher
    create_symlink "${SCRIPT_DIR}/config/rofi" "$HOME/.config/rofi"
    
    # Wallpaper management
    create_symlink "${SCRIPT_DIR}/config/variety" "$HOME/.config/variety"
    create_symlink "${SCRIPT_DIR}/config/hyprpaper" "$HOME/.config/hypr"
    
    # Screen locker
    create_symlink "${SCRIPT_DIR}/config/swaylock" "$HOME/.config/swaylock"
    
    # Global hotkeys (needs system-level symlink)
    if confirm_action "Create system-level symlink for swhkd? (requires sudo)"; then
        sudo mkdir -p /etc/swhkd
        sudo ln -sf "${SCRIPT_DIR}/config/swhkd/swhkdrc" /etc/swhkd/swhkdrc
        print_info "swhkd configuration linked to /etc/swhkd/"
    else
        print_warning "swhkd configuration skipped - link manually with:"
        print_warning "sudo mkdir -p /etc/swhkd && sudo ln -sf ${SCRIPT_DIR}/config/swhkd/swhkdrc /etc/swhkd/swhkdrc"
    fi
    
    print_success "Linux symlinks created"
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

install_core_packages() {
    print_info "Installing core packages"
    
    # Format: "cross-platform-name:macos-name:linux-name"
    local packages=(
        "awscli::awscli2"
        "bash::bash"
        "bash-completion::bash-completion"
        "coreutils::coreutils"
        "diff-so-fancy::git-delta"
        "git::git"
        "jq::jq"
        "neovim::neovim"
        "pipx::python3-pipx"
        "tmux::tmux"
        "lazygit::lazygit"
        "vim::vim-enhanced"
        "tldr::tldr"
        "gh::gh"
    )
    
    for package_spec in "${packages[@]}"; do
        IFS=':' read -r common_name macos_name linux_name <<< "${package_spec}"
        install_package "${common_name}" "${macos_name}" "${linux_name}"
    done
    
    print_success "Core packages installed successfully"
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

install_linux_desktop_packages() {
    print_info "Installing Linux desktop packages (Hyprland ecosystem on Fedora Atomic)"
    
    if [[ "${OS}" != "Linux" ]]; then
        print_debug "Skipping Linux desktop packages - not on Linux"
        return 0
    fi
    
    if is_fedora_atomic; then
        install_fedora_atomic_packages
    elif is_fedora; then
        install_fedora_traditional_packages  
    else
        print_error "Unsupported Linux distribution"
        return 1
    fi
}

install_fedora_atomic_packages() {
    print_info "Installing packages for Fedora Atomic (rpm-ostree + Flatpak)"
    
    # System packages via rpm-ostree (require reboot)
    local system_packages=(
        "hyprland"
        "waybar" 
        "rofi-wayland"
        "swayidle"
        "wl-clipboard"
        "kitty"
        "papirus-icon-theme"
        "rust"
        "cargo"
        "make"
        "git"
        "polkit-devel"
        "gcc"
        "gcc-c++"
    )
    
    print_info "Installing system packages (will require reboot after completion)"
    for package in "${system_packages[@]}"; do
        rpm_ostree_install_if_missing "${package}"
    done
    
    # Desktop applications via Flatpak (no reboot needed)
    local flatpak_apps=(
        "org.mozilla.firefox"
        "com.spotify.Client" 
        "com.slack.Slack"
        "org.telegram.desktop"
        "org.libreoffice.LibreOffice"
        "org.gimp.GIMP"
    )
    
    print_info "Installing desktop applications via Flatpak"
    for app in "${flatpak_apps[@]}"; do
        flatpak_install_if_missing "${app}"
    done
    
    # Manual installations needed
    install_variety_atomic
    install_hyprpaper_atomic
    install_swaylock_atomic
    install_swhkd_atomic
    
    if [[ "${REBOOT_REQUIRED:-false}" == "true" ]]; then
        print_warning "System packages installed - REBOOT REQUIRED to complete installation"
        print_info "After reboot, run the script again to complete setup"
    fi
    
    print_success "Fedora Atomic packages installed successfully"
}

install_fedora_traditional_packages() {
    print_info "Installing packages for traditional Fedora (dnf)"
    
    # Hyprland and Wayland ecosystem  
    local hyprland_packages=(
        "hyprland"
        "hyprpaper"
        "waybar"
        "rofi-wayland" 
        "swayidle"
        "wl-clipboard"
        "kitty"
        "variety"
        "papirus-icon-theme"
        "papirus-icon-theme-dark"
    )
    
    for package in "${hyprland_packages[@]}"; do
        dnf_install_if_missing "${package}"
    done
    
    # Install swaylock-effects from COPR
    install_swaylock_effects
    
    print_success "Traditional Fedora packages installed successfully"
}

# ───────────────────────────────────────────────────
# Fedora Atomic Specific Installations
# ───────────────────────────────────────────────────

install_variety_atomic() {
    print_info "Installing Variety wallpaper manager (Fedora Atomic)"
    
    # Variety might not be available in base repos for Atomic
    # Try Flatpak first, fallback to manual installation
    if ! flatpak_install_if_missing "io.github.varietywalls.variety" "flathub"; then
        print_warning "Variety not available via Flatpak, trying pip installation"
        pip3 install --user variety || print_warning "Failed to install Variety"
    fi
}

install_hyprpaper_atomic() {
    print_info "Installing hyprpaper (Fedora Atomic)"
    
    # hyprpaper should be available via rpm-ostree
    rpm_ostree_install_if_missing "hyprpaper"
}

install_swaylock_atomic() {
    print_info "Installing swaylock-effects (Fedora Atomic)"
    
    # Try to enable COPR and install via rpm-ostree
    if command -v dnf &> /dev/null; then
        # If dnf is available (even on Atomic for COPR management)
        sudo dnf copr enable -y eddsalkield/swaylock-effects 2>/dev/null || print_warning "Could not enable COPR repo"
    fi
    
    # Try rpm-ostree installation
    if ! rpm_ostree_install_if_missing "swaylock-effects"; then
        print_warning "swaylock-effects not available, using standard swaylock"
        rpm_ostree_install_if_missing "swaylock"
    fi
}

install_swhkd_atomic() {
    print_info "Installing swhkd hotkey daemon (Fedora Atomic - build from source)"
    
    # swhkd needs to be built from source on Atomic
    print_info "swhkd requires building from source on Fedora Atomic"
    print_info "Dependencies are being installed via rpm-ostree"
    print_info "After reboot, run these commands to build swhkd:"
    print_info "  git clone https://github.com/waycrate/swhkd.git /tmp/swhkd"
    print_info "  cd /tmp/swhkd && make build && sudo make install"
    print_info "  sudo systemctl enable swhkd.service"
}

install_swaylock_effects() {
    print_info "Installing swaylock-effects from COPR"
    
    if [[ "${OS}" != "Linux" ]] || ! is_fedora; then
        return 0
    fi
    
    # Enable COPR repository for swaylock-effects
    if ! sudo dnf copr enable -y eddsalkield/swaylock-effects; then
        print_warning "Failed to enable swaylock-effects COPR repository"
        return 1
    fi
    
    dnf_install_if_missing "swaylock-effects"
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
    
    # Cross-platform packages (package-name:macos-name:linux-name)
    local nvim_deps=(
        "ripgrep::ripgrep"
        "lazygit::lazygit" 
        "fd::fd-find"
        "tree-sitter::tree-sitter"
        "go::golang"
        "bottom::bottom"
        "gdu::gdu"
    )
    
    for dep_spec in "${nvim_deps[@]}"; do
        IFS=':' read -r common_name macos_name linux_name <<< "${dep_spec}"
        install_package "${common_name}" "${macos_name}" "${linux_name}"
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
    
    # Install package manager if needed
    if ! install_package_manager; then
        print_warning "Package manager setup failed - some features may not work"
        return 1
    fi
    
    # Install packages
    install_core_packages
    
    # Install OS-specific packages
    if [[ "${OS}" == "Darwin" ]]; then
        install_brew_casks
        install_brew_fonts
        # Optional: Install full Xcode (macOS only)
        install_xcode
    elif [[ "${OS}" == "Linux" ]]; then
        install_linux_desktop_packages
    fi
    
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

