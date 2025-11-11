#!/usr/bin/env bash
####################################################################################################
# Args           :
#                   -t, --token         GitHub Personal Access Token for authentication (required)
#                   -u, --user          GitHub username to filter repositories (optional)
#                   -d, --directory     Target directory for cloning (default: $HOME/git/$USER/github)
#                   --skip-forks        Skip forked repositories
#                   --skip-archived     Skip archived repositories
#                   --debug             Enable debug logging
#                   --dry-run           Run without making any changes
#                   -h, --help          Display this help message
#
# Usage          : ./clone_github_repositories.sh -t <github_token>
#                  ./clone_github_repositories.sh -t <token> -u octocat
#                  ./clone_github_repositories.sh --help
#
# Output stdout  : Cloning progress and status messages
# Output stderr  : Error messages if any issues occur
# Return code    : 0 on success, 1 on failure
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
GITHUB_TOKEN="${MYLICULA_GITHUB_PAT:-}"  # Read from environment variable if set
TARGET_DIR="$HOME/git/$USER/github"
GITHUB_USER="${MYLICULA_GITHUB_USER:-}"  # Read from environment variable if set
DEBUG=false
DRY_RUN=false
SKIP_FORKS=false
SKIP_ARCHIVED=false

# Path to the GitHub cloning script
CLONE_SCRIPT="$BASE_DIR/scripts/bash/github/clone_GitHub_repositories.sh"

# Function to display help
show_help() {
    cat << EOF
Usage: $(basename "$0") -t <github_token> [options]

Automatically clone all repositories from a GitHub account.

OPTIONS:
    -t, --token         GitHub Personal Access Token for authentication
                        (required unless MYLICULA_GITHUB_PAT is set)
    -u, --user          GitHub username to filter repositories (optional)
                        If not specified, clones repositories for authenticated user
    -d, --directory     Target directory for cloning (default: \$HOME/git/\$USER/github)
    --skip-forks        Skip forked repositories
    --skip-archived     Skip archived repositories
    --debug             Enable debug logging
    --dry-run           Run without making any changes
    -h, --help          Display this help message

DESCRIPTION:
    This script automatically clones all repositories from a GitHub account
    into a specified directory structure. It uses the GitHub CLI (gh) to fetch
    all repositories and clones them into the target directory.

    By default, the script clones all repositories accessible to the authenticated
    user. You can filter by username, skip forks, or skip archived repositories.

    Configuration values can be provided in two ways:
    1. Command-line parameters: -t <token> -u <username>
    2. Environment variables: MYLICULA_GITHUB_PAT=<token> MYLICULA_GITHUB_USER=<username>

    When called during MyLiCuLa installation, values are read from environment
    variables automatically. Command-line parameters override environment variables.

REQUIREMENTS:
    - GitHub Personal Access Token with repo scope
    - GitHub CLI (gh) must be installed
    - Helper script: scripts/bash/github/clone_GitHub_repositories.sh
    - git (for cloning)
    - jq (for JSON processing)

EXAMPLES:
    # Clone all repositories for authenticated user
    $(basename "$0") -t ghp_xxxxxxxxxxxx

    # Clone repositories for specific user
    $(basename "$0") -t ghp_xxxxxxxxxxxx -u octocat

    # Clone using environment variables (useful during installation)
    export MYLICULA_GITHUB_PAT="ghp_xxxxxxxxxxxx"
    export MYLICULA_GITHUB_USER="octocat"  # Optional
    $(basename "$0")

    # Clone to custom directory
    $(basename "$0") -t ghp_xxxxxxxxxxxx -d /custom/path

    # Skip forks and archived repositories
    $(basename "$0") -t ghp_xxxxxxxxxxxx --skip-forks --skip-archived

    # Dry run to see what would be cloned
    $(basename "$0") -t ghp_xxxxxxxxxxxx --dry-run

NOTES:
    - The target directory will be created if it doesn't exist
    - Existing repositories will be skipped (not overwritten)
    - Use --dry-run to preview what would be cloned
    - GitHub CLI (gh) must be installed and configured

AUTHOR:
    Francisco Güemes <francisco@franciscoguemes.com>
EOF
}

# Parse command line arguments
while [[ "$#" -gt 0 ]]; do
    case $1 in
        -t|--token) GITHUB_TOKEN="$2"; shift ;;
        -d|--directory) TARGET_DIR="$2"; shift ;;
        -u|--user) GITHUB_USER="$2"; shift ;;
        --skip-forks) SKIP_FORKS=true ;;
        --skip-archived) SKIP_ARCHIVED=true ;;
        --debug) DEBUG=true ;;
        --dry-run) DRY_RUN=true ;;
        -h|--help) show_help; exit 0 ;;
        *) echo "Error: Unknown parameter: $1" >&2; show_help; exit 1 ;;
    esac
    shift
done

# Check if GitHub token is provided (either via parameter or environment variable)
if [ -z "$GITHUB_TOKEN" ]; then
    echo "Error: GitHub Personal Access Token (PAT) is required." >&2
    echo "" >&2
    echo "Provide the token in one of two ways:" >&2
    echo "  1. Command-line parameter: -t <token>" >&2
    echo "  2. Environment variable: export MYLICULA_GITHUB_PAT=<token>" >&2
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
echo "GitHub Repository Cloning"
echo "============================================"
echo "Authentication:   GitHub PAT"
if [ -n "$GITHUB_USER" ]; then
    echo "Filter:           Repositories from user '$GITHUB_USER'"
else
    echo "Filter:           All accessible repositories (authenticated user)"
fi
echo "Target Directory: $TARGET_DIR"
echo "Skip Forks:       $SKIP_FORKS"
echo "Skip Archived:    $SKIP_ARCHIVED"
echo "Debug Mode:       $DEBUG"
echo "Dry Run:          $DRY_RUN"
echo "============================================"
echo ""

# Build command arguments
CMD_ARGS=()
CMD_ARGS+=("-t" "$GITHUB_TOKEN")
CMD_ARGS+=("-d" "$TARGET_DIR")

# If a specific GitHub user is set, use it to filter repositories
if [ -n "$GITHUB_USER" ]; then
    CMD_ARGS+=("-u" "$GITHUB_USER")
fi

if [ "$SKIP_FORKS" = true ]; then
    CMD_ARGS+=("--skip-forks")
fi

if [ "$SKIP_ARCHIVED" = true ]; then
    CMD_ARGS+=("--skip-archived")
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
