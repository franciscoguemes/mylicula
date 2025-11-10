#!/usr/bin/env bash
####################################################################################################
# Args           :
#                   $1  Path to the subdirectory to operate on.
# Usage          : ./executable_script.sh /path/to/subdirectory
# Output stdout  : Log messages for successful operations and information messages.
# Output stderr  : Error messages for failed Git operations or file edits.
# Return code    : 0 if successful, non-zero if any operation fails.
# Description	 : Script to operate on each repository, switching to master, pulling updates, creating
#                   a new branch, modifying files, committing, and pushing changes to create a GitLab MR.
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

# Ensure the directory exists
if [ ! -d "$dir/.git" ]; then
    echo "Error: Directory $dir is not a Git repository." >&2
    exit 1
fi

# 1. Switch to the master branch
if ! git -C "$dir" checkout master; then
    echo "Error: Failed to switch to master branch in $dir due to uncommitted changes or other issue." >&2
    exit 1
fi

# 2. Pull latest changes from master
if ! git -C "$dir" pull origin master; then
    echo "Error: Failed to pull latest changes from master in $dir" >&2
    exit 1
fi

