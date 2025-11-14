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

#==================================================================================================
# Installer Interface (Template Method Pattern)
#==================================================================================================
# These functions define the standard interface that all installer scripts MUST implement.
# This provides consistency across all installers and allows install.sh to interact with
# them in a predictable way.
#
# See setup/template_installer.sh for a complete example implementation.
# See setup/README.md for detailed documentation.
#==================================================================================================

#
# Function: get_installer_name
# Description: Return human-readable name for this installer
#              MUST be implemented by child scripts
# Args: None
# Usage: installer_name=$(get_installer_name)
# Output (stdout): Human-readable installer name
# Output (stderr): Error if not implemented
# Return code: 0 on success, 1 if not implemented
#
get_installer_name() {
    log_error "get_installer_name() not implemented!"
    log_error "This function must be implemented by the installer script"
    return 1
}

#
# Function: validate_environment
# Description: Validate that the environment is ready for installation
#              MUST be implemented by child scripts
#
#              Should check:
#              - Required applications are installed
#              - Required permissions are available
#              - Installation is not already complete (idempotency)
#              - Configuration values are valid
#              - Disk space is available (if relevant)
#
# Args: None
# Usage: if validate_environment; then ...; fi
# Output (stdout): Validation messages
# Output (stderr): Error messages if validation fails
# Return code:
#   0 - Validation passed, ready to install
#   1 - Validation failed, cannot proceed
#   2 - Already installed, skip installation (idempotent)
#
validate_environment() {
    log_error "validate_environment() not implemented!"
    log_error "This function must be implemented by the installer script"
    return 1
}

#
# Function: run_installation
# Description: Perform the actual installation
#              MUST be implemented by child scripts
#
#              Should:
#              - Be idempotent (safe to run multiple times)
#              - Respect DRY_RUN_MODE if set
#              - Provide progress feedback via log functions
#              - Clean up on failure (or delegate to cleanup_on_failure)
#
# Args: None
# Usage: if run_installation; then ...; fi
# Output (stdout): Installation progress messages
# Output (stderr): Error messages if installation fails
# Return code: 0 on success, 1 on failure
#
run_installation() {
    log_error "run_installation() not implemented!"
    log_error "This function must be implemented by the installer script"
    return 1
}

#
# Function: cleanup_on_failure
# Description: Clean up partial installation if run_installation fails
#              OPTIONAL - can be overridden by child scripts
#              Default implementation does nothing
#
# Args: None
# Usage: cleanup_on_failure
# Output (stdout): Cleanup messages
# Output (stderr): Error messages if cleanup fails
# Return code: 0 on success, 1 on failure
#
cleanup_on_failure() {
    # Default implementation: do nothing
    debug "No cleanup needed (default implementation)"
    return 0
}

#
# Function: execute_installer
# Description: Standard execution flow for installer scripts
#              Call this from main() in your installer script
#
#              Execution flow:
#              1. Verify required interface functions are implemented
#              2. Get installer name
#              3. Validate environment
#              4. Run installation (if validation passes)
#              5. Cleanup on failure (if installation fails)
#
# Args: None
# Usage: execute_installer
# Output (stdout): Progress and status messages
# Output (stderr): Error messages
# Return code: 0 on success, 1 on validation failure, 2 on installation failure
#
execute_installer() {
    local installer_name
    local validation_result

    # ========================================
    # PHASE 5: INTERFACE ENFORCEMENT
    # ========================================
    # Verify all required functions are implemented
    # This ensures all installer scripts follow the standard interface

    local required_functions=("get_installer_name" "validate_environment" "run_installation")
    local missing_functions=()

    for func in "${required_functions[@]}"; do
        # Check if function is declared
        if ! declare -F "$func" >/dev/null 2>&1; then
            missing_functions+=("$func")
        else
            # Check if it's not the default stub implementation
            # (default stubs contain "not implemented!" in their source)
            local func_source
            func_source=$(declare -f "$func" 2>/dev/null)
            if [[ "$func_source" =~ "not implemented!" ]]; then
                missing_functions+=("$func")
            fi
        fi
    done

    # If any required functions are missing or not implemented, fail with clear error
    if [[ ${#missing_functions[@]} -gt 0 ]]; then
        echo "========================================" >&2
        echo "ERROR: Installer Interface Not Implemented" >&2
        echo "========================================" >&2
        echo "" >&2
        echo "This script does not properly implement the MyLiCuLa installer interface." >&2
        echo "" >&2
        echo "Missing or not implemented functions:" >&2
        for func in "${missing_functions[@]}"; do
            echo "  ✗ ${func}()" >&2
        done
        echo "" >&2
        echo "All installer scripts MUST implement these required functions:" >&2
        echo "  - get_installer_name()    : Return human-readable installer name" >&2
        echo "  - validate_environment()  : Check prerequisites and readiness" >&2
        echo "  - run_installation()      : Perform the actual installation" >&2
        echo "" >&2
        echo "Optional functions:" >&2
        echo "  - cleanup_on_failure()    : Clean up after installation failure" >&2
        echo "" >&2
        echo "Documentation:" >&2
        echo "  - See setup/README.md for interface documentation" >&2
        echo "  - See setup/template_installer.sh for example implementation" >&2
        echo "  - See lib/installer_common.sh for function specifications" >&2
        echo "" >&2
        echo "========================================" >&2
        return 1
    fi

    debug "✓ Interface validation passed - all required functions implemented"

    # Get installer name
    if ! installer_name=$(get_installer_name); then
        log_error "Failed to get installer name"
        return 1
    fi

    log "INFO" "=========================================="
    log "INFO" "Installer: $installer_name"
    log "INFO" "=========================================="

    # Validate environment
    log "INFO" "Step 1/2: Validating environment..."
    if ! validate_environment; then
        validation_result=$?
        if [[ $validation_result -eq 2 ]]; then
            log "INFO" "✓ Already installed (skipping)"
            return 0
        else
            log "ERROR" "✗ Validation failed"
            return 1
        fi
    fi
    log "INFO" "✓ Validation passed"

    # Run installation
    log "INFO" "Step 2/2: Running installation..."
    if run_installation; then
        log "INFO" "✓ Installation completed successfully"
        return 0
    else
        log "ERROR" "✗ Installation failed"
        log "INFO" "Running cleanup..."
        cleanup_on_failure
        return 2
    fi
}
