#!/usr/bin/env bash
####################################################################################################
# Args           :
#                   --debug         Enable debug logging
#                   --dry-run       Run without making any changes
#                   -h, --help      Display this help message
#
# Usage          : ./install_set-title_function.sh
#                  ./install_set-title_function.sh --debug
#                  ./install_set-title_function.sh --dry-run
#
# Output stdout  : Progress messages for set-title function installation
# Output stderr  : Error messages if installation fails
# Return code    : 0   Success
#                  1   Validation failure
#                  2   Installation failure
#
# Description    : This script adds the set-title function to ~/.bashrc.
#                  The set-title function allows setting the terminal title to custom text.
#
#                  Usage after installation:
#                    set-title "My Custom Terminal Title"
#
#                  This script implements the MyLiCuLa installer interface for standardized
#                  installation flow and error handling.
#
# Author         : Francisco Güemes
# Email          : francisco@franciscoguemes.com
# See also       : setup/README.md for installer interface documentation
#                  lib/installer_common.sh for interface definitions
#                  https://blog.programster.org/ubuntu-16-04-set-terminal-title
#                  https://askubuntu.com/questions/616404/ubuntu-15-04-fresh-install-cant-rename-gnome-terminal-tabs
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

# Target user's home directory and bashrc
TARGET_HOME="${MYLICULA_HOME:-${HOME}}"
readonly BASHRC="${TARGET_HOME}/.bashrc"

# Function definition to be added to .bashrc
readonly FUNCTION_MARKER="# MyLiCuLa: set-title function"
readonly FUNCTION_DEFINITION='set-title(){
  ORIG=$PS1
  TITLE="\e]2;$@\a"
  PS1=${ORIG}${TITLE}
}'

#==================================================================================================
# Help Function
#==================================================================================================

show_help() {
    cat << EOF
Set-Title Function Installer for MyLiCuLa

Usage: $(basename "$0") [OPTIONS]

Install the set-title bash function to ~/.bashrc

OPTIONS:
    --debug         Enable debug logging with verbose output
    --dry-run       Run without making any changes to the system
    -h, --help      Display this help message

DESCRIPTION:
    This script adds the set-title function to your ~/.bashrc file.
    The set-title function allows you to change the terminal title dynamically.

    After installation, use it like this:
        set-title "My Project"
        set-title "Server: production"

    The function works by modifying the PS1 prompt to include an escape
    sequence that sets the terminal window title.

REQUIREMENTS:
    - ~/.bashrc file (created automatically if missing)
    - Bash shell

EXAMPLES:
    # Install the function
    $(basename "$0")

    # Install with debug output
    $(basename "$0") --debug

    # Test without making changes
    $(basename "$0") --dry-run

FILES:
    Target file: ${BASHRC}

NOTES:
    - The function is added only once (idempotent)
    - After installation, restart your terminal or run: source ~/.bashrc
    - The function is marked with a comment for easy identification

AUTHOR:
    Francisco Güemes <francisco@franciscoguemes.com>

SEE ALSO:
    setup/README.md - Installer interface documentation
    https://blog.programster.org/ubuntu-16-04-set-terminal-title
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
    echo "Set-Title Function Installation"
}

#
# Function: validate_environment
# Description: Validate that the environment is ready for installation
#
validate_environment() {
    log "INFO" "Validating environment for set-title function installation..."

    # Check if target home directory exists
    if [[ ! -d "$TARGET_HOME" ]]; then
        log "ERROR" "Target home directory does not exist: ${TARGET_HOME}"
        return 1
    fi

    debug "Target .bashrc: ${BASHRC}"

    # Check idempotency - if function already exists in .bashrc, consider it installed
    if [[ -f "$BASHRC" ]]; then
        if grep -q "set-title()" "$BASHRC" 2>/dev/null; then
            log "INFO" "set-title function already present in ${BASHRC}"
            return 2  # Already installed
        fi
    else
        debug ".bashrc does not exist yet (will be created)"
    fi

    log "INFO" "✓ Environment validation passed"
    return 0
}

#
# Function: run_installation
# Description: Perform the actual installation
#
run_installation() {
    log "INFO" "Starting set-title function installation..."

    # Create .bashrc if it doesn't exist
    if [[ ! -f "$BASHRC" ]]; then
        if [[ "$DRY_RUN_MODE" == true ]]; then
            log "INFO" "[DRY-RUN] Would create: ${BASHRC}"
        else
            debug "Creating .bashrc file: ${BASHRC}"
            if ! touch "$BASHRC" 2>/dev/null; then
                log "ERROR" "Failed to create .bashrc file: ${BASHRC}"
                return 1
            fi
        fi
    fi

    # Add the set-title function to .bashrc
    if [[ "$DRY_RUN_MODE" == true ]]; then
        log "INFO" "[DRY-RUN] Would add set-title function to: ${BASHRC}"
        log "INFO" "[DRY-RUN] Function definition:"
        log "INFO" "[DRY-RUN]   ${FUNCTION_MARKER}"
        log "INFO" "[DRY-RUN]   ${FUNCTION_DEFINITION}"
    else
        debug "Adding set-title function to ${BASHRC}"

        # Append function with marker comment
        {
            echo ""
            echo "$FUNCTION_MARKER"
            echo "$FUNCTION_DEFINITION"
        } >> "$BASHRC"

        if [[ $? -ne 0 ]]; then
            log "ERROR" "Failed to add function to ${BASHRC}"
            return 1
        fi

        log "INFO" "✓ set-title function added to ${BASHRC}"
    fi

    # Note about sourcing .bashrc
    log "INFO" ""
    log "INFO" "To use the set-title function immediately, run:"
    log "INFO" "  source ~/.bashrc"
    log "INFO" ""
    log "INFO" "Or simply restart your terminal."
    log "INFO" ""

    log "INFO" "✓ Set-title function installation completed successfully"
    return 0
}

#
# Function: cleanup_on_failure
# Description: Clean up partial installation if run_installation fails
#
cleanup_on_failure() {
    log "INFO" "Cleaning up after failure..."

    # If we just added the function and it failed, we could remove it
    # But since the function addition is atomic (append operation),
    # we don't need special cleanup - either it's there or it's not
    debug "No cleanup needed (append operation is atomic)"

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

    # Setup logging (no-root: modifies user's bash configuration)
    setup_installer_common "no-root"

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
