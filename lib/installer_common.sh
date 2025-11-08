#!/usr/bin/env bash
####################################################################################################
# Common installer functions for MyLiCuLa installation scripts
#
# This library provides shared functionality for package installation scripts:
#   - Logging infrastructure with DEBUG and INFO levels
#   - Argument parsing helpers
#   - Requirement checking
#   - Common configuration variables
#
# Usage:
#   source "${BASE_DIR}/lib/installer_common.sh"
#
# Required variables to be set by calling script:
#   SCRIPT_NAME - Name of the calling script
#   SCRIPT_DIR - Directory where the calling script resides
#
# Optional variables that can be overridden:
#   LOG_DIR - Directory for log files (default: /var/log/mylicula)
#   DEBUG_MODE - Enable debug logging (default: false)
#   DRY_RUN_MODE - Run without making changes (default: false)
#
#Author       	: Francisco Güemes
#Email         	: francisco@franciscoguemes.com
####################################################################################################

#==================================================================================================
# Global Configuration (can be overridden by calling script)
#==================================================================================================

# Set defaults if not already set
: ${LOG_DIR:="/var/log/mylicula"}
: ${DEBUG_MODE:=false}
: ${DRY_RUN_MODE:=false}

# Derived variables
readonly TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S')

# Log file (requires SCRIPT_NAME to be set)
if [[ -n "${SCRIPT_NAME}" ]]; then
    LOG_FILE="${LOG_DIR}/${SCRIPT_NAME%.*}.log"
fi

#==================================================================================================
# Logging Functions
#==================================================================================================

#
# Function: init_logging
# Description: Initialize logging infrastructure
# Args: None
# Usage: init_logging
# Output (stdout): None
# Output (stderr): Error message if log directory cannot be created
# Return code: 0 on success, exits with 1 on failure
#
init_logging() {
    if ! mkdir -p "$LOG_DIR" 2>/dev/null; then
        echo "ERROR: Cannot create log directory: $LOG_DIR" >&2
        echo "       Please run this script with sudo" >&2
        exit 1
    fi

    # Log execution separator with timestamp
    echo "================================================================================" >> "$LOG_FILE"
    echo "Execution started at: ${TIMESTAMP}" >> "$LOG_FILE"
    echo "================================================================================" >> "$LOG_FILE"
}

#
# Function: log
# Description: Log message to file and optionally to stdout
# Args:
#   $1 - Log level (INFO, ERROR, DEBUG, etc.)
#   $@ - Message to log
# Usage: log "INFO" "Installing packages..."
# Output (stdout): Message (if level is not DEBUG or DEBUG_MODE is true)
# Output (stderr): None
# Return code: 0
#
log() {
    local level=$1
    shift
    local message="$*"
    local log_line="[$(date '+%Y-%m-%d %H:%M:%S')] [${level}] ${message}"

    echo "$log_line" >> "$LOG_FILE"

    if [[ "$level" != "DEBUG" ]] || [[ "$DEBUG_MODE" == true ]]; then
        echo "$message"
    fi
}

#
# Function: debug
# Description: Log debug message (only when DEBUG_MODE is enabled)
# Args:
#   $@ - Debug message
# Usage: debug "Processing file: $filename"
# Output (stdout): Debug message (only if DEBUG_MODE=true)
# Output (stderr): None
# Return code: 0
#
debug() {
    if [[ "$DEBUG_MODE" == true ]]; then
        log "DEBUG" "$@"
    fi
}

#==================================================================================================
# Requirement Checking Functions
#==================================================================================================

#
# Function: check_required_app
# Description: Check if a required application is installed
# Args:
#   $1 - Application name (command to check)
#   $2 - Installation command/package name
# Usage: check_required_app "git" "git"
# Output (stdout): Error message if app is not installed
# Output (stderr): None
# Return code: 0 if app exists, 1 if not found
#
check_required_app() {
    local app=$1
    local install_command=$2

    if ! command -v "$app" &> /dev/null; then
        log "ERROR" "Required application '${app}' is not installed"
        log "ERROR" "Install it using: ${install_command}"
        return 1
    fi

    debug "Found required application: ${app}"
    return 0
}

#==================================================================================================
# Argument Parsing Helpers
#==================================================================================================

#
# Function: parse_common_args
# Description: Parse common command-line arguments (--debug, --dry-run, -h)
# Args:
#   $1 - Argument to parse
#   $2 - (optional) Usage function name to call for --help
# Usage:
#   if parse_common_args "$1" "usage"; then
#       shift; continue
#   fi
# Output (stdout): None (calls usage function if -h/--help)
# Output (stderr): Error message for unknown options
# Return code: 0 if argument was recognized, 1 if not recognized
#
parse_common_args() {
    local arg=$1
    local usage_function=${2:-}

    case "$arg" in
        -h|--help)
            if [[ -n "$usage_function" ]] && declare -f "$usage_function" &>/dev/null; then
                "$usage_function"
                exit 0
            else
                echo "ERROR: Usage function not defined" >&2
                exit 2
            fi
            ;;
        --debug)
            DEBUG_MODE=true
            return 0
            ;;
        --dry-run)
            DRY_RUN_MODE=true
            return 0
            ;;
        *)
            return 1
            ;;
    esac
}

#==================================================================================================
# Root Privilege Check
#==================================================================================================

#
# Function: require_root
# Description: Ensure script is run as root (with sudo)
# Args: None
# Usage: require_root
# Output (stdout): None
# Output (stderr): Error message if not run as root
# Return code: 0 if root, exits with 1 if not root
#
require_root() {
    if [[ $EUID -ne 0 ]]; then
        echo "ERROR: This script must be run as root (use sudo)" >&2
        exit 1
    fi
}

#==================================================================================================
# Common Setup
#==================================================================================================

#
# Function: setup_installer_common
# Description: Perform common setup tasks (init logging, check root)
# Args:
#   $1 - (optional) "no-root" to skip root check
# Usage: setup_installer_common
#        setup_installer_common "no-root"
# Output (stdout): None
# Output (stderr): Errors if setup fails
# Return code: 0 on success, exits on failure
#
setup_installer_common() {
    local skip_root=${1:-}

    # Check root unless explicitly skipped
    if [[ "$skip_root" != "no-root" ]]; then
        require_root
    fi

    # Initialize logging
    init_logging
}
