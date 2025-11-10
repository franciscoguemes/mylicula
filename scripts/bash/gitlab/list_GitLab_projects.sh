#!/usr/bin/env bash
####################################################################################################
#Args           : 
#                   -g, --gitlab-url  GitLab URL. The URL of the GitLab server to connect to.
#                   -p, --pat         PAT token. The PAT token to connect to GitLab.
#                   -n, --names       If included, list only project names; otherwise, return full JSON.
#                   --debug           Enable debug logging.
#                   --dry-run         Run the script without generating any changes.
#                   -h, --help        Display this help message.
#Usage          :   ./list_GitLab_projects.sh -g <gitlab_url> -p <pat_token> [-n]
#Output stdout  :   List of GitLab projects the user has access to or the full JSON response.
#Output stderr  :   Error messages if any issues occur.
#Return code    :   0 on success, 1 on failure.
#Description    :   Connects to a GitLab server and lists all projects the user has access to.
#                                                                                                                                                           
#Author       	: Francisco Güemes                                                
#Email         	: francisco@franciscoguemes.com                                           
#See also	    : https://stackoverflow.com/questions/14008125/shell-script-common-template
#                 https://devhints.io/bash
#                 https://linuxhint.com/30_bash_script_examples/
#                 https://stackoverflow.com/questions/192249/how-do-i-parse-command-line-arguments-in-bash  
####################################################################################################

# Default values
GITLAB_URL=""
LOG_FILE="/tmp/list_GitLab_projects.log"
DEBUG=false
DRY_RUN=false
LIST_NAMES=false

# Function to log messages
log() {
    local message="$1"
    # echo "$(date '+%Y-%m-%d %H:%M:%S') - $message" | tee -a "$LOG_FILE"  # Log to both terminal and file
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $message" >> "$LOG_FILE" 
}

# Function to display help
usage() {
    echo "Usage: $0 -g <gitlab_url> -p <pat_token> [-n] [--debug] [--dry-run] [-h|--help]"
    exit 1
}

# Function to fetch all projects from GitLab
fetch_projects() {
    local url="$1"
    local pat_token="$2"
    local all_projects="[]" # Initialize an empty JSON array
    local page=1

    # Loop through pages to get all projects
    while true; do
        local api_url="$url/api/v4/projects?simple=true&per_page=100&page=$page"
        log "Fetching page $page --> $api_url"
        response=$(curl --silent --header "PRIVATE-TOKEN: $pat_token" "$api_url")

        # Break the loop if no more projects are returned
        if [ "$(echo "$response" | jq '. | length')" -eq 0 ]; then
            break
        fi

        # Append the current page of projects to the all_projects array
        all_projects=$(echo "$all_projects" | jq --argjson new_projects "$response" '. + $new_projects')

        # Increment the page number
        page=$((page + 1))
    done

    echo "$all_projects"
}

# Parse arguments
while [[ "$#" -gt 0 ]]; do
    case "$1" in
        -g|--gitlab-url) GITLAB_URL="$2"; shift ;;
        -p|--pat) PAT_TOKEN="$2"; shift ;;
        -n|--names) LIST_NAMES=true ;;
        --debug) DEBUG=true ;;
        --dry-run) DRY_RUN=true ;;
        -h|--help) usage ;;
        *) echo "Unknown parameter passed: $1"; usage ;;
    esac
    shift
done

# Check if GITLAB_URL ends with a slash and remove it
GITLAB_URL="${GITLAB_URL%/}"

# Check if mandatory parameters are supplied
if [ -z "$GITLAB_URL" ] || [ -z "$PAT_TOKEN" ]; then
    echo "Error: GitLab URL and PAT token are mandatory."
    usage
fi

# Check if curl is installed
if ! command -v curl &> /dev/null; then
    echo "Error: curl is not installed. Please install curl:" >&2
    echo "  sudo nala install curl" >&2
    exit 1
fi

# Check if jq is installed
if ! command -v jq &> /dev/null; then
    echo "Error: jq is not installed. Please install jq:" >&2
    echo "  sudo nala install jq" >&2
    exit 1
fi

# Log the start of the script
log "Starting script execution."

# Dry run message
if [ "$DRY_RUN" = true ]; then
    log "Dry run mode enabled. No changes will be made."
fi

# Connect to GitLab and list projects
if [ "$DEBUG" = true ]; then
    log "Connecting to GitLab at $GITLAB_URL with PAT token."
fi

# Fetch projects from GitLab
if [ "$DRY_RUN" = false ]; then
    log "Fetching projects from GitLab... $GITLAB_URL/api/v4/projects"
    response=$(fetch_projects "$GITLAB_URL" "$PAT_TOKEN")

    # Check if the response is valid JSON
    if ! echo "$response" | jq . > /dev/null 2>&1; then
        log "Error: Invalid response from GitLab API."
        echo "Response: $response" >&2  # Redirect to stderr
        exit 1
    fi

    # Check if the response contains an error message
    if echo "$response" | jq -e 'has("message")' > /dev/null 2>&1; then
        log "Error: $response"
        exit 1
    fi
else
    log "Dry run: would fetch projects from GitLab."
    log "Generating an example of output..."
    SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    response="$(cat "$SCRIPT_DIR/projects-example.json")"  # Assuming you have an example JSON file
fi

# Output based on the -n flag
if [ "$LIST_NAMES" = true ]; then
    # Print the project names
    echo "$response" | jq -r '.[].name'
else
    # Print the full JSON response
    echo "$response" | jq
fi

# Log the end of the script
log "Script execution completed."
