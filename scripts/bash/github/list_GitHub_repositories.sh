#!/usr/bin/env bash
####################################################################################################
#Args           :
#                   -p, --pat       GitHub Personal Access Token (PAT) for authentication
#                   -u, --user        GitHub username to list repositories from (optional, defaults to authenticated user)
#                   -n, --names       If included, list only repository names; otherwise, return full JSON
#                   --debug           Enable debug logging
#                   --dry-run         Run the script without generating any changes
#                   -h, --help        Display this help message
#Usage          :   ./list_GitHub_repositories.sh -p <github_token> [-u <username>] [-n]
#Output stdout  :   List of GitHub repositories the user has access to or the full JSON response
#Output stderr  :   Error messages if any issues occur
#Return code    :   0 on success, 1 on failure
#Description    :   Connects to GitHub and lists all repositories the user has access to.
#                   Uses GitHub CLI (gh) for API interaction.
#
#Author       	: Francisco Güemes
#Email         	: francisco@franciscoguemes.com
#See also	    : https://stackoverflow.com/questions/14008125/shell-script-common-template
#                 https://devhints.io/bash
#                 https://linuxhint.com/30_bash_script_examples/
#                 https://stackoverflow.com/questions/192249/how-do-i-parse-command-line-arguments-in-bash
#                 https://cli.github.com/manual/gh_repo_list
####################################################################################################

# Default values
GITHUB_TOKEN="${MYLICULA_GITHUB_PAT:-}"  # Read from environment variable if set
GITHUB_USER=""
LOG_FILE="/tmp/list_GitHub_repositories.log"
DEBUG=false
DRY_RUN=false
LIST_NAMES=false
APP_NAME="mylicula"

# Function to log messages
log() {
    local message="$1"
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $message" >> "$LOG_FILE"
}

# Function to display help
show_help() {
    cat << EOF
Usage: $(basename "$0") -p <github_token> [options]

List all repositories from a GitHub account.

OPTIONS:
    -p, --pat       GitHub Personal Access Token for authentication
                      (required unless MYLICULA_GITHUB_PAT is set)
    -u, --user        GitHub username to list repositories from (optional)
                      If not specified, lists repositories for authenticated user
    -n, --names       List only repository names instead of full JSON
    --debug           Enable debug logging
    --dry-run         Run without making any changes (uses example data)
    -h, --help        Display this help message

DESCRIPTION:
    This script connects to GitHub using the GitHub CLI (gh) and lists all
    repositories the user has access to. It can list repositories for the
    authenticated user or for a specific GitHub username.

    The PAT token can be provided in two ways:
    1. Command-line parameter: -p <token>
    2. Environment variable: MYLICULA_GITHUB_PAT=<token>

    When called during MyLiCuLa installation, the token is read from the
    environment variable automatically. Command-line parameter overrides environment variable.

REQUIREMENTS:
    - GitHub CLI (gh) must be installed
    - GitHub Personal Access Token with repo scope

EXAMPLES:
    # List all repositories using command-line parameter
    $(basename "$0") -p ghp_xxxxxxxxxxxx

    # List using environment variable (useful during installation)
    export MYLICULA_GITHUB_PAT="ghp_xxxxxxxxxxxx"
    $(basename "$0")

    # List repositories for specific user
    $(basename "$0") -p ghp_xxxxxxxxxxxx -u octocat

    # List only repository names
    $(basename "$0") -p ghp_xxxxxxxxxxxx -n

    # Dry run mode
    $(basename "$0") -p ghp_xxxxxxxxxxxx --dry-run

AUTHOR:
    Francisco Güemes <francisco@franciscoguemes.com>
EOF
}

# Parse arguments
while [[ "$#" -gt 0 ]]; do
    case "$1" in
        -p|--pat) GITHUB_TOKEN="$2"; shift ;;
        -u|--user) GITHUB_USER="$2"; shift ;;
        -n|--names) LIST_NAMES=true ;;
        --debug) DEBUG=true ;;
        --dry-run) DRY_RUN=true ;;
        -h|--help) show_help; exit 0 ;;
        *) echo "Error: Unknown parameter: $1" >&2; show_help; exit 1 ;;
    esac
    shift
done

# Check if mandatory parameters are supplied
if [ -z "$GITHUB_TOKEN" ]; then
    echo "Error: GitHub Personal Access Token (PAT) is required." >&2
    echo "" >&2
    echo "Provide the token in one of two ways:" >&2
    echo "  1. Command-line parameter: -p <token>" >&2
    echo "  2. Environment variable: export MYLICULA_GITHUB_PAT=<token>" >&2
    echo "" >&2
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

# Check if jq is installed (needed for JSON processing)
if ! command -v jq &> /dev/null; then
    echo "Error: jq is not installed. Please install jq:" >&2
    echo "  sudo nala install jq" >&2
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

# Dry run message
if [ "$DRY_RUN" = true ]; then
    log "Dry run mode enabled. No changes will be made."
fi

# Set GitHub token for gh CLI
export GH_TOKEN="$GITHUB_TOKEN"

# Build gh command
if [ "$DEBUG" = true ]; then
    if [ -n "$GITHUB_USER" ]; then
        log "Fetching repositories for user: $GITHUB_USER"
    else
        log "Fetching repositories for authenticated user"
    fi
fi

# Fetch repositories from GitHub
log "Fetching repositories from GitHub..."

# Build gh command based on whether user is specified
if [ -n "$GITHUB_USER" ]; then
    # List repos for specific user
    response=$(gh repo list "$GITHUB_USER" --limit 1000 --json name,owner,nameWithOwner,url,isPrivate,isFork,isArchived,visibility 2>&1)
else
    # List repos for authenticated user
    response=$(gh repo list --limit 1000 --json name,owner,nameWithOwner,url,isPrivate,isFork,isArchived,visibility 2>&1)
fi

# Check if command was successful
if [ $? -ne 0 ]; then
    log "Error: Failed to fetch repositories from GitHub"
    echo "Error: $response" >&2
    exit 1
fi

# Validate JSON response
if ! echo "$response" | jq . > /dev/null 2>&1; then
    log "Error: Invalid JSON response from GitHub CLI"
    echo "Response: $response" >&2
    exit 1
fi

log "Successfully fetched repositories"

if [ "$DRY_RUN" = true ]; then
    log "Dry run mode: fetched real repository data (no changes made)"
fi

# Output based on the -n flag
if [ "$LIST_NAMES" = true ]; then
    # Print only repository names
    echo "$response" | jq -r '.[].name'
else
    # Print the full JSON response
    echo "$response" | jq
fi

# Log the end of the script
log "Script execution completed"
