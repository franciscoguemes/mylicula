#!/usr/bin/env bash
####################################################################################################
# Args           :
#                   $1  First argument: Path to the first directory
#                   $2  Second argument: Path to the second directory
#                   -h, --help  Display usage information
# Usage          :   ./compare_dirs.sh /path/to/dir1 /path/to/dir2
#                   ./compare_dirs.sh -h
# Output stdout  :   Lists files that differ between the two directories
# Output stderr  :   Error messages if directories do not exist or if incorrect arguments are provided
# Return code    :   0 if the script runs successfully, non-zero if there are errors
# Description    :   This script compares two directories recursively to check if the files are identical
#                    by calculating their MD5 hash. It outputs the differing files or missing files in either directory.
#
# Author         : Francisco Güemes
# Email          : francisco@franciscoguemes.com
# See also       : https://stackoverflow.com/questions/14008125/shell-script-common-template
#                  https://devhints.io/bash
#                  https://linuxhint.com/30_bash_script_examples/
#                  https://stackoverflow.com/questions/192249/how-do-i-parse-command-line-arguments-in-bash
####################################################################################################

# Function to display help
show_help() {
    cat << EOF
Usage: $(basename "$0") DIRECTORY1 DIRECTORY2 [-h|--help]

Compare two directories recursively using MD5 hash.

OPTIONS:
    DIRECTORY1       Path to first directory
    DIRECTORY2       Path to second directory
    -h, --help       Display this help message

DESCRIPTION:
    This script recursively compares all files in two directories by:
    1. Calculating MD5 hash for each file
    2. Reporting files that differ
    3. Reporting files missing in either directory

REQUIREMENTS:
    - md5sum (for file hashing)
    - find (for recursive directory traversal)

EXAMPLES:
    $(basename "$0") /path/to/dir1 /path/to/dir2    # Compare two directories
    $(basename "$0") --help                          # Show this help

AUTHOR:
    Francisco Güemes <francisco@franciscoguemes.com>
EOF
}

# Parse arguments for help
if [ "$#" -eq 1 ]; then
    case "$1" in
        -h|--help)
            show_help
            exit 0
            ;;
    esac
fi

# Check if md5sum is installed
if ! command -v md5sum &> /dev/null; then
    echo "Error: md5sum is not installed. Please install coreutils:" >&2
    echo "  sudo nala install coreutils" >&2
    exit 1
fi

# Function to compare two files using their hash
compare_files() {
    local file1="$1"
    local file2="$2"

    # Calculate hash of the files
    local hash1
    local hash2
    hash1=$(md5sum "$file1" | awk '{ print $1 }')
    hash2=$(md5sum "$file2" | awk '{ print $1 }')

    # Compare the hashes
    if [[ "$hash1" != "$hash2" ]]; then
        echo "Files differ: $file1 and $file2"
    fi
}

# Function to compare directories recursively
compare_directories() {
    local dir1="$1"
    local dir2="$2"

    # Find all files in the first directory
    find "$dir1" -type f | while read -r file; do
        # Remove the directory prefix to get the relative path
        local relative_path="${file#$dir1/}"
        local file2="$dir2/$relative_path"

        # Check if the corresponding file exists in the second directory
        if [[ ! -e "$file2" ]]; then
            echo "File missing in $dir2: $file2"
        else
            # Compare the files
            compare_files "$file" "$file2"
        fi
    done

    # Find all files in the second directory to check for any extra files
    find "$dir2" -type f | while read -r file; do
        # Remove the directory prefix to get the relative path
        local relative_path="${file#$dir2/}"
        local file1="$dir1/$relative_path"

        # Check if the corresponding file exists in the first directory
        if [[ ! -e "$file1" ]]; then
            echo "File missing in $dir1: $file1"
        fi
    done
}

# Check if the correct number of arguments is provided
if [[ "$#" -ne 2 ]]; then
    echo "Error: Exactly two directory arguments are required" >&2
    show_help
    exit 1
fi

# Function to normalize directory path
normalize_dir() {
    local dir="$1"
    # Remove trailing slash if exists
    echo "${dir%/}"
}

# Get the input directories and normalize them
dir1=$(normalize_dir "$1")
dir2=$(normalize_dir "$2")

# Check if the input directories exist
if [[ ! -d "$dir1" ]]; then
    echo "Error: Directory $dir1 does not exist." >&2
    exit 1
fi

if [[ ! -d "$dir2" ]]; then
    echo "Error: Directory $dir2 does not exist." >&2
    exit 1
fi

# Compare the directories
compare_directories "$dir1" "$dir2"
