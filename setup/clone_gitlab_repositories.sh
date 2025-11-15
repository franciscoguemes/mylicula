#!/usr/bin/env bash
####################################################################################################
# Args           :
#                   -g, --gitlab-url    GitLab URL (default: https://gitlab.com)
#                   -p, --pat           Personal Access Token for GitLab authentication (required)
#                   -u, --user          GitLab username to filter repositories (optional)
#                   -d, --directory     Target directory for cloning (default: $HOME/git/$USER/gitlab)
#                   --debug             Enable debug logging
#                   --dry-run           Run without making any changes
#                   -h, --help          Display this help message
#
# Usage          : ./clone_gitlab_repositories.sh -p <pat_token>
#                  ./clone_gitlab_repositories.sh -p <token> -u franciscoguemes
#                  ./clone_gitlab_repositories.sh --help
#
# Output stdout  : Cloning progress and status messages
# Output stderr  : Error messages if any issues occur
# Return code    : 0   Success
#                  1   Validation failure
#                  2   Installation failure
#
# Description    : Automatically clones all repositories from a GitLab account into a specified
#                  directory structure. This script uses the clone_GitLab_projects.sh script
#                  from the scripts/bash/gitlab/ directory.
#
#                  The script will:
#                  - Fetch projects owned by the authenticated user (or filtered by username)
#                  - Clone them preserving group/organization hierarchy (personal repos at root)
#                  - By default, only OWNED projects are fetched to avoid thousands of accessible projects
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
GITLAB_URL="https://gitlab.com"
PAT_TOKEN="${MYLICULA_GITLAB_PAT:-}"     # Read from environment variable if set
GITLAB_USER="${MYLICULA_GITLAB_USER:-}"  # Read from environment variable if set
TARGET_DIR="${HOME}/git/${USER}/gitlab"

# Path to the GitLab cloning script
readonly CLONE_SCRIPT="${BASE_DIR}/scripts/bash/gitlab/clone_GitLab_projects.sh"

#==================================================================================================
# Help Function
#==================================================================================================

show_help() {
    cat << EOF
GitLab Repository Cloner for MyLiCuLa

Usage: $(basename "$0") -p <pat_token> [OPTIONS]

Automatically clone all repositories from a GitLab account

OPTIONS:
    -g, --gitlab-url    GitLab URL (default: https://gitlab.com)
    -p, --pat           Personal Access Token for GitLab authentication
                        (required unless MYLICULA_GITLAB_PAT is set)
    -u, --user          GitLab username to filter repositories (optional)
                        If not specified, clones ALL repositories you have access to
    -d, --directory     Target directory for cloning (default: \$HOME/git/\$USER/gitlab)
    --debug             Enable debug logging with verbose output
    --dry-run           Run without making any changes to the system
    -h, --help          Display this help message

DESCRIPTION:
    This script automatically clones all repositories from a GitLab account
    into a specified directory structure. It uses the GitLab API to fetch
    all projects and clones them preserving the GitLab group/organization hierarchy.

    Directory structure examples:
    - Personal repos (single-level namespace): target_directory/docker
    - Group repos (multi-level namespace): target_directory/growth5875130/professional/ai

    Personal repositories (where namespace is just your username) are cloned
    directly to the target directory. Group/organization repositories maintain
    their full hierarchical path.

    By default (without -u), the script clones only repositories OWNED by the
    authenticated user (the owner of the PAT token). This prevents fetching
    thousands of public or group projects you may have access to.

    If you specify a GitLab username with -u, only repositories from that specific
    user/namespace will be cloned.

    Configuration values can be provided in two ways:
    1. Command-line parameters: -p <token> -u <username>
    2. Environment variables: MYLICULA_GITLAB_PAT=<token> MYLICULA_GITLAB_USER=<username>

    When called during MyLiCuLa installation, values are read from environment
    variables automatically. Command-line parameters override environment variables.

REQUIREMENTS:
    - Personal Access Token (PAT) with read_repository scope
    - Helper script: scripts/bash/gitlab/clone_GitLab_projects.sh
    - curl (for API calls)
    - jq (for JSON processing)
    - git (for cloning)

EXAMPLES:
    # Clone all repositories OWNED by the authenticated user
    $(basename "$0") -p glpat-xxxxxxxxxxxx

    # Clone only repositories from specific user/namespace
    $(basename "$0") -p glpat-xxxxxxxxxxxx -u franciscoguemes

    # Clone using environment variables (useful during installation)
    export MYLICULA_GITLAB_PAT="glpat-xxxxxxxxxxxx"
    export MYLICULA_GITLAB_USER="franciscoguemes"  # Optional
    $(basename "$0")

    # Clone from specific GitLab instance
    $(basename "$0") -g https://gitlab.company.com -p glpat-xxxxxxxxxxxx

    # Clone to custom directory
    $(basename "$0") -p glpat-xxxxxxxxxxxx -d /custom/path

    # Dry run to see what would be cloned
    $(basename "$0") -p glpat-xxxxxxxxxxxx --dry-run

FILES:
    Clone script: ${CLONE_SCRIPT}
    Target directory: ${TARGET_DIR}

NOTES:
    - The target directory will be created if it doesn't exist
    - Existing repositories will be skipped (not overwritten)
    - Use --dry-run to preview what would be cloned
    - Requires valid GitLab Personal Access Token

AUTHOR:
    Francisco Güemes <francisco@franciscoguemes.com>

SEE ALSO:
    setup/README.md - Installer interface documentation
    scripts/bash/gitlab/clone_GitLab_projects.sh - Actual cloning logic
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
    echo "GitLab Repository Cloning"
}

#
# Function: validate_environment
# Description: Validate that the environment is ready for installation
#
validate_environment() {
    log "INFO" "Validating environment for GitLab repository cloning..."

    # Check if PAT token is provided (either via parameter or environment variable)
    if [[ -z "$PAT_TOKEN" ]]; then
        log "ERROR" "GitLab Personal Access Token (PAT) is required but not found"
        log "ERROR" ""

        # Check if environment variable is set but empty
        if [[ -v MYLICULA_GITLAB_PAT ]]; then
            log "ERROR" "MYLICULA_GITLAB_PAT is set but empty"
            log "ERROR" "Please set a valid token in: ${CONFIG_FILE:-~/.config/mylicula/mylicula.conf}"
        else
            log "ERROR" "MYLICULA_GITLAB_PAT environment variable is not set"
            log "ERROR" "This should be loaded from: ${CONFIG_FILE:-~/.config/mylicula/mylicula.conf}"
        fi

        log "ERROR" ""
        log "ERROR" "You can also provide the token via command-line:"
        log "ERROR" "  $(basename "$0") -p <your-gitlab-token>"
        return 1
    fi

    debug "GitLab PAT token found (length: ${#PAT_TOKEN} characters)"

    # Validate token format (basic check - should start with glpat- or glptt-)
    if [[ ! "$PAT_TOKEN" =~ ^(glpat-|glptt-) ]]; then
        log "WARN" "GitLab token format doesn't match expected pattern"
        log "WARN" "Modern tokens start with: glpat- (personal) or glptt- (project)"
        debug "Token starts with: ${PAT_TOKEN:0:6}"
    fi

    # Validate GitLab URL format
    if [[ ! "$GITLAB_URL" =~ ^https?:// ]]; then
        log "ERROR" "Invalid GitLab URL format: ${GITLAB_URL}"
        log "ERROR" "URL must start with http:// or https://"
        return 1
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
    log "INFO" "Starting GitLab repository cloning..."

    # Display configuration summary
    log "INFO" "============================================"
    log "INFO" "GitLab Repository Cloning Configuration"
    log "INFO" "============================================"
    log "INFO" "GitLab URL:       ${GITLAB_URL}"
    log "INFO" "Authentication:   PAT token (${#PAT_TOKEN} chars)"
    if [[ -n "$GITLAB_USER" ]]; then
        log "INFO" "Filter:           Repositories from user/namespace '${GITLAB_USER}'"
    else
        log "INFO" "Filter:           Owned repositories only (authenticated user)"
    fi
    log "INFO" "Target Directory: ${TARGET_DIR}"
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
    cmd_args+=("-g" "$GITLAB_URL")
    cmd_args+=("-p" "$PAT_TOKEN")
    cmd_args+=("-d" "$TARGET_DIR")

    # If a specific GitLab user is set, use -i flag to filter by namespace
    # Note: The underlying clone script uses -i for namespace filtering
    if [[ -n "$GITLAB_USER" ]]; then
        cmd_args+=("-i" "$GITLAB_USER")
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
    log "INFO" "✓ GitLab repository cloning completed successfully"
    log "INFO" "Repositories cloned to: ${TARGET_DIR}"
    return 0
}

#
# Function: cleanup_on_failure
# Description: Clean up partial installation if run_installation fails
#
cleanup_on_failure() {
    log "INFO" "No cleanup needed for GitLab cloning (partial clones are valid)"
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
            -g|--gitlab-url)
                GITLAB_URL="$2"
                shift 2
                ;;
            -p|--pat)
                PAT_TOKEN="$2"
                shift 2
                ;;
            -u|--user)
                GITLAB_USER="$2"
                shift 2
                ;;
            -d|--directory)
                TARGET_DIR="$2"
                shift 2
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
