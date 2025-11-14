#!/usr/bin/env bash
####################################################################################################
# Args           :
#                   --debug         Enable debug logging
#                   --dry-run       Run without making any changes
#                   -h, --help      Display this help message
#
# Usage          : sudo ./install_packages.sh
#                  sudo ./install_packages.sh --debug
#                  sudo ./install_packages.sh --dry-run
#
# Output stdout  : Progress messages for package installation, repository additions, and GPG key imports
# Output stderr  : Error messages if package installation fails or required applications are missing
# Return code    : 0   Success
#                  1   Validation failure
#                  2   Installation failure
#
# Description    : This script installs Ubuntu packages from two sources:
#                  1. standard_packages.txt - Packages from default Ubuntu repositories
#                  2. custom_packages.txt - Packages requiring custom PPAs/repositories
#
#                  The script parses custom_packages.txt for metadata comments (REPO, GPG, KEYRING)
#                  and automatically configures repositories before installing packages.
#
#                  Format for custom_packages.txt:
#                    # Package Group Name
#                    # REPO: ppa:user/repo or full repository line
#                    # GPG: URL to GPG key (optional)
#                    # KEYRING: path to keyring file (optional)
#                    package-name-1
#                    package-name-2
#
#                  This script implements the MyLiCuLa installer interface for standardized
#                  installation flow and error handling.
#
# Author         : Francisco Güemes
# Email          : francisco@franciscoguemes.com
# See also       : setup/README.md for installer interface documentation
#                  lib/installer_common.sh for interface definitions
####################################################################################################

set -euo pipefail

#==================================================================================================
# Script Setup
#==================================================================================================

# Get script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SCRIPT_NAME="$(basename "${BASH_SOURCE[0]}")"

# Find BASE_DIR - Priority 1: env var, Priority 2: search for lib/common.sh
if [[ -n "${MYLICULA_BASE_DIR:-}" ]]; then
    BASE_DIR="$MYLICULA_BASE_DIR"
else
    # Search upwards for lib/common.sh (max 3 levels)
    BASE_DIR="$SCRIPT_DIR"
    for i in {1..3}; do
        if [[ -f "${BASE_DIR}/lib/common.sh" ]]; then
            break
        fi
        BASE_DIR="$(dirname "$BASE_DIR")"
    done

    if [[ ! -f "${BASE_DIR}/lib/common.sh" ]]; then
        echo "[ERROR] Cannot find MyLiCuLa project root" >&2
        echo "Please set MYLICULA_BASE_DIR environment variable or run via install.sh" >&2
        exit 1
    fi
fi

# Source common libraries
source "${BASE_DIR}/lib/common.sh"
source "${BASE_DIR}/lib/installer_common.sh"

#==================================================================================================
# Configuration
#==================================================================================================

# Package list files
readonly STANDARD_PACKAGES_FILE="${BASE_DIR}/resources/apt/standard_packages.txt"
readonly CUSTOM_PACKAGES_FILE="${BASE_DIR}/resources/apt/custom_packages.txt"

#==================================================================================================
# Help Function
#==================================================================================================

show_help() {
    cat << EOF
Package Installer for MyLiCuLa

Usage: sudo $(basename "$0") [OPTIONS]

Install Ubuntu packages from standard and custom repositories

OPTIONS:
    --debug         Enable debug logging with verbose output
    --dry-run       Run without making any changes to the system
    -h, --help      Display this help message

DESCRIPTION:
    This script installs packages from two sources:

    1. Standard Packages (resources/apt/standard_packages.txt):
       - Packages from default Ubuntu repositories
       - Installed using 'nala' package manager

    2. Custom Packages (resources/apt/custom_packages.txt):
       - Packages requiring PPAs or custom repositories
       - Automatically configures repositories and GPG keys
       - Supports metadata comments for repo configuration

    Custom Package Format:
        # Package Group Name
        # REPO: ppa:user/repo (or full repository line)
        # GPG: https://example.com/key.gpg (optional)
        # KEYRING: /usr/share/keyrings/example.gpg (optional)
        package-name-1
        package-name-2

        # Next group...

REQUIREMENTS:
    - Root privileges (run with sudo)
    - nala package manager (installed via bootstrap.sh)
    - curl (for downloading GPG keys)
    - gpg (for importing keys)
    - add-apt-repository (software-properties-common)

EXAMPLES:
    # Install all packages
    sudo $(basename "$0")

    # Install with debug output
    sudo $(basename "$0") --debug

    # Test without making changes
    sudo $(basename "$0") --dry-run

FILES:
    Standard packages: ${STANDARD_PACKAGES_FILE}
    Custom packages:   ${CUSTOM_PACKAGES_FILE}

NOTES:
    - The script automatically updates package lists after adding repositories
    - Existing repositories and GPG keys are detected (idempotent)
    - Failed package groups are logged but don't stop the entire installation
    - All output is logged to: /var/log/mylicula/install_packages.log

AUTHOR:
    Francisco Güemes <francisco@franciscoguemes.com>

SEE ALSO:
    setup/README.md - Installer interface documentation
    resources/apt/standard_packages.txt - Standard package list
    resources/apt/custom_packages.txt - Custom package list with repo metadata
EOF
}

#==================================================================================================
# Installer Interface Implementation
#==================================================================================================

#
# Function: get_installer_name
# Description: Return human-readable name for this installer
#
get_installer_name() {
    echo "Package Installation"
}

#
# Function: validate_environment
# Description: Validate that the environment is ready for installation
#
validate_environment() {
    log "INFO" "Validating environment for package installation..."

    # Check if we have root privileges
    if [[ $EUID -ne 0 ]]; then
        log "ERROR" "This script requires root privileges to install packages"
        log "ERROR" "Please run with: sudo $(basename "$0")"
        return 1
    fi

    # Check required applications
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

    # Check if package list files exist
    if [[ ! -f "$STANDARD_PACKAGES_FILE" ]]; then
        log "ERROR" "Standard packages file not found: ${STANDARD_PACKAGES_FILE}"
        return 1
    fi

    if [[ ! -f "$CUSTOM_PACKAGES_FILE" ]]; then
        log "ERROR" "Custom packages file not found: ${CUSTOM_PACKAGES_FILE}"
        return 1
    fi

    # Check idempotency - if most standard packages are installed, skip
    # Note: This is a simplified check. A more thorough check would verify
    # all packages, but that would be expensive.
    debug "Package installation is not fully idempotent - will attempt to install"
    debug "Package managers (nala/apt) handle already-installed packages gracefully"

    log "INFO" "✓ Environment validation passed"
    return 0
}

#
# Function: run_installation
# Description: Perform the actual installation
#
run_installation() {
    log "INFO" "Starting package installation..."

    # Install standard packages
    log "INFO" ""
    if ! install_standard_packages; then
        log "ERROR" "Standard package installation failed"
        return 1
    fi

    # Install custom packages
    log "INFO" ""
    if ! install_custom_packages; then
        log "ERROR" "Custom package installation failed"
        return 1
    fi

    log "INFO" "✓ Package installation completed successfully"
    return 0
}

#
# Function: cleanup_on_failure
# Description: Clean up partial installation if run_installation fails
#
cleanup_on_failure() {
    log "INFO" "Package installation failures are handled by package manager"
    log "INFO" "No additional cleanup needed (packages are atomic)"
    return 0
}

#==================================================================================================
# Package Installation Functions
#==================================================================================================

#
# Function: install_standard_packages
# Description: Install packages from standard_packages.txt
# Return: 0 on success, 1 on failure
#
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
        log "INFO" "No standard packages to install"
        return 0
    fi

    # Install packages
    if [[ "$DRY_RUN_MODE" == true ]]; then
        log "INFO" "[DRY-RUN] Would install ${#packages[@]} packages:"
        for pkg in "${packages[@]}"; do
            log "INFO" "[DRY-RUN]   - $pkg"
        done
    else
        log "INFO" "Installing ${#packages[@]} packages with nala..."
        if nala install -y "${packages[@]}" >> "$LOG_FILE" 2>&1; then
            log "INFO" "Successfully installed ${#packages[@]} standard packages"
        else
            log "ERROR" "Failed to install some standard packages (see log for details)"
            log "ERROR" "Log file: ${LOG_FILE}"
            return 1
        fi
    fi

    return 0
}

#
# Function: add_ppa_repository
# Description: Add PPA repository
# Args:
#   $1 - PPA identifier (e.g., ppa:user/repo)
# Return: 0 on success, 1 on failure
#
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

#
# Function: add_custom_repository
# Description: Add custom repository line
# Args:
#   $1 - Repository line (e.g., "deb [signed-by=...] https://...")
# Return: 0 on success, 1 on failure
#
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

#
# Function: import_gpg_key
# Description: Import GPG key from URL
# Args:
#   $1 - GPG key URL
#   $2 - Keyring file path
# Return: 0 on success, 1 on failure
#
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

#
# Function: install_package_group
# Description: Install a package group (packages with same repository configuration)
# Args:
#   $1 - Repository (PPA or custom line)
#   $2 - GPG key URL (optional)
#   $3 - Keyring path (optional)
#   $4+ - Package names
# Return: 0 on success, 1 on failure
#
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
                log "ERROR" "Failed to update package lists"
                return 1
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

#
# Function: install_custom_packages
# Description: Parse and install packages from custom_packages.txt
# Return: 0 on success, 1 on failure
#
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
# Main Function
#==================================================================================================

main() {
    # Parse arguments
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
                log_error "Unknown option: $1"
                echo ""
                show_help
                exit 1
                ;;
        esac
    done

    # Setup logging
    setup_installer_common

    # Execute the installer using the standard interface
    execute_installer
}

#==================================================================================================
# Script Entry Point
#==================================================================================================

# Only run main if script is executed directly (not sourced)
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
