#!/usr/bin/env bash
####################################################################################################
# Args           :
#                   $1  Path to the subdirectory to check.
# Usage          : ./committed_changes.sh /path/to/subdirectory
# Output stdout  : None
# Output stderr  : Debug or error messages.
# Return code    : 0 if directory meets filter criteria (no pending changes and aligned with remote), 1 otherwise.
# Description    : This script verifies if the supplied git repository is in a clean state:
#                  - Has no pending changes to commit (working directory clean)
#                  - Current branch is aligned with remote branch (no commits ahead or behind)
# Author         : Francisco Güemes
# Email          : francisco@franciscoguemes.com
# See also       : https://stackoverflow.com/questions/14008125/shell-script-common-template
#                  https://devhints.io/bash
#                  https://linuxhint.com/30_bash_script_examples/
#                  https://stackoverflow.com/questions/192249/how-do-i-parse-command-line-arguments-in-bash
####################################################################################################

# Check if directory path is provided
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

# Check if git command is available
if ! command -v git >/dev/null 2>&1; then
    echo "Error: git command is not installed. Install it using: nala install git" >&2
    exit 1
fi

# 1. Check if there are pending changes to commit
if ! git -C "$dir" diff-index --quiet HEAD --; then
    echo "Directory $dir has pending changes to commit." >&2
    exit 1
fi

# Check if there are untracked files that should be added
if [ -n "$(git -C "$dir" ls-files --others --exclude-standard)" ]; then
    echo "Directory $dir has untracked files." >&2
    exit 1
fi

# 2. Check if current branch is aligned with remote branch
# Get current branch name
current_branch=$(git -C "$dir" branch --show-current)
if [ -z "$current_branch" ]; then
    echo "Directory $dir is in detached HEAD state." >&2
    exit 1
fi

# Check if remote branch exists
if ! git -C "$dir" rev-parse --verify "origin/$current_branch" >/dev/null 2>&1; then
    echo "Directory $dir has no remote branch 'origin/$current_branch'." >&2
    exit 1
fi

# Check if local branch is ahead of remote
ahead=$(git -C "$dir" rev-list --count "origin/$current_branch..HEAD" 2>/dev/null)
if [ "$ahead" -gt 0 ]; then
    echo "Directory $dir is $ahead commits ahead of origin/$current_branch." >&2
    exit 1
fi

# Check if local branch is behind remote
behind=$(git -C "$dir" rev-list --count "HEAD..origin/$current_branch" 2>/dev/null)
if [ "$behind" -gt 0 ]; then
    echo "Directory $dir is $behind commits behind origin/$current_branch." >&2
    exit 1
fi

# If we reach here, the repository is clean and aligned
exit 0
