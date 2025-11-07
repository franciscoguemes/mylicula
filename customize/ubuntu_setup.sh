#!/usr/bin/env bash
####################################################################################################
#Args           : None - This script does not accept command-line arguments.
#                 Uses environment variables from install.sh:
#                   MYLICULA_USERNAME - Username for customization
#                   MYLICULA_EMAIL - Email address
#                   MYLICULA_COMPANY - Company/organization name
#                   DRY_RUN - If "true", preview changes only
#                   VERBOSE - If "true", show detailed output
#Usage          :   ./customize/ubuntu_setup.sh
#                   Called by install.sh - not typically run directly.
#                   Can be run standalone to apply Ubuntu-specific customizations.
#Output stdout  :   Progress messages for each customization script executed.
#                   Configuration details when VERBOSE=true.
#                   Success/failure summary after all scripts complete.
#Output stderr  :   Error messages if customizations fail.
#Return code    :   0 on success, non-zero if any customization fails.
#Description	: Orchestrator for Ubuntu-specific customizations.
#                 Runs all customization scripts in the ubuntu/ subdirectory in a controlled sequence,
#                 including scripts in the non_standard_installations/ subdirectory.
#                 Executes main Ubuntu scripts first, then non-standard installations.
#                 All scripts run alphabetically. Sources common utilities from lib/common.sh if available.
#
#Author       	: Francisco Güemes
#Email         	: francisco@franciscoguemes.com
#See also	    : https://stackoverflow.com/questions/14008125/shell-script-common-template
#                 https://devhints.io/bash
#                 https://linuxhint.com/30_bash_script_examples/
#                 https://stackoverflow.com/questions/192249/how-do-i-parse-command-line-arguments-in-bash
#                 customize/linux_setup.sh
#                 install.sh
####################################################################################################

set -euo pipefail

#–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––
# Setup
#–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" &>/dev/null && pwd)"
BASE_DIR="$(dirname "$SCRIPT_DIR")"

# Source common utilities if available
if [[ -f "${BASE_DIR}/lib/common.sh" ]]; then
    # shellcheck disable=SC1091
    source "${BASE_DIR}/lib/common.sh"
else
    # Fallback log functions if common.sh not available
    log_info() { echo "[INFO] $*"; }
    log_success() { echo "[SUCCESS] $*"; }
    log_warning() { echo "[WARNING] $*"; }
    log_error() { echo "[ERROR] $*" >&2; }
fi

#–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––
# Configuration
#–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––

UBUNTU_SCRIPTS_DIR="${SCRIPT_DIR}/ubuntu"
UBUNTU_NONSTANDARD_DIR="${UBUNTU_SCRIPTS_DIR}/non_standard_installations"

#–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––
# Functions
#–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––

#
# Function: run_script
# Description: Run a customization script with error handling
# Args:
#   $1 - Script path to execute
# Usage: run_script "/path/to/script.sh"
# Output (stdout): Script execution output
# Output (stderr): Error messages
# Return code: 0 on success, 1 on failure
#
run_script() {
    local script=$1
    local script_name
    script_name="$(basename "$script")"

    log_info "Running: $script_name"

    if [[ ! -f "$script" ]]; then
        log_error "Script not found: $script"
        return 1
    fi

    if [[ ! -x "$script" ]]; then
        log_warning "Script not executable: $script_name (making executable)"
        chmod +x "$script"
    fi

    # Run the script
    if bash "$script"; then
        log_success "Completed: $script_name"
        return 0
    else
        local exit_code=$?
        log_error "Failed: $script_name (exit code: $exit_code)"
        return 1
    fi
}

#
# Function: run_ubuntu_main_scripts
# Description: Execute main scripts in ubuntu/ directory (not in subdirectories)
# Args: None
# Usage: run_ubuntu_main_scripts
# Output (stdout): Execution progress
# Return code: 0 if all scripts succeed, 1 if any fail
#
run_ubuntu_main_scripts() {
    if [[ ! -d "$UBUNTU_SCRIPTS_DIR" ]]; then
        log_warning "Ubuntu scripts directory not found: $UBUNTU_SCRIPTS_DIR"
        return 0
    fi

    # Count scripts (maxdepth 1 to exclude subdirectories)
    local script_count
    script_count=$(find "$UBUNTU_SCRIPTS_DIR" -maxdepth 1 -type f -name "*.sh" | wc -l)

    if [[ $script_count -eq 0 ]]; then
        log_info "No main Ubuntu customization scripts found"
        return 0
    fi

    log_info "Found $script_count main Ubuntu customization script(s)"
    echo ""

    # Track failures
    local failed_scripts=()

    # Run each script in alphabetical order
    while IFS= read -r -d '' script; do
        if ! run_script "$script"; then
            failed_scripts+=("$(basename "$script")")
        fi
        echo ""
    done < <(find "$UBUNTU_SCRIPTS_DIR" -maxdepth 1 -type f -name "*.sh" -print0 | sort -z)

    # Check results
    if [[ ${#failed_scripts[@]} -gt 0 ]]; then
        log_error "Some main Ubuntu customizations failed:"
        for script in "${failed_scripts[@]}"; do
            echo "  - $script"
        done
        return 1
    fi

    return 0
}

#
# Function: run_nonstandard_installations
# Description: Execute non-standard installation scripts
# Args: None
# Usage: run_nonstandard_installations
# Output (stdout): Execution progress
# Return code: 0 if all scripts succeed, 1 if any fail
#
run_nonstandard_installations() {
    if [[ ! -d "$UBUNTU_NONSTANDARD_DIR" ]]; then
        log_info "Non-standard installations directory not found, skipping"
        return 0
    fi

    # Count scripts
    local script_count
    script_count=$(find "$UBUNTU_NONSTANDARD_DIR" -type f -name "*.sh" | wc -l)

    if [[ $script_count -eq 0 ]]; then
        log_info "No non-standard installation scripts found"
        return 0
    fi

    log_info "Found $script_count non-standard installation script(s)"
    echo ""

    # Track failures
    local failed_scripts=()

    # Run each script in alphabetical order
    while IFS= read -r -d '' script; do
        if ! run_script "$script"; then
            failed_scripts+=("$(basename "$script")")
        fi
        echo ""
    done < <(find "$UBUNTU_NONSTANDARD_DIR" -type f -name "*.sh" -print0 | sort -z)

    # Check results
    if [[ ${#failed_scripts[@]} -gt 0 ]]; then
        log_error "Some non-standard installations failed:"
        for script in "${failed_scripts[@]}"; do
            echo "  - $script"
        done
        return 1
    fi

    return 0
}

#–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––
# Main
#–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––

main() {
    log_info "=== Ubuntu-Specific Customizations ==="
    echo ""

    # Show configuration
    if [[ "${VERBOSE:-false}" == "true" ]]; then
        log_info "Configuration:"
        echo "  Username: ${MYLICULA_USERNAME:-$USER}"
        echo "  Email: ${MYLICULA_EMAIL:-not set}"
        echo "  Company: ${MYLICULA_COMPANY:-not set}"
        echo "  Dry-run: ${DRY_RUN:-false}"
        echo ""
    fi

    # Track overall success
    local overall_success=true

    # Run main Ubuntu scripts
    log_info "--- Main Ubuntu Customizations ---"
    echo ""
    if ! run_ubuntu_main_scripts; then
        overall_success=false
    fi
    echo ""

    # Run non-standard installations
    log_info "--- Non-Standard Installations ---"
    echo ""
    if ! run_nonstandard_installations; then
        overall_success=false
    fi
    echo ""

    # Final status
    if [[ "$overall_success" == "true" ]]; then
        log_success "Ubuntu setup completed successfully"
        return 0
    else
        log_error "Ubuntu setup completed with errors"
        return 1
    fi
}

# Run main function
main "$@"
