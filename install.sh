#!/bin/bash

# ───────────────────────────────────────────────────
# Dotfiles Installation Script (OS Router)
# ───────────────────────────────────────────────────

# CRITICAL: Ensure we're running in bash BEFORE any other operations
if [[ -z "${BASH_VERSION}" ]]; then
    echo "Switching to bash..."
    # Try different bash locations in order of preference
    if [[ -f "/opt/homebrew/bin/bash" ]]; then
        exec /opt/homebrew/bin/bash "$0" "$@"
    elif [[ -f "/usr/local/bin/bash" ]]; then
        exec /usr/local/bin/bash "$0" "$@"
    elif [[ -f "/bin/bash" ]]; then
        exec /bin/bash "$0" "$@"
    elif [[ -f "/usr/bin/bash" ]]; then
        exec /usr/bin/bash "$0" "$@"
    else
        echo "Error: No suitable bash found. Please install bash and try again."
        exit 1
    fi
fi

set -uo pipefail

# Global variables
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
OS="$(uname -s)"

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

# ───────────────────────────────────────────────────
# OS Detection and Routing
# ───────────────────────────────────────────────────

main() {
    print_info "Detecting operating system"
    print_info "Detected OS: ${OS}"

    case "${OS}" in
        "Darwin")
            print_info "Routing to macOS installation script"
            if [[ -f "${SCRIPT_DIR}/install-mac.sh" ]]; then
                exec "${SCRIPT_DIR}/install-mac.sh" "$@"
            else
                print_error "install-mac.sh not found"
                exit 1
            fi
            ;;
        "Linux")
            print_info "Routing to OMARCHY installation script"
            if [[ -f "${SCRIPT_DIR}/install-omarchy.sh" ]]; then
                exec "${SCRIPT_DIR}/install-omarchy.sh" "$@"
            else
                print_error "install-omarchy.sh not found"
                exit 1
            fi
            ;;
        *)
            print_error "Unsupported operating system: ${OS}"
            print_error "This script supports macOS (Darwin) and Linux only"
            exit 1
            ;;
    esac
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
