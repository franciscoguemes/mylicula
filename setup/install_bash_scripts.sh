#!/usr/bin/env bash
####################################################################################################
# Args           :
#                   --debug         Enable debug logging
#                   --dry-run       Run without making any changes
#                   -h, --help      Display this help message
#
# Usage          : sudo ./install_bash_scripts.sh (from any directory)
#                  sudo ./install_bash_scripts.sh --debug
#
# Output stdout  : Success messages indicating the files that have been linked
# Output stderr  : Error messages if any issues occur during permission setting or symlink creation
# Return code    : 0   Success
#                  1   Validation failure
#                  2   Installation failure
#
# Description    : This script gives execution permissions to bash scripts in 'scripts/bash'
#                  and creates symlinks to them in '/usr/local/bin'.
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

# Directory where the scripts to be installed are located
BASH_DIR="$BASE_DIR/scripts/bash"

# Destination directory for symlinks
BIN_DIR="/usr/local/bin"

# Global error counter for idempotency
error_count=0

#==================================================================================================
# Help Function
#==================================================================================================

show_help() {
    cat << EOF
Bash Scripts Installer for MyLiCuLa

Usage: sudo $(basename "$0") [OPTIONS]

Install bash scripts from scripts/bash directory to /usr/local/bin

OPTIONS:
    --debug         Enable debug logging
    --dry-run       Run without making any changes
    -h, --help      Display this help message

DESCRIPTION:
    This script:
    - Sets execute permissions on bash scripts in scripts/bash/
    - Creates symlinks in /usr/local/bin for global access
    - Handles traverse.sh and its subdirectory dependencies separately
    - Provides idempotent installation (safe to run multiple times)

REQUIREMENTS:
    - Root privileges (run with sudo)
    - MyLiCuLa project directory structure

EXAMPLES:
    # Install bash scripts
    sudo $(basename "$0")

    # Install with debug output
    sudo $(basename "$0") --debug

    # Test without making changes
    sudo $(basename "$0") --dry-run

AUTHOR:
    Francisco Güemes <francisco@franciscoguemes.com>

SEE ALSO:
    setup/README.md - Installer interface documentation
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
    echo "Bash Scripts Installation"
}

#
# Function: validate_environment
# Description: Validate that the environment is ready for installation
#
validate_environment() {
    log "INFO" "Validating environment for bash scripts installation..."

    # Check if we have root privileges
    if [[ $EUID -ne 0 ]]; then
        log "ERROR" "This script requires root privileges to create symlinks in $BIN_DIR"
        log "ERROR" "Please run with: sudo $(basename "$0")"
        return 1
    fi

    # Check if source directory exists
    if [[ ! -d "$BASH_DIR" ]]; then
        log "ERROR" "Source directory does not exist: $BASH_DIR"
        return 1
    fi

    # Check if destination directory exists (create if needed)
    if [[ ! -d "$BIN_DIR" ]]; then
        log "ERROR" "Destination directory does not exist: $BIN_DIR"
        return 1
    fi

    # Check if we have write permissions to destination
    if [[ ! -w "$BIN_DIR" ]]; then
        log "ERROR" "No write permission to destination directory: $BIN_DIR"
        return 1
    fi

    log "INFO" "✓ Environment validation passed"
    return 0
}

#
# Function: run_installation
# Description: Perform the actual installation
#
run_installation() {
    log "INFO" "Starting bash scripts installation..."

    # Reset error counter
    error_count=0

    # Process main bash scripts directory
    process_files "$BASH_DIR"

    # Install traverse.sh separately (has subdirectory dependencies)
    install_traverse_script

    # Check final error count
    if [[ $error_count -eq 0 ]]; then
        log "INFO" "✓ All bash scripts installed successfully"
        return 0
    else
        log "ERROR" "Installation completed with $error_count errors"
        return 1
    fi
}

#
# Function: cleanup_on_failure
# Description: Clean up partial installation if run_installation fails
#
cleanup_on_failure() {
    log "INFO" "No cleanup needed for bash scripts (symlinks are idempotent)"
    return 0
}

#==================================================================================================
# Helper Functions
#==================================================================================================

#
# Function: process_files
# Description: Process and install bash scripts from a given directory
# Args:
#   $1 - Directory path containing bash scripts
#
process_files() {
    local dir="$1"
    local processed_count=0

    log "INFO" "Installing bash scripts from: $dir"

    # Enable nullglob to handle empty directories gracefully
    shopt -s nullglob

    # Iterate over each file in the specified directory (only direct children, not subdirectories)
    for file in "$dir"/*; do
        # Skip if it's a directory
        if [[ -d "$file" ]]; then
            continue
        fi

        # Ensure it's a regular file (not a directory) and ends with .sh
        if [[ -f "$file" ]] && [[ "$file" == *.sh ]]; then
            filename=$(basename "$file")

            # Check if the file has execute permission, if not add it
            if [[ ! -x "$file" ]]; then
                if [[ "$DRY_RUN_MODE" == true ]]; then
                    log "INFO" "[DRY-RUN] Would set execute permissions: $filename"
                else
                    debug "Setting execute permissions for $filename"
                    if ! chmod +x "$file" 2>/dev/null; then
                        log "ERROR" "Failed to set execute permissions for $filename"
                        ((error_count++)) || true
                        continue
                    fi
                fi
            fi

            # Create a symlink in /usr/local/bin using the robust create_symlink function
            link_path="$BIN_DIR/$filename"

            if [[ "$DRY_RUN_MODE" == true ]]; then
                log "INFO" "[DRY-RUN] Would create symlink: $link_path -> $file"
            else
                # create_symlink returns 0 for success, 1 for error, 2 for skip
                # We don't treat "already exists" (return 2) as an error for idempotency
                local symlink_result=0
                if create_symlink "$file" "$link_path"; then
                    symlink_result=0
                else
                    symlink_result=$?
                fi

                if [[ $symlink_result -eq 1 ]]; then
                    # Return code 1 indicates an error
                    ((error_count++)) || true
                fi
            fi

            ((processed_count++)) || true
        fi
    done

    # Restore nullglob
    shopt -u nullglob

    log "INFO" "Processed $processed_count script(s) | Errors: $error_count"
}

#
# Function: install_traverse_script
# Description: Install traverse.sh separately (main script with subdirectory dependencies)
#
install_traverse_script() {
    log "INFO" "Installing traverse.sh (with subdirectory helpers)..."

    local traverse_script="$BASH_DIR/traverse/traverse.sh"

    if [[ ! -f "$traverse_script" ]]; then
        log "INFO" "traverse.sh not found at $traverse_script (skipping)"
        return 0
    fi

    # Check if the file has execute permission, if not add it
    if [[ ! -x "$traverse_script" ]]; then
        if [[ "$DRY_RUN_MODE" == true ]]; then
            log "INFO" "[DRY-RUN] Would set execute permissions: traverse.sh"
        else
            debug "Setting execute permissions for traverse.sh"
            if ! chmod +x "$traverse_script" 2>/dev/null; then
                log "ERROR" "Failed to set execute permissions for traverse.sh"
                ((error_count++)) || true
                return 1
            fi
        fi
    fi

    # Create symlink for traverse.sh
    local link_path="$BIN_DIR/traverse.sh"

    if [[ "$DRY_RUN_MODE" == true ]]; then
        log "INFO" "[DRY-RUN] Would create symlink: $link_path -> $traverse_script"
    else
        # Capture return code without triggering set -e
        local symlink_result=0
        if create_symlink "$traverse_script" "$link_path"; then
            symlink_result=0
        else
            symlink_result=$?
        fi

        if [[ $symlink_result -eq 1 ]]; then
            # Return code 1 indicates an error
            ((error_count++)) || true
            return 1
        fi
    fi

    log "INFO" "Helper directories: $BASH_DIR/traverse/filters/ and $BASH_DIR/traverse/executioners/"
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
