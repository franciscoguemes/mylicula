#!/usr/bin/env bash
####################################################################################################
# Args           :
#                   $1  Path to the subdirectory to check.
# Usage          : ./git_repository.sh /path/to/subdirectory
# Output stdout  : None
# Output stderr  : Debug or error messages.
# Return code    : 0 if directory meets filter criteria (does not meet security criteria), 1 otherwise.
# Description    : This script verifies if the supplied directory is a git repository:
#                  - The directory contains a subdirectory called `.git`
# Author         : Francisco Güemes
# Email          : francisco@franciscoguemes.com
####################################################################################################

# Check if directory path is provided
if [ -z "$1" ]; then
    echo "Error: No directory specified." >&2
    exit 1
fi

dir="$1"

# 1. Check if directory is a Git repository
if [ ! -d "$dir/.git" ]; then
    echo "Directory $dir is not a Git repository." >&2
    exit 1
fi