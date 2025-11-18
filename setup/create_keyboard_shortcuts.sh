#!/usr/bin/env bash
####################################################################################################
# Args           :
#                   --debug         Enable debug logging
#                   --dry-run       Run without making any changes
#                   -h, --help      Display this help message
#
# Usage          : ./create_keyboard_shortcuts.sh
#                  ./create_keyboard_shortcuts.sh --debug
#                  ./create_keyboard_shortcuts.sh --dry-run
#
# Output stdout  : Progress messages for keyboard shortcut creation
# Output stderr  : Error messages if shortcut creation fails
# Return code    : 0   Success
#                  1   Validation failure
#                  2   Installation failure
#
# Description    : This script creates GNOME keyboard shortcuts for bash scripts that were
#                  installed by install_bash_scripts.sh. It checks for the existence of
#                  symbolic links in /usr/local/bin before creating shortcuts.
#
#                  This script implements the MyLiCuLa installer interface for standardized
#                  installation flow and error handling.
#
# Author         : Francisco Güemes
# Email          : francisco@franciscoguemes.com
# See also       : setup/README.md for installer interface documentation
#                  lib/installer_common.sh for interface definitions
#                  https://askubuntu.com/questions/597395/how-to-create-custom-keyboard-shortcuts-from-terminal
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

# Directory where script symlinks are installed
readonly INSTALL_DIR="/usr/local/bin"

# Keyboard shortcuts to create
# Format: "Name|Command|Keybinding"
declare -a SHORTCUTS=(
    "Generate link|generate_link.sh|<Shift>L"
    "Text to Markdown code|code_2_markdown_in_clipboard.sh|<Primary>Above_Tab"
    "Find text in files|find_text.sh|<Alt>F"
    "Adapt URL in clipboard|update_url_in_clipboard.sh|<Primary>u"
    "Connect to VPN|connect_to_VPN.sh|<Shift>KP_Add"
    "Disconnect from VPN|disconnect_from_VPN.sh|<Shift>KP_Subtract"
    "Insert signature in clipboard|insert_signature_in_clipboard.sh|<Primary><Shift>s"
    "Show keyboard layout|show_keyboard_layout.sh|<Super>k"
)

#==================================================================================================
# Help Function
#==================================================================================================

show_help() {
    cat << EOF
GNOME Keyboard Shortcuts Creator for MyLiCuLa

Usage: $(basename "$0") [OPTIONS]

Create GNOME keyboard shortcuts for installed bash scripts

OPTIONS:
    --debug         Enable debug logging with verbose output
    --dry-run       Run without making any changes to the system
    -h, --help      Display this help message

DESCRIPTION:
    This script creates GNOME keyboard shortcuts for bash scripts installed
    by install_bash_scripts.sh. It configures gsettings to bind keyboard
    combinations to script commands.

    Shortcuts created:
    - <Shift>L              : Generate link
    - <Primary>Above_Tab    : Text to Markdown code
    - <Alt>F                : Find text in files
    - <Primary>u            : Adapt URL in clipboard
    - <Shift>KP_Add         : Connect to VPN
    - <Shift>KP_Subtract    : Disconnect from VPN
    - <Primary><Shift>s     : Insert signature in clipboard
    - <Super>k              : Show keyboard layout

    The script will:
    - Verify all required scripts are installed in /usr/local/bin
    - Check for keybinding conflicts
    - Find available slots for custom keybindings
    - Create shortcuts using gsettings

REQUIREMENTS:
    - GNOME desktop environment
    - gsettings command (part of GLib)
    - Required scripts installed in /usr/local/bin

EXAMPLES:
    # Create keyboard shortcuts
    $(basename "$0")

    # Create with debug output
    $(basename "$0") --debug

    # Test without making changes
    $(basename "$0") --dry-run

NOTES:
    - Shortcuts are created using GNOME gsettings
    - Existing shortcuts with the same keybinding will be detected
    - Run install_bash_scripts.sh first to install required scripts

USEFUL COMMANDS:
    View all custom shortcuts:
      gsettings get org.gnome.settings-daemon.plugins.media-keys custom-keybindings

    View specific shortcut (example for custom0):
      gsettings get org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom0/ name

    Reset all custom shortcuts:
      gsettings reset org.gnome.settings-daemon.plugins.media-keys custom-keybindings

    Remove shortcuts:
      ./uninstall/remove_keyboard_shortcuts.sh

AUTHOR:
    Francisco Güemes <francisco@franciscoguemes.com>

SEE ALSO:
    setup/README.md - Installer interface documentation
    setup/install_bash_scripts.sh - Install required scripts first
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
    echo "Keyboard Shortcuts Creation"
}

#
# Function: validate_environment
# Description: Validate that the environment is ready for installation
#
validate_environment() {
    log "INFO" "Validating environment for keyboard shortcuts creation..."

    # Check if gsettings is available (GNOME desktop required)
    if ! check_required_app "gsettings" "GNOME desktop environment required"; then
        log "ERROR" "Missing required application: gsettings (GNOME)"
        log "ERROR" "This script only works on GNOME desktop environment"
        return 1
    fi

    # Check if required script symlinks exist
    log "INFO" "Checking for required script symlinks in ${INSTALL_DIR}..."
    local missing_count=0

    for shortcut_def in "${SHORTCUTS[@]}"; do
        IFS='|' read -r name command binding <<< "$shortcut_def"

        if [[ ! -L "$INSTALL_DIR/$command" ]]; then
            log "ERROR" "Symbolic link missing: ${INSTALL_DIR}/${command}"
            ((missing_count++)) || true
        else
            debug "Found: ${command}"
        fi
    done

    if [[ $missing_count -gt 0 ]]; then
        log "ERROR" "Missing ${missing_count} required script(s) in ${INSTALL_DIR}"
        log "ERROR" "Please run: sudo setup/install_bash_scripts.sh"
        return 1
    fi

    # Check idempotency - if all shortcuts already exist with correct bindings
    log "INFO" "Checking for existing keyboard shortcuts..."
    local existing_bindings
    existing_bindings=$(gsettings get org.gnome.settings-daemon.plugins.media-keys custom-keybindings 2>/dev/null || echo "@as []")

    if [[ "$existing_bindings" != "@as []" ]]; then
        local shortcuts_exist=0
        local total_shortcuts=${#SHORTCUTS[@]}

        for shortcut_def in "${SHORTCUTS[@]}"; do
            IFS='|' read -r name command binding <<< "$shortcut_def"

            if check_shortcut_exists "$name" "$command" "$binding"; then
                ((shortcuts_exist++)) || true
            fi
        done

        if [[ $shortcuts_exist -eq $total_shortcuts ]]; then
            log "INFO" "All keyboard shortcuts already exist (${shortcuts_exist}/${total_shortcuts})"
            return 2  # Already installed
        fi

        debug "Shortcuts status: ${shortcuts_exist}/${total_shortcuts} already exist"
    fi

    log "INFO" "✓ Environment validation passed"
    return 0
}

#
# Function: run_installation
# Description: Perform the actual installation
#
run_installation() {
    log "INFO" "Starting keyboard shortcuts creation..."

    local created_count=0
    local skipped_count=0
    local error_count=0

    for shortcut_def in "${SHORTCUTS[@]}"; do
        IFS='|' read -r name command binding <<< "$shortcut_def"

        # Check if shortcut already exists
        if check_shortcut_exists "$name" "$command" "$binding"; then
            debug "Shortcut already exists: ${name}"
            ((skipped_count++)) || true
            continue
        fi

        # Create the shortcut
        if create_shortcut "$name" "$command" "$binding"; then
            ((created_count++)) || true
        else
            ((error_count++)) || true
        fi
    done

    # Summary
    log "INFO" "Keyboard shortcuts creation summary:"
    log "INFO" "  Created: $created_count"
    log "INFO" "  Skipped: $skipped_count (already exist)"
    log "INFO" "  Errors: $error_count"

    if [[ $error_count -gt 0 ]]; then
        log "ERROR" "Keyboard shortcuts creation completed with errors"
        return 1
    fi

    log "INFO" "✓ Keyboard shortcuts created successfully"
    log "INFO" ""
    log "INFO" "Useful commands:"
    log "INFO" "  View all shortcuts: gsettings get org.gnome.settings-daemon.plugins.media-keys custom-keybindings"
    log "INFO" "  Remove shortcuts:   ./uninstall/remove_keyboard_shortcuts.sh"
    return 0
}

#
# Function: cleanup_on_failure
# Description: Clean up partial installation if run_installation fails
#
cleanup_on_failure() {
    log "INFO" "No automatic cleanup for keyboard shortcuts"
    log "INFO" "To remove shortcuts manually, run: ./uninstall/remove_keyboard_shortcuts.sh"
    return 0
}

#==================================================================================================
# Helper Functions
#==================================================================================================

#
# Function: check_shortcut_exists
# Description: Check if a keyboard shortcut already exists with the same name, command, and binding
# Args:
#   $1 - Shortcut name
#   $2 - Command
#   $3 - Keybinding
# Return: 0 if exists, 1 if not
#
check_shortcut_exists() {
    local name="$1"
    local command="$2"
    local binding="$3"

    local existing_bindings
    existing_bindings=$(gsettings get org.gnome.settings-daemon.plugins.media-keys custom-keybindings 2>/dev/null || echo "@as []")

    if [[ "$existing_bindings" == "@as []" ]]; then
        return 1
    fi

    # Extract binding paths
    local binding_paths
    binding_paths=$(echo "$existing_bindings" | grep -o "'/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom[0-9]*/'")

    for binding_path in $binding_paths; do
        binding_path=${binding_path#\'}
        binding_path=${binding_path%\'}

        local existing_name
        local existing_command
        local existing_binding

        existing_name=$(gsettings get org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:"$binding_path" name 2>/dev/null | sed "s/'//g")
        existing_command=$(gsettings get org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:"$binding_path" command 2>/dev/null | sed "s/'//g")
        existing_binding=$(gsettings get org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:"$binding_path" binding 2>/dev/null | sed "s/'//g")

        if [[ "$existing_name" == "$name" ]] && [[ "$existing_command" == "$command" ]] && [[ "$existing_binding" == "$binding" ]]; then
            return 0
        fi
    done

    return 1
}

#
# Function: create_shortcut
# Description: Create a keyboard shortcut using gsettings
# Args:
#   $1 - Shortcut name
#   $2 - Command
#   $3 - Keybinding
# Return: 0 on success, 1 on failure
#
create_shortcut() {
    local name="$1"
    local command="$2"
    local binding="$3"

    if [[ "$DRY_RUN_MODE" == true ]]; then
        log "INFO" "[DRY-RUN] Would create shortcut: ${name} (${binding}) -> ${command}"
        return 0
    fi

    # Check if the binding is already used by a different shortcut
    local existing_bindings
    existing_bindings=$(gsettings get org.gnome.settings-daemon.plugins.media-keys custom-keybindings 2>/dev/null || echo "@as []")

    if [[ "$existing_bindings" != "@as []" ]]; then
        local binding_paths
        binding_paths=$(echo "$existing_bindings" | grep -o "'/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom[0-9]*/'")

        for binding_path in $binding_paths; do
            binding_path=${binding_path#\'}
            binding_path=${binding_path%\'}

            local existing_binding
            existing_binding=$(gsettings get org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:"$binding_path" binding 2>/dev/null | sed "s/'//g")

            if [[ "$existing_binding" == "$binding" ]]; then
                local shortcut_name
                shortcut_name=$(gsettings get org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:"$binding_path" name 2>/dev/null | sed "s/'//g")

                log "ERROR" "Keybinding ${binding} is already in use by: ${shortcut_name}"
                return 1
            fi
        done
    fi

    # Find an empty slot in custom keybindings
    local slot_index=-1
    for i in {0..100}; do
        local existing_binding
        existing_binding=$(echo "$existing_bindings" | grep -o "'/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom$i/'")

        if [[ -z "$existing_binding" ]]; then
            slot_index=$i
            break
        fi
    done

    if [[ $slot_index -eq -1 ]]; then
        log "ERROR" "No available slots for custom keybindings"
        return 1
    fi

    # Define the new custom keybinding path
    local new_binding_path="/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom${slot_index}/"

    debug "Creating shortcut in slot: custom${slot_index}"

    # Add the new binding path to the list of custom keybindings
    local current_bindings
    current_bindings=$(gsettings get org.gnome.settings-daemon.plugins.media-keys custom-keybindings 2>/dev/null || echo "@as []")

    local new_bindings
    if [[ "$current_bindings" == "@as []" ]]; then
        new_bindings="['$new_binding_path']"
    else
        # Remove outer brackets from current_bindings
        current_bindings=${current_bindings#[}
        current_bindings=${current_bindings%]}
        new_bindings="[${current_bindings}, '${new_binding_path}']"
    fi

    # Set the list of custom keybindings
    if ! gsettings set org.gnome.settings-daemon.plugins.media-keys custom-keybindings "$new_bindings" 2>/dev/null; then
        log "ERROR" "Failed to update custom-keybindings list"
        return 1
    fi

    # Set the name, command, and binding for the new custom keybinding
    if ! gsettings set org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:"$new_binding_path" name "$name" 2>/dev/null; then
        log "ERROR" "Failed to set shortcut name"
        return 1
    fi

    if ! gsettings set org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:"$new_binding_path" command "$command" 2>/dev/null; then
        log "ERROR" "Failed to set shortcut command"
        return 1
    fi

    if ! gsettings set org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:"$new_binding_path" binding "$binding" 2>/dev/null; then
        log "ERROR" "Failed to set shortcut binding"
        return 1
    fi

    log "INFO" "✓ Created shortcut: ${name} (${binding}) -> ${command}"
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

    # Setup logging (no-root: this modifies user's GNOME settings, not system-wide)
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
