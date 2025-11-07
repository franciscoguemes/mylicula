#!/usr/bin/env bash
#
# Script Name: install.sh
# Description: Main installation script for MyLiCuLa - My Linux Custom Layer
#              Interactive installer that collects configuration and orchestrates
#              Linux and Ubuntu customizations for homogeneous system setup
#
# Args:
#   --dry-run : Preview changes without applying them (creates .target directory)
#   --verbose : Show detailed output during installation
#   --help    : Show this help message
#
# Usage: ./install.sh [--dry-run] [--verbose]
#
# Output (stdout): Installation progress and results
# Output (stderr): Error messages and warnings
# Return code: 0 on success, non-zero on failure
#
# Author: Francisco Güemes
# Email: francisco@franciscoguemes.com
# See also: customize/linux_setup.sh, customize/ubuntu_setup.sh

set -euo pipefail

#–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––
# Setup and initialization
#–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––

# Get the directory where this script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" &>/dev/null && pwd)"

# Source common utility functions
# shellcheck disable=SC1091
source "${SCRIPT_DIR}/lib/common.sh"

# Configuration variables (will be collected from user)
declare -gA CONFIG
CONFIG_DIR="${HOME}/.config/mylicula"
CONFIG_FILE="${CONFIG_DIR}/mylicula.conf"
CONFIG_EXAMPLE="${SCRIPT_DIR}/mylicula.conf.example"

#–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––
# Functions
#–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––

#
# Function: show_help
# Description: Display help message
# Args: None
# Usage: show_help
# Output (stdout): Help text
# Return code: 0
#
show_help() {
    cat << EOF
MyLiCuLa - My Linux Custom Layer
Installation script to customize Linux/Ubuntu systems for homogeneity

Usage: $0 [OPTIONS]

Options:
    --dry-run       Preview changes without applying them
    --verbose       Show detailed output during installation
    --help          Show this help message

Description:
    This script collects configuration information and orchestrates
    the installation of customizations across your Linux system.

    The installation process:
    1. Collects user configuration (username, email, company)
    2. Applies generic Linux customizations
    3. Applies Ubuntu-specific customizations (if on Ubuntu)

    In dry-run mode, all files are copied to .target/ directory
    for review before actual installation.

Examples:
    # Normal installation
    ./install.sh

    # Preview changes without applying
    ./install.sh --dry-run

    # Verbose output for troubleshooting
    ./install.sh --verbose

For more information, see README.md
EOF
}

#
# Function: parse_arguments
# Description: Parse command line arguments
# Args: All script arguments ($@)
# Usage: parse_arguments "$@"
# Output (stdout): None
# Return code: 0 on success, exits on invalid arguments
#
parse_arguments() {
    while [[ $# -gt 0 ]]; do
        case $1 in
            --dry-run)
                export DRY_RUN=true
                log_info "Dry-run mode enabled"
                shift
                ;;
            --verbose)
                export VERBOSE=true
                log_info "Verbose mode enabled"
                shift
                ;;
            --help|-h)
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
}

#
# Function: check_requirements
# Description: Check system requirements before installation
# Args: None
# Usage: check_requirements
# Output (stdout): Requirement check results
# Return code: 0 on success, exits on failure
#
check_requirements() {
    log_info "Checking system requirements..."

    # Check bash version
    if [[ "${BASH_VERSINFO[0]}" -lt 4 ]]; then
        die "Bash 4.0 or higher required. Current: $BASH_VERSION"
    fi
    log_success "Bash version: $BASH_VERSION"

    # Check if running on Linux
    if [[ "$(uname -s)" != "Linux" ]]; then
        die "This script is designed for Linux systems"
    fi
    log_success "Running on Linux"

    # Check if Ubuntu (optional - some scripts may not run if not Ubuntu)
    if is_ubuntu; then
        local version
        version=$(get_ubuntu_version)
        log_success "Detected Ubuntu $version"
        CONFIG[UBUNTU_VERSION]="$version"
        CONFIG[IS_UBUNTU]="true"
    else
        log_warning "Not running on Ubuntu - Ubuntu-specific customizations will be skipped"
        CONFIG[UBUNTU_VERSION]=""
        CONFIG[IS_UBUNTU]="false"
    fi

    # Check for required commands
    local required_commands=("git" "bash")
    for cmd in "${required_commands[@]}"; do
        if ! command_exists "$cmd"; then
            die "Required command not found: $cmd"
        fi
    done
    log_success "Required commands found"
}

#
# Function: load_saved_config
# Description: Load previously saved configuration if it exists
# Args: None
# Usage: load_saved_config
# Output (stdout): None
# Return code: 0
#
load_saved_config() {
    if [[ -f "$CONFIG_FILE" ]]; then
        log_info "Loading saved configuration from $CONFIG_FILE"
        # shellcheck disable=SC1090
        source "$CONFIG_FILE"
        return 0
    fi
    return 1
}

#
# Function: save_config
# Description: Save configuration to file for future use
# Args: None
# Usage: save_config
# Output (stdout): None
# Return code: 0
#
save_config() {
    # Create config directory if it doesn't exist
    if [[ ! -d "$CONFIG_DIR" ]]; then
        log_info "Creating configuration directory: $CONFIG_DIR"
        mkdir -p "$CONFIG_DIR"
        chmod 700 "$CONFIG_DIR"  # Make it private to user
    fi

    log_info "Saving configuration to $CONFIG_FILE"

    cat > "$CONFIG_FILE" << EOF
# MyLiCuLa Configuration File
# Generated on $(date)
#
# Location: ~/.config/mylicula/mylicula.conf
#
# IMPORTANT: This file may contain secrets (GitHub tokens, API keys, etc.)
#            DO NOT commit this file to version control!
#            DO NOT share this file with others!
#
# To reconfigure: Delete this file and run ./install.sh again
# To edit manually: Edit this file directly with your text editor

# =============================================================================
# User Information
# =============================================================================

CONFIG[USERNAME]="${CONFIG[USERNAME]}"
CONFIG[EMAIL]="${CONFIG[EMAIL]}"
CONFIG[FULL_NAME]="${CONFIG[FULL_NAME]}"
CONFIG[COMPANY]="${CONFIG[COMPANY]}"
CONFIG[GITHUB_USER]="${CONFIG[GITHUB_USER]}"

# =============================================================================
# System Paths (auto-detected)
# =============================================================================

CONFIG[HOME]="${CONFIG[HOME]}"
CONFIG[SCRIPT_DIR]="${CONFIG[SCRIPT_DIR]}"

# =============================================================================
# System Information (auto-detected)
# =============================================================================

CONFIG[UBUNTU_VERSION]="${CONFIG[UBUNTU_VERSION]}"
CONFIG[IS_UBUNTU]="${CONFIG[IS_UBUNTU]}"

# =============================================================================
# Secrets (Future Use)
# =============================================================================
# IMPORTANT: Add your secrets below (uncomment and fill in)
#            These values will be used by scripts that need authentication

# GitHub Personal Access Token (for API access, private repos)
# Generate at: https://github.com/settings/tokens
# CONFIG[GITHUB_TOKEN]="ghp_xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx"

# Other API keys as needed
# CONFIG[SOME_API_KEY]="your_api_key_here"

EOF

    chmod 600 "$CONFIG_FILE"  # Make it readable only by owner
    log_success "Configuration saved (mode 600 - owner read/write only)"
}

#
# Function: collect_configuration
# Description: Interactively collect configuration from user
# Args: None
# Usage: collect_configuration
# Output (stdout): Prompts and collected values
# Return code: 0
#
collect_configuration() {
    echo ""
    log_info "=== Configuration Setup ==="
    echo ""

    # Try to load saved config
    local use_saved=false
    if load_saved_config && [[ -n "${CONFIG[USERNAME]:-}" ]]; then
        echo "Found saved configuration:"
        echo "  Username: ${CONFIG[USERNAME]}"
        echo "  Email:    ${CONFIG[EMAIL]}"
        echo "  Company:  ${CONFIG[COMPANY]}"
        echo ""
        if prompt_yes_no "Use saved configuration?" "y"; then
            use_saved=true
        fi
    fi

    if [[ "$use_saved" == "false" ]]; then
        # Collect user information
        echo ""
        log_info "Please provide your information for customization:"
        echo ""

        # Username (default to current user)
        CONFIG[USERNAME]=$(prompt_with_default "Username" "${USER}")

        # Email (try to get from git config)
        local default_email=""
        if command_exists git; then
            default_email=$(git config --global user.email 2>/dev/null || echo "")
        fi
        CONFIG[EMAIL]=$(prompt_with_default "Email address" "${default_email:-user@example.com}")

        # Full name (try to get from git config)
        local default_name=""
        if command_exists git; then
            default_name=$(git config --global user.name 2>/dev/null || echo "")
        fi
        CONFIG[FULL_NAME]=$(prompt_with_default "Full name" "${default_name:-$USER}")

        # Company/Organization
        CONFIG[COMPANY]=$(prompt_with_default "Company/Organization" "Personal")

        # GitHub username (optional)
        CONFIG[GITHUB_USER]=$(prompt_with_default "GitHub username (optional)" "${CONFIG[USERNAME]}")

        # Add derived configuration BEFORE saving
        CONFIG[HOME]="${HOME}"
        CONFIG[SCRIPT_DIR]="${SCRIPT_DIR}"

        # Save configuration for future use
        save_config
    fi

    # Ensure derived configuration is set even when loading saved config
    CONFIG[HOME]="${HOME}"
    CONFIG[SCRIPT_DIR]="${SCRIPT_DIR}"

    # Display collected configuration
    echo ""
    log_success "Configuration collected:"
    echo "  Username:  ${CONFIG[USERNAME]}"
    echo "  Email:     ${CONFIG[EMAIL]}"
    echo "  Full Name: ${CONFIG[FULL_NAME]}"
    echo "  Company:   ${CONFIG[COMPANY]}"
    echo "  GitHub:    ${CONFIG[GITHUB_USER]}"
    echo "  Home:      ${CONFIG[HOME]}"
    echo ""

    # Export for use by child scripts
    export MYLICULA_USERNAME="${CONFIG[USERNAME]}"
    export MYLICULA_EMAIL="${CONFIG[EMAIL]}"
    export MYLICULA_FULL_NAME="${CONFIG[FULL_NAME]}"
    export MYLICULA_COMPANY="${CONFIG[COMPANY]}"
    export MYLICULA_GITHUB_USER="${CONFIG[GITHUB_USER]}"
}

#
# Function: setup_dry_run
# Description: Setup .target directory for dry-run mode
# Args: None
# Usage: setup_dry_run
# Output (stdout): Setup messages
# Return code: 0
#
setup_dry_run() {
    if [[ "${DRY_RUN}" == "true" ]]; then
        local target_dir="${SCRIPT_DIR}/.target"

        log_info "Setting up dry-run environment in $target_dir"

        # Remove old .target if exists
        if [[ -d "$target_dir" ]]; then
            rm -rf "$target_dir"
        fi

        # Create .target directory structure
        mkdir -p "$target_dir/home/${CONFIG[USERNAME]}"
        mkdir -p "$target_dir/etc"
        mkdir -p "$target_dir/usr/local"

        log_success "Dry-run environment ready at $target_dir"
        log_warning "No actual changes will be made to your system"

        export TARGET_DIR="$target_dir"
    fi
}

#
# Function: run_linux_setup
# Description: Run generic Linux customizations
# Args: None
# Usage: run_linux_setup
# Output (stdout): Setup progress
# Return code: 0 on success
#
run_linux_setup() {
    local setup_script="${SCRIPT_DIR}/customize/linux_setup.sh"

    if [[ ! -f "$setup_script" ]]; then
        log_warning "Linux setup script not found: $setup_script"
        log_warning "Skipping generic Linux customizations"
        return 0
    fi

    log_info "Running generic Linux customizations..."
    bash "$setup_script"
    log_success "Linux customizations completed"
}

#
# Function: run_ubuntu_setup
# Description: Run Ubuntu-specific customizations
# Args: None
# Usage: run_ubuntu_setup
# Output (stdout): Setup progress
# Return code: 0 on success
#
run_ubuntu_setup() {
    # Skip if not Ubuntu
    if [[ "${CONFIG[IS_UBUNTU]}" != "true" ]]; then
        log_info "Not running Ubuntu - skipping Ubuntu-specific customizations"
        return 0
    fi

    local setup_script="${SCRIPT_DIR}/customize/ubuntu_setup.sh"

    if [[ ! -f "$setup_script" ]]; then
        log_warning "Ubuntu setup script not found: $setup_script"
        log_warning "Skipping Ubuntu-specific customizations"
        return 0
    fi

    log_info "Running Ubuntu-specific customizations..."
    bash "$setup_script"
    log_success "Ubuntu customizations completed"
}

#
# Function: show_completion_message
# Description: Show completion message with next steps
# Args: None
# Usage: show_completion_message
# Output (stdout): Completion message
# Return code: 0
#
show_completion_message() {
    echo ""
    echo "=========================================="
    log_success "MyLiCuLa Installation Complete!"
    echo "=========================================="
    echo ""

    if [[ "${DRY_RUN}" == "true" ]]; then
        log_info "Dry-run results available in: ${SCRIPT_DIR}/.target"
        echo ""
        echo "To review changes:"
        echo "  cd ${SCRIPT_DIR}/.target"
        echo "  find . -type f"
        echo ""
        echo "To apply changes, run without --dry-run:"
        echo "  ./install.sh"
    else
        echo "Next steps:"
        echo "  1. Log out and log back in for all changes to take effect"
        echo "  2. Or reload your shell configuration:"
        echo "     source ~/.bashrc"
        echo ""
        echo "Configuration saved to: $CONFIG_FILE"
    fi
    echo ""
}

#–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––
# Main installation flow
#–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––

main() {
    # Print banner
    echo ""
    echo "=========================================="
    echo "  MyLiCuLa - My Linux Custom Layer"
    echo "  Linux Customization Installer"
    echo "=========================================="
    echo ""

    # Parse command line arguments
    parse_arguments "$@"

    # Check system requirements
    check_requirements

    # Collect configuration from user
    collect_configuration

    # Setup dry-run environment if requested
    setup_dry_run

    # Confirm before proceeding
    echo ""
    if ! prompt_yes_no "Proceed with installation?" "y"; then
        log_info "Installation cancelled by user"
        exit 0
    fi
    echo ""

    # Run customization scripts
    log_info "=== Starting customization process ==="
    echo ""

    run_linux_setup
    echo ""

    run_ubuntu_setup
    echo ""

    # Show completion message
    show_completion_message
}

# Run main function with all arguments
main "$@"
