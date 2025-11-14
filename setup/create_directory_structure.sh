#!/usr/bin/env bash
####################################################################################################
# Args           :
#                   --debug         Enable debug logging
#                   --dry-run       Run without making any changes
#                   -h, --help      Display this help message
#
# Usage          : sudo ./create_directory_structure.sh
#                  sudo ./create_directory_structure.sh --debug
#                  sudo ./create_directory_structure.sh --dry-run
#
# Output stdout  : Directory creation messages and status
# Output stderr  : Error messages if directory creation fails
# Return code    : 0   Success
#                  1   Validation failure
#                  2   Installation failure
#
# Description    : Creates the directory structure on which the rest of the installation will rely.
#                  Creates system directories (/usr/lib/jvm) and user directories (Downloads, Documents,
#                  Templates, Videos, Music, Pictures, bin, .config, development, git, workspaces).
#                  Uses MYLICULA_COMPANY variable to create company-specific directories if set.
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

# Get configuration from environment
COMPANY="${MYLICULA_COMPANY:-}"
TARGET_USER="${MYLICULA_USERNAME:-${USER}}"
TARGET_HOME="${MYLICULA_HOME:-${HOME}}"

# System directories (require sudo)
declare -a SYSTEM_DIRS=(
    "/usr/lib/jvm"
)

# User directories (no sudo required)
declare -a USER_BASE_DIRS=(
    "${TARGET_HOME}/Downloads"
    "${TARGET_HOME}/Templates"
    "${TARGET_HOME}/Documents/Mega"
    "${TARGET_HOME}/Books"
    "${TARGET_HOME}/Ebooks"
    "${TARGET_HOME}/Videos"
    "${TARGET_HOME}/Music"
    "${TARGET_HOME}/Pictures"
    "${TARGET_HOME}/bin"
    "${TARGET_HOME}/.config"
)

# Development directories
declare -a DEV_DIRS=(
    "${TARGET_HOME}/development/flyway"
    "${TARGET_HOME}/development/eclipse"
    "${TARGET_HOME}/development/netbeans"
    "${TARGET_HOME}/development/intellij-community"
)

# Git directories (base structure)
declare -a GIT_DIRS=(
    "${TARGET_HOME}/git/${TARGET_USER}/gitlab"
    "${TARGET_HOME}/git/${TARGET_USER}/github"
    "${TARGET_HOME}/git/other"
)

# Workspace directories
declare -a WORKSPACE_DIRS=(
    "${TARGET_HOME}/workspaces/eclipse"
    "${TARGET_HOME}/workspaces/netbeans"
    "${TARGET_HOME}/workspaces/intellij"
)

#==================================================================================================
# Help Function
#==================================================================================================

show_help() {
    cat << EOF
Directory Structure Creator for MyLiCuLa

Usage: sudo $(basename "$0") [OPTIONS]

Create the standard directory structure for MyLiCuLa installation

OPTIONS:
    --debug         Enable debug logging
    --dry-run       Run without making any changes
    -h, --help      Display this help message

DESCRIPTION:
    This script creates the directory structure required for MyLiCuLa:

    System Directories (requires sudo):
    - /usr/lib/jvm                    Java Virtual Machine directory

    User Directories:
    - ~/Downloads, ~/Templates         Standard user directories
    - ~/Documents/Mega                 Cloud storage
    - ~/Documents/{COMPANY}            Company-specific documents
    - ~/Books, ~/Ebooks                Reading materials
    - ~/Videos, ~/Music, ~/Pictures    Media files
    - ~/bin                            User scripts
    - ~/.config                        Configuration files

    Development Directories:
    - ~/development/*                  Development tools (flyway, eclipse, etc.)
    - ~/git/{USER}/gitlab              GitLab repositories
    - ~/git/{USER}/github              GitHub repositories
    - ~/git/{COMPANY}                  Company repositories (if COMPANY set)
    - ~/git/other                      Other repositories
    - ~/workspaces/*                   IDE workspaces

ENVIRONMENT VARIABLES:
    MYLICULA_COMPANY                   Company name (optional, creates company dirs)
    MYLICULA_USERNAME                  Target username (default: \$USER)
    MYLICULA_HOME                      Target home directory (default: \$HOME)

REQUIREMENTS:
    - Root privileges (for system directories)
    - MYLICULA_COMPANY can be empty or unset

EXAMPLES:
    # Create directory structure
    sudo $(basename "$0")

    # Create with company-specific directories
    export MYLICULA_COMPANY="Acme"
    sudo $(basename "$0")

    # Test without making changes
    sudo $(basename "$0") --dry-run

    # Run with debug output
    sudo $(basename "$0") --debug

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
    echo "Directory Structure Creation"
}

#
# Function: validate_environment
# Description: Validate that the environment is ready for installation
#
validate_environment() {
    log "INFO" "Validating environment for directory structure creation..."

    # Check if we have root privileges (needed for system directories)
    if [[ $EUID -ne 0 ]]; then
        log "ERROR" "This script requires root privileges to create system directories"
        log "ERROR" "Please run with: sudo $(basename "$0")"
        return 1
    fi

    # Validate TARGET_HOME exists
    if [[ ! -d "$TARGET_HOME" ]]; then
        log "ERROR" "Target home directory does not exist: $TARGET_HOME"
        return 1
    fi

    # Check if COMPANY is set (can be empty string, that's OK)
    debug "COMPANY variable: '${COMPANY}' (empty is OK)"
    debug "TARGET_USER: ${TARGET_USER}"
    debug "TARGET_HOME: ${TARGET_HOME}"

    # Check idempotency - if most directories already exist, consider it installed
    local existing_count=0
    local total_check=5
    local check_dirs=(
        "${TARGET_HOME}/Downloads"
        "${TARGET_HOME}/development"
        "${TARGET_HOME}/git"
        "${TARGET_HOME}/workspaces"
        "/usr/lib/jvm"
    )

    for dir in "${check_dirs[@]}"; do
        if [[ -d "$dir" ]]; then
            ((existing_count++)) || true
        fi
    done

    if [[ $existing_count -ge $total_check ]]; then
        log "INFO" "All major directories already exist (${existing_count}/${total_check})"
        return 2  # Already installed
    fi

    log "INFO" "✓ Environment validation passed"
    return 0
}

#
# Function: run_installation
# Description: Perform the actual installation
#
run_installation() {
    log "INFO" "Creating directory structure..."

    local created_count=0
    local skipped_count=0
    local error_count=0

    # Create system directories
    log "INFO" "Creating system directories..."
    for dir in "${SYSTEM_DIRS[@]}"; do
        if create_directory "$dir"; then
            ((created_count++)) || true
        else
            ((error_count++)) || true
        fi
    done

    # Create user base directories
    log "INFO" "Creating user base directories..."
    for dir in "${USER_BASE_DIRS[@]}"; do
        if create_directory "$dir"; then
            ((created_count++)) || true
        else
            ((error_count++)) || true
        fi
    done

    # Create company-specific document directory (if COMPANY is set and not empty)
    if [[ -n "${COMPANY}" ]]; then
        log "INFO" "Creating company-specific directories for: ${COMPANY}..."
        local company_doc_dir="${TARGET_HOME}/Documents/${COMPANY}"
        if create_directory "$company_doc_dir"; then
            ((created_count++)) || true
        else
            ((error_count++)) || true
        fi

        local company_git_dir="${TARGET_HOME}/git/${COMPANY}"
        if create_directory "$company_git_dir"; then
            ((created_count++)) || true
        else
            ((error_count++)) || true
        fi
    else
        debug "COMPANY not set or empty, skipping company-specific directories"
    fi

    # Create development directories
    log "INFO" "Creating development directories..."
    for dir in "${DEV_DIRS[@]}"; do
        if create_directory "$dir"; then
            ((created_count++)) || true
        else
            ((error_count++)) || true
        fi
    done

    # Create git directories
    log "INFO" "Creating git directories..."
    for dir in "${GIT_DIRS[@]}"; do
        if create_directory "$dir"; then
            ((created_count++)) || true
        else
            ((error_count++)) || true
        fi
    done

    # Create workspace directories
    log "INFO" "Creating workspace directories..."
    for dir in "${WORKSPACE_DIRS[@]}"; do
        if create_directory "$dir"; then
            ((created_count++)) || true
        else
            ((error_count++)) || true
        fi
    done

    # Summary
    log "INFO" "Directory creation summary:"
    log "INFO" "  Created: $created_count"
    log "INFO" "  Skipped: $skipped_count (already exist)"
    log "INFO" "  Errors: $error_count"

    if [[ $error_count -gt 0 ]]; then
        log "ERROR" "Directory structure creation completed with errors"
        return 1
    fi

    log "INFO" "✓ Directory structure created successfully"
    return 0
}

#
# Function: cleanup_on_failure
# Description: Clean up partial installation if run_installation fails
#
cleanup_on_failure() {
    log "INFO" "No cleanup needed for directory creation (directories are idempotent)"
    return 0
}

#==================================================================================================
# Helper Functions
#==================================================================================================

#
# Function: create_directory
# Description: Create a directory if it doesn't exist (idempotent)
# Args:
#   $1 - Directory path
# Return: 0 on success (created or exists), 1 on error
#
create_directory() {
    local dir="$1"

    # Check if already exists
    if [[ -d "$dir" ]]; then
        debug "Directory already exists: $dir"
        return 0
    fi

    # Dry-run mode
    if [[ "$DRY_RUN_MODE" == true ]]; then
        log "INFO" "[DRY-RUN] Would create directory: $dir"
        return 0
    fi

    # Create directory
    if mkdir -p "$dir" 2>/dev/null; then
        debug "Created directory: $dir"
        return 0
    else
        log "ERROR" "Failed to create directory: $dir"
        return 1
    fi
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
