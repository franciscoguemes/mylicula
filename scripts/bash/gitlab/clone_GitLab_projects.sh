#!/usr/bin/env bash
####################################################################################################
#Args           : 
#                   -g, --gitlab-url  GitLab URL. The URL of the GitLab server to connect to.
#                   -p, --pat         PAT token. The PAT token to connect to GitLab.
#                   -d, --directory   Root directory. The directory where the script will start cloning.
#                   -i, --include-groups Group paths. The group(s) whose projects should be cloned.
#                   -e, --exclude-groups Exclude group paths. The group(s) whose projects should not be cloned.
#                   --debug           Enable debug logging.
#                   --dry-run         Run the script without generating any changes.
#                   -h, --help        Display this help message.
#Usage          :   ./clone_GitLab_projects.sh -g <gitlab_url> -p <pat_token> -d <root_directory>
#Output stdout  :   Cloning status of GitLab projects.
#Output stderr  :   Error messages if any issues occur.
#Return code    :   0 on success, 1 on failure.
#Description    :   Connects to a GitLab server, retrieves projects, and clones them into a specified directory
#                   reproducing the directory structure of the projects in the GitLab server.
#                   It uses internally the list_GitLab_projects.sh script to get the projects.
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
PAT_TOKEN=""
ROOT_DIR=""
LOG_FILE="/tmp/clone_GitLab_projects.log"
DEBUG=false
DRY_RUN=false
INCLUDE_GROUPS=()  # New array to hold included group names
EXCLUDE_GROUPS=()  # New array to hold excluded group names

# Function to log messages
log() {
    local message="$1"
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $message" >> "$LOG_FILE"  # Log only to file
}

# Function to display help
usage() {
    echo "Usage: $0 -g <gitlab_url> -p <pat_token> -d <root_directory> [-i <group_path1,group_path2,...>] [-e <group_path1,group_path2,...>] [--debug] [--dry-run] [-h|--help]"
    echo "Note: Groups must be specified as paths and can be separated by commas."
    echo "You cannot use both --include-groups and --exclude-groups at the same time."
    exit 1
}

# Function to clone projects
clone_projects() {
    local projects_json="$1"
    local root_dir="$2"

    # Iterate over each project in the JSON array
    echo "$projects_json" | jq -c '.[]' | while read -r project; do
        local project_name
        project_name=$(echo "$project" | jq -r '.name')
#        local project_path
#        project_path=$(echo "$project" | jq -r '.full_path')
        local project_group
        project_group=$(echo "$project" | jq -r '.namespace.full_path')  # Get the group path

        # Check if the project belongs to the specified included groups
        if [[ ${#INCLUDE_GROUPS[@]} -gt 0 ]]; then
            if ! [[ " ${INCLUDE_GROUPS[@]} " =~ " ${project_group} " ]]; then
                log "Skipping project $project_name as it does not belong to the specified included groups."
                continue
            fi
        fi

        # Check if the project belongs to the specified excluded groups
        if [[ ${#EXCLUDE_GROUPS[@]} -gt 0 ]]; then
            if [[ " ${EXCLUDE_GROUPS[@]} " =~ " ${project_group} " ]]; then
                log "Skipping project $project_name as it belongs to the excluded groups."
                continue
            fi
        fi

        # Create the directory structure
        # local dir_path="$root_dir/$(dirname "$project_path")"
        local dir_path="$root_dir/$project_group"

        # Check if the directory already exists
        if [ ! -d "$dir_path" ]; then
            if [ "$DRY_RUN" = false ]; then
                mkdir -p "$dir_path"
                log "Created directory: $dir_path"
            else
                log "Dry run: would create directory: $dir_path"
            fi
        else
            log "Directory already exists: $dir_path"
        fi

        # Check if the project already exists
        if [ ! -d "$dir_path/$project_name" ]; then
            if [ "$DRY_RUN" = false ]; then
                # git clone "$project_url" "$dir_path/$project_name" >> "$LOG_FILE" 2>&1
                git clone "$project_url" "$dir_path/$project_name" 2>&1 | tee -a "$LOG_FILE"
                log "Cloned project: $project_name into $dir_path"
            else
                log "Dry run: would clone project: $project_name into $dir_path"
            fi
        else
            log "Project $project_name already exists in $dir_path, skipping clone."
        fi
    done
}

# Parse arguments
while [[ "$#" -gt 0 ]]; do
    case "$1" in
        -g|--gitlab-url) GITLAB_URL="$2"; shift ;;
        -p|--pat) PAT_TOKEN="$2"; shift ;;
        -d|--directory) ROOT_DIR="$2"; shift ;;
        -i|--include-groups) 
            if [[ ${#EXCLUDE_GROUPS[@]} -gt 0 ]]; then
                echo "Error: You cannot use both --include-groups and --exclude-groups at the same time."
                usage
            fi
            IFS=',' read -r -a INCLUDE_GROUPS <<< "$2"; shift ;;  # Add included groups to the array
        -e|--exclude-groups) 
            if [[ ${#INCLUDE_GROUPS[@]} -gt 0 ]]; then
                echo "Error: You cannot use both --include-groups and --exclude-groups at the same time."
                usage
            fi
            IFS=',' read -r -a EXCLUDE_GROUPS <<< "$2"; shift ;;  # Add excluded groups to the array
        --debug) DEBUG=true ;;
        --dry-run) DRY_RUN=true ;;
        -h|--help) usage ;;
        *) echo "Unknown parameter passed: $1"; usage ;;
    esac
    shift
done

# Check if mandatory parameters are supplied
if [ -z "$GITLAB_URL" ] || [ -z "$PAT_TOKEN" ] || [ -z "$ROOT_DIR" ]; then
    echo "Error: GitLab URL, PAT token, and root directory are mandatory."
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

# Fetch projects from GitLab
log "Fetching projects from GitLab..."
response=""
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"  # Get the directory of the current script
if [ "$DRY_RUN" = true ]; then
    response=$(bash "$SCRIPT_DIR/list_GitLab_projects.sh" -g "$GITLAB_URL" -p "$PAT_TOKEN" --dry-run)
else
    response=$(bash "$SCRIPT_DIR/list_GitLab_projects.sh" -g "$GITLAB_URL" -p "$PAT_TOKEN")   
fi

# Log the raw response for debugging
if [ "$DEBUG" = true ]; then
    log "Raw response: $response"
fi

# Check if the response is valid JSON
if ! echo "$response" | jq . > /dev/null 2>&1; then
    log "Error: Invalid response from GitLab API."
    # echo "Response: $response"
    exit 1
fi

# Check for empty response
if [ -z "$response" ]; then
    log "Error: No projects returned from GitLab."
    exit 1
fi

# Clone the projects
clone_projects "$response" "$ROOT_DIR"

# Log the end of the script
log "Script execution completed." 
