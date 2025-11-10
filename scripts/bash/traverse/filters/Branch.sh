#!/usr/bin/env bash
####################################################################################################
# Args           :
#                   $1  Path to the directory to be checked.
# Usage          : ./Branch.sh /path/to/subdirectory
# Output stdout  : No direct output on success (for use as a filter script).
# Output stderr  : Error messages if conditions are not met.
# Return code    : 0 if all conditions are met, 1 otherwise.
# Description	 : Checks if a directory meets specific conditions:
#                   - Is a git repository (contains .git directory).
#                   - Contains a branch matching the configured prefix pattern.
#                   - Optionally contains a specific file in any subdirectory.
#
#                 This is an example filter that can be customized for your needs.
#                 Modify BRANCH_PREFIX and TARGET_FILE constants below.
#
# Author         : Francisco Güemes
# Email          : francisco@franciscoguemes.com
####################################################################################################

#==================================================================================================
# Configuration Constants - Modify these for your use case
#==================================================================================================
# Branch prefix pattern to match (e.g., "feature/TICKET-123", "bugfix/", "release/")
BRANCH_PREFIX="feature/EXAMPLE-123"

# Optional: Target file to search for in the repository
TARGET_FILE="SpecificController.java"

# Set to true to enable file search, false to disable
CHECK_TARGET_FILE=false
#==================================================================================================

# Check if directory is provided
if [ -z "$1" ]; then
    echo "Error: No directory specified." >&2
    exit 1
fi

dir="$1"

# Check if directory is a Git repository
if [ ! -d "$dir/.git" ]; then
    echo "Directory $dir is not a Git repository." >&2
    exit 1
fi

# Check for branches matching the configured prefix
branch_found=false
while read -r branch; do
    if [[ "$branch" =~ ^(feature/${BRANCH_PREFIX}|${BRANCH_PREFIX}) ]]; then
        branch_found=true
        break
    fi
done < <(git -C "$dir" branch --list --all | sed 's/.*origin\///')  # Strips "origin/" from branch names for remote branches

if [ "$branch_found" = false ]; then
    echo "Directory $dir does not have a branch starting with '${BRANCH_PREFIX}' or 'feature/${BRANCH_PREFIX}'." >&2
    exit 1
fi

# Optional: Check for target file in any subdirectory
if [ "$CHECK_TARGET_FILE" = true ]; then
    if ! find "$dir" -type f -name "$TARGET_FILE" | grep -q .; then
        echo "Directory $dir does not contain a $TARGET_FILE file." >&2
        exit 1
    fi
fi

# If all checks pass
exit 0
