#!/usr/bin/env bash
####################################################################################################
# Args           :
#                   $1  Path to the directory to be checked.
# Usage          : ./DB-1555.sh /path/to/subdirectory
# Output stdout  : No direct output on success (for use as a filter script).
# Output stderr  : Error messages if conditions are not met.
# Return code    : 0 if all conditions are met, 1 otherwise.
# Description	 : Checks if a directory meets specific conditions:
#                   - Is a git repository (contains .git directory).
#                   - Has a remote URL starting with "https://devtools.zulutrade.local" in .git/config.
#                   - Contains a branch starting with "DB-1555" or "feature/DB-1555".
#                   - Contains a "ReadinessController.java" file in any subdirectory.
# Author         : Francisco Güemes
# Email          : francisco@franciscoguemes.com
####################################################################################################

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

# Check remote URL in .git/config
remote_url=$(git -C "$dir" config --get remote.origin.url)
if [[ "$remote_url" != https://devtools.zulutrade.local* ]]; then
    echo "Directory $dir does not have a valid zulutrade remote URL." >&2
    exit 1
fi

# Check for branches starting with "DB-1555" or "feature/DB-1555"
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

# Check for ReadinessController.java in any subdirectory
if ! find "$dir" -type f -name "ReadinessController.java" | grep -q .; then
    echo "Directory $dir does not contain a ReadinessController.java file." >&2
    exit 1
fi

# If all checks pass
exit 0
