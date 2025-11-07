#!/usr/bin/env bash
#
# Script Name: install_gnome-terminal_functions.sh
# Description: Install terminal functions that allow setting titles in gnome-terminal windows
#
# Args: None
#
# Usage: ./install_gnome-terminal_functions.sh
#
# Output (stdout): Installation progress messages
# Output (stderr): Error messages if installation fails
# Return code: 0 on success, non-zero on failure
#
# Author: Francisco Güemes
# Email: francisco@franciscoguemes.com
#
# See also:
#   https://unix.stackexchange.com/questions/77277/how-to-append-multiple-lines-to-a-file

set -euo pipefail

# Source common functions if available
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" &>/dev/null && pwd)"
BASE_DIR="$(cd "$SCRIPT_DIR/../.." &>/dev/null && pwd)"

if [[ -f "${BASE_DIR}/lib/common.sh" ]]; then
    # shellcheck disable=SC1091
    source "${BASE_DIR}/lib/common.sh"
else
    log_info() { echo "[INFO] $*"; }
    log_success() { echo "[SUCCESS] $*"; }
    log_warning() { echo "[WARNING] $*"; }
fi

# Configuration
BASHRC_PATH="${HOME}/.bashrc"

# The function to add
FUNCTION_CONTENT='
####################################################################################################
# Description: The set-title function is used to name the gnome-terminal windows.
# Usage: set-title "Here goes your title"
####################################################################################################

set-title(){
  ORIG=$PS1
  TITLE="\e]2;$@\a"
  PS1=${ORIG}${TITLE}
}
'

main() {
    log_info "Installing gnome-terminal set-title function"

    # Check if bashrc exists
    if [[ ! -f "${BASHRC_PATH}" ]]; then
        log_warning "Creating ${BASHRC_PATH}"
        touch "${BASHRC_PATH}"
    fi

    # Check if function already exists (idempotent)
    if grep -q "set-title()" "${BASHRC_PATH}"; then
        log_info "set-title function already installed in ${BASHRC_PATH}"
        return 0
    fi

    # Add function to bashrc
    echo "${FUNCTION_CONTENT}" >> "${BASHRC_PATH}"

    log_success "Installed set-title function to ${BASHRC_PATH}"
    log_info "Reload your shell or run: source ~/.bashrc"
}

main "$@"

