#!/usr/bin/env bash
####################################################################################################
# Args           :
#                   $1  Path to the directory to be checked.
# Usage          : ./zulutrade_project.sh /path/to/subdirectory
# Output stdout  : No direct output on success (for use as a filter script).
# Output stderr  : Error messages if conditions are not met.
# Return code    : 0 if all conditions are met, 1 otherwise.
# Description	 : Checks if a directory meets specific conditions:
#                   - Is a git repository (contains .git directory).
#                   - Has a remote URL starting with "https://devtools.zulutrade.local" in .git/config.
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