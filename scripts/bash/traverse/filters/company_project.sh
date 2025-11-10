#!/usr/bin/env bash
####################################################################################################
# Args           :
#                   $1  Path to the directory to be checked.
# Usage          : ./company_project.sh /path/to/subdirectory
# Output stdout  : No direct output on success (for use as a filter script).
# Output stderr  : Error messages if conditions are not met.
# Return code    : 0 if all conditions are met, 1 otherwise.
# Description	 : Checks if a directory meets specific conditions:
#                   - Is a git repository (contains .git directory).
#                   - Has a remote URL matching the configured company URL pattern in .git/config.
#
#                 This is an example filter that can be customized for your needs.
#                 Modify COMPANY_URL constant below to match your company's Git server.
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

COMPANY_URL=https://devtools.company.local*

# Check remote URL in .git/config
remote_url=$(git -C "$dir" config --get remote.origin.url)
if [[ "$remote_url" != "$COMPANY_URL" ]]; then
    echo "Directory $dir does not have a valid remote URL." >&2
    exit 1
fi