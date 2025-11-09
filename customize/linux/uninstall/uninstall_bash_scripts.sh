#!/usr/bin/env bash
####################################################################################################
# Args           :
#                   None
# Usage          :   sudo ./uninstall_bash_scripts.sh
# Output stdout  :   Messages indicating the uninstallation status of bash scripts.
# Output stderr  :   Error messages if uninstallation fails.
# Return code    :   0 on success, 1 on failure.
# Description    :   This script uninstalls all bash scripts by removing symbolic links from /usr/local/bin
#                   that correspond to scripts in the scripts/bash directory.
# Author         :   Francisco Güemes
# Email          :   francisco@franciscoguemes.com
# See also       :   https://stackoverflow.com/questions/14008125/shell-script-common-template
#                   https://devhints.io/bash
#                   https://linuxhint.com/30_bash_script_examples/
#                   https://stackoverflow.com/questions/192249/how-do-i-parse-command-line-arguments-in-bash
####################################################################################################

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Find BASE_DIR - Priority 1: env var, Priority 2: search for lib/common.sh
if [[ -n "${MYLICULA_BASE_DIR:-}" ]]; then
    BASE_DIR="$MYLICULA_BASE_DIR"
else
    # Search upwards for lib/common.sh (max 4 levels for uninstall/ subdirectory)
    BASE_DIR="$SCRIPT_DIR"
    for i in {1..4}; do
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

# Source common library for color output
source "${BASE_DIR}/lib/common.sh"

# Define the source directory for bash scripts
BASH_DIR="$BASE_DIR/scripts/bash"

# Define the target directory for symbolic links
TARGET_DIR="/usr/local/bin"

# Check if source directory exists
if [ ! -d "$BASH_DIR" ]; then
    echo "${COLOR_RED}[ERROR]${COLOR_RESET} Source directory does not exist: $BASH_DIR"
    exit 1
fi

# Function to uninstall scripts from a specific directory
uninstall_scripts() {
    local dir="$1"
    local removed_count=0
    local skipped_count=0
    local error_count=0

    echo "${COLOR_BLUE}[INFO]${COLOR_RESET} Uninstalling bash scripts from: $dir"

    # Iterate over all files in the source directory
    for script in "$dir"/*; do
        # Check if it's a regular file
        if [ -f "$script" ]; then
            # Get the basename of the script (e.g., "myscript.sh" from "/path/to/scripts/myscript.sh")
            script_name=$(basename "$script")

            # Define the target link path
            target_link="$TARGET_DIR/$script_name"

            # Check if the target link exists and is a symbolic link
            if [ -L "$target_link" ]; then
                # Check if the symlink points to our script
                link_target=$(readlink -f "$target_link" 2>/dev/null)
                script_path=$(readlink -f "$script" 2>/dev/null)

                if [ "$link_target" = "$script_path" ]; then
                    # Remove the symbolic link
                    if rm "$target_link" 2>/dev/null; then
                        echo "${COLOR_GREEN}[SUCCESS]${COLOR_RESET} Removed symbolic link: $target_link"
                        ((removed_count++))
                    else
                        echo "${COLOR_RED}[ERROR]${COLOR_RESET} Failed to remove symbolic link: $target_link"
                        ((error_count++))
                    fi
                else
                    echo "${COLOR_YELLOW}[SKIP]${COLOR_RESET} Link $target_link points to different location. Skipping."
                    ((skipped_count++))
                fi
            elif [ -e "$target_link" ]; then
                echo "${COLOR_YELLOW}[SKIP]${COLOR_RESET} $target_link exists but is not a symbolic link. Skipping."
                ((skipped_count++))
            else
                echo "${COLOR_YELLOW}[SKIP]${COLOR_RESET} Link $target_link does not exist. Already removed."
                ((skipped_count++))
            fi
        fi
    done

    echo ""
    echo "${COLOR_GREEN}[SUMMARY]${COLOR_RESET} Removed: $removed_count | Skipped: $skipped_count | Errors: $error_count"
    return $error_count
}

# Uninstall scripts from bash directory
uninstall_scripts "$BASH_DIR"
result=$?

if [ $result -eq 0 ]; then
    echo "${COLOR_GREEN}[SUCCESS]${COLOR_RESET} Bash scripts uninstalled successfully."
    exit 0
else
    echo "${COLOR_YELLOW}[WARNING]${COLOR_RESET} Uninstallation completed with $result errors."
    exit 1
fi
