#!/usr/bin/env bash
####################################################################################################
# Args           :
#                   --debug         Enable debug logging
#                   --dry-run       Run without making any changes
#                   -h, --help      Display this help message
#
# Usage          : sudo ./install_snap.sh
#                  sudo ./install_snap.sh --debug
#                  sudo ./install_snap.sh --dry-run
#
# Output stdout  : Progress messages for snap package installation
# Output stderr  : Error messages if package installation fails or required applications are missing
# Return code    : 0   Success
#                  1   Validation failure
#                  2   Installation failure
#
# Description    : This script installs snap packages from list_of_snap.txt
#
#                  The script parses the file for metadata comments (FLAGS) and automatically
#                  applies the correct flags when installing packages.
#
#                  Format for list_of_snap.txt:
#                    # Package Group Name
#                    # FLAGS: --classic (or other snap install flags)
#                    package-name-1
#                    package-name-2
#
#                  This script implements the MyLiCuLa installer interface for standardized
#                  installation flow and error handling.
#
# Author         : Francisco Güemes
# Email          : francisco@franciscoguemes.com
# See also       : setup/README.md for installer interface documentation
#                  lib/installer_common.sh for interface definitions
####################################################################################################

set -euo pipefail

#==================================================================================================
# Script Setup
#==================================================================================================

# Get script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SCRIPT_NAME="$(basename "${BASH_SOURCE[0]}")"

# Find BASE_DIR - Priority 1: env var, Priority 2: search for lib/common.sh
if [[ -n "${MYLICULA_BASE_DIR:-}" ]]; then
    BASE_DIR="$MYLICULA_BASE_DIR"
else
    # Search upwards for lib/common.sh (max 3 levels)
    BASE_DIR="$SCRIPT_DIR"
    for i in {1..3}; do
        if [[ -f "${BASE_DIR}/lib/common.sh" ]]; then
            break
        fi
        BASE_DIR="$(dirname "$BASE_DIR")"
    done

    if [[ ! -f "${BASE_DIR}/lib/common.sh" ]]; then
        echo "[ERROR] Cannot find MyLiCuLa project root" >&2
        echo "Please set MYLICULA_BASE_DIR environment variable or run via install.sh" >&2
        exit 1
    fi
fi

# Source common libraries
source "${BASE_DIR}/lib/common.sh"
source "${BASE_DIR}/lib/installer_common.sh"

#==================================================================================================
# Configuration
#==================================================================================================

# Snap packages list file
readonly SNAP_PACKAGES_FILE="${BASE_DIR}/resources/snap/list_of_snap.txt"

#==================================================================================================
# Help Function
#==================================================================================================

show_help() {
    cat << EOF
Snap Package Installer for MyLiCuLa

Usage: sudo $(basename "$0") [OPTIONS]

Install snap packages from list_of_snap.txt

OPTIONS:
    --debug         Enable debug logging with verbose output
    --dry-run       Run without making any changes to the system
    -h, --help      Display this help message

DESCRIPTION:
    This script installs snap packages with support for installation flags
    (like --classic, --edge, --beta) specified in metadata comments.

    Package List Format (resources/snap/list_of_snap.txt):
        # Package Group Name
        # FLAGS: --classic (or other snap install flags)
        package-name-1
        package-name-2

        # Another group with different flags
        # FLAGS: --edge
        package-name-3

    Common Snap Flags:
        --classic       : Install classic snap (full system access)
        --edge          : Install from edge channel (latest development)
        --beta          : Install from beta channel (pre-release)
        --candidate     : Install from candidate channel (release candidate)
        --stable        : Install from stable channel (default)

REQUIREMENTS:
    - Root privileges (run with sudo)
    - snapd package manager (installed via bootstrap.sh)

EXAMPLES:
    # Install all snap packages
    sudo $(basename "$0")

    # Install with debug output
    sudo $(basename "$0") --debug

    # Test without making changes
    sudo $(basename "$0") --dry-run

FILES:
    Snap packages: ${SNAP_PACKAGES_FILE}

NOTES:
    - Snap packages are installed individually (not in batch)
    - Existing snaps are detected and skipped automatically
    - All output is logged to: /var/log/mylicula/install_snap.log

AUTHOR:
    Francisco Güemes <francisco@franciscoguemes.com>

SEE ALSO:
    setup/README.md - Installer interface documentation
    resources/snap/list_of_snap.txt - Snap package list with flags
EOF
}

#==================================================================================================
# Installer Interface Implementation
#==================================================================================================

#
# Function: get_installer_name
# Description: Return human-readable name for this installer
#
get_installer_name() {
    echo "Snap Package Installation"
}

#
# Function: validate_environment
# Description: Validate that the environment is ready for installation
#
validate_environment() {
    log "INFO" "Validating environment for snap package installation..."

    # Check if we have root privileges
    if [[ $EUID -ne 0 ]]; then
        log "ERROR" "This script requires root privileges to install snap packages"
        log "ERROR" "Please run with: sudo $(basename "$0")"
        return 1
    fi

    # Check required applications
    if ! check_required_app "snap" "sudo nala install snapd"; then
        log "ERROR" "Missing required application: snap"
        return 1
    fi

    # Check if snap packages file exists
    if [[ ! -f "$SNAP_PACKAGES_FILE" ]]; then
        log "ERROR" "Snap packages file not found: ${SNAP_PACKAGES_FILE}"
        return 1
    fi

    # Check idempotency - snap handles already-installed packages gracefully
    debug "Snap installation is idempotent - snap handles already-installed packages"

    log "INFO" "✓ Environment validation passed"
    return 0
}

#
# Function: run_installation
# Description: Perform the actual installation
#
run_installation() {
    log "INFO" "Starting snap package installation..."

    if ! install_snap_packages; then
        log "ERROR" "Snap package installation failed"
        return 1
    fi

    log "INFO" "✓ Snap package installation completed successfully"
    return 0
}

#
# Function: cleanup_on_failure
# Description: Clean up partial installation if run_installation fails
#
cleanup_on_failure() {
    log "INFO" "Snap installation failures are handled by snap daemon"
    log "INFO" "No additional cleanup needed (snap is atomic per package)"
    return 0
}

#==================================================================================================
# Snap Package Installation Functions
#==================================================================================================

#
# Function: install_snap_package
# Description: Install a single snap package with specified flags
# Args:
#   $1 - Package name
#   $2 - Installation flags (optional)
# Return: 0 on success, 1 on failure
#
install_snap_package() {
    local package=$1
    local flags=${2:-}

    if [[ "$DRY_RUN_MODE" == true ]]; then
        if [[ -n "$flags" ]]; then
            log "INFO" "[DRY-RUN] Would install: snap install ${flags} ${package}"
        else
            log "INFO" "[DRY-RUN] Would install: snap install ${package}"
        fi
        return 0
    fi

    log "INFO" "Installing: ${package}"
    if [[ -n "$flags" ]]; then
        debug "  Using flags: ${flags}"
    fi

    # Install snap package
    if snap install ${flags} "${package}" >> "$LOG_FILE" 2>&1; then
        log "INFO" "Successfully installed: ${package}"
        return 0
    else
        # Check if it's already installed (snap returns error for already installed)
        if snap list "${package}" &>/dev/null; then
            debug "Package already installed: ${package}"
            return 0
        else
            log "ERROR" "Failed to install: ${package}"
            log "ERROR" "Check log for details: ${LOG_FILE}"
            return 1
        fi
    fi
}

#
# Function: install_package_group
# Description: Install a group of snap packages with the same flags
# Args:
#   $1 - Installation flags (optional)
#   $2+ - Package names
# Return: 0 on success (even if some packages fail)
#
install_package_group() {
    local flags=$1
    shift
    local -a packages=("$@")

    if [[ ${#packages[@]} -eq 0 ]]; then
        debug "No packages to install in this group"
        return 0
    fi

    log "INFO" "Installing package group (${#packages[@]} packages)..."
    if [[ -n "$flags" ]]; then
        log "INFO" "  Using flags: ${flags}"
    fi

    local success_count=0
    local fail_count=0

    # Install each package individually (snap doesn't support batch installs like apt)
    for package in "${packages[@]}"; do
        if install_snap_package "$package" "$flags"; then
            ((success_count++))
        else
            ((fail_count++))
        fi
    done

    log "INFO" "Package group results: ${success_count} successful, ${fail_count} failed"

    # Return success if at least some packages installed
    # This prevents one bad package from stopping the entire installation
    if [[ $success_count -gt 0 ]] || [[ $fail_count -eq 0 ]]; then
        return 0
    else
        return 1
    fi
}

#
# Function: install_snap_packages
# Description: Parse and install snap packages from list_of_snap.txt
# Return: 0 on success, 1 on failure
#
install_snap_packages() {
    log "INFO" "Processing snap packages from: ${SNAP_PACKAGES_FILE}"

    if [[ ! -f "$SNAP_PACKAGES_FILE" ]]; then
        log "ERROR" "Snap packages file not found: ${SNAP_PACKAGES_FILE}"
        return 1
    fi

    local flags=""
    local -a packages=()
    local line_count=0
    local group_count=0
    local total_packages=0

    while IFS= read -r line; do
        ((line_count++))

        # Extract FLAGS metadata from comments
        if [[ "$line" =~ ^[[:space:]]*#[[:space:]]*FLAGS:[[:space:]]*(.*)$ ]]; then
            flags="${BASH_REMATCH[1]}"
            debug "  Found FLAGS: ${flags}"
        elif [[ "$line" =~ ^[[:space:]]*# ]]; then
            # Other comments - skip
            continue
        elif [[ -z "${line// }" ]]; then
            # Empty line - install accumulated packages if any
            if [[ ${#packages[@]} -gt 0 ]]; then
                ((group_count++))
                install_package_group "$flags" "${packages[@]}"
                total_packages=$((total_packages + ${#packages[@]}))

                # Reset for next group
                packages=()
                flags=""
            fi
        else
            # Package name
            local package=$(echo "$line" | xargs)
            if [[ -n "$package" ]]; then
                packages+=("$package")
                debug "  Found package: ${package}"
            fi
        fi
    done < "$SNAP_PACKAGES_FILE"

    # Install last group if any packages remain
    if [[ ${#packages[@]} -gt 0 ]]; then
        ((group_count++))
        install_package_group "$flags" "${packages[@]}"
        total_packages=$((total_packages + ${#packages[@]}))
    fi

    log "INFO" "Processed ${total_packages} packages in ${group_count} groups from ${line_count} lines"
    return 0
}

#==================================================================================================
# Main Function
#==================================================================================================

main() {
    # Parse arguments
    while [[ $# -gt 0 ]]; do
        case $1 in
            -h|--help)
                show_help
                exit 0
                ;;
            --debug)
                DEBUG_MODE=true
                shift
                ;;
            --dry-run)
                DRY_RUN_MODE=true
                shift
                ;;
            *)
                log_error "Unknown option: $1"
                echo ""
                show_help
                exit 1
                ;;
        esac
    done

    # Setup logging
    setup_installer_common

    # Execute the installer using the standard interface
    execute_installer
}

#==================================================================================================
# Script Entry Point
#==================================================================================================

# Only run main if script is executed directly (not sourced)
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
