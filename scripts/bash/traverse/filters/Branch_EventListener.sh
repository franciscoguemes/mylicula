#!/usr/bin/env bash
####################################################################################################
# Args           :
#                   $1  Path to the subdirectory to check.
# Usage          : ./Branch_EventListener.sh /path/to/subdirectory
# Output stdout  : None
# Output stderr  : Debug or error messages.
# Return code    : 0 if directory meets criteria, 1 otherwise.
# Description    : This script verifies the following for each subdirectory:
#                  - The directory is a Git repository (contains .git directory).
#                  - Contains a branch with name matching the configured prefix pattern.
#                  - Contains a specific target file (configurable).
#                  - Contains a Java file with specific annotation pattern (configurable).
#                  - Excludes files with main method (configurable).
#
#                  This is an example filter for Java Spring Boot projects that can be
#                  customized for your needs. Modify the constants below.
#
# Author         : Francisco Güemes
# Email          : francisco@franciscoguemes.com
####################################################################################################

#==================================================================================================
# Configuration Constants - Modify these for your use case
#==================================================================================================
# Branch prefix pattern to match (e.g., "feature/TICKET-123", "bugfix/", "release/")
BRANCH_PREFIX="feature/EXAMPLE-123"

# Target file to search for in the repository
TARGET_FILE="ReadinessController.java"

# Annotation pattern to search for in Java files
ANNOTATION_PATTERN="ApplicationReadyEvent.class"

# Set to true to exclude files containing main method
EXCLUDE_MAIN_METHOD=true
#==================================================================================================

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

# 2. Check for branch names matching the configured prefix
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


# 3. Check for target file in any subdirectory
if ! find "$dir" -type f -name "$TARGET_FILE" | grep -q '.'; then
    echo "Directory $dir does not contain $TARGET_FILE." >&2
    exit 1
fi

# 4. Check for annotation pattern in Java files
java_files_with_annotation=$(find "$dir" -type f -name "*.java" -exec grep -l "$ANNOTATION_PATTERN" {} +)
for file in $java_files_with_annotation; do
    # Optionally exclude files that contain a main method
    if [ "$EXCLUDE_MAIN_METHOD" = true ]; then
        if ! grep -q 'public static void main' "$file"; then
            exit 0  # Found a matching file, exit successfully
        fi
    else
        exit 0  # Found a matching file, exit successfully
    fi
done

echo "Directory $dir does not contain a Java file with '$ANNOTATION_PATTERN' matching the criteria." >&2
exit 1
