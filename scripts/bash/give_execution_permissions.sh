#!/usr/bin/env bash
####################################################################################################
#Args           :
#                   $1          Directory to process (required)
#                   -r, --recursive  Process subdirectories recursively
#                   --debug     Enable debug mode for more verbose logging
#                   --dry-run   Run without making any changes
#                   -h, --help  Display help message
#Usage          : ./give_execution_permissions.sh <directory> [options]
#                 ./give_execution_permissions.sh /path/to/scripts --recursive --debug
#                 ./give_execution_permissions.sh /path/to/scripts -r --dry-run
#Output stdout  : Progress messages about the scripts being processed
#Output stderr  : Error messages if any
#Return code    : 0 on success, non-zero on failure
#Description    : This script gives execution permissions to all bash scripts in a specified directory.
#                 By default, only processes files in the specified directory. Use -r flag to process
#                 subdirectories recursively.
#
#Author         : Francisco Güemes
#Email          : francisco@franciscoguemes.com
####################################################################################################

# Set up logging
LOG_FILE="/tmp/$(basename "$0").log"

# Default values for options
DEBUG=false
DRY_RUN=false
RECURSIVE=false
DIRECTORY=""

# Function for logging
log() {
    local message="$1"
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $message" | tee -a "$LOG_FILE"
}

# Function for debug logging
debug_log() {
    if [ "$DEBUG" = true ]; then
        log "DEBUG: $1"
    fi
}

# Add timestamp separator to log file
add_separator() {
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    echo "************************************* $timestamp *************************************" >> "$LOG_FILE"
}

# Function to show help
show_help() {
    cat << EOF
Usage: $(basename "$0") <directory> [options]

Give execution permissions to bash scripts in a directory.

ARGUMENTS:
    directory       Directory containing scripts to process (required)

OPTIONS:
    -r, --recursive Process subdirectories recursively
    --debug         Enable debug mode for more verbose logging
    --dry-run       Run without making any changes
    -h, --help      Display this help message

DESCRIPTION:
    This script finds all bash scripts (files with #!/bin/bash or #!/bin/sh shebang)
    in the specified directory and gives them execution permissions.

    By default, only processes files in the specified directory.
    Use -r or --recursive to process subdirectories as well.

EXAMPLES:
    $(basename "$0") /path/to/scripts
    $(basename "$0") /path/to/scripts --recursive
    $(basename "$0") /path/to/scripts -r --debug
    $(basename "$0") /path/to/scripts --dry-run --debug

AUTHOR:
    Francisco Güemes <francisco@franciscoguemes.com>
EOF
}

# Parse command line arguments
while [[ "$#" -gt 0 ]]; do
    case $1 in
        -r|--recursive) RECURSIVE=true ;;
        --debug) DEBUG=true ;;
        --dry-run) DRY_RUN=true ;;
        -h|--help) show_help; exit 0 ;;
        -*)
            echo "Error: Unknown option: $1" >&2
            show_help
            exit 1
            ;;
        *)
            if [ -z "$DIRECTORY" ]; then
                DIRECTORY="$1"
            else
                echo "Error: Multiple directories specified. Only one directory is allowed." >&2
                show_help
                exit 1
            fi
            ;;
    esac
    shift
done

# Check if directory was provided
if [ -z "$DIRECTORY" ]; then
    echo "Error: Directory parameter is required." >&2
    show_help
    exit 1
fi

# Check if directory exists
if [ ! -d "$DIRECTORY" ]; then
    echo "Error: Directory does not exist: $DIRECTORY" >&2
    exit 1
fi

# Convert to absolute path
DIRECTORY="$(cd "$DIRECTORY" && pwd)"

# Function to check if a file is a bash script
is_bash_script() {
    local file="$1"
    if head -n1 "$file" | grep -q "^#!.*bash" || head -n1 "$file" | grep -q "^#!.*sh"; then
        return 0  # True, it is a bash script
    fi
    return 1  # False, it is not a bash script
}

# Function to process files in a single directory (non-recursive)
process_directory_single() {
    local dir="$1"
    debug_log "Processing directory (non-recursive): $dir"

    # Find all .sh files in the current directory only
    for file in "$dir"/*.sh; do
        # Check if glob matched any files
        [ -e "$file" ] || continue

        if [ -f "$file" ]; then
            debug_log "Checking file: $file"
            if is_bash_script "$file"; then
                debug_log "File is a bash script: $file"
                # Check if file already has execution permissions
                if [ -x "$file" ]; then
                    log "Skipping file (already executable): $file"
                else
                    log "Giving execution permissions to: $file"
                    if [ "$DRY_RUN" = false ]; then
                        chmod +x "$file"
                        debug_log "Execution permissions given to: $file"
                    else
                        debug_log "DRY-RUN: Would give execution permissions to: $file"
                    fi
                fi
            else
                debug_log "File is not a bash script: $file"
            fi
        fi
    done
}

# Function to process files recursively
process_directory_recursive() {
    local dir="$1"
    debug_log "Processing directory (recursive): $dir"

    # Process files in current directory
    for file in "$dir"/*.sh; do
        # Check if glob matched any files
        [ -e "$file" ] || continue

        if [ -f "$file" ]; then
            debug_log "Checking file: $file"
            if is_bash_script "$file"; then
                debug_log "File is a bash script: $file"
                # Check if file already has execution permissions
                if [ -x "$file" ]; then
                    log "Skipping file (already executable): $file"
                else
                    log "Giving execution permissions to: $file"
                    if [ "$DRY_RUN" = false ]; then
                        chmod +x "$file"
                        debug_log "Execution permissions given to: $file"
                    else
                        debug_log "DRY-RUN: Would give execution permissions to: $file"
                    fi
                fi
            else
                debug_log "File is not a bash script: $file"
            fi
        fi
    done

    # Process subdirectories recursively
    for subdir in "$dir"/*; do
        if [ -d "$subdir" ]; then
            process_directory_recursive "$subdir"
        fi
    done
}

# Start processing
add_separator
log "Starting to process scripts in: $DIRECTORY"
[ "$RECURSIVE" = true ] && log "Recursive mode enabled"
[ "$DEBUG" = true ] && log "Debug mode enabled"
[ "$DRY_RUN" = true ] && log "Dry run mode enabled"

if [ "$RECURSIVE" = true ]; then
    process_directory_recursive "$DIRECTORY"
else
    process_directory_single "$DIRECTORY"
fi

log "Finished processing scripts"
