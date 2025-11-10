#!/usr/bin/env bash
####################################################################################################
# Args           :
#                   $1  Path to the subdirectory to check.
# Usage          : ./filter.sh /path/to/subdirectory
# Output stdout  : None
# Output stderr  : Debug or error messages.
# Return code    : 0 if directory meets criteria, 1 otherwise.
# Description    : This script verifies the following for each subdirectory:
#                  - The directory is a Git repository (contains .git directory).
#                  - The directory is a zulutrade project (remote URL starts with https://devtools.zulutrade.local).
#                  - Contains a branch with name starting with DB-1555 or feature/DB-1555.
#                  - Contains a file named ReadinessController.java.
#                  - Contains a Java file with @EventListener(ApplicationReadyEvent.class) but excludes files with main method.
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

# 2. Check if it's a zulutrade project
remote_url=$(git -C "$dir" config --get remote.origin.url)
if [[ "$remote_url" != https://devtools.zulutrade.local* ]]; then
    echo "Directory $dir is not a zulutrade project." >&2
    exit 1
fi

# 3. Check for branch names starting with DB-1555 or feature/DB-1555
branch_found=false
while read -r branch; do
    if [[ "$branch" =~ ^(feature/DB-1555|DB-1555) ]]; then
        branch_found=true
        break
    fi
done < <(git -C "$dir" branch --list --all | sed 's/.*origin\///')  # Strips "origin/" from branch names for remote branches

if [ "$branch_found" = false ]; then
    echo "Directory $dir does not have a branch starting with 'DB-1555' or 'feature/DB-1555'." >&2
    exit 1
fi


# 4. Check for ReadinessController.java file in any subdirectory
if ! find "$dir" -type f -name "ReadinessController.java" | grep -q '.'; then
    echo "Directory $dir does not contain ReadinessController.java." >&2
    exit 1
fi

# 5. Check for @EventListener(ApplicationReadyEvent.class) in Java files excluding those with main method
java_files_with_event=$(find "$dir" -type f -name "*.java" -exec grep -l 'ApplicationReadyEvent.class' {} +)
for file in $java_files_with_event; do
    # Exclude files that contain a main method
    if ! grep -q 'public static void main' "$file"; then
        exit 0  # Found a matching file, exit successfully
    fi
done

echo "Directory $dir does not contain a Java file with @EventListener(ApplicationReadyEvent.class) excluding main method files." >&2
exit 1
