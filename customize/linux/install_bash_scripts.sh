#!/usr/bin/env bash
####################################################################################################
#Args           : None
#Usage          : sudo ./install_bash_scripts.sh (from any directory)
#Output stdout  : Success messages indicating the files that have been linked.
#Output stderr  : Error messages if any issues occur during permission setting or symlink creation.
#Return code    : 0   Success
#                 1   Failure (e.g., cannot set permissions, cannot create symlinks)
#Description	: This script gives execution permissions to bash scripts in 'scripts/bash'
#                 and creates symlinks to them in '/usr/local/bin'.
#
#Author       	: Francisco Güemes
#Email         	: francisco@franciscoguemes.com
#See also	    : https://stackoverflow.com/questions/14008125/shell-script-common-template
#                 https://devhints.io/bash
####################################################################################################

# Ensure the script runs from the correct location regardless of where it's executed
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BASE_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"

# Source common library for create_symlink function
source "${BASE_DIR}/lib/common.sh"

# Directory where the scripts to be installed are located
BASH_DIR="$BASE_DIR/scripts/bash"

# Destination directory for symlinks
BIN_DIR="/usr/local/bin"

# Check if source directory exists
if [ ! -d "$BASH_DIR" ]; then
    echo "${COLOR_RED}[ERROR]${COLOR_RESET} Source directory does not exist: $BASH_DIR"
    exit 1
fi

# Function to process files in a given directory
process_files() {
    local dir="$1"
    local processed_count=0
    local skipped_count=0
    local error_count=0

    echo "${COLOR_BLUE}[INFO]${COLOR_RESET} Installing bash scripts from: $dir"

    # Iterate over each file in the specified directory
    for file in "$dir"/*; do
        # Ensure it's a regular file (not a directory)
        if [ -f "$file" ]; then
            filename=$(basename "$file")

            # Check if the file has execute permission, if not add it
            if [ ! -x "$file" ]; then
                echo "${COLOR_YELLOW}[INFO]${COLOR_RESET} Setting execute permissions for $filename"
                chmod +x "$file" || {
                    echo "${COLOR_RED}[ERROR]${COLOR_RESET} Failed to set execute permissions for $filename"
                    ((error_count++))
                    continue
                }
            fi

            # Create a symlink in /usr/local/bin using the robust create_symlink function
            link_path="$BIN_DIR/$filename"

            if create_symlink "$file" "$link_path" true; then
                ((processed_count++))
            else
                ((error_count++))
            fi
        fi
    done

    echo ""
    echo "${COLOR_GREEN}[SUMMARY]${COLOR_RESET} Processed: $processed_count | Errors: $error_count"
}

# Run the process for bash scripts directory
process_files "$BASH_DIR"

if [ $error_count -eq 0 ]; then
    echo "${COLOR_GREEN}[SUCCESS]${COLOR_RESET} Installation completed successfully."
    exit 0
else
    echo "${COLOR_YELLOW}[WARNING]${COLOR_RESET} Installation completed with $error_count errors."
    exit 1
fi
