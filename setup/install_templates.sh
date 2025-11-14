#!/usr/bin/env bash
####################################################################################################
# Args           :
#                   --debug         Enable debug logging
#                   --dry-run       Run without making any changes
#                   -h, --help      Display this help message
#
# Usage          : ./install_templates.sh
#                  ./install_templates.sh --debug
#                  ./install_templates.sh --dry-run
#
# Output stdout  : Progress messages for template installation
# Output stderr  : Error messages if template operations fail
# Return code    : 0   Success
#                  1   Validation failure
#                  2   Installation failure
#
# Description    : This script installs templates in Ubuntu so when you right-click inside Nautilus
#                  and select "New Document" you can see the different template options.
#
#                  The script creates symbolic links from resources/templates to ~/Templates folder.
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

# Template source and destination directories
readonly TEMPLATES_DIR="${BASE_DIR}/resources/templates"
readonly DESTINATION_DIR="${HOME}/Templates"

#==================================================================================================
# Help Function
#==================================================================================================

show_help() {
    cat << EOF
Template Installer for MyLiCuLa

Usage: $(basename "$0") [OPTIONS]

Install Nautilus "New Document" templates

OPTIONS:
    --debug         Enable debug logging with verbose output
    --dry-run       Run without making any changes to the system
    -h, --help      Display this help message

DESCRIPTION:
    This script installs templates for the Nautilus file manager's "New Document"
    context menu. When you right-click in Nautilus and select "New Document",
    you'll see all installed templates.

    The script:
    - Creates symbolic links from resources/templates to ~/Templates
    - Removes any broken symbolic links from previous installations
    - Makes templates available in Nautilus "New Document" menu

REQUIREMENTS:
    - Template files in resources/templates directory
    - ~/Templates directory (created automatically if needed)

EXAMPLES:
    # Install all templates
    $(basename "$0")

    # Install with debug output
    $(basename "$0") --debug

    # Test without making changes
    $(basename "$0") --dry-run

FILES:
    Source templates: ${TEMPLATES_DIR}
    Destination: ${DESTINATION_DIR}

NOTES:
    - Templates are installed as symbolic links (space-efficient)
    - Existing templates are detected and skipped automatically
    - Broken symbolic links are cleaned up automatically

AUTHOR:
    Francisco Güemes <francisco@franciscoguemes.com>

SEE ALSO:
    setup/README.md - Installer interface documentation
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
    echo "Template Installation"
}

#
# Function: validate_environment
# Description: Validate that the environment is ready for installation
#
validate_environment() {
    log "INFO" "Validating environment for template installation..."

    # Check if templates source directory exists
    if [[ ! -d "$TEMPLATES_DIR" ]]; then
        log "ERROR" "Templates source directory not found: ${TEMPLATES_DIR}"
        return 1
    fi

    # Check if there are any template files
    local template_count
    template_count=$(find "$TEMPLATES_DIR" -maxdepth 1 -type f | wc -l)
    if [[ $template_count -eq 0 ]]; then
        log "ERROR" "No template files found in: ${TEMPLATES_DIR}"
        return 1
    fi

    debug "Found ${template_count} template file(s) in source directory"

    # Check idempotency - if all templates already exist at destination, consider it installed
    if [[ -d "$DESTINATION_DIR" ]]; then
        local existing_count=0
        local total_count=0

        for template_file in "$TEMPLATES_DIR"/*; do
            if [[ -f "$template_file" ]]; then
                ((total_count++)) || true
                local filename=$(basename "$template_file")
                local link_path="${DESTINATION_DIR}/${filename}"

                if [[ -L "$link_path" ]] && [[ -e "$link_path" ]]; then
                    ((existing_count++)) || true
                fi
            fi
        done

        if [[ $total_count -gt 0 ]] && [[ $existing_count -eq $total_count ]]; then
            log "INFO" "All templates already installed (${existing_count}/${total_count})"
            return 2  # Already installed
        fi

        debug "Templates status: ${existing_count}/${total_count} already installed"
    fi

    log "INFO" "✓ Environment validation passed"
    return 0
}

#
# Function: run_installation
# Description: Perform the actual installation
#
run_installation() {
    log "INFO" "Starting template installation..."

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

    # Remove broken symbolic links from destination
    log "INFO" "Cleaning up broken symbolic links..."
    if [[ "$DRY_RUN_MODE" == true ]]; then
        # In dry-run mode, just report what would be removed
        local broken_count=0
        for link in "$DESTINATION_DIR"/*; do
            if [[ -L "$link" ]] && [[ ! -e "$link" ]]; then
                log "INFO" "[DRY-RUN] Would remove broken link: $(basename "$link")"
                ((broken_count++)) || true
            fi
        done
        if [[ $broken_count -eq 0 ]]; then
            debug "[DRY-RUN] No broken links found"
        fi
    else
        # Use remove_broken_links from lib/common.sh
        if remove_broken_links "$DESTINATION_DIR" 2>/dev/null; then
            debug "✓ Broken links cleaned up"
        else
            debug "No broken links found or cleanup not needed"
        fi
    fi

    # Create symbolic links for all templates
    log "INFO" "Installing template files..."
    for template_file in "$TEMPLATES_DIR"/*; do
        # Skip if not a regular file
        if [[ ! -f "$template_file" ]]; then
            continue
        fi

        local filename=$(basename "$template_file")
        local link_path="${DESTINATION_DIR}/${filename}"

        if [[ "$DRY_RUN_MODE" == true ]]; then
            log "INFO" "[DRY-RUN] Would create symlink: ${link_path} -> ${template_file}"
            ((created_count++)) || true
        else
            debug "Installing template: ${filename}"

            # create_symlink returns 0 for success, 1 for error, 2 for skip
            local symlink_result=0
            if create_symlink "$template_file" "$link_path"; then
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

    # Summary
    log "INFO" "Template installation summary:"
    log "INFO" "  Created: $created_count"
    log "INFO" "  Skipped: $skipped_count (already exist)"
    log "INFO" "  Errors: $error_count"

    if [[ $error_count -gt 0 ]]; then
        log "ERROR" "Template installation completed with errors"
        return 1
    fi

    log "INFO" "✓ Template installation completed successfully"
    return 0
}

#
# Function: cleanup_on_failure
# Description: Clean up partial installation if run_installation fails
#
cleanup_on_failure() {
    log "INFO" "No cleanup needed for template installation (symlinks are idempotent)"
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
