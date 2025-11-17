#!/usr/bin/env bash
####################################################################################################
#Args           :
#                   --debug         Enable debug logging
#                   --dry-run       Run without making any changes
#                   -h, --help      Display help message
#
#Usage          : ./insert_signature_in_clipboard.sh
#                 ./insert_signature_in_clipboard.sh --debug
#                 ./insert_signature_in_clipboard.sh --dry-run
#
#Output stdout  : Success message confirming text copied to clipboard
#Output stderr  : Error messages if clipboard operation fails
#Return code    : 0   Success
#                 1   Failure (missing dependencies or clipboard error)
#
#Description    : Inserts a signature block into the system clipboard.
#                 The signature includes:
#                   Kind regards,
#
#                   [Your Full Name from config]
#
#                 The full name is read from ~/.config/mylicula/mylicula.conf
#                 (USERNAME_FULL_NAME property). If the config file doesn't exist,
#                 it falls back to the git user.name or system username.
#
#                 This script requires xclip to be installed for clipboard access.
#                 If xclip is not installed, the script will fail with instructions
#                 on how to install it using nala.
#
#Author         : Francisco Güemes
#Email          : francisco@franciscoguemes.com
#See also       : https://stackoverflow.com/questions/14008125/shell-script-common-template
#                 https://devhints.io/bash
#                 https://linuxhint.com/30_bash_script_examples/
#                 https://stackoverflow.com/questions/192249/how-do-i-parse-command-line-arguments-in-bash
####################################################################################################

set -euo pipefail

#==================================================================================================
# Configuration
#==================================================================================================

# Application name for logging
APP_NAME="mylicula"

# Script metadata
SCRIPT_NAME="$(basename "${BASH_SOURCE[0]}")"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Log configuration
LOG_DIR="/var/log/${APP_NAME}"
LOG_FILE="${LOG_DIR}/${SCRIPT_NAME%.sh}.log"

# Execution modes
DEBUG_MODE=false
DRY_RUN_MODE=false

# MyLiCuLa configuration file
CONFIG_FILE="${HOME}/.config/mylicula/mylicula.conf"

# Configuration associative array
declare -A CONFIG

# User full name (to be loaded from config or detected)
USER_FULL_NAME=""

#==================================================================================================
# Logging Functions
#==================================================================================================

#
# Function: log
# Description: Write a log message to the log file with timestamp
# Args:
#   $1 - Log level (INFO, ERROR, DEBUG)
#   $2 - Log message
#
log() {
    local level="$1"
    local message="$2"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')

    echo "[${timestamp}] [${level}] ${message}" | tee -a "$LOG_FILE"
}

#
# Function: debug
# Description: Write a debug message (only if DEBUG_MODE is enabled)
# Args:
#   $1 - Debug message
#
debug() {
    if [[ "$DEBUG_MODE" == true ]]; then
        log "DEBUG" "$1"
    fi
}

#
# Function: log_separator
# Description: Write a separator line with timestamp to the log file
#
log_separator() {
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    echo "" >> "$LOG_FILE"
    echo "================================================================================" >> "$LOG_FILE"
    echo "Script execution: ${timestamp}" >> "$LOG_FILE"
    echo "================================================================================" >> "$LOG_FILE"
}

#==================================================================================================
# Setup Functions
#==================================================================================================

#
# Function: setup_logging
# Description: Initialize logging directory and log file
#
setup_logging() {
    # Create log directory if it doesn't exist
    if [[ ! -d "$LOG_DIR" ]]; then
        if ! sudo mkdir -p "$LOG_DIR" 2>/dev/null; then
            echo "[ERROR] Failed to create log directory: $LOG_DIR" >&2
            echo "[ERROR] Please run: sudo mkdir -p $LOG_DIR && sudo chown $USER:$USER $LOG_DIR" >&2
            exit 1
        fi
        sudo chown "$USER:$USER" "$LOG_DIR"
    fi

    # Create log file if it doesn't exist
    if [[ ! -f "$LOG_FILE" ]]; then
        touch "$LOG_FILE" 2>/dev/null || {
            echo "[ERROR] Failed to create log file: $LOG_FILE" >&2
            exit 1
        }
    fi

    log_separator
}

#
# Function: load_configuration
# Description: Load configuration from mylicula.conf file
# Return: 0 on success, 1 if config file doesn't exist
#
load_configuration() {
    if [[ -f "$CONFIG_FILE" ]]; then
        debug "Loading configuration from: $CONFIG_FILE"
        # Source the config file to populate CONFIG array
        source "$CONFIG_FILE"
        debug "Configuration loaded successfully"
        return 0
    else
        debug "Configuration file not found: $CONFIG_FILE"
        return 1
    fi
}

#
# Function: get_user_full_name
# Description: Get user's full name from config, git, or system
# Return: Sets USER_FULL_NAME variable
#
get_user_full_name() {
    # Priority 1: Configuration file
    if [[ -n "${CONFIG[USERNAME_FULL_NAME]:-}" ]]; then
        USER_FULL_NAME="${CONFIG[USERNAME_FULL_NAME]}"
        debug "Full name from config: $USER_FULL_NAME"
        return 0
    fi

    # Priority 2: Git user.name
    if command -v git &> /dev/null; then
        local git_name
        git_name=$(git config --global user.name 2>/dev/null || echo "")
        if [[ -n "$git_name" ]]; then
            USER_FULL_NAME="$git_name"
            debug "Full name from git config: $USER_FULL_NAME"
            return 0
        fi
    fi

    # Priority 3: System username (fallback)
    USER_FULL_NAME="$USER"
    debug "Full name fallback to system username: $USER_FULL_NAME"
}

#
# Function: check_dependencies
# Description: Check if required applications are installed
# Return: 0 if all dependencies are met, 1 otherwise
#
check_dependencies() {
    local missing_deps=()

    # Check for xclip
    if ! command -v xclip &> /dev/null; then
        missing_deps+=("xclip")
    fi

    if [[ ${#missing_deps[@]} -gt 0 ]]; then
        log "ERROR" "Missing required dependencies: ${missing_deps[*]}"
        log "ERROR" "Please install them using:"
        log "ERROR" "  sudo nala install ${missing_deps[*]}"
        return 1
    fi

    debug "All dependencies are installed"
    return 0
}

#==================================================================================================
# Help Function
#==================================================================================================

#
# Function: show_help
# Description: Display help message
#
show_help() {
    cat << EOF
Insert Signature in Clipboard

Usage: $SCRIPT_NAME [OPTIONS]

Insert your signature block into the system clipboard

OPTIONS:
    --debug         Enable debug logging
    --dry-run       Run without making any changes (show what would be copied)
    -h, --help      Display this help message

DESCRIPTION:
    This script copies a signature block into your system clipboard:

        Kind regards,

        [Your Full Name]

    The full name is read from the MyLiCuLa configuration file with
    the following priority:
        1. ~/.config/mylicula/mylicula.conf (USERNAME_FULL_NAME)
        2. Git global user.name (git config --global user.name)
        3. System username (\$USER)

    After running this script, you can paste (Ctrl+V) the signature
    anywhere you need it.

CONFIGURATION:
    Edit ~/.config/mylicula/mylicula.conf and set:
        CONFIG[USERNAME_FULL_NAME]="Your Full Name"

REQUIREMENTS:
    - xclip (install with: sudo nala install xclip)
    - MyLiCuLa config file (created by ./install.sh)

EXAMPLES:
    # Copy signature to clipboard
    $SCRIPT_NAME

    # Show what would be copied without actually copying
    $SCRIPT_NAME --dry-run

    # Run with debug output to see where name is loaded from
    $SCRIPT_NAME --debug

LOG FILE:
    $LOG_FILE

AUTHOR:
    Francisco Güemes <francisco@franciscoguemes.com>

EOF
}

#==================================================================================================
# Main Functions
#==================================================================================================

#
# Function: insert_to_clipboard
# Description: Insert the signature text into the system clipboard
# Return: 0 on success, 1 on failure
#
insert_to_clipboard() {
    debug "Preparing to insert text into clipboard"

    # Build signature text dynamically
    local signature_text="Kind regards,

${USER_FULL_NAME}"

    if [[ "$DRY_RUN_MODE" == true ]]; then
        log "INFO" "[DRY-RUN] Would copy the following text to clipboard:"
        echo ""
        echo "$signature_text"
        echo ""
        log "INFO" "[DRY-RUN] No actual clipboard operation performed"
        return 0
    fi

    # Insert text into clipboard using xclip
    if echo "$signature_text" | xclip -selection clipboard; then
        log "INFO" "✓ Signature successfully copied to clipboard"
        debug "Clipboard content:"
        debug "$signature_text"
        return 0
    else
        log "ERROR" "Failed to copy signature to clipboard"
        return 1
    fi
}

#==================================================================================================
# Main Entry Point
#==================================================================================================

main() {
    # Parse command line arguments
    while [[ $# -gt 0 ]]; do
        case $1 in
            -h|--help)
                show_help
                exit 0
                ;;
            --debug)
                DEBUG_MODE=true
                shift
                ;;
            --dry-run)
                DRY_RUN_MODE=true
                shift
                ;;
            *)
                echo "[ERROR] Unknown option: $1" >&2
                echo ""
                show_help
                exit 1
                ;;
        esac
    done

    # Setup logging
    setup_logging

    log "INFO" "Starting signature clipboard insertion..."
    debug "Debug mode: $DEBUG_MODE"
    debug "Dry-run mode: $DRY_RUN_MODE"

    # Load configuration
    load_configuration

    # Get user's full name from config, git, or system
    get_user_full_name
    log "INFO" "Using full name: $USER_FULL_NAME"

    # Check dependencies
    if ! check_dependencies; then
        exit 1
    fi

    # Insert signature into clipboard
    if insert_to_clipboard; then
        log "INFO" "Script completed successfully"
        exit 0
    else
        log "ERROR" "Script failed"
        exit 1
    fi
}

# Execute main function
main "$@"
