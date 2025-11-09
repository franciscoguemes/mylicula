#!/usr/bin/env bash
####################################################################################################
#Args           : 
#                   $1  Path to parent directory containing subdirectories to zip
#Usage          :   ./zip_subdirs.sh /path/to/parent_dir [--debug] [--dry-run] [-h|--help]                                                                                            
#Output stdout  :   Progress messages and help information
#Output stderr  :   Error messages and warnings
#Return code    :   0 on success, 1 on error
#Description	: Zips each subdirectory in the specified parent directory into individual zip files
#                                                                                                                                                           
#Author       	: Francisco Güemes                                                
#Email         	: francisco@franciscoguemes.com                                           
#See also	    : https://stackoverflow.com/questions/14008125/shell-script-common-template
#                 https://devhints.io/bash
#                 https://linuxhint.com/30_bash_script_examples/
#                 https://stackoverflow.com/questions/192249/how-do-i-parse-command-line-arguments-in-bash  
####################################################################################################

# Global variables
SCRIPT_NAME="$(basename "$0")"
LOG_FILE="/tmp/${SCRIPT_NAME%.*}.log"
DEBUG=false
DRY_RUN=false
PARENT_DIR=""

# Function to log messages
log_message() {
    local message="$1"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    echo "[$timestamp] $message" >> "$LOG_FILE"
    if [ "$DEBUG" = true ]; then
        echo "[$timestamp] $message"
    fi
}

# Function to print help
print_help() {
    cat << EOF
Usage: $SCRIPT_NAME <parent_directory> [OPTIONS]

DESCRIPTION:
    Zips each subdirectory in the specified parent directory into individual zip files.
    Each subdirectory will be compressed into a zip file with the same name.

ARGUMENTS:
    parent_directory    Path to the parent directory containing subdirectories to zip

OPTIONS:
    -h, --help         Show this help message and exit
    --debug            Enable debug mode with verbose output
    --dry-run          Show what would be done without actually creating zip files

EXAMPLES:
    $SCRIPT_NAME /home/user/projects
    $SCRIPT_NAME /home/user/projects --debug
    $SCRIPT_NAME /home/user/projects --dry-run

REQUIREMENTS:
    - zip: Command-line zip utility
      Install with: sudo nala install zip

EOF
}

# Function to check dependencies
check_dependencies() {
    local missing_deps=()
    
    if ! command -v zip >/dev/null 2>&1; then
        missing_deps+=("zip")
    fi
    
    if [ ${#missing_deps[@]} -gt 0 ]; then
        echo "Error: Missing required dependencies: ${missing_deps[*]}" >&2
        echo "Please install them using: sudo nala install ${missing_deps[*]}" >&2
        exit 1
    fi
}

# Function to parse command line arguments
parse_arguments() {
    while [ $# -gt 0 ]; do
        case $1 in
            -h|--help)
                print_help
                exit 0
                ;;
            --debug)
                DEBUG=true
                shift
                ;;
            --dry-run)
                DRY_RUN=true
                shift
                ;;
            -*)
                echo "Error: Unknown option $1" >&2
                echo "Use -h or --help for usage information" >&2
                exit 1
                ;;
            *)
                if [ -z "$PARENT_DIR" ]; then
                    PARENT_DIR="$1"
                else
                    echo "Error: Multiple directories specified" >&2
                    echo "Use -h or --help for usage information" >&2
                    exit 1
                fi
                shift
                ;;
        esac
    done
    
    if [ -z "$PARENT_DIR" ]; then
        echo "Error: No parent directory specified" >&2
        echo "Use -h or --help for usage information" >&2
        exit 1
    fi
}

# Function to validate parent directory
validate_parent_directory() {
    if [ ! -d "$PARENT_DIR" ]; then
        echo "Error: $PARENT_DIR is not a directory" >&2
        log_message "ERROR: $PARENT_DIR is not a directory"
        exit 1
    fi
    
    if [ ! -r "$PARENT_DIR" ]; then
        echo "Error: No read permission for directory $PARENT_DIR" >&2
        log_message "ERROR: No read permission for directory $PARENT_DIR"
        exit 1
    fi
}

# Function to zip subdirectories
zip_subdirectories() {
    local subdir_count=0
    local success_count=0
    local error_count=0
    
    log_message "Starting to process subdirectories in: $PARENT_DIR"
    
    for dir in "$PARENT_DIR"/*/; do
        # Skip if not a directory
        [ -d "$dir" ] || continue
        
        subdir_count=$((subdir_count + 1))
        dirname=$(basename "$dir")
        zipfile="$PARENT_DIR/${dirname}.zip"
        
        log_message "Processing subdirectory: $dirname"
        
        if [ "$DRY_RUN" = true ]; then
            echo "Would zip: $dirname -> $zipfile"
            log_message "DRY RUN: Would zip $dirname -> $zipfile"
            success_count=$((success_count + 1))
        else
            if zip -r "$zipfile" "$dir" >/dev/null 2>&1; then
                echo "Zipped: $dirname -> $zipfile"
                log_message "SUCCESS: Zipped $dirname -> $zipfile"
                success_count=$((success_count + 1))
            else
                echo "Error: Failed to zip $dirname" >&2
                log_message "ERROR: Failed to zip $dirname"
                error_count=$((error_count + 1))
            fi
        fi
    done
    
    log_message "Processing complete. Total: $subdir_count, Success: $success_count, Errors: $error_count"
    
    if [ $error_count -gt 0 ]; then
        echo "Warning: $error_count subdirectories failed to zip" >&2
        return 1
    fi
    
    return 0
}

# Main execution
main() {
    # Add timestamp separator to log
    echo "===============================================" >> "$LOG_FILE"
    log_message "Script execution started"
    
    # Parse command line arguments
    parse_arguments "$@"
    
    # Check dependencies
    check_dependencies
    log_message "Dependencies check passed"
    
    # Validate parent directory
    validate_parent_directory
    log_message "Parent directory validation passed: $PARENT_DIR"
    
    # Process subdirectories
    if zip_subdirectories; then
        echo "Done! All subdirectories processed successfully."
        log_message "Script execution completed successfully"
        exit 0
    else
        echo "Done! Some subdirectories failed to process."
        log_message "Script execution completed with errors"
        exit 1
    fi
}

# Execute main function
main "$@"
