#!/bin/bash
#
# Script Name: install_postgresql.sh
# Description: Install PostgreSQL database from official PostgreSQL repository
#              This provides newer versions than Ubuntu's default packages
#
# Args: None
#
# Usage: ./install_postgresql.sh
#
# Output (stdout): Installation progress messages
# Output (stderr): Error messages if installation fails
# Return code: 0 on success, non-zero on failure
#
# Author: Francisco Güemes
# Email: francisco@franciscoguemes.com
#
# See also:
#   https://www.postgresql.org/download/linux/ubuntu/
#   https://docs.docker.com/engine/install/ubuntu/#installation-methods
#
# Note: This script should run after the install_packages script
#       Requires sudo privileges

set -euo pipefail

# Source common functions if available
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" &>/dev/null && pwd)"
BASE_DIR="$(cd "$SCRIPT_DIR/../../.." &>/dev/null && pwd)"

if [[ -f "${BASE_DIR}/lib/common.sh" ]]; then
    # shellcheck disable=SC1091
    source "${BASE_DIR}/lib/common.sh"
else
    log_info() { echo "[INFO] $*"; }
    log_success() { echo "[SUCCESS] $*"; }
    log_error() { echo "[ERROR] $*" >&2; }
    die() { log_error "$1"; exit "${2:-1}"; }
fi

#–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––
# Main installation
#–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––

main() {
    log_info "Installing PostgreSQL from official repository"

    # Check if already installed
    if command -v psql &>/dev/null; then
        local version
        version=$(psql --version | awk '{print $3}')
        log_info "PostgreSQL is already installed (version: $version)"

        if [[ "${DRY_RUN:-false}" == "true" ]]; then
            log_info "Dry-run mode: Would skip installation"
            return 0
        fi

        read -p "Reinstall PostgreSQL? [y/N]: " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            log_info "Skipping PostgreSQL installation"
            return 0
        fi
    fi

    if [[ "${DRY_RUN:-false}" == "true" ]]; then
        log_info "Dry-run mode: Would install PostgreSQL"
        log_info "  1. Add PostgreSQL repository"
        log_info "  2. Import signing key"
        log_info "  3. Update package lists"
        log_info "  4. Install postgresql package"
        return 0
    fi

    # Create the file repository configuration
    log_info "Adding PostgreSQL repository..."
    sudo sh -c 'echo "deb http://apt.postgresql.org/pub/repos/apt $(lsb_release -cs)-pgdg main" > /etc/apt/sources.list.d/pgdg.list'

    # Import the repository signing key
    log_info "Importing repository signing key..."
    wget --quiet -O - https://www.postgresql.org/media/keys/ACCC4CF8.asc | sudo apt-key add -

    # Update the package lists
    log_info "Updating package lists..."
    sudo apt-get update

    # Install the latest version of PostgreSQL
    # Note: Use 'postgresql-14' or similar for a specific version
    log_info "Installing PostgreSQL..."
    sudo apt-get -y install postgresql

    log_success "PostgreSQL installation complete"

    # Show status
    log_info "PostgreSQL cluster status:"
    sudo pg_lsclusters || true
}

main "$@"
