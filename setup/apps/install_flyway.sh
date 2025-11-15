#!/usr/bin/env bash
####################################################################################################
# Args           :
#                   --debug         Enable debug logging
#                   --dry-run       Run without making any changes
#                   --force         Force reinstallation even if latest version is installed
#                   -h, --help      Display this help message
#
# Usage          : sudo ./install_flyway.sh
#                  sudo ./install_flyway.sh --debug
#                  sudo ./install_flyway.sh --dry-run
#                  sudo ./install_flyway.sh --force
#
# Output stdout  : Progress messages for Flyway installation
# Output stderr  : Error messages if installation fails or required applications are missing
# Return code    : 0   Success
#                  1   Validation failure
#                  2   Installation failure
#
# Description    : This script installs or updates Flyway Database Migration Tool.
#                  It checks the latest version from Redgate downloads, compares with
#                  installed version, and installs or updates as needed.
#
#                  This script implements the MyLiCuLa installer interface for standardized
#                  installation flow and error handling.
#
# Author         : Francisco Güemes
# Email          : francisco@franciscoguemes.com
# See also       : setup/README.md for installer interface documentation
#                  lib/installer_common.sh for interface definitions
#                  https://flywaydb.org/
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
    # Search upwards for lib/common.sh (max 3 levels up from setup/apps/)
    BASE_DIR="$SCRIPT_DIR"
    for i in {1..4}; do
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

# Flyway installation directories (system-wide locations)
readonly FLYWAY_INSTALL_DIR="/opt/flyway"
readonly FLYWAY_BIN="/usr/local/bin/flyway"

# Flyway download URL for version discovery
readonly XML_URL="https://redgate-download.s3.eu-west-1.amazonaws.com/?delimiter=/&prefix=maven/release/com/redgate/flyway/flyway-commandline/"

# Force reinstallation flag
FORCE_INSTALL=false

#==================================================================================================
# Help Function
#==================================================================================================

show_help() {
    cat << EOF
Flyway Database Migration Tool Installer for MyLiCuLa

Usage: sudo $(basename "$0") [OPTIONS]

Install or update Flyway Database Migration Tool

OPTIONS:
    --debug         Enable debug logging with verbose output
    --dry-run       Run without making any changes to the system
    --force         Force reinstallation even if latest version is installed
    -h, --help      Display this help message

DESCRIPTION:
    This script installs or updates Flyway, an open-source database migration tool.

    The script:
    - Checks for the latest Flyway version from Redgate downloads
    - Compares with installed version (if any)
    - Downloads and installs/updates to the latest version
    - Creates symlink in /usr/local/bin for global access

REQUIREMENTS:
    - Root privileges (run with sudo)
    - wget (for downloading)
    - curl (for version checking)
    - tar (for extraction)
    - Internet connection

EXAMPLES:
    # Install Flyway
    sudo $(basename "$0")

    # Install with debug output
    sudo $(basename "$0") --debug

    # Test without making changes
    sudo $(basename "$0") --dry-run

    # Force reinstall even if up to date
    sudo $(basename "$0") --force

FILES:
    Installation: ${FLYWAY_INSTALL_DIR}
    Binary link: ${FLYWAY_BIN}

NOTES:
    - Flyway is installed to /opt/flyway (system-wide)
    - Binary symlink in /usr/local/bin/flyway (in PATH for all users)
    - Requires sudo for installation
    - Existing installation is replaced during updates
    - Version is checked against Redgate S3 repository

AUTHOR:
    Francisco Güemes <francisco@franciscoguemes.com>

SEE ALSO:
    setup/README.md - Installer interface documentation
    https://flywaydb.org/ - Flyway homepage
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
    echo "Flyway Installation"
}

#
# Function: validate_environment
# Description: Validate that the environment is ready for installation
#
validate_environment() {
    log "INFO" "Validating environment for Flyway installation..."

    # Check required applications
    if ! check_required_app "wget" "sudo nala install wget"; then
        log "ERROR" "Missing required application: wget"
        return 1
    fi

    if ! check_required_app "curl" "sudo nala install curl"; then
        log "ERROR" "Missing required application: curl"
        return 1
    fi

    if ! check_required_app "tar" "sudo nala install tar"; then
        log "ERROR" "Missing required application: tar"
        return 1
    fi

    # Check idempotency - if Flyway is installed and is latest version (unless --force)
    if [[ "$FORCE_INSTALL" == false ]] && check_flyway_installed; then
        local installed_version
        local latest_version

        installed_version=$(get_installed_version)
        latest_version=$(get_latest_version)

        if [[ -n "$installed_version" ]] && [[ -n "$latest_version" ]]; then
            if [[ "$installed_version" == "$latest_version" ]]; then
                log "INFO" "Flyway ${installed_version} is already installed (latest version)"
                return 2  # Already installed
            else
                log "INFO" "Flyway ${installed_version} is installed, but ${latest_version} is available"
            fi
        fi
    fi

    log "INFO" "✓ Environment validation passed"
    return 0
}

#
# Function: run_installation
# Description: Perform the actual installation
#
run_installation() {
    log "INFO" "Starting Flyway installation..."

    # Get latest version
    log "INFO" "Checking for latest Flyway version..."
    local latest_version
    if ! latest_version=$(get_latest_version); then
        log "ERROR" "Failed to determine latest Flyway version"
        return 1
    fi

    if [[ -z "$latest_version" ]]; then
        log "ERROR" "Could not determine latest Flyway version"
        return 1
    fi

    log "INFO" "Latest Flyway version: ${latest_version}"

    # Check if already installed
    if check_flyway_installed; then
        local installed_version
        installed_version=$(get_installed_version)
        log "INFO" "Currently installed version: ${installed_version}"

        if [[ "$installed_version" == "$latest_version" ]] && [[ "$FORCE_INSTALL" == false ]]; then
            log "INFO" "Flyway ${installed_version} is already the latest version"
            return 0
        fi

        if [[ "$FORCE_INSTALL" == true ]]; then
            log "INFO" "Force flag set - reinstalling Flyway ${latest_version}"
        else
            log "INFO" "Updating Flyway from ${installed_version} to ${latest_version}"
        fi
    else
        log "INFO" "Flyway not found - installing version ${latest_version}"
    fi

    # Install Flyway
    if ! install_flyway_version "$latest_version"; then
        log "ERROR" "Failed to install Flyway ${latest_version}"
        return 1
    fi

    log "INFO" "✓ Flyway installation completed successfully"
    return 0
}

#
# Function: cleanup_on_failure
# Description: Clean up partial installation if run_installation fails
#
cleanup_on_failure() {
    log "INFO" "Cleaning up after installation failure..."

    if [[ "$DRY_RUN_MODE" == true ]]; then
        log "INFO" "[DRY-RUN] Would remove: ${FLYWAY_INSTALL_DIR}"
        log "INFO" "[DRY-RUN] Would remove: ${FLYWAY_BIN}"
    else
        # Remove installation directory if it exists
        if [[ -d "$FLYWAY_INSTALL_DIR" ]]; then
            debug "Removing partial installation: ${FLYWAY_INSTALL_DIR}"
            rm -rf "$FLYWAY_INSTALL_DIR" 2>/dev/null || true
        fi

        # Remove symlink if it exists
        if [[ -L "$FLYWAY_BIN" ]]; then
            debug "Removing broken symlink: ${FLYWAY_BIN}"
            rm -f "$FLYWAY_BIN" 2>/dev/null || true
        fi

        log "INFO" "Cleanup completed"
    fi

    return 0
}

#==================================================================================================
# Flyway Installation Functions
#==================================================================================================

#
# Function: check_flyway_installed
# Description: Check if Flyway is installed and accessible
# Return: 0 if installed, 1 if not
#
check_flyway_installed() {
    if command -v flyway &>/dev/null; then
        return 0
    else
        return 1
    fi
}

#
# Function: get_installed_version
# Description: Get the currently installed Flyway version
# Return: Version string on stdout, or empty if not installed
#
get_installed_version() {
    if check_flyway_installed; then
        flyway -v 2>/dev/null | awk 'FNR == 1' | awk '{print $4}'
    else
        echo ""
    fi
}

#
# Function: get_latest_version
# Description: Get the latest Flyway version from Redgate downloads
# Return: 0 on success with version on stdout, 1 on failure
#
get_latest_version() {
    local version
    version=$(curl -s "$XML_URL" \
        | grep -oP '(?<=<CommonPrefixes><Prefix>maven/release/com/redgate/flyway/flyway-commandline/)\d+\.\d+\.\d+(?=/)' \
        | sort -V | tail -n 1)

    if [[ -z "$version" ]]; then
        return 1
    fi

    echo "$version"
    return 0
}

#
# Function: install_flyway_version
# Description: Download and install a specific Flyway version
# Args:
#   $1 - Version to install
# Return: 0 on success, 1 on failure
#
install_flyway_version() {
    local version="$1"
    local download_url="https://download.red-gate.com/maven/release/com/redgate/flyway/flyway-commandline/${version}/flyway-commandline-${version}-linux-x64.tar.gz"

    if [[ "$DRY_RUN_MODE" == true ]]; then
        log "INFO" "[DRY-RUN] Would install Flyway ${version}"
        log "INFO" "[DRY-RUN]   Download: ${download_url}"
        log "INFO" "[DRY-RUN]   Install to: ${FLYWAY_INSTALL_DIR}"
        log "INFO" "[DRY-RUN]   Symlink: ${FLYWAY_BIN}"
        return 0
    fi

    log "INFO" "Installing Flyway ${version}..."

    # Create installation directory
    debug "Creating installation directory: ${FLYWAY_INSTALL_DIR}"
    if ! mkdir -p "$FLYWAY_INSTALL_DIR" 2>/dev/null; then
        log "ERROR" "Failed to create installation directory: ${FLYWAY_INSTALL_DIR}"
        return 1
    fi

    # Remove old installation
    debug "Removing old installation files"
    rm -rf "${FLYWAY_INSTALL_DIR:?}"/* 2>/dev/null || true

    # Download and extract Flyway
    log "INFO" "Downloading Flyway ${version}..."
    debug "Download URL: ${download_url}"

    if ! wget -qO- "$download_url" | tar -xz -C "$FLYWAY_INSTALL_DIR" --strip-components=1; then
        log "ERROR" "Failed to download and extract Flyway"
        return 1
    fi

    # Set execute permissions
    debug "Setting execute permissions on flyway binary"
    if ! chmod a+x "${FLYWAY_INSTALL_DIR}/flyway" 2>/dev/null; then
        log "ERROR" "Failed to set execute permissions"
        return 1
    fi

    # Create symlink
    debug "Creating symlink: ${FLYWAY_BIN} -> ${FLYWAY_INSTALL_DIR}/flyway"
    if ! ln -sf "${FLYWAY_INSTALL_DIR}/flyway" "$FLYWAY_BIN" 2>/dev/null; then
        log "ERROR" "Failed to create symlink"
        return 1
    fi

    # Verify installation
    if check_flyway_installed; then
        local installed_version
        installed_version=$(get_installed_version)
        log "INFO" "✓ Flyway ${installed_version} installed successfully"
    else
        log "ERROR" "Installation completed but flyway command not found"
        return 1
    fi

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
            --force)
                FORCE_INSTALL=true
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

    # Setup logging (requires root for /opt/ and /usr/local/bin/ installation)
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
