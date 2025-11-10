#!/usr/bin/env bash
####################################################################################################
# Args           :
#                   $1  Path to the subdirectory to operate on.
# Usage          : ./fail.sh /path/to/subdirectory
# Output stdout  : Log messages for successful operations and information messages.
# Output stderr  : Error messages for failed Git operations or file edits.
# Return code    : 0 if successful, non-zero if any operation fails.
# Description	 : Script to fail on each sub-directory. This script is just for testing purposes.
# Author         : Francisco Güemes
# Email          : francisco@franciscoguemes.com
####################################################################################################

# Check if directory path is provided
if [ -z "$1" ]; then
    echo "Error: No directory specified." >&2
    exit 1
fi

# Variables
dir="$1"

echo "Error: Failed for directory $dir" >&2
exit 1

