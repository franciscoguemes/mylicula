#!/usr/bin/env bash
####################################################################################################
#Args           :
#                   --help, -h    Show help message
#Usage          :   ./install.sh
#Output stdout  :   Installation progress messages via whiptail dialogs
#Output stderr  :   Error messages
#Return code    :   0 on success, 1 on error
#Description    :   Main installation script for MyLiCuLa - My Linux Custom Layer
#                   Interactive installer using whiptail for GUI dialogs.
#                   Manages configuration and orchestrates system customization.
#
#Author         :   Francisco Güemes
#Email          :   francisco@franciscoguemes.com
#See also       :   https://github.com/franciscoguemes/mylicula
#                   setup/ directory for installation scripts
####################################################################################################

set -euo pipefail

#==================================================================================================
# Configuration
#==================================================================================================

# Get the directory where this script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" &>/dev/null && pwd)"

# Configuration paths
CONFIG_DIR="${HOME}/.config/mylicula"
CONFIG_FILE="${CONFIG_DIR}/mylicula.conf"
CONFIG_EXAMPLE="${SCRIPT_DIR}/resources/config/mylicula.conf.example"
BANNER_FILE="${SCRIPT_DIR}/resources/banner/banner.txt"

# Export base directory for child scripts
export MYLICULA_BASE_DIR="$SCRIPT_DIR"

# Colors for terminal output (when not using whiptail)
readonly COLOR_RED='\033[0;31m'
readonly COLOR_GREEN='\033[0;32m'
readonly COLOR_YELLOW='\033[1;33m'
readonly COLOR_BLUE='\033[0;34m'
readonly COLOR_RESET='\033[0m'

#==================================================================================================
# Output Functions
#==================================================================================================

log_info() {
    echo -e "${COLOR_BLUE}[INFO]${COLOR_RESET} $*" >&2
}

log_success() {
    echo -e "${COLOR_GREEN}[SUCCESS]${COLOR_RESET} $*" >&2
}

log_warning() {
    echo -e "${COLOR_YELLOW}[WARNING]${COLOR_RESET} $*" >&2
}

log_error() {
    echo -e "${COLOR_RED}[ERROR]${COLOR_RESET} $*" >&2
}

#==================================================================================================
# Utility Functions
#==================================================================================================

command_exists() {
    command -v "$1" &> /dev/null
}

show_banner() {
    if [[ -f "$BANNER_FILE" ]]; then
        clear
        cat "$BANNER_FILE"
        echo ""
        echo "    Version: 1.0.0"
        echo "    Author: Francisco Güemes"
        echo ""
        sleep 2
    fi
}

show_help() {
    cat << EOF
MyLiCuLa - My Linux Custom Layer
Installation script to customize Linux/Ubuntu systems for homogeneity

Usage: $0 [OPTIONS]

Options:
    -h, --help          Show this help message

Description:
    This script manages the installation of MyLiCuLa customizations.
    It uses whiptail for interactive dialogs and guides you through
    the configuration and installation process.

    On first run, it creates a configuration file that you must edit
    with your personal information before proceeding with installation.

For more information, see README.md
EOF
}

check_prerequisites() {
    local missing_tools=()

    # Check for whiptail
    if ! command_exists whiptail; then
        missing_tools+=("whiptail")
    fi

    # Check bash version
    if [[ "${BASH_VERSINFO[0]}" -lt 4 ]]; then
        log_error "Bash 4.0+ required. Current: $BASH_VERSION"
        exit 1
    fi

    # Check if running on Linux
    if [[ "$(uname -s)" != "Linux" ]]; then
        log_error "This script is designed for Linux systems"
        exit 1
    fi

    if [[ ${#missing_tools[@]} -gt 0 ]]; then
        log_error "Missing required tools: ${missing_tools[*]}"
        log_info "Install with: sudo nala install ${missing_tools[*]}"
        exit 1
    fi
}

config_exists() {
    [[ -f "$CONFIG_FILE" ]]
}

check_sudo_required() {
    local selections="$1"

    # Remove quotes from selections
    selections=$(echo "$selections" | tr -d '"')

    # Check if any of the selected steps require sudo
    for item in $selections; do
        case "$item" in
            packages|snap|directory|bash_scripts)
                return 0  # Requires sudo
                ;;
        esac
    done

    return 1  # No sudo required
}

prompt_sudo_early() {
    log_info "Some installation steps require administrative privileges."
    log_info "You will be prompted for your password..."
    echo ""

    # Warm up sudo credentials
    if sudo -v; then
        log_success "Sudo credentials cached successfully"
        echo ""
        return 0
    else
        log_error "Failed to obtain sudo privileges"
        return 1
    fi
}

create_config_from_example() {
    log_info "Creating configuration directory: $CONFIG_DIR"
    mkdir -p "$CONFIG_DIR"
    chmod 700 "$CONFIG_DIR"

    log_info "Copying configuration template to: $CONFIG_FILE"
    cp "$CONFIG_EXAMPLE" "$CONFIG_FILE"
    chmod 600 "$CONFIG_FILE"

    log_success "Configuration file created at: $CONFIG_FILE"
}

update_last_run_timestamp() {
    local timestamp
    timestamp=$(date '+%Y-%m-%d %H:%M:%S')

    # Update LAST_TIME_RUN in config file
    if grep -q "CONFIG\[LAST_TIME_RUN\]" "$CONFIG_FILE"; then
        sed -i "s/CONFIG\[LAST_TIME_RUN\]=.*/CONFIG[LAST_TIME_RUN]=\"$timestamp\"/" "$CONFIG_FILE"
    else
        echo "CONFIG[LAST_TIME_RUN]=\"$timestamp\"" >> "$CONFIG_FILE"
    fi
}

get_last_run_info() {
    if [[ -f "$CONFIG_FILE" ]]; then
        # Declare CONFIG as associative array before sourcing
        declare -A CONFIG

        # Source the config file to read values
        # shellcheck disable=SC1090
        source "$CONFIG_FILE" 2>/dev/null || true

        local last_run="${CONFIG[LAST_TIME_RUN]:-Never}"
        local username="${CONFIG[USERNAME]:-<not set>}"
        local email="${CONFIG[EMAIL]:-<not set>}"
        local company="${CONFIG[COMPANY]:-<not set>}"

        echo "Last installation run: $last_run

Configuration summary:
  Username: $username
  Email: $email
  Company: $company

Config file: $CONFIG_FILE

Note: Secrets (tokens, PATs) are not displayed for security.
To view or edit your configuration, open:
  $CONFIG_FILE"
    fi
}

show_installation_menu() {
    # Use file descriptor 3 to capture output while allowing UI to display
    local selections

    set +e  # Temporarily disable exit on error
    selections=$(whiptail --title "MyLiCuLa - Select Installation Steps" \
        --checklist "\nSelect which components to install:\n(Use SPACE to select/deselect, ARROW keys to navigate, ENTER to confirm)" \
        24 78 14 \
        "packages" "Install packages & applications" ON \
        "snap" "Install snap applications" ON \
        "directory" "Create directory structure" ON \
        "bash_scripts" "Install bash scripts" ON \
        "keyboard" "Create keyboard shortcuts" ON \
        "gitlab" "Clone GitLab repositories" OFF \
        "github" "Clone GitHub repositories" OFF \
        "icons" "Customize UI: Install icons" ON \
        "templates" "Customize UI: Install templates" ON \
        "set_title" "Others: Install set-title function" ON \
        "maven" "Others: Create Maven global configuration" OFF \
        "flyway" "3rd party apps: Flyway" OFF \
        "toolbox" "3rd party apps: Toolbox" OFF \
        3>&1 1>&2 2>&3)

    local whiptail_exit=$?
    set -e  # Re-enable exit on error

    if [[ $whiptail_exit -eq 0 ]]; then
        # Return the selections (space-separated list of tags)
        echo "$selections"
        return 0
    else
        return 1
    fi
}

execute_installation_step() {
    local step_name="$1"
    local script_path="$2"
    local needs_sudo="${3:-false}"

    log_info "Executing: $step_name"

    if [[ ! -f "$script_path" ]]; then
        log_error "Script not found: $script_path"
        return 1
    fi

    # Execute with or without sudo based on needs
    if [[ "$needs_sudo" == "true" ]]; then
        if sudo bash "$script_path"; then
            log_success "Completed: $step_name"
            return 0
        else
            log_error "Failed: $step_name"
            return 1
        fi
    else
        if bash "$script_path"; then
            log_success "Completed: $step_name"
            return 0
        else
            log_error "Failed: $step_name"
            return 1
        fi
    fi
}

run_selected_installations() {
    local selections="$1"

    # Remove quotes from selections
    selections=$(echo "$selections" | tr -d '"')

    local total_steps=0
    local completed_steps=0
    local failed_steps=0

    # Count total steps
    for item in $selections; do
        total_steps=$((total_steps + 1))
    done

    log_info "Starting installation of $total_steps selected component(s)"
    echo ""

    # Execute each selected step
    for item in $selections; do
        case "$item" in
            packages)
                if execute_installation_step "Install packages & applications" \
                    "${SCRIPT_DIR}/setup/install_packages.sh" "true"; then
                    completed_steps=$((completed_steps + 1))
                else
                    failed_steps=$((failed_steps + 1))
                fi
                ;;
            snap)
                if execute_installation_step "Install snap applications" \
                    "${SCRIPT_DIR}/setup/install_snap.sh" "true"; then
                    completed_steps=$((completed_steps + 1))
                else
                    failed_steps=$((failed_steps + 1))
                fi
                ;;
            directory)
                if execute_installation_step "Create directory structure" \
                    "${SCRIPT_DIR}/setup/create_directory_structure.sh" "true"; then
                    completed_steps=$((completed_steps + 1))
                else
                    failed_steps=$((failed_steps + 1))
                fi
                ;;
            bash_scripts)
                if execute_installation_step "Install bash scripts" \
                    "${SCRIPT_DIR}/setup/install_bash_scripts.sh" "true"; then
                    completed_steps=$((completed_steps + 1))
                else
                    failed_steps=$((failed_steps + 1))
                fi
                ;;
            keyboard)
                if execute_installation_step "Create keyboard shortcuts" \
                    "${SCRIPT_DIR}/setup/create_keyboard_shortcuts.sh"; then
                    completed_steps=$((completed_steps + 1))
                else
                    failed_steps=$((failed_steps + 1))
                fi
                ;;
            gitlab)
                if execute_installation_step "Clone GitLab repositories" \
                    "${SCRIPT_DIR}/setup/clone_gitlab_repositories.sh"; then
                    completed_steps=$((completed_steps + 1))
                else
                    failed_steps=$((failed_steps + 1))
                fi
                ;;
            github)
                if execute_installation_step "Clone GitHub repositories" \
                    "${SCRIPT_DIR}/setup/clone_github_repositories.sh"; then
                    completed_steps=$((completed_steps + 1))
                else
                    failed_steps=$((failed_steps + 1))
                fi
                ;;
            icons)
                if execute_installation_step "Customize UI: Install icons" \
                    "${SCRIPT_DIR}/setup/install_icons.sh"; then
                    completed_steps=$((completed_steps + 1))
                else
                    failed_steps=$((failed_steps + 1))
                fi
                ;;
            templates)
                if execute_installation_step "Customize UI: Install templates" \
                    "${SCRIPT_DIR}/setup/install_templates.sh"; then
                    completed_steps=$((completed_steps + 1))
                else
                    failed_steps=$((failed_steps + 1))
                fi
                ;;
            set_title)
                if execute_installation_step "Others: Install set-title function" \
                    "${SCRIPT_DIR}/setup/install_set-title_function.sh"; then
                    completed_steps=$((completed_steps + 1))
                else
                    failed_steps=$((failed_steps + 1))
                fi
                ;;
            maven)
                if execute_installation_step "Others: Create Maven global configuration" \
                    "${SCRIPT_DIR}/setup/create_maven_global_configuration.sh"; then
                    completed_steps=$((completed_steps + 1))
                else
                    failed_steps=$((failed_steps + 1))
                fi
                ;;
            flyway)
                if execute_installation_step "3rd party apps: Flyway" \
                    "${SCRIPT_DIR}/setup/apps/install_flyway.sh"; then
                    completed_steps=$((completed_steps + 1))
                else
                    failed_steps=$((failed_steps + 1))
                fi
                ;;
            toolbox)
                if execute_installation_step "3rd party apps: Toolbox" \
                    "${SCRIPT_DIR}/setup/apps/install_toolbox.sh"; then
                    completed_steps=$((completed_steps + 1))
                else
                    failed_steps=$((failed_steps + 1))
                fi
                ;;
            *)
                log_warning "Unknown installation step: $item"
                ;;
        esac
        echo ""
    done

    # Show summary
    echo ""
    echo "=========================================="
    log_info "Installation Summary"
    echo "=========================================="
    log_info "Total steps: $total_steps"
    log_success "Completed: $completed_steps"
    if [[ $failed_steps -gt 0 ]]; then
        log_error "Failed: $failed_steps"
    fi
    echo ""
}

#==================================================================================================
# Main Installation Flow
#==================================================================================================

main() {
    # Parse arguments
    while [[ $# -gt 0 ]]; do
        case $1 in
            -h|--help)
                show_help
                exit 0
                ;;
            *)
                log_error "Unknown option: $1"
                echo ""
                show_help
                exit 1
                ;;
        esac
    done

    # Check prerequisites
    check_prerequisites

    # Show banner
    show_banner

    # Check if configuration exists
    if config_exists; then
        # Configuration exists - show info and ask to continue
        local config_info
        config_info=$(get_last_run_info)

        if whiptail --title "MyLiCuLa - Configuration Found" \
            --yesno "$config_info\n\nDo you want to continue with this configuration?" \
            20 78; then

            # User wants to continue - show installation menu
            local selections
            if selections=$(show_installation_menu); then
                # Check if sudo is needed and prompt early
                if check_sudo_required "$selections"; then
                    if ! prompt_sudo_early; then
                        log_error "Cannot proceed without sudo privileges"
                        exit 1
                    fi
                fi

                # User selected components - update timestamp and start installation
                update_last_run_timestamp

                # Execute selected installations
                run_selected_installations "$selections"

                # Show completion message
                whiptail --title "MyLiCuLa - Installation Complete" \
                    --msgbox "Installation completed!\n\nPlease review the output above for any errors.\n\nYou may need to log out and log back in for all changes to take effect." \
                    12 70

                log_success "Installation completed"
            else
                # User cancelled the selection menu
                whiptail --title "MyLiCuLa - Cancelled" \
                    --msgbox "Installation cancelled by user." \
                    8 50
                log_info "Installation cancelled by user"
                exit 0
            fi
        else
            # User cancelled configuration confirmation
            whiptail --title "MyLiCuLa - Cancelled" \
                --msgbox "Installation cancelled by user.\n\nTo reconfigure, edit:\n  $CONFIG_FILE\n\nOr delete it and run this script again." \
                12 70
            log_info "Installation cancelled by user"
            exit 0
        fi
    else
        # Configuration doesn't exist - create from example
        whiptail --title "MyLiCuLa - First Run" \
            --msgbox "Welcome to MyLiCuLa!\n\nNo configuration file found. A template will be created for you.\n\nYou will need to edit it with your personal information before running the installer again." \
            12 70

        # Create config from example
        create_config_from_example

        # Show instructions
        whiptail --title "MyLiCuLa - Configuration Required" \
            --msgbox "Configuration file created at:\n  $CONFIG_FILE\n\nPlease edit this file and update the following:\n\n  1. Your username, email, and full name\n  2. Your company/organization\n  3. Your GitHub username (optional)\n  4. GitLab credentials (optional)\n  5. GitHub PAT token (optional)\n\nAfter editing the configuration file, run this script again to start the installation.\n\nTo edit now:\n  nano $CONFIG_FILE\n  or\n  gedit $CONFIG_FILE" \
            20 78

        log_info "Configuration file created. Please edit it and run this script again."
        log_info "Edit with: nano $CONFIG_FILE"
        exit 0
    fi
}

# Run main function
main "$@"
