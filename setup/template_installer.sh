#!/usr/bin/env bash
####################################################################################################
# Args           :
#                   --debug         Enable debug logging
#                   --dry-run       Run without making any changes
#                   -h, --help      Display this help message
#
# Usage          : sudo ./template_installer.sh
#                  sudo ./template_installer.sh --debug
#                  sudo ./template_installer.sh --dry-run
#
# Output stdout  : Installation progress and status messages
# Output stderr  : Error messages if any issues occur
# Return code    : 0   Success
#                  1   Validation failure
#                  2   Installation failure
#
# Description    : Template installer script demonstrating the MyLiCuLa installer interface.
#
#                  This template shows how to implement the standard installer interface:
#                  - get_installer_name()    : Return human-readable installer name
#                  - validate_environment()  : Check prerequisites and idempotency
#                  - run_installation()      : Perform the actual installation
#                  - cleanup_on_failure()    : Clean up if installation fails (optional)
#
#                  Copy this template to create new installers and implement the
#                  required functions according to your installation needs.
#
# Author         : Francisco Güemes
# Email          : francisco@franciscoguemes.com
# See also       : setup/README.md for interface documentation
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

# Add your installer-specific configuration here
# Example:
# PACKAGE_NAME="example-package"
# CONFIG_FILE="/etc/example/config.conf"
# REQUIRED_APPS=("git" "curl" "jq")

#==================================================================================================
# Help Function
#==================================================================================================

show_help() {
    cat << EOF
Template Installer for MyLiCuLa

Usage: sudo $(basename "$0") [OPTIONS]

This is a template demonstrating the MyLiCuLa installer interface.
Copy and modify this template to create new installers.

OPTIONS:
    --debug         Enable debug logging
    --dry-run       Run without making any changes
    -h, --help      Display this help message

DESCRIPTION:
    This template shows how to implement the standard installer interface
    required by all MyLiCuLa installation scripts.

    Required interface functions:
    - get_installer_name()    : Return human-readable name
    - validate_environment()  : Check prerequisites
    - run_installation()      : Perform installation

    Optional interface functions:
    - cleanup_on_failure()    : Clean up on error

EXAMPLES:
    # Run with default settings
    sudo $(basename "$0")

    # Run in debug mode
    sudo $(basename "$0") --debug

    # Test without making changes
    sudo $(basename "$0") --dry-run

AUTHOR:
    Francisco Güemes <francisco@franciscoguemes.com>

SEE ALSO:
    setup/README.md - Interface documentation
    lib/installer_common.sh - Interface definitions
EOF
}

#==================================================================================================
# Installer Interface Implementation (REQUIRED)
#==================================================================================================

#
# Function: get_installer_name
# Description: Return human-readable name for this installer
# Args: None
# Return: String with installer name (stdout)
#
get_installer_name() {
    echo "Template Installer Example"
}

#
# Function: validate_environment
# Description: Validate that the environment is ready for installation
# Args: None
# Return: 0 if ready, 1 if validation fails, 2 if already installed
#
validate_environment() {
    log "INFO" "Validating environment..."

    # Example 1: Check required applications
    # Uncomment and modify as needed:
    # for app in "${REQUIRED_APPS[@]}"; do
    #     if ! check_required_app "$app" "sudo nala install $app"; then
    #         return 1
    #     fi
    # done

    # Example 2: Check required permissions
    if [[ $EUID -ne 0 ]]; then
        log "ERROR" "This installer requires root privileges"
        log "ERROR" "Please run with: sudo $(basename "$0")"
        return 1
    fi

    # Example 3: Check for idempotency (already installed)
    # Uncomment and modify as needed:
    # if [[ -f "$CONFIG_FILE" ]]; then
    #     log "INFO" "Already installed (found: $CONFIG_FILE)"
    #     return 2
    # fi

    # Example 4: Check required environment variables
    # Uncomment and modify as needed:
    # if [[ -z "${MYLICULA_USERNAME:-}" ]]; then
    #     log "ERROR" "MYLICULA_USERNAME environment variable not set"
    #     return 1
    # fi

    # Example 5: Check disk space
    # Uncomment and modify as needed:
    # local required_space_mb=100
    # local available_space_mb
    # available_space_mb=$(df -m / | awk 'NR==2 {print $4}')
    # if [[ $available_space_mb -lt $required_space_mb ]]; then
    #     log "ERROR" "Insufficient disk space: ${available_space_mb}MB < ${required_space_mb}MB"
    #     return 1
    # fi

    log "INFO" "✓ Environment validation passed"
    return 0
}

#
# Function: run_installation
# Description: Perform the actual installation
# Args: None
# Return: 0 on success, 1 on failure
#
run_installation() {
    log "INFO" "Starting installation..."

    # Example 1: Create directories
    # Uncomment and modify as needed:
    # if [[ "$DRY_RUN_MODE" == true ]]; then
    #     log "INFO" "[DRY-RUN] Would create directory: /etc/example"
    # else
    #     mkdir -p /etc/example
    #     log "INFO" "Created directory: /etc/example"
    # fi

    # Example 2: Copy files
    # Uncomment and modify as needed:
    # local source_file="${BASE_DIR}/resources/example/config.conf"
    # local dest_file="/etc/example/config.conf"
    # if [[ "$DRY_RUN_MODE" == true ]]; then
    #     log "INFO" "[DRY-RUN] Would copy: $source_file -> $dest_file"
    # else
    #     cp "$source_file" "$dest_file"
    #     log "INFO" "Copied: $source_file -> $dest_file"
    # fi

    # Example 3: Run commands
    # Uncomment and modify as needed:
    # if [[ "$DRY_RUN_MODE" == true ]]; then
    #     log "INFO" "[DRY-RUN] Would run: systemctl enable example"
    # else
    #     systemctl enable example
    #     log "INFO" "Enabled service: example"
    # fi

    # Example 4: Create symlinks
    # Uncomment and modify as needed:
    # if [[ "$DRY_RUN_MODE" == true ]]; then
    #     log "INFO" "[DRY-RUN] Would create symlink: /usr/local/bin/example"
    # else
    #     create_symlink "${BASE_DIR}/scripts/example.sh" "/usr/local/bin/example"
    # fi

    # Placeholder implementation
    log "INFO" "This is a template - implement your installation logic here"
    log "INFO" "✓ Installation completed successfully"

    return 0
}

#
# Function: cleanup_on_failure (OPTIONAL)
# Description: Clean up partial installation if run_installation fails
# Args: None
# Return: 0 on success
#
cleanup_on_failure() {
    log "INFO" "Cleaning up after installation failure..."

    # Example cleanup tasks:
    # Uncomment and modify as needed:
    # if [[ -f "/etc/example/config.conf" ]]; then
    #     rm -f "/etc/example/config.conf"
    #     log "INFO" "Removed: /etc/example/config.conf"
    # fi

    # if [[ -L "/usr/local/bin/example" ]]; then
    #     rm -f "/usr/local/bin/example"
    #     log "INFO" "Removed symlink: /usr/local/bin/example"
    # fi

    log "INFO" "Cleanup completed"
    return 0
}

#==================================================================================================
# Helper Functions (OPTIONAL)
#==================================================================================================

# Add your installer-specific helper functions here
# These are private to your installer and not part of the interface

# Example helper function:
# process_config_file() {
#     local config_file=$1
#     # Implementation here
# }

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
