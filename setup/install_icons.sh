#!/usr/bin/env bash
####################################################################################################
# Args           :
#                   --debug         Enable debug logging
#                   --dry-run       Run without making any changes
#                   -h, --help      Display this help message
#
# Usage          : sudo ./install_icons.sh
#                  sudo ./install_icons.sh --debug
#                  sudo ./install_icons.sh --dry-run
#
# Output stdout  : Progress messages for icon installation
# Output stderr  : Error messages if icon operations fail or required applications are missing
# Return code    : 0   Success
#                  1   Validation failure
#                  2   Installation failure
#
# Description    : This script installs the customization icons and sets them up. All the icons in
#                  this script are free of royalties. Thanks to the authors of the icons:
#                    https://imgur.com/gallery/n1js84s
#
#                  The script creates symbolic links from resources/icons to
#                  ~/Pictures/Ubuntu_customization/icons and sets custom icons for directories
#                  using the gio command.
#
#                  This script implements the MyLiCuLa installer interface for standardized
#                  installation flow and error handling.
#
# Author         : Francisco Güemes
# Email          : francisco@franciscoguemes.com
# See also       : setup/README.md for installer interface documentation
#                  lib/installer_common.sh for interface definitions
#                  https://askubuntu.com/questions/1044358/is-it-possible-to-insert-icons-on-folders-with-the-gio-set-command
#                  https://forums.linuxmint.com/viewtopic.php?t=352261
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

# Icon source and destination directories
readonly ICONS_DIR="${BASE_DIR}/resources/icons"
readonly DESTINATION_DIR="${HOME}/Pictures/Ubuntu_customization/icons"

# Directories that will receive custom icons (using gio command)
declare -A DIRECTORY_ICONS=(
    ["${HOME}/Documents/Mega"]="${DESTINATION_DIR}/Mega-nz.png"
)

#==================================================================================================
# Help Function
#==================================================================================================

show_help() {
    cat << EOF
Icon Installer for MyLiCuLa

Usage: sudo $(basename "$0") [OPTIONS]

Install custom directory icons for Ubuntu customization

OPTIONS:
    --debug         Enable debug logging with verbose output
    --dry-run       Run without making any changes to the system
    -h, --help      Display this help message

DESCRIPTION:
    This script installs custom directory icons by:
    - Creating symbolic links from resources/icons to ~/Pictures/Ubuntu_customization/icons
    - Setting custom icons for specific directories using the gio command

    All icons in this script are free of royalties.
    Thanks to the authors: https://imgur.com/gallery/n1js84s

REQUIREMENTS:
    - gio command (part of glib2.0-bin package)
    - Icon files in resources/icons directory

EXAMPLES:
    # Install all icons
    sudo $(basename "$0")

    # Install with debug output
    sudo $(basename "$0") --debug

    # Test without making changes
    sudo $(basename "$0") --dry-run

FILES:
    Source icons: ${ICONS_DIR}
    Destination: ${DESTINATION_DIR}

NOTES:
    - Icons are installed as symbolic links (space-efficient)
    - Existing icons are detected and skipped automatically
    - To reset an icon to default: gio set DIRECTORY -t unset metadata::custom-icon

AUTHOR:
    Francisco Güemes <francisco@franciscoguemes.com>

SEE ALSO:
    setup/README.md - Installer interface documentation
    https://askubuntu.com/questions/1044358/is-it-possible-to-insert-icons-on-folders-with-the-gio-set-command
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
    echo "Icon Installation"
}

#
# Function: validate_environment
# Description: Validate that the environment is ready for installation
#
validate_environment() {
    log "INFO" "Validating environment for icon installation..."

    # Check required applications
    if ! check_required_app "gio" "sudo nala install glib2.0-bin"; then
        log "ERROR" "Missing required application: gio"
        return 1
    fi

    # Check if icons source directory exists
    if [[ ! -d "$ICONS_DIR" ]]; then
        log "ERROR" "Icons source directory not found: ${ICONS_DIR}"
        return 1
    fi

    # Check if there are any icon files
    local icon_count
    icon_count=$(find "$ICONS_DIR" -maxdepth 1 -type f | wc -l)
    if [[ $icon_count -eq 0 ]]; then
        log "ERROR" "No icon files found in: ${ICONS_DIR}"
        return 1
    fi

    debug "Found ${icon_count} icon file(s) in source directory"

    # Check idempotency - if all icons already exist at destination, consider it installed
    if [[ -d "$DESTINATION_DIR" ]]; then
        local existing_count=0
        local total_count=0

        for icon_file in "$ICONS_DIR"/*; do
            if [[ -f "$icon_file" ]]; then
                ((total_count++)) || true
                local filename=$(basename "$icon_file")
                local link_path="${DESTINATION_DIR}/${filename}"

                if [[ -L "$link_path" ]] && [[ -e "$link_path" ]]; then
                    ((existing_count++)) || true
                fi
            fi
        done

        if [[ $total_count -gt 0 ]] && [[ $existing_count -eq $total_count ]]; then
            log "INFO" "All icons already installed (${existing_count}/${total_count})"
            return 2  # Already installed
        fi

        debug "Icons status: ${existing_count}/${total_count} already installed"
    fi

    log "INFO" "✓ Environment validation passed"
    return 0
}

#
# Function: run_installation
# Description: Perform the actual installation
#
run_installation() {
    log "INFO" "Starting icon installation..."

    local created_count=0
    local skipped_count=0
    local error_count=0

    # Create destination directory if needed
    if [[ ! -d "$DESTINATION_DIR" ]]; then
        if [[ "$DRY_RUN_MODE" == true ]]; then
            log "INFO" "[DRY-RUN] Would create directory: ${DESTINATION_DIR}"
        else
            debug "Creating destination directory: ${DESTINATION_DIR}"
            if ! mkdir -p "$DESTINATION_DIR" 2>/dev/null; then
                log "ERROR" "Failed to create destination directory: ${DESTINATION_DIR}"
                return 1
            fi
        fi
    fi

    # Create symbolic links for all icons
    log "INFO" "Installing icon files..."
    for icon_file in "$ICONS_DIR"/*; do
        # Skip if not a regular file
        if [[ ! -f "$icon_file" ]]; then
            continue
        fi

        local filename=$(basename "$icon_file")
        local link_path="${DESTINATION_DIR}/${filename}"

        if [[ "$DRY_RUN_MODE" == true ]]; then
            log "INFO" "[DRY-RUN] Would create symlink: ${link_path} -> ${icon_file}"
            ((created_count++)) || true
        else
            debug "Installing icon: ${filename}"

            # create_symlink returns 0 for success, 1 for error, 2 for skip
            local symlink_result=0
            if create_symlink "$icon_file" "$link_path"; then
                symlink_result=0
                ((created_count++)) || true
            else
                symlink_result=$?
                if [[ $symlink_result -eq 2 ]]; then
                    # Already exists - this is OK for idempotency
                    ((skipped_count++)) || true
                else
                    # Real error
                    ((error_count++)) || true
                fi
            fi
        fi
    done

    # Set custom icons for directories using gio
    log "INFO" "Setting custom directory icons..."
    for directory in "${!DIRECTORY_ICONS[@]}"; do
        local icon_file="${DIRECTORY_ICONS[$directory]}"

        # Skip if directory doesn't exist
        if [[ ! -d "$directory" ]]; then
            debug "Directory does not exist (skipping): ${directory}"
            continue
        fi

        if [[ "$DRY_RUN_MODE" == true ]]; then
            log "INFO" "[DRY-RUN] Would set icon for: ${directory}"
            log "INFO" "[DRY-RUN]   Icon file: ${icon_file}"
        else
            debug "Setting icon for directory: ${directory}"
            debug "  Icon file: ${icon_file}"

            # Set the custom icon (suppress errors as gio might not be fully available in all environments)
            if gio set -t string "$directory" metadata::custom-icon "file://${icon_file}" 2>/dev/null; then
                debug "✓ Custom icon set successfully"
            else
                debug "⚠ Could not set custom icon (gio command failed, continuing anyway)"
            fi
        fi
    done

    # Summary
    log "INFO" "Icon installation summary:"
    log "INFO" "  Created: $created_count"
    log "INFO" "  Skipped: $skipped_count (already exist)"
    log "INFO" "  Errors: $error_count"

    if [[ $error_count -gt 0 ]]; then
        log "ERROR" "Icon installation completed with errors"
        return 1
    fi

    log "INFO" "✓ Icon installation completed successfully"
    return 0
}

#
# Function: cleanup_on_failure
# Description: Clean up partial installation if run_installation fails
#
cleanup_on_failure() {
    log "INFO" "No cleanup needed for icon installation (symlinks are idempotent)"
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
