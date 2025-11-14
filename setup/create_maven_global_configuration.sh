#!/usr/bin/env bash
####################################################################################################
# Args           :
#                   -d, --directory     Target directory for Maven configuration (default: $HOME/.m2)
#                   --debug             Enable debug logging
#                   --dry-run           Run without making any changes
#                   -h, --help          Display this help message
#
# Usage          : ./create_maven_global_configuration.sh
#                  ./create_maven_global_configuration.sh -d /custom/path
#                  ./create_maven_global_configuration.sh --debug
#
# Output stdout  : Progress messages for Maven configuration creation
# Output stderr  : Error messages if configuration creation fails
# Return code    : 0   Success
#                  1   Validation failure
#                  2   Installation failure
#
# Description    : This script creates Maven global configuration directory and copies predefined
#                  settings files. It sets up vanilla and custom settings templates and creates
#                  the default settings.xml from the vanilla template.
#
#                  This script implements the MyLiCuLa installer interface for standardized
#                  installation flow and error handling.
#
# Author         : Francisco Güemes
# Email          : francisco@franciscoguemes.com
# See also       : setup/README.md for installer interface documentation
#                  lib/installer_common.sh for interface definitions
#                  https://maven.apache.org/settings.html
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

# Default Maven directory
TARGET_DIR="${HOME}/.m2"

# Maven resources directory
readonly MAVEN_RESOURCES="${BASE_DIR}/resources/maven"

# Settings files to copy
readonly SETTINGS_VANILLA="settings.vanilla.xml"
readonly SETTINGS_CUSTOM="settings.custom.xml"
readonly SETTINGS_DEFAULT="settings.xml"

#==================================================================================================
# Help Function
#==================================================================================================

show_help() {
    cat << EOF
Maven Global Configuration Creator for MyLiCuLa

Usage: $(basename "$0") [OPTIONS]

Create Maven global configuration with predefined settings files

OPTIONS:
    -d, --directory     Target directory for Maven configuration
                        (default: \$HOME/.m2)
    --debug             Enable debug logging with verbose output
    --dry-run           Run without making any changes to the system
    -h, --help          Display this help message

DESCRIPTION:
    This script creates Maven global configuration directory and sets up
    predefined settings files. It provides both vanilla and custom Maven
    settings templates.

    The script:
    - Creates the Maven configuration directory (~/.m2 by default)
    - Copies settings.vanilla.xml (minimal configuration)
    - Copies settings.custom.xml (customized configuration template)
    - Creates settings.xml from vanilla template as default

    Files created:
    - settings.vanilla.xml : Minimal Maven settings
    - settings.custom.xml  : Custom settings template
    - settings.xml         : Active settings (initially vanilla)

REQUIREMENTS:
    - Maven settings templates in resources/maven/
    - Write permissions to target directory

EXAMPLES:
    # Create Maven configuration in default location
    $(basename "$0")

    # Create with debug output
    $(basename "$0") --debug

    # Test without making changes
    $(basename "$0") --dry-run

    # Create in custom directory
    $(basename "$0") -d /custom/path/.m2

FILES:
    Source directory: ${MAVEN_RESOURCES}
    Target directory: ${TARGET_DIR}

NOTES:
    - This script should be run as regular user (not root)
    - Existing settings.xml will NOT be overwritten
    - Vanilla and custom templates will be overwritten if they exist
    - You can switch between vanilla and custom by copying files

AUTHOR:
    Francisco Güemes <francisco@franciscoguemes.com>

SEE ALSO:
    setup/README.md - Installer interface documentation
    https://maven.apache.org/settings.html - Maven settings reference
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
    echo "Maven Global Configuration Creation"
}

#
# Function: validate_environment
# Description: Validate that the environment is ready for installation
#
validate_environment() {
    log "INFO" "Validating environment for Maven configuration creation..."

    # Ensure script is not run as root
    if [[ $EUID -eq 0 ]]; then
        log "ERROR" "This script cannot be run as root"
        log "ERROR" "Maven configuration must be created for regular user"
        return 1
    fi

    # Check if Maven resources directory exists
    if [[ ! -d "$MAVEN_RESOURCES" ]]; then
        log "ERROR" "Maven resources directory not found: ${MAVEN_RESOURCES}"
        log "ERROR" "Please ensure the repository is complete"
        return 1
    fi

    # Check if required settings files exist in resources
    if [[ ! -f "${MAVEN_RESOURCES}/${SETTINGS_VANILLA}" ]]; then
        log "ERROR" "Required file not found: ${MAVEN_RESOURCES}/${SETTINGS_VANILLA}"
        return 1
    fi

    if [[ ! -f "${MAVEN_RESOURCES}/${SETTINGS_CUSTOM}" ]]; then
        log "ERROR" "Required file not found: ${MAVEN_RESOURCES}/${SETTINGS_CUSTOM}"
        return 1
    fi

    # Check if target directory parent exists and is writable
    local target_parent
    target_parent="$(dirname "$TARGET_DIR")"

    if [[ ! -d "$target_parent" ]]; then
        log "ERROR" "Parent directory does not exist: ${target_parent}"
        return 1
    fi

    if [[ ! -w "$target_parent" ]]; then
        log "ERROR" "No write permission to parent directory: ${target_parent}"
        return 1
    fi

    # Check idempotency - if Maven configuration already exists with all required files
    if [[ -d "$TARGET_DIR" ]]; then
        local files_exist=0
        local required_files=("$SETTINGS_VANILLA" "$SETTINGS_CUSTOM" "$SETTINGS_DEFAULT")

        for file in "${required_files[@]}"; do
            if [[ -f "${TARGET_DIR}/${file}" ]]; then
                ((files_exist++)) || true
            fi
        done

        if [[ $files_exist -eq ${#required_files[@]} ]]; then
            log "INFO" "Maven configuration already exists (${files_exist}/${#required_files[@]} files present)"
            log "INFO" "Target directory: ${TARGET_DIR}"
            return 2  # Already installed
        fi

        debug "Maven directory exists but incomplete: ${files_exist}/${#required_files[@]} files"
    fi

    log "INFO" "✓ Environment validation passed"
    return 0
}

#
# Function: run_installation
# Description: Perform the actual installation
#
run_installation() {
    log "INFO" "Starting Maven configuration creation..."

    # Display configuration summary
    log "INFO" "============================================"
    log "INFO" "Maven Configuration Setup"
    log "INFO" "============================================"
    log "INFO" "Source Directory: ${MAVEN_RESOURCES}"
    log "INFO" "Target Directory: ${TARGET_DIR}"
    log "INFO" "Debug Mode:       ${DEBUG_MODE}"
    log "INFO" "Dry Run:          ${DRY_RUN_MODE}"
    log "INFO" "============================================"
    log "INFO" ""

    # Create target directory if it doesn't exist
    if [[ ! -d "$TARGET_DIR" ]]; then
        if [[ "$DRY_RUN_MODE" == true ]]; then
            log "INFO" "[DRY-RUN] Would create directory: ${TARGET_DIR}"
        else
            debug "Creating Maven configuration directory: ${TARGET_DIR}"
            if ! mkdir -p "$TARGET_DIR" 2>/dev/null; then
                log "ERROR" "Failed to create directory: ${TARGET_DIR}"
                return 1
            fi
            log "INFO" "✓ Created directory: ${TARGET_DIR}"
        fi
    else
        debug "Target directory already exists: ${TARGET_DIR}"
    fi

    # Copy vanilla settings
    if [[ "$DRY_RUN_MODE" == true ]]; then
        log "INFO" "[DRY-RUN] Would copy: ${SETTINGS_VANILLA}"
    else
        debug "Copying ${SETTINGS_VANILLA}..."
        if ! cp "${MAVEN_RESOURCES}/${SETTINGS_VANILLA}" "${TARGET_DIR}/${SETTINGS_VANILLA}" 2>/dev/null; then
            log "ERROR" "Failed to copy ${SETTINGS_VANILLA}"
            return 1
        fi
        log "INFO" "✓ Copied: ${SETTINGS_VANILLA}"
    fi

    # Copy custom settings
    if [[ "$DRY_RUN_MODE" == true ]]; then
        log "INFO" "[DRY-RUN] Would copy: ${SETTINGS_CUSTOM}"
    else
        debug "Copying ${SETTINGS_CUSTOM}..."
        if ! cp "${MAVEN_RESOURCES}/${SETTINGS_CUSTOM}" "${TARGET_DIR}/${SETTINGS_CUSTOM}" 2>/dev/null; then
            log "ERROR" "Failed to copy ${SETTINGS_CUSTOM}"
            return 1
        fi
        log "INFO" "✓ Copied: ${SETTINGS_CUSTOM}"
    fi

    # Create default settings.xml from vanilla template (only if it doesn't exist)
    if [[ -f "${TARGET_DIR}/${SETTINGS_DEFAULT}" ]]; then
        log "INFO" "Preserving existing ${SETTINGS_DEFAULT}"
        debug "Existing settings.xml will not be overwritten"
    else
        if [[ "$DRY_RUN_MODE" == true ]]; then
            log "INFO" "[DRY-RUN] Would create: ${SETTINGS_DEFAULT} (from vanilla)"
        else
            debug "Creating default ${SETTINGS_DEFAULT} from vanilla template..."
            if ! cp "${TARGET_DIR}/${SETTINGS_VANILLA}" "${TARGET_DIR}/${SETTINGS_DEFAULT}" 2>/dev/null; then
                log "ERROR" "Failed to create ${SETTINGS_DEFAULT}"
                return 1
            fi
            log "INFO" "✓ Created: ${SETTINGS_DEFAULT} (from vanilla template)"
        fi
    fi

    log "INFO" ""
    log "INFO" "✓ Maven configuration created successfully"
    log "INFO" "Configuration directory: ${TARGET_DIR}"
    log "INFO" ""
    log "INFO" "Available settings:"
    log "INFO" "  - ${SETTINGS_VANILLA} : Minimal Maven settings"
    log "INFO" "  - ${SETTINGS_CUSTOM}  : Custom settings template"
    log "INFO" "  - ${SETTINGS_DEFAULT}      : Active settings (currently vanilla)"
    log "INFO" ""
    log "INFO" "To switch to custom settings:"
    log "INFO" "  cp ${TARGET_DIR}/${SETTINGS_CUSTOM} ${TARGET_DIR}/${SETTINGS_DEFAULT}"
    return 0
}

#
# Function: cleanup_on_failure
# Description: Clean up partial installation if run_installation fails
#
cleanup_on_failure() {
    log "INFO" "Cleaning up after installation failure..."

    # Remove partially created directory (only if it was created by this run)
    if [[ -d "$TARGET_DIR" ]] && [[ -z "$(ls -A "$TARGET_DIR" 2>/dev/null)" ]]; then
        if [[ "$DRY_RUN_MODE" == true ]]; then
            log "INFO" "[DRY-RUN] Would remove empty directory: ${TARGET_DIR}"
        else
            debug "Removing empty directory: ${TARGET_DIR}"
            rmdir "$TARGET_DIR" 2>/dev/null || true
        fi
    fi

    log "INFO" "Cleanup completed"
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
            -d|--directory)
                TARGET_DIR="$2"
                shift 2
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
