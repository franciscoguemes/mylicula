#!/usr/bin/env bash
####################################################################################################
#Args           : 
#                   -d, --directory  Root directory where to create the GitLab structure.
#                   -j, --json       JSON file containing the list of GitLab groups.
#                   --debug          Enable debug logging.
#                   --dry-run        Run the script without generating any changes.
#                   -h, --help       Display this help message.
#Usage          :   ./create_GitLab_structure.sh -d <root_directory> -j <json_file>
#Output stdout  :   Directory structure created based on the GitLab groups.
#Output stderr  :   Error messages if any issues occur.
#Return code    :   0 on success, 1 on failure.
#Description    :   Creates a directory structure based on the GitLab groups defined in a JSON file.
#                                                                                                                                                           
#Author       	: Francisco Güemes                                                
#Email         	: francisco@franciscoguemes.com                                           
#See also	    : https://stackoverflow.com/questions/14008125/shell-script-common-template
#                 https://devhints.io/bash
#                 https://linuxhint.com/30_bash_script_examples/
#                 https://stackoverflow.com/questions/192249/how-do-i-parse-command-line-arguments-in-bash  
####################################################################################################

# Default values
LOG_FILE="/tmp/create_GitLab_structure.log"
DEBUG=false
DRY_RUN=false
ROOT_DIR=""
JSON_FILE=""

# Function to log messages
log() {
    local message="$1"
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $message" | tee -a "$LOG_FILE"  # Log to both terminal and file
}

# Function to display help
usage() {
    echo "Usage: $0 -d <root_directory> -j <json_file> [--debug] [--dry-run] [-h|--help]"
    exit 1
}

# Parse arguments
while [[ "$#" -gt 0 ]]; do
    case "$1" in
        -d|--directory) ROOT_DIR="$2"; shift ;;
        -j|--json) JSON_FILE="$2"; shift ;;
        --debug) DEBUG=true ;;
        --dry-run) DRY_RUN=true ;;
        -h|--help) usage ;;
        *) echo "Unknown parameter passed: $1"; usage ;;
    esac
    shift
done

# Check if mandatory parameters are supplied
if [ -z "$ROOT_DIR" ] || [ -z "$JSON_FILE" ]; then
    echo "Error: Root directory and JSON file are mandatory."
    usage
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

# Read the JSON file and create the directory structure
create_structure() {
    local parent_path="$1"
    local json_data="$2"

    # Create the base directory

    # Iterate over each group in the JSON data
    echo "$json_data" | jq -c '.[]' | while read -r group; do
        # Check if the group is an object
        if ! echo "$group" | jq -e 'type == "object"' > /dev/null; then
            log "Skipping non-object group: $group"
            continue
        fi

        local group_name
        group_name=$(echo "$group" | jq -r '.name // empty')  # Use // empty to handle null
        local group_path
        group_path=$(echo "$group" | jq -r '.full_path // empty')  # Use // empty to handle null

        # Skip if group_name or group_path is empty
        if [ -z "$group_name" ] || [ -z "$group_path" ]; then
            log "Skipping group due to missing name or path."
            continue
        fi

        # Create the directory path
        local dir_path="$parent_path/$group_path"
        
        if [ "$DRY_RUN" = false ]; then
            mkdir -p "$dir_path"
            log "Created directory: $dir_path"
        else
            log "Dry run: would create directory: $dir_path"
        fi

        # Check for subgroups and recursively create their structure
        # local subgroups
        # subgroups=$(echo "$json_data" | jq -c --arg parent_id "$(echo "$group" | jq -r '.id')" '.[] | select(.parent_id == ($parent_id | tonumber))')
        # if [ -n "$subgroups" ]; then
        #     create_structure "$dir_path" "$subgroups"
        # fi
    done
}

# Read the JSON file
json_content=$(<"$JSON_FILE")

# Create the directory structure
create_structure "$ROOT_DIR" "$json_content"

# Log the end of the script
log "Script execution completed."
