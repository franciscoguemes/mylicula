#!/usr/bin/env bash
####################################################################################################
# Args           :
#                   --debug         Enable debug logging
#                   --dry-run       Run without making any changes
#                   --launch        Launch Toolbox after installation
#                   -h, --help      Display this help message
#
# Usage          : ./install_toolbox.sh
#                  ./install_toolbox.sh --debug
#                  ./install_toolbox.sh --dry-run
#                  ./install_toolbox.sh --launch
#
# Output stdout  : Progress messages for JetBrains Toolbox installation
# Output stderr  : Error messages if installation fails or required applications are missing
# Return code    : 0   Success
#                  1   Validation failure
#                  2   Installation failure
#
# Description    : This script automates the download, verification, extraction, and optionally
#                  execution of the latest version of JetBrains Toolbox on a Linux system.
#                  It ensures that necessary tools are installed, fetches the latest release
#                  details from JetBrains, verifies the integrity of the downloaded file,
#                  and extracts the Toolbox application.
#
#                  This script implements the MyLiCuLa installer interface for standardized
#                  installation flow and error handling.
#
# Author         : Francisco Güemes
# Email          : francisco@franciscoguemes.com
# See also       : setup/README.md for installer interface documentation
#                  lib/installer_common.sh for interface definitions
#                  https://www.jetbrains.com/toolbox-app/
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
    # Search upwards for lib/common.sh (max 3 levels up from setup/apps/)
    BASE_DIR="$SCRIPT_DIR"
    for i in {1..4}; do
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

# Target user's home directory
TARGET_HOME="${MYLICULA_HOME:-${HOME}}"

# JetBrains Toolbox installation directory
readonly INSTALL_DIR="${TARGET_HOME}/development/jetbrains-toolbox"

# JetBrains API URL for latest release
readonly RELEASE_API_URL="https://data.services.jetbrains.com/products/releases?code=TBA&latest=true&type=release"

# Temporary directory for downloads
TMP_DIR=""

# Launch Toolbox after installation flag
LAUNCH_AFTER_INSTALL=false

#==================================================================================================
# Help Function
#==================================================================================================

show_help() {
    cat << EOF
JetBrains Toolbox Installer for MyLiCuLa

Usage: $(basename "$0") [OPTIONS]

Install JetBrains Toolbox App

OPTIONS:
    --debug         Enable debug logging with verbose output
    --dry-run       Run without making any changes to the system
    --launch        Launch Toolbox after successful installation
    -h, --help      Display this help message

DESCRIPTION:
    This script installs JetBrains Toolbox, an application manager for JetBrains IDEs.

    The script:
    - Checks for the latest Toolbox version from JetBrains API
    - Downloads the tar.gz package and SHA-256 checksum
    - Verifies the integrity of the download
    - Extracts to ~/development/jetbrains-toolbox
    - Optionally launches the application (with --launch flag)

REQUIREMENTS:
    - wget (for downloading)
    - tar (for extraction)
    - sha256sum (for checksum verification)
    - jq (for JSON parsing)
    - Internet connection

EXAMPLES:
    # Install Toolbox
    $(basename "$0")

    # Install with debug output
    $(basename "$0") --debug

    # Test without making changes
    $(basename "$0") --dry-run

    # Install and launch immediately
    $(basename "$0") --launch

FILES:
    Installation: ${INSTALL_DIR}

NOTES:
    - Toolbox is extracted to ~/development/jetbrains-toolbox
    - Each version is kept in a separate subdirectory
    - By default, Toolbox is NOT launched after installation
    - Use --launch flag to start Toolbox after installation

AUTHOR:
    Francisco Güemes <francisco@franciscoguemes.com>

SEE ALSO:
    setup/README.md - Installer interface documentation
    https://www.jetbrains.com/toolbox-app/ - JetBrains Toolbox homepage
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
    echo "JetBrains Toolbox Installation"
}

#
# Function: validate_environment
# Description: Validate that the environment is ready for installation
#
validate_environment() {
    log "INFO" "Validating environment for JetBrains Toolbox installation..."

    # Check required applications
    if ! check_required_app "wget" "sudo nala install wget"; then
        log "ERROR" "Missing required application: wget"
        return 1
    fi

    if ! check_required_app "tar" "sudo nala install tar"; then
        log "ERROR" "Missing required application: tar"
        return 1
    fi

    if ! check_required_app "sha256sum" "sudo nala install coreutils"; then
        log "ERROR" "Missing required application: sha256sum"
        return 1
    fi

    if ! check_required_app "jq" "sudo nala install jq"; then
        log "ERROR" "Missing required application: jq"
        return 1
    fi

    # Check if target home directory exists
    if [[ ! -d "$TARGET_HOME" ]]; then
        log "ERROR" "Target home directory does not exist: ${TARGET_HOME}"
        return 1
    fi

    # Check idempotency - if Toolbox is already installed
    log "INFO" "Checking for existing JetBrains Toolbox installation..."

    if [[ -d "$INSTALL_DIR" ]] && [[ -n "$(ls -A "$INSTALL_DIR" 2>/dev/null)" ]]; then
        # Find the most recent installation
        local existing_dir
        existing_dir=$(find "$INSTALL_DIR" -maxdepth 1 -type d -name "jetbrains-toolbox-*" 2>/dev/null | sort -V | tail -1)

        if [[ -n "$existing_dir" ]]; then
            local installed_version
            installed_version=$(basename "$existing_dir" | grep -oP '\d+\.\d+\.\d+\.\d+' || echo "")

            if [[ -n "$installed_version" ]]; then
                log "INFO" "Found existing installation: version ${installed_version}"
                log "INFO" "Checking for latest available version..."

                # We need to fetch the latest version to compare
                # Create temporary directory for version check
                local temp_check_dir
                temp_check_dir=$(mktemp -d -p "${TARGET_HOME}" ".toolbox-version-check-XXXXXX")

                # Fetch latest release to get version
                local timestamp
                timestamp=$(($(date +%s%N)/1000000))
                local api_url="${RELEASE_API_URL}&_=${timestamp}"

                if wget --header="User-Agent: Mozilla/5.0" -q -O "${temp_check_dir}/release.json" "$api_url" 2>/dev/null; then
                    local latest_url
                    latest_url=$(jq -r '.TBA[0].downloads.linux.link' "${temp_check_dir}/release.json" 2>/dev/null)

                    if [[ -n "$latest_url" ]] && [[ "$latest_url" != "null" ]]; then
                        local latest_version
                        latest_version=$(basename "$latest_url" | grep -oP '\d+\.\d+\.\d+\.\d+' || echo "")

                        if [[ -n "$latest_version" ]]; then
                            log "INFO" "Latest available version: ${latest_version}"

                            if [[ "$installed_version" == "$latest_version" ]]; then
                                log "INFO" "JetBrains Toolbox ${installed_version} is already installed and up-to-date"
                                log "INFO" "✓ Skipping installation"
                                rm -rf "$temp_check_dir" 2>/dev/null
                                return 2  # Already installed
                            else
                                log "INFO" "Upgrade available: ${installed_version} → ${latest_version}"
                                log "INFO" "Will proceed with upgrade"
                            fi
                        fi
                    fi
                fi

                # Cleanup temp directory
                rm -rf "$temp_check_dir" 2>/dev/null
            else
                log "INFO" "Existing installation found but version could not be determined"
                log "INFO" "Will proceed with installation"
            fi
        fi
    else
        log "INFO" "No existing installation found"
        log "INFO" "Will proceed with fresh installation"
    fi

    log "INFO" "✓ Environment validation passed"
    return 0
}

#
# Function: run_installation
# Description: Perform the actual installation
#
run_installation() {
    log "INFO" "Starting JetBrains Toolbox installation..."

    # Create temporary directory
    TMP_DIR=$(mktemp -d -p "${TARGET_HOME}" ".toolbox-install-XXXXXX")
    debug "Created temporary directory: ${TMP_DIR}"

    # Fetch latest release details
    if ! fetch_latest_release; then
        log "ERROR" "Failed to fetch latest release details"
        return 1
    fi

    # Download Toolbox package
    if ! download_toolbox; then
        log "ERROR" "Failed to download JetBrains Toolbox"
        return 1
    fi

    # Verify checksum
    if ! verify_checksum; then
        log "ERROR" "Checksum verification failed"
        return 1
    fi

    # Extract package
    if ! extract_toolbox; then
        log "ERROR" "Failed to extract JetBrains Toolbox"
        return 1
    fi

    # Launch if requested
    if [[ "$LAUNCH_AFTER_INSTALL" == true ]]; then
        launch_toolbox
    fi

    # Cleanup temp directory
    cleanup_temp_dir

    log "INFO" "✓ JetBrains Toolbox installation completed successfully"
    return 0
}

#
# Function: cleanup_on_failure
# Description: Clean up partial installation if run_installation fails
#
cleanup_on_failure() {
    log "INFO" "Cleaning up after installation failure..."

    # Remove temporary directory
    cleanup_temp_dir

    log "INFO" "Cleanup completed"
    return 0
}

#==================================================================================================
# JetBrains Toolbox Installation Functions
#==================================================================================================

#
# Function: cleanup_temp_dir
# Description: Remove temporary directory if it exists
#
cleanup_temp_dir() {
    if [[ -n "$TMP_DIR" ]] && [[ -d "$TMP_DIR" ]]; then
        debug "Removing temporary directory: ${TMP_DIR}"
        rm -rf "$TMP_DIR" 2>/dev/null || true
    fi
}

#
# Function: fetch_latest_release
# Description: Fetch latest release details from JetBrains API
# Return: 0 on success, 1 on failure
#
fetch_latest_release() {
    log "INFO" "Fetching latest release details from JetBrains..."

    local timestamp
    timestamp=$(($(date +%s%N)/1000000))
    local api_url="${RELEASE_API_URL}&_=${timestamp}"

    if [[ "$DRY_RUN_MODE" == true ]]; then
        log "INFO" "[DRY-RUN] Would fetch release details from: ${api_url}"
        # Create dummy JSON for dry-run
        echo '{"TBA":[{"downloads":{"linux":{"link":"https://example.com/jetbrains-toolbox-1.0.0.0.tar.gz","checksumLink":"https://example.com/jetbrains-toolbox-1.0.0.0.tar.gz.sha256"}}}]}' > "${TMP_DIR}/release.json"
        return 0
    fi

    debug "API URL: ${api_url}"

    if ! wget --header="User-Agent: Mozilla/5.0" -q -O "${TMP_DIR}/release.json" "$api_url"; then
        log "ERROR" "Failed to download release details"
        return 1
    fi

    # Verify we got valid JSON
    if ! jq empty "${TMP_DIR}/release.json" 2>/dev/null; then
        log "ERROR" "Invalid JSON response from JetBrains API"
        return 1
    fi

    debug "✓ Release details fetched successfully"
    return 0
}

#
# Function: download_toolbox
# Description: Download Toolbox tar.gz and checksum
# Return: 0 on success, 1 on failure
#
download_toolbox() {
    log "INFO" "Downloading JetBrains Toolbox..."

    # Parse download URLs from JSON
    local download_url
    local checksum_url

    download_url=$(jq -r '.TBA[0].downloads.linux.link' "${TMP_DIR}/release.json")
    checksum_url=$(jq -r '.TBA[0].downloads.linux.checksumLink' "${TMP_DIR}/release.json")

    if [[ -z "$download_url" ]] || [[ "$download_url" == "null" ]]; then
        log "ERROR" "Failed to extract download URL from release details"
        return 1
    fi

    if [[ -z "$checksum_url" ]] || [[ "$checksum_url" == "null" ]]; then
        log "ERROR" "Failed to extract checksum URL from release details"
        return 1
    fi

    debug "Download URL: ${download_url}"
    debug "Checksum URL: ${checksum_url}"

    if [[ "$DRY_RUN_MODE" == true ]]; then
        log "INFO" "[DRY-RUN] Would download: ${download_url}"
        log "INFO" "[DRY-RUN] Would download: ${checksum_url}"
        # Create dummy files for dry-run
        touch "${TMP_DIR}/jetbrains-toolbox.tar.gz"
        echo "dummy-checksum-value" > "${TMP_DIR}/jetbrains-toolbox.sha256"
        return 0
    fi

    # Download tar.gz
    if ! wget --header="User-Agent: Mozilla/5.0" -q -O "${TMP_DIR}/jetbrains-toolbox.tar.gz" "$download_url"; then
        log "ERROR" "Failed to download Toolbox package"
        return 1
    fi

    # Download checksum
    if ! wget --header="User-Agent: Mozilla/5.0" -q -O "${TMP_DIR}/jetbrains-toolbox.sha256" "$checksum_url"; then
        log "ERROR" "Failed to download checksum file"
        return 1
    fi

    # Extract version from filename
    local filename
    filename=$(basename "$download_url")
    local version
    version=$(echo "$filename" | grep -oP '\d+\.\d+\.\d+\.\d+' || echo "unknown")

    log "INFO" "✓ Downloaded JetBrains Toolbox version: ${version}"
    return 0
}

#
# Function: verify_checksum
# Description: Verify SHA-256 checksum of downloaded file
# Return: 0 on success, 1 on failure
#
verify_checksum() {
    log "INFO" "Verifying SHA-256 checksum..."

    if [[ "$DRY_RUN_MODE" == true ]]; then
        log "INFO" "[DRY-RUN] Would verify SHA-256 checksum"
        return 0
    fi

    local actual_checksum
    local expected_checksum

    actual_checksum=$(sha256sum "${TMP_DIR}/jetbrains-toolbox.tar.gz" | awk '{print $1}')
    expected_checksum=$(cat "${TMP_DIR}/jetbrains-toolbox.sha256" | awk '{print $1}')

    debug "Expected checksum: ${expected_checksum}"
    debug "Actual checksum:   ${actual_checksum}"

    if [[ "$actual_checksum" != "$expected_checksum" ]]; then
        log "ERROR" "SHA-256 checksum mismatch!"
        log "ERROR" "  Expected: ${expected_checksum}"
        log "ERROR" "  Actual:   ${actual_checksum}"
        return 1
    fi

    log "INFO" "✓ SHA-256 checksum verification passed"
    return 0
}

#
# Function: extract_toolbox
# Description: Extract Toolbox to installation directory
# Return: 0 on success, 1 on failure
#
extract_toolbox() {
    log "INFO" "Extracting JetBrains Toolbox..."

    if [[ "$DRY_RUN_MODE" == true ]]; then
        log "INFO" "[DRY-RUN] Would extract to: ${INSTALL_DIR}"
        return 0
    fi

    # Create installation directory
    if ! mkdir -p "$INSTALL_DIR" 2>/dev/null; then
        log "ERROR" "Failed to create installation directory: ${INSTALL_DIR}"
        return 1
    fi

    debug "Extracting to: ${INSTALL_DIR}"

    # Extract tarball
    if ! tar -xzf "${TMP_DIR}/jetbrains-toolbox.tar.gz" -C "$INSTALL_DIR"; then
        log "ERROR" "Failed to extract tarball"
        return 1
    fi

    # Get extracted directory name
    local extracted_dir
    extracted_dir=$(tar -tf "${TMP_DIR}/jetbrains-toolbox.tar.gz" | head -1 | cut -f1 -d"/")

    if [[ -z "$extracted_dir" ]]; then
        log "ERROR" "Failed to determine extracted directory name"
        return 1
    fi

    local toolbox_path="${INSTALL_DIR}/${extracted_dir}"

    if [[ ! -d "$toolbox_path" ]]; then
        log "ERROR" "Extraction completed but directory not found: ${toolbox_path}"
        return 1
    fi

    log "INFO" "✓ Extracted to: ${toolbox_path}"
    return 0
}

#
# Function: launch_toolbox
# Description: Launch JetBrains Toolbox application
#
launch_toolbox() {
    log "INFO" "Launching JetBrains Toolbox..."

    if [[ "$DRY_RUN_MODE" == true ]]; then
        log "INFO" "[DRY-RUN] Would launch JetBrains Toolbox"
        return 0
    fi

    # Find the most recent toolbox directory
    local latest_dir
    latest_dir=$(find "$INSTALL_DIR" -maxdepth 1 -type d -name "jetbrains-toolbox-*" | sort -V | tail -1)

    if [[ -z "$latest_dir" ]]; then
        log "ERROR" "Could not find JetBrains Toolbox executable directory"
        return 1
    fi

    local toolbox_bin="${latest_dir}/jetbrains-toolbox"

    if [[ ! -x "$toolbox_bin" ]]; then
        log "ERROR" "JetBrains Toolbox executable not found: ${toolbox_bin}"
        return 1
    fi

    debug "Launching: ${toolbox_bin}"

    # Launch in background
    nohup "$toolbox_bin" > /dev/null 2>&1 &

    log "INFO" "✓ JetBrains Toolbox launched"
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
            --launch)
                LAUNCH_AFTER_INSTALL=true
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

    # Setup logging (no-root: installs to user's home directory)
    setup_installer_common "no-root"

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
