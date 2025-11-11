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
    local max_pages=100  # Safety limit to prevent infinite loops

    # Loop through pages to get all projects
    while [ $page -le $max_pages ]; do
        # Use owned=true to get only projects owned by the authenticated user
        # This prevents fetching thousands of public/group projects
        local api_url="$url/api/v4/projects?owned=true&per_page=100&page=$page"
        log "Fetching page $page --> $api_url"

        # Only show pagination details in debug mode
        if [ "$DEBUG" = true ]; then
            echo "Fetching page $page from GitLab API..." >&2
        fi

        response=$(curl --silent --max-time 30 --header "PRIVATE-TOKEN: $pat_token" "$api_url")

        # Check for curl errors
        if [ $? -ne 0 ]; then
            echo "Error: Failed to fetch from GitLab API (curl timeout or connection error)" >&2
            log "Error: curl failed for $api_url"
            return 1
        fi

        # Validate that response is a JSON array
        if ! echo "$response" | jq -e 'type == "array"' > /dev/null 2>&1; then
            echo "Error: GitLab API returned non-array response. Possible authentication issue." >&2
            log "Error: Non-array response from API: $response"
            # Check if it's an error message
            if echo "$response" | jq -e '.message' > /dev/null 2>&1; then
                local error_msg=$(echo "$response" | jq -r '.message')
                echo "GitLab API error: $error_msg" >&2
            fi
            return 1
        fi

        # Get the array length
        local length=$(echo "$response" | jq '. | length')

        # Break the loop if no more projects are returned
        if [ "$length" -eq 0 ]; then
            log "No more projects on page $page, stopping pagination"
            if [ "$DEBUG" = true ]; then
                echo "No more projects found. Total pages fetched: $((page - 1))" >&2
            fi
            break
        fi

        if [ "$DEBUG" = true ]; then
            echo "  → Found $length projects on page $page" >&2
        fi
        log "Found $length projects on page $page"

        # Append the current page of projects to the all_projects array
        all_projects=$(echo "$all_projects" | jq --argjson new_projects "$response" '. + $new_projects')

        # Increment the page number
        page=$((page + 1))
    done

    if [ $page -gt $max_pages ]; then
        echo "Warning: Reached maximum page limit ($max_pages). There may be more projects." >&2
        log "Warning: Reached max_pages limit"
    fi

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
    log "Dry run mode enabled. Making API calls to fetch project list, but no cloning will occur."
    if [ "$DEBUG" = true ]; then
        echo "Dry run mode: Fetching project list from GitLab API..." >&2
    fi
fi

# Connect to GitLab and list projects
if [ "$DEBUG" = true ]; then
    log "Connecting to GitLab at $GITLAB_URL with PAT token."
fi

# Fetch projects from GitLab
log "Fetching projects from GitLab... $GITLAB_URL/api/v4/projects"
if [ "$DEBUG" = false ]; then
    echo "Fetching repositories from GitLab..." >&2
fi
response=$(fetch_projects "$GITLAB_URL" "$PAT_TOKEN")

# Check if fetch_projects failed
if [ $? -ne 0 ] || [ -z "$response" ]; then
    log "Error: Failed to fetch projects from GitLab"
    echo "Error: Failed to fetch projects from GitLab. Check your PAT token and network connection." >&2
    exit 1
fi

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

log "Successfully fetched projects from GitLab"

if [ "$DRY_RUN" = true ]; then
    log "Dry run mode: fetched real project data (no changes made)"
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
