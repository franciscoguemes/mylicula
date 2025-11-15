#!/usr/bin/env bash
####################################################################################################
# Args           :
#                   -p, --pat           GitHub Personal Access Token for authentication (required)
#                   -u, --user          GitHub username to filter repositories (optional)
#                   -d, --directory     Target directory for cloning (default: $HOME/git/$USER/github)
#                   --skip-forks        Skip forked repositories
#                   --skip-archived     Skip archived repositories
#                   --debug             Enable debug logging
#                   --dry-run           Run without making any changes
#                   -h, --help          Display this help message
#
# Usage          : ./clone_github_repositories.sh -p <github_token>
#                  ./clone_github_repositories.sh -p <token> -u octocat
#                  ./clone_github_repositories.sh --help
#
# Output stdout  : Cloning progress and status messages
# Output stderr  : Error messages if any issues occur
# Return code    : 0   Success
#                  1   Validation failure
#                  2   Installation failure
#
# Description    : Automatically clones all repositories from a GitHub account into a specified
#                  directory structure. This script uses the clone_GitHub_repositories.sh script
#                  from the scripts/bash/github/ directory.
#
#                  The script will:
#                  - Fetch repositories owned by or accessible to the authenticated user
#                  - Clone them into the target directory
#                  - Skip forks and archived repos if requested
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

# Default values (can be overridden by command-line parameters)
GITHUB_TOKEN="${MYLICULA_GITHUB_PAT:-}"  # Read from environment variable if set
GITHUB_USER="${MYLICULA_GITHUB_USER:-}"  # Read from environment variable if set
TARGET_DIR="${HOME}/git/${USER}/github"
SKIP_FORKS=false
SKIP_ARCHIVED=false

# Path to the GitHub cloning script
readonly CLONE_SCRIPT="${BASE_DIR}/scripts/bash/github/clone_GitHub_repositories.sh"

#==================================================================================================
# Help Function
#==================================================================================================

show_help() {
    cat << EOF
GitHub Repository Cloner for MyLiCuLa

Usage: $(basename "$0") -p <github_token> [OPTIONS]

Automatically clone all repositories from a GitHub account

OPTIONS:
    -p, --pat           GitHub Personal Access Token for authentication
                        (required unless MYLICULA_GITHUB_PAT is set)
    -u, --user          GitHub username to filter repositories (optional)
                        If not specified, clones repositories for authenticated user
    -d, --directory     Target directory for cloning (default: \$HOME/git/\$USER/github)
    --skip-forks        Skip forked repositories
    --skip-archived     Skip archived repositories
    --debug             Enable debug logging with verbose output
    --dry-run           Run without making any changes to the system
    -h, --help          Display this help message

DESCRIPTION:
    This script automatically clones all repositories from a GitHub account
    into a specified directory structure. It uses the GitHub API to fetch
    all repositories and clones them into the target directory.

    By default, the script clones all repositories accessible to the authenticated
    user. You can filter by username, skip forks, or skip archived repositories.

    Configuration values can be provided in two ways:
    1. Command-line parameters: -p <token> -u <username>
    2. Environment variables: MYLICULA_GITHUB_PAT=<token> MYLICULA_GITHUB_USER=<username>

    When called during MyLiCuLa installation, values are read from environment
    variables automatically. Command-line parameters override environment variables.

REQUIREMENTS:
    - GitHub Personal Access Token with repo scope
    - Helper script: scripts/bash/github/clone_GitHub_repositories.sh
    - git (for cloning)
    - curl (for GitHub API calls)
    - jq (for JSON processing)

EXAMPLES:
    # Clone all repositories for authenticated user
    $(basename "$0") -p ghp_xxxxxxxxxxxx

    # Clone repositories for specific user
    $(basename "$0") -p ghp_xxxxxxxxxxxx -u octocat

    # Clone using environment variables (useful during installation)
    export MYLICULA_GITHUB_PAT="ghp_xxxxxxxxxxxx"
    export MYLICULA_GITHUB_USER="octocat"  # Optional
    $(basename "$0")

    # Clone to custom directory
    $(basename "$0") -p ghp_xxxxxxxxxxxx -d /custom/path

    # Skip forks and archived repositories
    $(basename "$0") -p ghp_xxxxxxxxxxxx --skip-forks --skip-archived

    # Dry run to see what would be cloned
    $(basename "$0") -p ghp_xxxxxxxxxxxx --dry-run

FILES:
    Clone script: ${CLONE_SCRIPT}
    Target directory: ${TARGET_DIR}

NOTES:
    - The target directory will be created if it doesn't exist
    - Existing repositories will be skipped (not overwritten)
    - Use --dry-run to preview what would be cloned
    - Requires valid GitHub Personal Access Token

AUTHOR:
    Francisco Güemes <francisco@franciscoguemes.com>

SEE ALSO:
    setup/README.md - Installer interface documentation
    scripts/bash/github/clone_GitHub_repositories.sh - Actual cloning logic
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
    echo "GitHub Repository Cloning"
}

#
# Function: validate_environment
# Description: Validate that the environment is ready for installation
#
validate_environment() {
    log "INFO" "Validating environment for GitHub repository cloning..."

    # Check if GitHub token is provided (either via parameter or environment variable)
    if [[ -z "$GITHUB_TOKEN" ]]; then
        log "ERROR" "GitHub Personal Access Token (PAT) is required"
        log "ERROR" ""
        log "ERROR" "Provide the token in one of two ways:"
        log "ERROR" "  1. Command-line parameter: -p <token>"
        log "ERROR" "  2. Environment variable: export MYLICULA_GITHUB_PAT=<token>"
        return 1
    fi

    # Validate token format (basic check - should start with ghp_, gho_, or ghs_)
    if [[ ! "$GITHUB_TOKEN" =~ ^(ghp_|gho_|ghs_|github_pat_) ]]; then
        log "WARN" "GitHub token format doesn't match expected pattern"
        log "WARN" "Modern tokens start with: ghp_, gho_, ghs_, or github_pat_"
        debug "Token starts with: ${GITHUB_TOKEN:0:4}"
    fi

    # Check required applications
    if ! check_required_app "git" "sudo nala install git"; then
        log "ERROR" "Missing required application: git"
        return 1
    fi

    if ! check_required_app "curl" "sudo nala install curl"; then
        log "ERROR" "Missing required application: curl"
        return 1
    fi

    if ! check_required_app "jq" "sudo nala install jq"; then
        log "ERROR" "Missing required application: jq"
        return 1
    fi

    # Check if clone script exists
    if [[ ! -f "$CLONE_SCRIPT" ]]; then
        log "ERROR" "Clone script not found: ${CLONE_SCRIPT}"
        log "ERROR" "Please ensure the repository is complete"
        return 1
    fi

    # Check if clone script is executable
    if [[ ! -x "$CLONE_SCRIPT" ]]; then
        log "ERROR" "Clone script is not executable: ${CLONE_SCRIPT}"
        log "ERROR" "Fix with: chmod +x ${CLONE_SCRIPT}"
        return 1
    fi

    # Check idempotency - if target directory exists and has repos, warn but continue
    if [[ -d "$TARGET_DIR" ]] && [[ -n "$(ls -A "$TARGET_DIR" 2>/dev/null)" ]]; then
        debug "Target directory already exists: ${TARGET_DIR}"
        debug "Existing repositories will be skipped (not overwritten)"
    fi

    log "INFO" "✓ Environment validation passed"
    return 0
}

#
# Function: run_installation
# Description: Perform the actual installation
#
run_installation() {
    log "INFO" "Starting GitHub repository cloning..."

    # Display configuration summary
    log "INFO" "============================================"
    log "INFO" "GitHub Repository Cloning Configuration"
    log "INFO" "============================================"
    log "INFO" "Authentication:   GitHub PAT (${#GITHUB_TOKEN} chars)"
    if [[ -n "$GITHUB_USER" ]]; then
        log "INFO" "Filter:           Repositories from user '${GITHUB_USER}'"
    else
        log "INFO" "Filter:           All accessible repositories (authenticated user)"
    fi
    log "INFO" "Target Directory: ${TARGET_DIR}"
    log "INFO" "Skip Forks:       ${SKIP_FORKS}"
    log "INFO" "Skip Archived:    ${SKIP_ARCHIVED}"
    log "INFO" "Debug Mode:       ${DEBUG_MODE}"
    log "INFO" "Dry Run:          ${DRY_RUN_MODE}"
    log "INFO" "============================================"
    log "INFO" ""

    # Create target directory if it doesn't exist
    if [[ ! -d "$TARGET_DIR" ]]; then
        if [[ "$DRY_RUN_MODE" == true ]]; then
            log "INFO" "[DRY-RUN] Would create directory: ${TARGET_DIR}"
        else
            debug "Creating target directory: ${TARGET_DIR}"
            if ! mkdir -p "$TARGET_DIR" 2>/dev/null; then
                log "ERROR" "Failed to create target directory: ${TARGET_DIR}"
                return 1
            fi
        fi
    fi

    # Build command arguments for clone script
    local -a cmd_args=()
    cmd_args+=("-p" "$GITHUB_TOKEN")
    cmd_args+=("-d" "$TARGET_DIR")

    # If a specific GitHub user is set, use it to filter repositories
    if [[ -n "$GITHUB_USER" ]]; then
        cmd_args+=("-u" "$GITHUB_USER")
    fi

    if [[ "$SKIP_FORKS" == true ]]; then
        cmd_args+=("--skip-forks")
    fi

    if [[ "$SKIP_ARCHIVED" == true ]]; then
        cmd_args+=("--skip-archived")
    fi

    if [[ "$DEBUG_MODE" == true ]]; then
        cmd_args+=("--debug")
    fi

    if [[ "$DRY_RUN_MODE" == true ]]; then
        cmd_args+=("--dry-run")
    fi

    # Execute the clone script
    log "INFO" "Executing clone script: ${CLONE_SCRIPT}"
    debug "Arguments: ${cmd_args[*]}"
    log "INFO" ""

    if ! "$CLONE_SCRIPT" "${cmd_args[@]}"; then
        log "ERROR" "Clone script failed"
        return 1
    fi

    log "INFO" ""
    log "INFO" "✓ GitHub repository cloning completed successfully"
    log "INFO" "Repositories cloned to: ${TARGET_DIR}"
    return 0
}

#
# Function: cleanup_on_failure
# Description: Clean up partial installation if run_installation fails
#
cleanup_on_failure() {
    log "INFO" "No cleanup needed for GitHub cloning (partial clones are valid)"
    log "INFO" "Existing cloned repositories remain in: ${TARGET_DIR}"
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
            -p|--pat)
                GITHUB_TOKEN="$2"
                shift 2
                ;;
            -u|--user)
                GITHUB_USER="$2"
                shift 2
                ;;
            -d|--directory)
                TARGET_DIR="$2"
                shift 2
                ;;
            --skip-forks)
                SKIP_FORKS=true
                shift
                ;;
            --skip-archived)
                SKIP_ARCHIVED=true
                shift
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

    # Setup logging (no-root: cloning repos to user's home directory)
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
