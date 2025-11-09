#!/usr/bin/env bash
####################################################################################################
#Args           :
#                   --debug     : Enable debug mode with extra logging information
#                   --dry-run   : Run the script without making any changes to the system
#                   -h, --help  : Display usage information
#Usage          :   sudo ./install_packages.sh
#                   sudo ./install_packages.sh --debug
#                   sudo ./install_packages.sh --dry-run
#Output stdout  :   Progress messages for package installation, repository additions, and GPG key imports
#Output stderr  :   Error messages if package installation fails or required applications are missing
#Return code    :   0 on success, 1 on error, 2 on usage error
#Description	: This script installs Ubuntu packages from two sources:
#                 1. standard_packages.txt - Packages from default Ubuntu repositories
#                 2. custom_packages.txt - Packages requiring custom PPAs/repositories
#
#                 The script parses custom_packages.txt for metadata comments (REPO, GPG, KEYRING)
#                 and automatically configures repositories before installing packages.
#
#                 Format for custom_packages.txt:
#                   # Package Group Name
#                   # REPO: ppa:user/repo or full repository line
#                   # GPG: URL to GPG key (optional)
#                   # KEYRING: path to keyring file (optional)
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
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Find BASE_DIR - Priority 1: env var, Priority 2: search for lib/installer_common.sh
if [[ -n "${MYLICULA_BASE_DIR:-}" ]]; then
    BASE_DIR="$MYLICULA_BASE_DIR"
else
    # Search upwards for lib/installer_common.sh (max 3 levels)
    BASE_DIR="$SCRIPT_DIR"
    for i in {1..3}; do
        if [[ -f "${BASE_DIR}/lib/installer_common.sh" ]]; then
            break
        fi
        BASE_DIR="$(dirname "$BASE_DIR")"
    done

    if [[ ! -f "${BASE_DIR}/lib/installer_common.sh" ]]; then
        echo "[ERROR] Cannot find MyLiCuLa project root" >&2
        echo "Please set MYLICULA_BASE_DIR environment variable or run via install.sh" >&2
        exit 1
    fi
fi

readonly BASE_DIR

# Source common installer functions
if [[ -f "${BASE_DIR}/lib/installer_common.sh" ]]; then
    # shellcheck disable=SC1091
    source "${BASE_DIR}/lib/installer_common.sh"
else
    echo "ERROR: Cannot find lib/installer_common.sh" >&2
    exit 1
fi

# Package list files
readonly STANDARD_PACKAGES_FILE="${SCRIPT_DIR}/resources/apt/standard_packages.txt"
readonly CUSTOM_PACKAGES_FILE="${SCRIPT_DIR}/resources/apt/custom_packages.txt"

#==================================================================================================
# Utility Functions
#==================================================================================================

# Print usage information
usage() {
    cat << EOF
Usage: sudo ${SCRIPT_NAME} [OPTIONS]

Install Ubuntu packages from standard and custom repositories.

OPTIONS:
    -h, --help      Display this help message
    --debug         Enable debug mode with verbose logging
    --dry-run       Run without making any changes to the system

EXAMPLES:
    sudo ${SCRIPT_NAME}
    sudo ${SCRIPT_NAME} --debug
    sudo ${SCRIPT_NAME} --dry-run

DESCRIPTION:
    This script installs packages from two sources:
    - standard_packages.txt: Packages from default Ubuntu repos
    - custom_packages.txt: Packages requiring PPAs or custom repos

    The script automatically configures repositories, imports GPG keys,
    and installs packages in the correct order.

EOF
}

# Check all required applications
check_requirements() {
    log "INFO" "Checking required applications..."

    local missing=false

    if ! check_required_app "nala" "nala"; then
        missing=true
    fi

    if ! check_required_app "curl" "curl"; then
        missing=true
    fi

    if ! check_required_app "gpg" "gnupg"; then
        missing=true
    fi

    if ! check_required_app "add-apt-repository" "software-properties-common"; then
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
# Package Installation Functions
#==================================================================================================

# Install packages from standard_packages.txt
install_standard_packages() {
    log "INFO" "Installing standard packages..."

    if [[ ! -f "$STANDARD_PACKAGES_FILE" ]]; then
        log "ERROR" "Standard packages file not found: ${STANDARD_PACKAGES_FILE}"
        return 1
    fi

    local -a packages=()
    local line_count=0

    # Read packages into array
    while IFS= read -r line; do
        ((line_count++))

        # Skip comments and empty lines
        [[ "$line" =~ ^[[:space:]]*# ]] && continue
        [[ -z "${line// }" ]] && continue

        # Extract package name (trim whitespace)
        local package=$(echo "$line" | xargs)

        if [[ -n "$package" ]]; then
            packages+=("$package")
            debug "  Found package: ${package}"
        fi
    done < "$STANDARD_PACKAGES_FILE"

    log "INFO" "Found ${#packages[@]} standard packages to install (from ${line_count} lines)"

    if [[ ${#packages[@]} -eq 0 ]]; then
        log "WARN" "No standard packages to install"
        return 0
    fi

    # Install packages
    if [[ "$DRY_RUN_MODE" == true ]]; then
        log "INFO" "[DRY-RUN] Would install: ${packages[*]}"
    else
        log "INFO" "Installing packages with nala..."
        if nala install -y "${packages[@]}" >> "$LOG_FILE" 2>&1; then
            log "INFO" "Successfully installed ${#packages[@]} standard packages"
        else
            log "ERROR" "Failed to install some standard packages (see log for details)"
            return 1
        fi
    fi

    return 0
}

# Add PPA repository
add_ppa_repository() {
    local ppa=$1

    debug "Adding PPA: ${ppa}"

    if [[ "$DRY_RUN_MODE" == true ]]; then
        log "INFO" "[DRY-RUN] Would add PPA: ${ppa}"
        return 0
    fi

    if add-apt-repository -y "$ppa" >> "$LOG_FILE" 2>&1; then
        log "INFO" "Successfully added PPA: ${ppa}"
        return 0
    else
        log "ERROR" "Failed to add PPA: ${ppa}"
        return 1
    fi
}

# Add custom repository line
add_custom_repository() {
    local repo_line=$1
    local list_file="/etc/apt/sources.list.d/mylicula-custom.list"

    debug "Adding custom repository: ${repo_line}"

    if [[ "$DRY_RUN_MODE" == true ]]; then
        log "INFO" "[DRY-RUN] Would add repository to ${list_file}"
        log "INFO" "[DRY-RUN]   ${repo_line}"
        return 0
    fi

    # Check if repository already exists
    if grep -qF "$repo_line" "$list_file" 2>/dev/null; then
        debug "Repository already exists in ${list_file}"
        return 0
    fi

    # Add repository
    if echo "$repo_line" | tee -a "$list_file" >> "$LOG_FILE" 2>&1; then
        log "INFO" "Successfully added repository to ${list_file}"
        return 0
    else
        log "ERROR" "Failed to add repository to ${list_file}"
        return 1
    fi
}

# Import GPG key
import_gpg_key() {
    local gpg_url=$1
    local keyring_path=$2

    debug "Importing GPG key from: ${gpg_url}"
    debug "  Keyring destination: ${keyring_path}"

    if [[ "$DRY_RUN_MODE" == true ]]; then
        log "INFO" "[DRY-RUN] Would download GPG key from: ${gpg_url}"
        log "INFO" "[DRY-RUN] Would save to: ${keyring_path}"
        return 0
    fi

    # Check if keyring already exists
    if [[ -f "$keyring_path" ]]; then
        debug "GPG keyring already exists: ${keyring_path}"
        return 0
    fi

    # Ensure parent directory exists
    local keyring_dir=$(dirname "$keyring_path")
    if ! mkdir -p "$keyring_dir" 2>/dev/null; then
        log "ERROR" "Cannot create keyring directory: ${keyring_dir}"
        return 1
    fi

    # Download and import GPG key
    if curl -fsSL "$gpg_url" | gpg --dearmor -o "$keyring_path" 2>> "$LOG_FILE"; then
        log "INFO" "Successfully imported GPG key to: ${keyring_path}"
        return 0
    else
        log "ERROR" "Failed to import GPG key from: ${gpg_url}"
        return 1
    fi
}

# Install a package group (packages with same repository configuration)
install_package_group() {
    local repo=$1
    local gpg_key=$2
    local keyring=$3
    shift 3
    local -a packages=("$@")

    log "INFO" "Installing package group: ${packages[*]}"

    # Import GPG key if specified
    if [[ -n "$gpg_key" ]] && [[ -n "$keyring" ]]; then
        if ! import_gpg_key "$gpg_key" "$keyring"; then
            log "ERROR" "Failed to import GPG key, skipping package group"
            return 1
        fi
    fi

    # Add repository
    if [[ -n "$repo" ]]; then
        # Check if it's a PPA or custom repository line
        if [[ "$repo" =~ ^ppa: ]]; then
            if ! add_ppa_repository "$repo"; then
                log "ERROR" "Failed to add PPA, skipping package group"
                return 1
            fi
        else
            if ! add_custom_repository "$repo"; then
                log "ERROR" "Failed to add repository, skipping package group"
                return 1
            fi
        fi

        # Update package lists after adding repository
        if [[ "$DRY_RUN_MODE" == false ]]; then
            debug "Updating package lists..."
            if ! nala update >> "$LOG_FILE" 2>&1; then
                log "WARN" "Failed to update package lists"
            fi
        fi
    fi

    # Install packages
    if [[ "$DRY_RUN_MODE" == true ]]; then
        log "INFO" "[DRY-RUN] Would install: ${packages[*]}"
    else
        if nala install -y "${packages[@]}" >> "$LOG_FILE" 2>&1; then
            log "INFO" "Successfully installed package group: ${packages[*]}"
        else
            log "ERROR" "Failed to install package group: ${packages[*]}"
            return 1
        fi
    fi

    return 0
}

# Parse and install packages from custom_packages.txt
install_custom_packages() {
    log "INFO" "Installing custom packages..."

    if [[ ! -f "$CUSTOM_PACKAGES_FILE" ]]; then
        log "ERROR" "Custom packages file not found: ${CUSTOM_PACKAGES_FILE}"
        return 1
    fi

    local repo="" gpg_key="" keyring=""
    local -a packages=()
    local line_count=0
    local group_count=0

    while IFS= read -r line; do
        ((line_count++))

        # Extract metadata from comments
        if [[ "$line" =~ ^[[:space:]]*#[[:space:]]*REPO:[[:space:]]*(.*)$ ]]; then
            repo="${BASH_REMATCH[1]}"
            debug "  Found REPO: ${repo}"
        elif [[ "$line" =~ ^[[:space:]]*#[[:space:]]*GPG:[[:space:]]*(.*)$ ]]; then
            gpg_key="${BASH_REMATCH[1]}"
            debug "  Found GPG: ${gpg_key}"
        elif [[ "$line" =~ ^[[:space:]]*#[[:space:]]*KEYRING:[[:space:]]*(.*)$ ]]; then
            keyring="${BASH_REMATCH[1]}"
            debug "  Found KEYRING: ${keyring}"
        elif [[ "$line" =~ ^[[:space:]]*# ]]; then
            # Other comments - skip
            continue
        elif [[ -z "${line// }" ]]; then
            # Empty line - install accumulated packages if any
            if [[ ${#packages[@]} -gt 0 ]]; then
                ((group_count++))
                install_package_group "$repo" "$gpg_key" "$keyring" "${packages[@]}"

                # Reset for next group
                packages=()
                repo="" gpg_key="" keyring=""
            fi
        else
            # Package name
            local package=$(echo "$line" | xargs)
            if [[ -n "$package" ]]; then
                packages+=("$package")
                debug "  Found package: ${package}"
            fi
        fi
    done < "$CUSTOM_PACKAGES_FILE"

    # Install last group if any packages remain
    if [[ ${#packages[@]} -gt 0 ]]; then
        ((group_count++))
        install_package_group "$repo" "$gpg_key" "$keyring" "${packages[@]}"
    fi

    log "INFO" "Processed ${group_count} package groups from ${line_count} lines"
    return 0
}

#==================================================================================================
# Main Script
#==================================================================================================

main() {
    # Parse command-line arguments
    while [[ $# -gt 0 ]]; do
        if parse_common_args "$1" "usage"; then
            shift
            continue
        fi

        # No script-specific arguments, so this is unknown
        echo "ERROR: Unknown option: $1" >&2
        echo "       Use -h or --help for usage information" >&2
        exit 2
    done

    # Setup common installer infrastructure (root check + logging)
    setup_installer_common

    log "INFO" "========================================"
    log "INFO" "MyLiCuLa Package Installation"
    log "INFO" "========================================"
    log "INFO" "Debug mode: ${DEBUG_MODE}"
    log "INFO" "Dry-run mode: ${DRY_RUN_MODE}"
    log "INFO" ""

    # Check requirements
    if ! check_requirements; then
        exit 1
    fi

    # Install standard packages
    log "INFO" ""
    if ! install_standard_packages; then
        log "ERROR" "Standard package installation failed"
        exit 1
    fi

    # Install custom packages
    log "INFO" ""
    if ! install_custom_packages; then
        log "ERROR" "Custom package installation failed"
        exit 1
    fi

    log "INFO" ""
    log "INFO" "========================================"
    log "INFO" "Package installation completed successfully"
    log "INFO" "========================================"
    log "INFO" "Log file: ${LOG_FILE}"
}

# Run main function
main "$@"
