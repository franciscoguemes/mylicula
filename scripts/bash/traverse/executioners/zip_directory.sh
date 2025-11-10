#!/usr/bin/env bash
####################################################################################################
# Args           :
#                   $1  Path to the subdirectory to operate on.
# Usage          : ./zip_directory.sh /path/to/subdirectory
# Output stdout  : Log messages for successful operations and information messages.
# Output stderr  : Error messages for failed operations or missing dependencies.
# Return code    : 0 if successful, non-zero if any operation fails.
# Description    : Script to zip each subdirectory into a file with the same name as the subdirectory.
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
if [ ! -d "$dir" ]; then
    echo "Error: Directory $dir does not exist." >&2
    exit 1
fi

# Check if zip command is available
if ! command -v zip >/dev/null 2>&1; then
    echo "Error: zip command not found. Please install it using: nala install zip" >&2
    exit 1
fi

# Get the directory name and parent directory
dir_name=$(basename "$dir")
parent_dir=$(dirname "$dir")
zip_file="${dir_name}.zip"

# Check if zip file already exists
full_zip_path="$parent_dir/$zip_file"
if [ -f "$full_zip_path" ]; then
    echo "Warning: Zip file $full_zip_path already exists. It will be overwritten." >&2
fi

# Create the zip file
if (cd "$parent_dir" && zip -r "$zip_file" "$dir_name" >/dev/null 2>&1); then
    echo "Successfully created zip file: $full_zip_path" >&2
    exit 0
else
    echo "Error: Failed to create zip file $full_zip_path from directory $dir" >&2
    exit 1
fi
