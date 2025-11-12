#!/usr/bin/env bash
####################################################################################################
# MyLiCuLa Bootstrap Installer
#
# Description: Lightweight bootstrap script that downloads MyLiCuLa from GitHub and runs installation.
#              This script can be executed directly via curl/wget without cloning the repository first.
#
# Usage:
#   Quick install (review recommended):
#     curl -fsSL https://raw.githubusercontent.com/franciscoguemes/mylicula/main/bootstrap.sh | bash
#
#   Download and review before running (recommended):
#     curl -fsSL https://raw.githubusercontent.com/franciscoguemes/mylicula/main/bootstrap.sh -o bootstrap.sh
#     less bootstrap.sh  # Review the script
#     bash bootstrap.sh
#
#   With custom installation directory:
#     curl -fsSL https://raw.githubusercontent.com/franciscoguemes/mylicula/main/bootstrap.sh | MYLICULA_DIR=~/custom/path bash
#
# Environment Variables:
#   MYLICULA_DIR       - Installation directory (default: $HOME/mylicula)
#   MYLICULA_BRANCH    - Git branch to use (default: main)
#   MYLICULA_KEEP_REPO - Keep repository after install (default: true)
#
# Author: Francisco Güemes
# Email: francisco@franciscoguemes.com
# Repository: https://github.com/franciscoguemes/mylicula
####################################################################################################

set -euo pipefail

# Colors for output
readonly COLOR_RED='\033[0;31m'
readonly COLOR_GREEN='\033[0;32m'
readonly COLOR_YELLOW='\033[1;33m'
readonly COLOR_BLUE='\033[0;34m'
readonly COLOR_RESET='\033[0m'

# Configuration
readonly REPO_URL="https://github.com/franciscoguemes/mylicula.git"
readonly DEFAULT_INSTALL_DIR="${HOME}/git/${USER}/github/mylicula"
#readonly DEFAULT_INSTALL_DIR="/tmp/git/${USER}/github/mylicula"
readonly DEFAULT_BRANCH="main"

# User-configurable via environment variables
INSTALL_DIR="${MYLICULA_DIR:-$DEFAULT_INSTALL_DIR}"
BRANCH="${MYLICULA_BRANCH:-$DEFAULT_BRANCH}"
KEEP_REPO="${MYLICULA_KEEP_REPO:-true}"

#==================================================================================================
# Output Functions
#==================================================================================================

info() {
    echo -e "${COLOR_BLUE}[INFO]${COLOR_RESET} $*"
}

success() {
    echo -e "${COLOR_GREEN}[SUCCESS]${COLOR_RESET} $*"
}

warning() {
    echo -e "${COLOR_YELLOW}[WARNING]${COLOR_RESET} $*"
}

error() {
    echo -e "${COLOR_RED}[ERROR]${COLOR_RESET} $*" >&2
}

#==================================================================================================
# Utility Functions
#==================================================================================================

command_exists() {
    command -v "$1" &> /dev/null
}

install_nala() {
    info "Installing nala with apt..."
    if sudo apt update && sudo apt install -y nala; then
        success "nala installed successfully"
        return 0
    else
        error "Failed to install nala"
        return 1
    fi
}

prompt_yes_no() {
    local prompt="$1"
    local response

    while true; do
        read -p "${prompt} [y/N] " -n 1 -r response
        echo
        case "$response" in
            [Yy]) return 0 ;;
            [Nn]|"") return 1 ;;
            *) warning "Please answer 'y' or 'n'" ;;
        esac
    done
}

check_and_install_nala() {
    if command_exists nala; then
        success "nala is installed"
        return 0
    fi

    warning "nala is not installed (recommended package manager)"
    echo ""

    if prompt_yes_no "Would you like to install nala now?"; then
        if install_nala; then
            return 0
        else
            error "Failed to install nala. Please install it manually."
            return 1
        fi
    else
        info "To install nala manually:"
        info "  sudo apt update"
        info "  sudo apt install nala"
        echo ""
        error "Nala is not ppresent in the system. Please install it manually."
        return 1
    fi
}

check_and_install_bash() {
    if [ "${BASH_VERSINFO[0]}" -ge 4 ]; then
        success "Bash version: ${BASH_VERSION}"
        return 0
    fi

    error "Bash 4.0+ required. Current version: ${BASH_VERSION}"
    echo ""

    if prompt_yes_no "Would you like to upgrade Bash now?"; then
        info "Upgrading Bash with nala..."
        if sudo nala update && sudo nala install -y bash; then
            success "Bash upgraded successfully"
            warning "Please restart this script to use the new Bash version"
            exit 0
        else
            error "Failed to upgrade Bash"
            return 1
        fi
    else
        info "To upgrade Bash manually:"
        info "  sudo nala update"
        info "  sudo nala install bash"
        echo ""
        error "Cannot continue without Bash 4.0+"
        return 1
    fi
}

check_and_install_git() {
    if command_exists git; then
        success "Git found: $(git --version | head -1)"
        return 0
    fi

    error "Git is not installed"
    echo ""

    if prompt_yes_no "Would you like to install Git now?"; then
        info "Installing Git with nala..."
        if sudo nala update && sudo nala install -y git; then
            success "Git installed successfully"
            return 0
        else
            error "Failed to install Git"
            return 1
        fi
    else
        info "To install Git manually:"
        info "  sudo nala update"
        info "  sudo nala install git"
        echo ""
        error "Cannot continue without Git"
        return 1
    fi
}

check_botstrap_prerequisites() {
    info "Checking prerequisites..."
    echo ""

    # Step 1: Check and optionally install nala
    if ! check_and_install_nala; then
        return 1
    fi
    echo ""

    # Step 2: Check and optionally install/upgrade bash
    if ! check_and_install_bash; then
        return 1
    fi
    echo ""

    # Step 3: Check and optionally install git
    if ! check_and_install_git; then
        return 1
    fi

    return 0
}

clone_repository() {
    local repo_url="$1"
    local target_dir="$2"
    local branch="$3"

    info "Cloning MyLiCuLa repository..."
    info "  Repository: ${repo_url}"
    info "  Branch: ${branch}"
    info "  Target: ${target_dir}"

    if [ -d "${target_dir}" ]; then
        warning "Directory already exists: ${target_dir}"
        read -p "Remove and re-clone? [y/N] " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            info "Removing existing directory..."
            rm -rf "${target_dir}"
        else
            error "Installation cancelled by user"
            return 1
        fi
    fi

    # Clone the repository
    if ! git clone --branch "${branch}" --depth 1 "${repo_url}" "${target_dir}"; then
        error "Failed to clone repository"
        return 1
    fi

    success "Repository cloned successfully"
    return 0
}

run_installation() {
    local install_dir="$1"
    local install_script="${install_dir}/install.sh"

    if [ ! -f "${install_script}" ]; then
        error "Installation script not found: ${install_script}"
        return 1
    fi

    if [ ! -x "${install_script}" ]; then
        info "Making installation script executable..."
        chmod +x "${install_script}"
    fi

    info "Running MyLiCuLa installation..."
    echo ""
    echo "════════════════════════════════════════════════════════════════════════════════"
    echo "                        Starting MyLiCuLa Installation"
    echo "════════════════════════════════════════════════════════════════════════════════"
    echo ""

    # Change to installation directory and run install.sh
    cd "${install_dir}"
    bash "${install_script}"

    local exit_code=$?

    echo ""
    echo "════════════════════════════════════════════════════════════════════════════════"

    if [ $exit_code -eq 0 ]; then
        success "MyLiCuLa installation completed successfully!"
    else
        error "Installation failed with exit code: ${exit_code}"
        return $exit_code
    fi

    return 0
}

cleanup_repository() {
    local install_dir="$1"

    if [ "${KEEP_REPO}" = "false" ]; then
        info "Cleaning up repository..."
        rm -rf "${install_dir}"
        success "Repository removed"
    else
        info "Repository kept at: ${install_dir}"
        info "To remove it later, run: rm -rf ${install_dir}"
    fi
}

show_banner() {
    echo ""
    echo "╔════════════════════════════════════════════════════════════════════════════════╗"
    echo "║                                                                                ║"
    echo "║                         MyLiCuLa Bootstrap Installer                           ║"
    echo "║                     My Linux Custom Layer for Ubuntu                           ║"
    echo "║                                                                                ║"
    echo "╚════════════════════════════════════════════════════════════════════════════════╝"
    echo ""
    info "Repository: https://github.com/franciscoguemes/mylicula"
    info "Author: Francisco Güemes"
    echo ""
}

show_configuration() {
    info "Installation Configuration:"
    echo "  Installation Directory: ${INSTALL_DIR}"
    echo "  Branch: ${BRANCH}"
    echo "  Keep Repository: ${KEEP_REPO}"
    echo ""
}

#==================================================================================================
# Main Installation Flow
#==================================================================================================

main() {
    show_banner
    show_configuration

    # Step 1: Check prerequisites
    if ! check_botstrap_prerequisites; then
        error "Prerequisites check failed"
        exit 1
    fi

    echo ""

    # Step 2: Clone repository
    if ! clone_repository "${REPO_URL}" "${INSTALL_DIR}" "${BRANCH}"; then
        error "Failed to clone repository"
        exit 1
    fi

    echo ""

    # Step 3: Run installation
    if ! run_installation "${INSTALL_DIR}"; then
        error "Installation failed"
        exit 1
    fi

    echo ""

    # Step 4: Cleanup (if requested)
    cleanup_repository "${INSTALL_DIR}"

    echo ""
    success "Bootstrap installation complete!"
    echo ""
    echo "Next steps:"
    echo "  - Review installed customizations"
    echo "  - Restart your terminal to apply changes"
    if [ "${KEEP_REPO}" = "true" ]; then
        echo "  - Repository location: ${INSTALL_DIR}"
    fi
    echo ""
}

# Run main installation
main "$@"
