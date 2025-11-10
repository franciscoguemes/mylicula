#!/usr/bin/env bash
####################################################################################################
#Args           :
#                   -t, --token           GitHub Personal Access Token (PAT) for authentication
#                   -d, --directory       Root directory where repositories will be cloned
#                   -u, --user            GitHub username to clone repositories from (optional, defaults to authenticated user)
#                   -i, --include-owners  Owner names to include (comma-separated). Only repos from these owners will be cloned
#                   -e, --exclude-owners  Owner names to exclude (comma-separated). Repos from these owners will be skipped
#                   --skip-forks          Skip forked repositories
#                   --skip-archived       Skip archived repositories
#                   --debug               Enable debug logging
#                   --dry-run             Run the script without generating any changes
#                   -h, --help            Display this help message
#Usage          :   ./clone_GitHub_repositories.sh -t <github_token> -d <root_directory>
#                   ./clone_GitHub_repositories.sh -t <token> -d ~/repos -u octocat
#                   ./clone_GitHub_repositories.sh --help
#Output stdout  :   Cloning status of GitHub repositories
#Output stderr  :   Error messages if any issues occur
#Return code    :   0 on success, 1 on failure
#Description    :   Connects to GitHub, retrieves repositories, and clones them into a specified directory
#                   reproducing the directory structure (owner/repository).
#                   It uses the GitHub CLI (gh) to interact with GitHub API.
#
#Author       	: Francisco Güemes
#Email         	: francisco@franciscoguemes.com
#See also	    : https://stackoverflow.com/questions/14008125/shell-script-common-template
#                 https://devhints.io/bash
#                 https://linuxhint.com/30_bash_script_examples/
#                 https://stackoverflow.com/questions/192249/how-do-i-parse-command-line-arguments-in-bash
#                 https://cli.github.com/manual/gh_repo_list
####################################################################################################

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Default values
GITHUB_TOKEN="${MYLICULA_GITHUB_PAT:-}"  # Read from environment variable if set
ROOT_DIR=""
GITHUB_USER=""
LOG_FILE="/tmp/clone_GitHub_repositories.log"
DEBUG=false
DRY_RUN=false
SKIP_FORKS=false
SKIP_ARCHIVED=false
INCLUDE_OWNERS=()
EXCLUDE_OWNERS=()
APP_NAME="mylicula"

# Function to log messages
log() {
    local message="$1"
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $message" >> "$LOG_FILE"
}

# Function to display help
show_help() {
    cat << EOF
Usage: $(basename "$0") -t <github_token> -d <root_directory> [options]

Clone all repositories from a GitHub account maintaining owner/repository structure.

OPTIONS:
    -t, --token           GitHub Personal Access Token for authentication
                          (required unless MYLICULA_GITHUB_PAT is set)
    -d, --directory       Root directory where repositories will be cloned (required)
    -u, --user            GitHub username to clone repositories from (optional)
                          If not specified, clones repositories for authenticated user
    -i, --include-owners  Owner names to include (comma-separated)
                          Only repositories from these owners will be cloned
    -e, --exclude-owners  Owner names to exclude (comma-separated)
                          Repositories from these owners will be skipped
    --skip-forks          Skip forked repositories
    --skip-archived       Skip archived repositories
    --debug               Enable debug logging
    --dry-run             Run without making any changes
    -h, --help            Display this help message

DESCRIPTION:
    This script automatically clones all repositories from a GitHub account
    into a specified directory structure. It uses the GitHub CLI (gh) to fetch
    all repositories and clones them maintaining the owner/repository structure.

    The script creates a directory structure: root_dir/owner/repository
    making it easy to maintain the same structure locally as on GitHub.

    Configuration values can be provided in two ways:
    1. Command-line parameter: -t <token>
    2. Environment variable: MYLICULA_GITHUB_PAT=<token>

    When called during MyLiCuLa installation, values are read from environment
    variables automatically. Command-line parameter overrides environment variable.

    You cannot use both --include-owners and --exclude-owners at the same time.

REQUIREMENTS:
    - GitHub CLI (gh) must be installed
    - GitHub Personal Access Token with repo scope
    - git (for cloning)
    - jq (for JSON processing)

EXAMPLES:
    # Clone all repositories using command-line parameter
    $(basename "$0") -t ghp_xxxxxxxxxxxx -d ~/github-repos

    # Clone using environment variable (useful during installation)
    export MYLICULA_GITHUB_PAT="ghp_xxxxxxxxxxxx"
    $(basename "$0") -d ~/github-repos

    # Clone repositories for specific user
    $(basename "$0") -t ghp_xxxxxxxxxxxx -d ~/repos -u octocat

    # Clone only from specific owners
    $(basename "$0") -t ghp_xxxxxxxxxxxx -d ~/repos -i "octocat,github"

    # Skip forks and archived repositories
    $(basename "$0") -t ghp_xxxxxxxxxxxx -d ~/repos --skip-forks --skip-archived

    # Dry run to see what would be cloned
    $(basename "$0") -t ghp_xxxxxxxxxxxx -d ~/repos --dry-run

NOTES:
    - The target directory will be created if it doesn't exist
    - Existing repositories will be skipped (not overwritten)
    - Use --dry-run to preview what would be cloned
    - Progress is logged to /var/log/mylicula/clone_GitHub_repositories.log

AUTHOR:
    Francisco Güemes <francisco@franciscoguemes.com>
EOF
}

# Function to clone repositories
clone_repositories() {
    local repos_json="$1"
    local root_dir="$2"

    # Count total repositories
    local total_repos
    total_repos=$(echo "$repos_json" | jq '. | length')
    log "Total repositories to process: $total_repos"

    local cloned_count=0
    local skipped_count=0

    # Iterate over each repository in the JSON array
    echo "$repos_json" | jq -c '.[]' | while read -r repo; do
        local repo_name
        repo_name=$(echo "$repo" | jq -r '.name')
        local owner
        owner=$(echo "$repo" | jq -r '.owner.login')
        local repo_url
        repo_url=$(echo "$repo" | jq -r '.url')
        local is_fork
        is_fork=$(echo "$repo" | jq -r '.isFork')
        local is_archived
        is_archived=$(echo "$repo" | jq -r '.isArchived')
        local full_name
        full_name=$(echo "$repo" | jq -r '.nameWithOwner')

        # Check if we should skip forks
        if [ "$SKIP_FORKS" = true ] && [ "$is_fork" = "true" ]; then
            log "Skipping fork: $full_name"
            ((skipped_count++)) || true
            continue
        fi

        # Check if we should skip archived repos
        if [ "$SKIP_ARCHIVED" = true ] && [ "$is_archived" = "true" ]; then
            log "Skipping archived repository: $full_name"
            ((skipped_count++)) || true
            continue
        fi

        # Check if repository belongs to included owners
        if [[ ${#INCLUDE_OWNERS[@]} -gt 0 ]]; then
            if ! [[ " ${INCLUDE_OWNERS[@]} " =~ " ${owner} " ]]; then
                log "Skipping $full_name (owner not in include list)"
                ((skipped_count++)) || true
                continue
            fi
        fi

        # Check if repository belongs to excluded owners
        if [[ ${#EXCLUDE_OWNERS[@]} -gt 0 ]]; then
            if [[ " ${EXCLUDE_OWNERS[@]} " =~ " ${owner} " ]]; then
                log "Skipping $full_name (owner in exclude list)"
                ((skipped_count++)) || true
                continue
            fi
        fi

        # Check if the repository already exists
        if [ ! -d "$root_dir/$repo_name" ]; then
            if [ "$DRY_RUN" = false ]; then
                echo "Cloning $full_name into $root_dir/$repo_name"

                # Modify URL to include PAT token for authentication
                # Convert https://github.com/owner/repo to https://token@github.com/owner/repo
                local clone_url="${repo_url/https:\/\//https:\/\/${GITHUB_TOKEN}@}"

                git clone "$clone_url" "$root_dir/$repo_name" 2>&1 | tee -a "$LOG_FILE"
                log "Cloned repository: $full_name into $root_dir"
                ((cloned_count++)) || true
            else
                echo "[DRY-RUN] Would clone: $full_name into $root_dir/$repo_name"
                log "Dry run: would clone repository: $full_name into $root_dir"
                ((cloned_count++)) || true
            fi
        else
            echo "Repository $full_name already exists in $root_dir, skipping"
            log "Repository $repo_name already exists in $root_dir, skipping clone"
            ((skipped_count++)) || true
        fi
    done

    log "Cloning completed. Cloned: $cloned_count, Skipped: $skipped_count"
}

# Parse arguments
while [[ "$#" -gt 0 ]]; do
    case "$1" in
        -t|--token) GITHUB_TOKEN="$2"; shift ;;
        -d|--directory) ROOT_DIR="$2"; shift ;;
        -u|--user) GITHUB_USER="$2"; shift ;;
        -i|--include-owners)
            if [[ ${#EXCLUDE_OWNERS[@]} -gt 0 ]]; then
                echo "Error: You cannot use both --include-owners and --exclude-owners at the same time." >&2
                show_help
                exit 1
            fi
            IFS=',' read -r -a INCLUDE_OWNERS <<< "$2"; shift ;;
        -e|--exclude-owners)
            if [[ ${#INCLUDE_OWNERS[@]} -gt 0 ]]; then
                echo "Error: You cannot use both --include-owners and --exclude-owners at the same time." >&2
                show_help
                exit 1
            fi
            IFS=',' read -r -a EXCLUDE_OWNERS <<< "$2"; shift ;;
        --skip-forks) SKIP_FORKS=true ;;
        --skip-archived) SKIP_ARCHIVED=true ;;
        --debug) DEBUG=true ;;
        --dry-run) DRY_RUN=true ;;
        -h|--help) show_help; exit 0 ;;
        *) echo "Error: Unknown parameter: $1" >&2; show_help; exit 1 ;;
    esac
    shift
done

# Check if mandatory parameters are supplied
if [ -z "$GITHUB_TOKEN" ] || [ -z "$ROOT_DIR" ]; then
    if [ -z "$GITHUB_TOKEN" ]; then
        echo "Error: GitHub Personal Access Token (PAT) is required." >&2
        echo "" >&2
        echo "Provide the token in one of two ways:" >&2
        echo "  1. Command-line parameter: -t <token>" >&2
        echo "  2. Environment variable: export MYLICULA_GITHUB_PAT=<token>" >&2
        echo "" >&2
    fi
    if [ -z "$ROOT_DIR" ]; then
        echo "Error: Root directory is required." >&2
        echo "" >&2
        echo "Provide the directory using: -d <directory>" >&2
        echo "" >&2
    fi
    show_help
    exit 1
fi

# Check if gh is installed
if ! command -v gh &> /dev/null; then
    echo "Error: gh (GitHub CLI) is not installed. Please install gh:" >&2
    echo "  sudo nala install gh" >&2
    echo "  Or visit: https://cli.github.com/" >&2
    exit 1
fi

# Check if jq is installed
if ! command -v jq &> /dev/null; then
    echo "Error: jq is not installed. Please install jq:" >&2
    echo "  sudo nala install jq" >&2
    exit 1
fi

# Check if git is installed
if ! command -v git &> /dev/null; then
    echo "Error: git is not installed. Please install git:" >&2
    echo "  sudo nala install git" >&2
    exit 1
fi

# Setup log directory
log_dir="/var/log/${APP_NAME}"
if [ -d "$log_dir" ] && [ -w "$log_dir" ]; then
    # Directory exists and is writable
    LOG_FILE="$log_dir/$(basename "$0" .sh).log"
elif [ -w "/var/log" ]; then
    # /var/log is writable, create app directory
    mkdir -p "$log_dir" 2>/dev/null || true
    if [ -d "$log_dir" ] && [ -w "$log_dir" ]; then
        LOG_FILE="$log_dir/$(basename "$0" .sh).log"
    else
        LOG_FILE="/tmp/$(basename "$0" .sh).log"
    fi
else
    # Fallback to /tmp if we can't write to /var/log
    LOG_FILE="/tmp/$(basename "$0" .sh).log"
fi

# Log separator with timestamp
echo "========================================" >> "$LOG_FILE"
log "Script execution started"

# Create target directory if it doesn't exist
if [ ! -d "$ROOT_DIR" ]; then
    echo "Creating target directory: $ROOT_DIR"
    if [ "$DRY_RUN" = false ]; then
        mkdir -p "$ROOT_DIR"
        log "Created root directory: $ROOT_DIR"
    else
        echo "[DRY-RUN] Would create directory: $ROOT_DIR"
        log "Dry run: would create directory: $ROOT_DIR"
    fi
fi

# Display configuration
echo "============================================"
echo "GitHub Repository Cloning"
echo "============================================"
echo "Target Directory: $ROOT_DIR"
if [ -n "$GITHUB_USER" ]; then
    echo "GitHub User:      $GITHUB_USER"
else
    echo "GitHub User:      (authenticated user)"
fi
echo "Skip Forks:       $SKIP_FORKS"
echo "Skip Archived:    $SKIP_ARCHIVED"
echo "Debug Mode:       $DEBUG"
echo "Dry Run:          $DRY_RUN"
echo "============================================"
echo ""

log "Configuration: ROOT_DIR=$ROOT_DIR, GITHUB_USER=$GITHUB_USER, SKIP_FORKS=$SKIP_FORKS, SKIP_ARCHIVED=$SKIP_ARCHIVED"

# Dry run message
if [ "$DRY_RUN" = true ]; then
    log "Dry run mode enabled. No actual cloning will occur."
fi

# Set GitHub token for gh CLI
export GH_TOKEN="$GITHUB_TOKEN"

# Fetch repositories
echo "Fetching repositories from GitHub..."
log "Fetching repositories from GitHub..."

# Build gh command based on whether user is specified
if [ -n "$GITHUB_USER" ]; then
    repos_json=$(gh repo list "$GITHUB_USER" --limit 1000 --json name,owner,nameWithOwner,url,isPrivate,isFork,isArchived,visibility 2>&1)
else
    repos_json=$(gh repo list --limit 1000 --json name,owner,nameWithOwner,url,isPrivate,isFork,isArchived,visibility 2>&1)
fi

# Check if command was successful
if [ $? -ne 0 ]; then
    log "Error: Failed to fetch repositories from GitHub"
    echo "Error: $repos_json" >&2
    exit 1
fi

# Validate JSON response
if ! echo "$repos_json" | jq . > /dev/null 2>&1; then
    log "Error: Invalid JSON response from GitHub CLI"
    echo "Response: $repos_json" >&2
    exit 1
fi

log "Successfully fetched repositories"

if [ "$DRY_RUN" = true ]; then
    log "Dry run mode: will preview repositories without cloning"
fi

echo ""
echo "Starting repository cloning..."
echo ""

# Clone repositories
clone_repositories "$repos_json" "$ROOT_DIR"

echo ""
echo "============================================"
echo "Cloning process completed!"
echo "============================================"
echo "Repositories cloned to: $ROOT_DIR"
echo ""

log "Script execution completed"
