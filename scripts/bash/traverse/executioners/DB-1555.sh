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
branch_name="DB-1555__Improvements"
commit_message="DB-1555: De-clutter logs by removing unnecessary logging statements"
mr_target_branch="staging"
mr_title="DB-1555: Improvements in readiness probe"
mr_description="Improvements for the readiness probe in Kubernetes"
mr_assignee="gkranas"

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

# 3. Create new branch if it doesn't already exist
if git -C "$dir" branch --list | grep -q "$branch_name"; then
    echo "Error: Branch $branch_name already exists in $dir" >&2
    exit 1
fi
git -C "$dir" checkout -b "$branch_name"

# 4. Search and modify ReadinessController.java
readiness_file=$(find "$dir" -type f -name "ReadinessController.java")
if [ -z "$readiness_file" ]; then
    echo "Info: No ReadinessController.java file found in $dir" >&2
    exit 1
fi
if ! grep -q 'log\.debug\|log\.info' "$readiness_file"; then
    echo "Info: No log.debug or log.info statements found in $readiness_file" >&2
    exit 1
fi
sed -i '/log\.debug/d; /log\.info/d' "$readiness_file"

# 5. Commit changes
if ! git -C "$dir" add "$readiness_file"; then
    echo "Error: Failed to stage changes for $readiness_file in $dir" >&2
    exit 1
fi
if ! git -C "$dir" commit -m "$commit_message"; then
    echo "Error: Failed to commit changes in $dir" >&2
    exit 1
fi

# 6. Push the new branch to origin with MR options
if ! git -C "$dir" push -u origin "$branch_name" \
        -o merge_request.create \
        -o merge_request.target="$mr_target_branch" \
        -o merge_request.title="$mr_title" \
        -o merge_request.description="$mr_description" \
        -o merge_request.assign="$mr_assignee" \
        -o merge_request.squash; then
    echo "Error: Failed to push branch $branch_name to origin in $dir" >&2
    exit 1
fi

echo "Merge Request creation initiated successfully for $dir targeting $mr_target_branch" >&2
exit 0
