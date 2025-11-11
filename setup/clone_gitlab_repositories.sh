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
# Return code    : 0 on success, 1 on failure
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
# Author         : Francisco Güemes
# Email          : francisco@franciscoguemes.com
# See also       : https://stackoverflow.com/questions/14008125/shell-script-common-template
#                  https://devhints.io/bash
#                  https://linuxhint.com/30_bash_script_examples/
#                  https://stackoverflow.com/questions/192249/how-do-i-parse-command-line-arguments-in-bash
####################################################################################################

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

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

# Default values
GITLAB_URL="https://gitlab.com"
PAT_TOKEN="${MYLICULA_GITLAB_PAT:-}"  # Read from environment variable if set
TARGET_DIR="$HOME/git/$USER/gitlab"
GITLAB_USER="${MYLICULA_GITLAB_USER:-}"  # Read from environment variable if set
DEBUG=false
DRY_RUN=false

# Path to the GitLab cloning script
CLONE_SCRIPT="$BASE_DIR/scripts/bash/gitlab/clone_GitLab_projects.sh"

# Function to display help
show_help() {
    cat << EOF
Usage: $(basename "$0") -p <pat_token> [options]

Automatically clone all repositories from a GitLab account.

OPTIONS:
    -g, --gitlab-url    GitLab URL (default: https://gitlab.com)
    -p, --pat           Personal Access Token for GitLab authentication
                        (required unless MYLICULA_GITLAB_PAT is set)
    -u, --user          GitLab username to filter repositories (optional)
                        If not specified, clones ALL repositories you have access to
    -d, --directory     Target directory for cloning (default: \$HOME/git/\$USER/gitlab)
    --debug             Enable debug logging
    --dry-run           Run without making any changes
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

NOTES:
    - The target directory will be created if it doesn't exist
    - Existing repositories will be skipped (not overwritten)
    - Use --dry-run to preview what would be cloned

AUTHOR:
    Francisco Güemes <francisco@franciscoguemes.com>
EOF
}

# Parse command line arguments
while [[ "$#" -gt 0 ]]; do
    case $1 in
        -g|--gitlab-url) GITLAB_URL="$2"; shift ;;
        -p|--pat) PAT_TOKEN="$2"; shift ;;
        -d|--directory) TARGET_DIR="$2"; shift ;;
        -u|--user) GITLAB_USER="$2"; shift ;;
        --debug) DEBUG=true ;;
        --dry-run) DRY_RUN=true ;;
        -h|--help) show_help; exit 0 ;;
        *) echo "Error: Unknown parameter: $1" >&2; show_help; exit 1 ;;
    esac
    shift
done

# Check if PAT token is provided (either via parameter or environment variable)
if [ -z "$PAT_TOKEN" ]; then
    echo "Error: GitLab Personal Access Token (PAT) is required." >&2
    echo "" >&2
    echo "Provide the token in one of two ways:" >&2
    echo "  1. Command-line parameter: -p <token>" >&2
    echo "  2. Environment variable: export MYLICULA_GITLAB_PAT=<token>" >&2
    echo "" >&2
    show_help
    exit 1
fi

# Check if clone script exists
if [ ! -f "$CLONE_SCRIPT" ]; then
    echo "Error: Clone script not found at: $CLONE_SCRIPT" >&2
    exit 1
fi

# Check if clone script is executable
if [ ! -x "$CLONE_SCRIPT" ]; then
    echo "Error: Clone script is not executable: $CLONE_SCRIPT" >&2
    echo "  chmod +x $CLONE_SCRIPT" >&2
    exit 1
fi

# Create target directory if it doesn't exist
if [ ! -d "$TARGET_DIR" ]; then
    echo "Creating target directory: $TARGET_DIR"
    if [ "$DRY_RUN" = false ]; then
        mkdir -p "$TARGET_DIR"
    else
        echo "[DRY-RUN] Would create directory: $TARGET_DIR"
    fi
fi

# Build the clone command
echo "============================================"
echo "GitLab Repository Cloning"
echo "============================================"
echo "GitLab URL:       $GITLAB_URL"
echo "Authentication:   PAT token"
if [ -n "$GITLAB_USER" ]; then
    echo "Filter:           Repositories from user/namespace '$GITLAB_USER'"
else
    echo "Filter:           Owned repositories only (authenticated user)"
fi
echo "Target Directory: $TARGET_DIR"
echo "Debug Mode:       $DEBUG"
echo "Dry Run:          $DRY_RUN"
echo "============================================"
echo ""

# Build command arguments
CMD_ARGS=()
CMD_ARGS+=("-g" "$GITLAB_URL")
CMD_ARGS+=("-p" "$PAT_TOKEN")
CMD_ARGS+=("-d" "$TARGET_DIR")

# If a specific GitLab user is set, use it to filter repositories by namespace
if [ -n "$GITLAB_USER" ]; then
    CMD_ARGS+=("-i" "$GITLAB_USER")
fi

if [ "$DEBUG" = true ]; then
    CMD_ARGS+=("--debug")
fi

if [ "$DRY_RUN" = true ]; then
    CMD_ARGS+=("--dry-run")
fi

# Execute the clone script
echo "Starting repository cloning..."
echo ""

# Always execute the clone script - it handles dry-run internally
# This ensures users see what repositories would be cloned
"$CLONE_SCRIPT" "${CMD_ARGS[@]}"

echo ""
echo "============================================"
echo "Cloning process completed!"
echo "============================================"
echo "Repositories cloned to: $TARGET_DIR"
echo ""
