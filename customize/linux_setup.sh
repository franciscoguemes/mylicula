#!/usr/bin/env bash
####################################################################################################
#Args           : None - This script does not accept command-line arguments.
#                 Uses environment variables from install.sh:
#                   MYLICULA_USERNAME - Username for customization
#                   MYLICULA_EMAIL - Email address
#                   MYLICULA_COMPANY - Company/organization name
#                   DRY_RUN - If "true", preview changes only
#                   VERBOSE - If "true", show detailed output
#Usage          :   ./customize/linux_setup.sh
#                   Called by install.sh - not typically run directly.
#                   Can be run standalone to apply generic Linux customizations.
#Output stdout  :   Progress messages for each customization script executed.
#                   Configuration details when VERBOSE=true.
#                   Success/failure summary after all scripts complete.
#Output stderr  :   Error messages if customizations fail.
#Return code    :   0 on success, non-zero if any customization fails.
#Description	: Orchestrator for generic Linux customizations.
#                 Runs all customization scripts in the linux/ subdirectory in a controlled sequence.
#                 Executes scripts alphabetically and reports on success/failure.
#                 Sources common utilities from lib/common.sh if available.
#
#Author       	: Francisco Güemes
#Email         	: francisco@franciscoguemes.com
#See also	    : https://stackoverflow.com/questions/14008125/shell-script-common-template
#                 https://devhints.io/bash
#                 https://linuxhint.com/30_bash_script_examples/
#                 https://stackoverflow.com/questions/192249/how-do-i-parse-command-line-arguments-in-bash
#                 customize/ubuntu_setup.sh
#                 install.sh
####################################################################################################

set -euo pipefail

#–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––
# Setup
#–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" &>/dev/null && pwd)"

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

LINUX_SCRIPTS_DIR="${SCRIPT_DIR}/linux"

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
# Function: run_all_linux_scripts
# Description: Execute all scripts in the linux/ directory
# Args: None
# Usage: run_all_linux_scripts
# Output (stdout): Execution progress
# Return code: 0 if all scripts succeed, 1 if any fail
#
run_all_linux_scripts() {
    if [[ ! -d "$LINUX_SCRIPTS_DIR" ]]; then
        log_warning "Linux scripts directory not found: $LINUX_SCRIPTS_DIR"
        log_info "No generic Linux customizations to apply"
        return 0
    fi

    # Count scripts
    local script_count
    script_count=$(find "$LINUX_SCRIPTS_DIR" -maxdepth 1 -type f -name "*.sh" | wc -l)

    if [[ $script_count -eq 0 ]]; then
        log_info "No Linux customization scripts found"
        return 0
    fi

    log_info "Found $script_count Linux customization script(s)"
    echo ""

    # Track failures
    local failed_scripts=()

    # Run each script in alphabetical order
    while IFS= read -r -d '' script; do
        if ! run_script "$script"; then
            failed_scripts+=("$(basename "$script")")
        fi
        echo ""
    done < <(find "$LINUX_SCRIPTS_DIR" -maxdepth 1 -type f -name "*.sh" -print0 | sort -z)

    # Report results
    if [[ ${#failed_scripts[@]} -eq 0 ]]; then
        log_success "All Linux customizations completed successfully"
        return 0
    else
        log_error "Some Linux customizations failed:"
        for script in "${failed_scripts[@]}"; do
            echo "  - $script"
        done
        return 1
    fi
}

#–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––
# Main
#–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––

main() {
    log_info "=== Generic Linux Customizations ==="
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

    # Run all Linux customization scripts
    run_all_linux_scripts

    local exit_code=$?
    echo ""

    if [[ $exit_code -eq 0 ]]; then
        log_success "Linux setup completed"
    else
        log_error "Linux setup completed with errors"
    fi

    return $exit_code
}

# Run main function
main "$@"
