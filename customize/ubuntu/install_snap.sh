#!/usr/bin/env bash
####################################################################################################
#Args           :
#                   --debug     : Enable debug mode with extra logging information
#                   --dry-run   : Run the script without making any changes to the system
#                   -h, --help  : Display usage information
#Usage          :   sudo ./install_snap.sh
#                   sudo ./install_snap.sh --debug
#                   sudo ./install_snap.sh --dry-run
#Output stdout  :   Progress messages for snap package installation
#Output stderr  :   Error messages if package installation fails or required applications are missing
#Return code    :   0 on success, 1 on error, 2 on usage error
#Description	: This script installs snap packages from list_of_snap.txt
#
#                 The script parses the file for metadata comments (FLAGS) and automatically
#                 applies the correct flags when installing packages.
#
#                 Format for list_of_snap.txt:
#                   # Package Group Name
#                   # FLAGS: --classic (or other snap install flags)
#                   package-name-1
#                   package-name-2
#
#Author       	: Francisco Güemes
#Email         	: francisco@franciscoguemes.com
#See also	    : https://stackoverflow.com/questions/14008125/shell-script-common-template
#                 https://devhints.io/bash
#                 https://linuxhint.com/30_bash_script_examples/
#                 https://stackoverflow.com/questions/192249/how-do-i-parse-command-line-arguments-in-bash
####################################################################################################

#==================================================================================================
# Global Configuration
#==================================================================================================
readonly SCRIPT_NAME=$(basename "$0")
readonly SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
readonly LOG_DIR="/var/log/mylicula"
readonly LOG_FILE="${LOG_DIR}/${SCRIPT_NAME%.*}.log"
readonly TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S')

# Snap packages list file
readonly SNAP_PACKAGES_FILE="${SCRIPT_DIR}/resources/snap/list_of_snap.txt"

# Runtime flags
DEBUG_MODE=false
DRY_RUN_MODE=false

#==================================================================================================
# Utility Functions
#==================================================================================================

# Print usage information
usage() {
    cat << EOF
Usage: sudo ${SCRIPT_NAME} [OPTIONS]

Install snap packages from list_of_snap.txt.

OPTIONS:
    -h, --help      Display this help message
    --debug         Enable debug mode with verbose logging
    --dry-run       Run without making any changes to the system

EXAMPLES:
    sudo ${SCRIPT_NAME}
    sudo ${SCRIPT_NAME} --debug
    sudo ${SCRIPT_NAME} --dry-run

DESCRIPTION:
    This script installs snap packages with support for installation flags
    (like --classic) specified in metadata comments.

EOF
}

# Initialize logging
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

# Log message to file and optionally to stdout
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

# Debug logging (only when --debug is enabled)
debug() {
    if [[ "$DEBUG_MODE" == true ]]; then
        log "DEBUG" "$@"
    fi
}

# Check if required application is installed
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

# Check all required applications
check_requirements() {
    log "INFO" "Checking required applications..."

    local missing=false

    if ! check_required_app "snap" "sudo apt install snapd"; then
        missing=true
    fi

    if [[ "$missing" == true ]]; then
        log "ERROR" "Missing required applications. Cannot continue."
        return 1
    fi

    log "INFO" "All required applications are installed"
    return 0
}

#==================================================================================================
# Snap Package Installation Functions
#==================================================================================================

# Install a package or package group with specified flags
install_snap_package() {
    local flags=$1
    shift
    local -a packages=("$@")

    if [[ ${#packages[@]} -eq 0 ]]; then
        debug "No packages to install"
        return 0
    fi

    log "INFO" "Installing snap package(s): ${packages[*]}"
    if [[ -n "$flags" ]]; then
        debug "  Using flags: ${flags}"
    fi

    # Install each package individually (snap doesn't support batch installs like apt)
    for package in "${packages[@]}"; do
        if [[ "$DRY_RUN_MODE" == true ]]; then
            log "INFO" "[DRY-RUN] Would install: snap install ${flags} ${package}"
        else
            log "INFO" "Installing: ${package}"
            if snap install ${flags} "${package}" >> "$LOG_FILE" 2>&1; then
                log "INFO" "Successfully installed: ${package}"
            else
                log "ERROR" "Failed to install: ${package}"
                return 1
            fi
        fi
    done

    return 0
}

# Parse and install snap packages from list_of_snap.txt
install_snap_packages() {
    log "INFO" "Installing snap packages..."

    if [[ ! -f "$SNAP_PACKAGES_FILE" ]]; then
        log "ERROR" "Snap packages file not found: ${SNAP_PACKAGES_FILE}"
        return 1
    fi

    local flags=""
    local -a packages=()
    local line_count=0
    local group_count=0
    local total_packages=0

    while IFS= read -r line; do
        ((line_count++))

        # Extract FLAGS metadata from comments
        if [[ "$line" =~ ^[[:space:]]*#[[:space:]]*FLAGS:[[:space:]]*(.*)$ ]]; then
            flags="${BASH_REMATCH[1]}"
            debug "  Found FLAGS: ${flags}"
        elif [[ "$line" =~ ^[[:space:]]*# ]]; then
            # Other comments - skip
            continue
        elif [[ -z "${line// }" ]]; then
            # Empty line - install accumulated packages if any
            if [[ ${#packages[@]} -gt 0 ]]; then
                ((group_count++))
                install_snap_package "$flags" "${packages[@]}"
                total_packages=$((total_packages + ${#packages[@]}))

                # Reset for next group
                packages=()
                flags=""
            fi
        else
            # Package name
            local package=$(echo "$line" | xargs)
            if [[ -n "$package" ]]; then
                packages+=("$package")
                debug "  Found package: ${package}"
            fi
        fi
    done < "$SNAP_PACKAGES_FILE"

    # Install last group if any packages remain
    if [[ ${#packages[@]} -gt 0 ]]; then
        ((group_count++))
        install_snap_package "$flags" "${packages[@]}"
        total_packages=$((total_packages + ${#packages[@]}))
    fi

    log "INFO" "Processed ${total_packages} packages in ${group_count} groups from ${line_count} lines"
    return 0
}

#==================================================================================================
# Main Script
#==================================================================================================

main() {
    # Parse command-line arguments
    while [[ $# -gt 0 ]]; do
        case $1 in
            -h|--help)
                usage
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
                echo "ERROR: Unknown option: $1" >&2
                echo "       Use -h or --help for usage information" >&2
                exit 2
                ;;
        esac
    done

    # Check if running as root
    if [[ $EUID -ne 0 ]]; then
        echo "ERROR: This script must be run as root (use sudo)" >&2
        exit 1
    fi

    # Initialize logging
    init_logging

    log "INFO" "========================================"
    log "INFO" "MyLiCuLa Snap Package Installation"
    log "INFO" "========================================"
    log "INFO" "Debug mode: ${DEBUG_MODE}"
    log "INFO" "Dry-run mode: ${DRY_RUN_MODE}"
    log "INFO" ""

    # Check requirements
    if ! check_requirements; then
        exit 1
    fi

    # Install snap packages
    log "INFO" ""
    if ! install_snap_packages; then
        log "ERROR" "Snap package installation failed"
        exit 1
    fi

    log "INFO" ""
    log "INFO" "========================================"
    log "INFO" "Snap package installation completed successfully"
    log "INFO" "========================================"
    log "INFO" "Log file: ${LOG_FILE}"
}

# Run main function
main "$@"
