#!/bin/bash
#
# Script Name: common.sh
# Description: Common utility functions used across MyLiCuLa scripts
# Location: lib/common.sh
# Author: MyLiCuLa Project
# See also: Used by install.sh and all setup scripts
#
# Usage: source "$(dirname "$0")/lib/common.sh"
#
# This library provides common functions for:
# - Script directory detection
# - User input and prompts
# - Command existence checks
# - Idempotent file operations
# - Error handling and logging

set -euo pipefail

# Terminal colors for output
readonly COLOR_RED='\033[0;31m'
readonly COLOR_GREEN='\033[0;32m'
readonly COLOR_YELLOW='\033[0;33m'
readonly COLOR_BLUE='\033[0;34m'
readonly COLOR_RESET='\033[0m'

# Script metadata
declare -g SCRIPT_NAME="${0##*/}"
declare -g VERBOSE="${VERBOSE:-false}"
declare -g DRY_RUN="${DRY_RUN:-false}"

#
# Function: get_script_dir
# Description: Get the directory of the calling script reliably
# Args: None
# Usage: SCRIPT_DIR=$(get_script_dir)
# Output (stdout): Absolute path to script directory
# Output (stderr): None
# Return code: 0 on success
#
get_script_dir() {
    local source="${BASH_SOURCE[1]}"
    while [[ -h "$source" ]]; do
        local dir
        dir="$(cd -P "$(dirname "$source")" &>/dev/null && pwd)"
        source="$(readlink "$source")"
        [[ $source != /* ]] && source="$dir/$source"
    done
    cd -P "$(dirname "$source")" &>/dev/null && pwd
}

#
# Function: log_info
# Description: Print informational message
# Args:
#   $1 - Message to print
# Usage: log_info "Installing package..."
# Output (stdout): Formatted info message
# Output (stderr): None
# Return code: 0
#
log_info() {
    echo -e "${COLOR_BLUE}[INFO]${COLOR_RESET} $*"
}

#
# Function: log_success
# Description: Print success message
# Args:
#   $1 - Message to print
# Usage: log_success "Installation complete"
# Output (stdout): Formatted success message
# Output (stderr): None
# Return code: 0
#
log_success() {
    echo -e "${COLOR_GREEN}[SUCCESS]${COLOR_RESET} $*"
}

#
# Function: log_warning
# Description: Print warning message
# Args:
#   $1 - Message to print
# Usage: log_warning "Configuration file not found"
# Output (stdout): Formatted warning message
# Output (stderr): None
# Return code: 0
#
log_warning() {
    echo -e "${COLOR_YELLOW}[WARNING]${COLOR_RESET} $*"
}

#
# Function: log_error
# Description: Print error message
# Args:
#   $1 - Message to print
# Usage: log_error "Failed to install package"
# Output (stdout): None
# Output (stderr): Formatted error message
# Return code: 0
#
log_error() {
    echo -e "${COLOR_RED}[ERROR]${COLOR_RESET} $*" >&2
}

#
# Function: die
# Description: Print error message and exit
# Args:
#   $1 - Error message
#   $2 - Exit code (optional, default: 1)
# Usage: die "Critical error occurred" 2
# Output (stdout): None
# Output (stderr): Error message
# Return code: Does not return (exits)
#
die() {
    local message=$1
    local exit_code=${2:-1}
    log_error "$message"
    exit "$exit_code"
}

#
# Function: command_exists
# Description: Check if a command exists in PATH
# Args:
#   $1 - Command name to check
# Usage: if command_exists git; then ...; fi
# Output (stdout): None
# Output (stderr): None
# Return code: 0 if command exists, 1 otherwise
#
command_exists() {
    command -v "$1" &>/dev/null
}

#
# Function: prompt_user
# Description: Prompt user for input without default
# Args:
#   $1 - Prompt message
# Usage: EMAIL=$(prompt_user "Enter your email")
# Output (stdout): User input
# Output (stderr): None
# Return code: 0 on success
#
prompt_user() {
    local prompt=$1
    local response
    read -r -p "$prompt: " response
    echo "$response"
}

#
# Function: prompt_with_default
# Description: Prompt user for input with a default value
# Args:
#   $1 - Prompt message
#   $2 - Default value
# Usage: USERNAME=$(prompt_with_default "Enter username" "$USER")
# Output (stdout): User input or default if empty
# Output (stderr): None
# Return code: 0 on success
#
prompt_with_default() {
    local prompt=$1
    local default=$2
    local response
    read -r -p "$prompt [$default]: " response
    echo "${response:-$default}"
}

#
# Function: prompt_yes_no
# Description: Ask user a yes/no question
# Args:
#   $1 - Question to ask
#   $2 - Default answer (y/n, optional, default: n)
# Usage: if prompt_yes_no "Continue installation?" "y"; then ...; fi
# Output (stdout): None
# Output (stderr): None
# Return code: 0 for yes, 1 for no
#
prompt_yes_no() {
    local question=$1
    local default=${2:-n}
    local prompt

    if [[ "$default" == "y" ]]; then
        prompt="$question [Y/n]"
    else
        prompt="$question [y/N]"
    fi

    local response
    read -r -p "$prompt: " response
    response=${response:-$default}

    case "$response" in
        [Yy]|[Yy][Ee][Ss]) return 0 ;;
        *) return 1 ;;
    esac
}

#
# Function: add_to_file_once
# Description: Add content to a file only if it doesn't already exist (idempotent)
# Args:
#   $1 - Content to add
#   $2 - Target file path
# Usage: add_to_file_once "export PATH=\$PATH:\$HOME/bin" "$HOME/.bashrc"
# Output (stdout): None
# Output (stderr): None
# Return code: 0 on success
#
add_to_file_once() {
    local content=$1
    local file=$2

    # Create file if it doesn't exist
    touch "$file"

    # Add content only if not already present
    if ! grep -qF "$content" "$file"; then
        echo "$content" >> "$file"
        [[ "$VERBOSE" == "true" ]] && log_info "Added to $file: $content"
    else
        [[ "$VERBOSE" == "true" ]] && log_info "Already in $file: $content"
    fi
}

#
# Function: backup_file
# Description: Create a backup of a file with timestamp
# Args:
#   $1 - File path to backup
# Usage: backup_file "$HOME/.bashrc"
# Output (stdout): Backup file path
# Output (stderr): None
# Return code: 0 on success, 1 if file doesn't exist
#
backup_file() {
    local file=$1

    if [[ ! -f "$file" ]]; then
        log_warning "Cannot backup $file: file not found"
        return 1
    fi

    local backup="${file}.backup.$(date +%Y%m%d_%H%M%S)"
    cp "$file" "$backup"
    log_info "Created backup: $backup"
    echo "$backup"
}

#
# Function: create_symlink
# Description: Create a symbolic link, checking if target exists (idempotent)
# Args:
#   $1 - Source file (what the link points to)
#   $2 - Link name (the symlink to create)
#   $3 - Verbose output (optional, "verbose" for detailed feedback)
# Usage: create_symlink "/usr/local/bin/app" "$HOME/bin/app"
#        create_symlink "/path/to/source" "$HOME/link" "verbose"
# Output (stdout): Status messages
# Output (stderr): Error messages if applicable
# Return code: 0 on success, 1 on error, 2 on skip
#
create_symlink() {
    local source=$1
    local link=$2
    local verbose_mode=${3:-}

    # Check if source exists
    if [[ ! -e "$source" ]]; then
        if [[ "$verbose_mode" == "verbose" ]]; then
            echo "        [ERROR] Source does not exist: $source" >&2
        fi
        log_error "Cannot create symlink: source '$source' does not exist"
        return 1
    fi

    # If link already exists and points to correct location
    if [[ -L "$link" ]]; then
        local current_target
        current_target=$(readlink "$link")
        if [[ "$current_target" == "$source" ]]; then
            if [[ "$verbose_mode" == "verbose" ]]; then
                echo "        [SKIP] Link already points to correct target"
            elif [[ "$VERBOSE" == "true" ]]; then
                log_info "Symlink already correct: $link -> $source"
            fi
            return 2  # Return 2 to indicate "skipped"
        else
            if [[ "$verbose_mode" == "verbose" ]]; then
                echo "        [UPDATE] Link points to wrong target, updating..."
            else
                log_warning "Updating symlink: $link"
            fi
            rm -f "$link"
        fi
    elif [[ -e "$link" ]]; then
        # File/directory exists but is not a symlink
        if [[ "$verbose_mode" == "verbose" ]]; then
            echo "        [ERROR] $(basename "$link") exists but is not a symlink, skipping..." >&2
        else
            log_warning "File exists and is not a symlink, skipping: $link"
        fi
        return 1
    fi

    # Create directory if needed
    local link_dir
    link_dir="$(dirname "$link")"
    mkdir -p "$link_dir"

    # Create the symlink
    if ln -s "$source" "$link"; then
        if [[ "$verbose_mode" == "verbose" ]]; then
            echo "        [OK] Link created successfully"
        else
            log_success "Created symlink: $link -> $source"
        fi
        return 0
    else
        if [[ "$verbose_mode" == "verbose" ]]; then
            echo "        [ERROR] Failed to create link" >&2
        else
            log_error "Failed to create symlink: $link"
        fi
        return 1
    fi
}

#
# Function: remove_broken_links
# Description: Remove all broken symbolic links from a directory
# Args:
#   $1 - Directory path to search
#   $2 - Verbose output (optional, "verbose" for detailed feedback)
# Usage: remove_broken_links "$HOME/Templates"
#        remove_broken_links "$HOME/Templates" "verbose"
# Output (stdout): Messages about broken links removed
# Output (stderr): None
# Return code: 0 on success
#
remove_broken_links() {
    local directory=$1
    local verbose_mode=${2:-}

    if [[ ! -d "$directory" ]]; then
        log_warning "Directory not found: $directory"
        return 0
    fi

    if [[ "$verbose_mode" == "verbose" ]]; then
        echo "Deleting broken links..."
    fi

    # Find and remove broken symbolic links
    local broken_links
    broken_links=$(find "$directory" -xtype l 2>/dev/null)

    if [[ -n "$broken_links" ]]; then
        while IFS= read -r link; do
            if [[ "$verbose_mode" == "verbose" ]]; then
                echo "    $link"
            elif [[ "$VERBOSE" == "true" ]]; then
                log_info "Removing broken link: $link"
            fi
            rm -f "$link"
        done <<< "$broken_links"
    else
        if [[ "$verbose_mode" == "verbose" ]]; then
            echo "    No broken links found"
        fi
    fi
}

#
# Function: ensure_directory
# Description: Ensure directory exists, create if it doesn't
# Args:
#   $1 - Directory path
# Usage: ensure_directory "$HOME/.config/myapp"
# Output (stdout): None
# Output (stderr): None
# Return code: 0 on success
#
ensure_directory() {
    local dir=$1
    if [[ ! -d "$dir" ]]; then
        mkdir -p "$dir"
        log_info "Created directory: $dir"
    fi
}

#
# Function: source_file_if_exists
# Description: Source a file if it exists
# Args:
#   $1 - File path to source
# Usage: source_file_if_exists "$HOME/.bashrc"
# Output (stdout): Depends on sourced file
# Output (stderr): Depends on sourced file
# Return code: 0 if file sourced or doesn't exist, 1 on error
#
source_file_if_exists() {
    local file=$1
    if [[ -f "$file" ]]; then
        # shellcheck disable=SC1090
        source "$file"
        return $?
    fi
    return 0
}

#
# Function: is_ubuntu
# Description: Check if running on Ubuntu
# Args: None
# Usage: if is_ubuntu; then ...; fi
# Output (stdout): None
# Output (stderr): None
# Return code: 0 if Ubuntu, 1 otherwise
#
is_ubuntu() {
    [[ -f /etc/os-release ]] && grep -q "^ID=ubuntu" /etc/os-release
}

#
# Function: get_ubuntu_version
# Description: Get Ubuntu version (e.g., "22.04")
# Args: None
# Usage: VERSION=$(get_ubuntu_version)
# Output (stdout): Ubuntu version string
# Output (stderr): None
# Return code: 0 on success, 1 if not Ubuntu
#
get_ubuntu_version() {
    if is_ubuntu; then
        grep "^VERSION_ID=" /etc/os-release | cut -d'"' -f2
    else
        return 1
    fi
}

#
# Function: interpolate_string
# Description: Replace <<<KEY>>> patterns with values from CONFIG array
# Args:
#   $1 - Input string to interpolate
# Usage: RESULT=$(interpolate_string "$input_string")
# Output (stdout): Interpolated string
# Output (stderr): None
# Return code: 0 on success
#
# Note: Requires CONFIG associative array to be declared with values
#       Uses environment variables MYLICULA_* as fallback
#
interpolate_string() {
    local input=$1
    local output=$input

    # Define interpolation mappings (CONFIG keys or environment variables)
    declare -A interpolation_map=(
        ["USERNAME"]="${CONFIG[USERNAME]:-${MYLICULA_USERNAME:-${USER}}}"
        ["EMAIL"]="${CONFIG[EMAIL]:-${MYLICULA_EMAIL:-}}"
        ["FULL_NAME"]="${CONFIG[FULL_NAME]:-${MYLICULA_FULL_NAME:-}}"
        ["COMPANY"]="${CONFIG[COMPANY]:-${MYLICULA_COMPANY:-}}"
        ["GITHUB_USER"]="${CONFIG[GITHUB_USER]:-${MYLICULA_GITHUB_USER:-}}"
        ["HOME"]="${HOME}"
        ["USER"]="${USER}"
    )

    # Replace each <<<KEY>>> pattern with its value
    for key in "${!interpolation_map[@]}"; do
        local value="${interpolation_map[$key]}"
        # Use | as sed delimiter to avoid issues with / in paths
        output=$(echo "$output" | sed "s|<<<${key}>>>|${value}|g")
    done

    echo "$output"
}

#
# Function: interpolate_file
# Description: Replace <<<KEY>>> patterns in a file with configuration values
# Args:
#   $1 - Source file path
#   $2 - Destination file path (optional, defaults to source file)
# Usage: interpolate_file "template.sh" "output.sh"
#        interpolate_file "config.sh"  # In-place
# Output (stdout): None
# Output (stderr): Error messages if any
# Return code: 0 on success, 1 on failure
#
# Note: Creates a backup before in-place edits (.backup.TIMESTAMP)
#       Requires CONFIG associative array with interpolation values
#
interpolate_file() {
    local source_file=$1
    local dest_file=${2:-$source_file}

    if [[ ! -f "$source_file" ]]; then
        log_error "Source file not found: $source_file"
        return 1
    fi

    # If in-place edit, create backup
    if [[ "$source_file" == "$dest_file" ]]; then
        local backup="${source_file}.backup.$(date +%Y%m%d_%H%M%S)"
        cp "$source_file" "$backup"
        [[ "$VERBOSE" == "true" ]] && log_info "Created backup: $backup"
    fi

    # Read file content
    local content
    content=$(<"$source_file")

    # Interpolate content
    local interpolated
    interpolated=$(interpolate_string "$content")

    # Write to destination
    echo "$interpolated" > "$dest_file"

    [[ "$VERBOSE" == "true" ]] && log_info "Interpolated: $source_file -> $dest_file"
    return 0
}

#
# Function: interpolate_directory
# Description: Recursively interpolate all files in a directory
# Args:
#   $1 - Source directory path
#   $2 - Destination directory path (optional, defaults to source)
#   $3 - File pattern (optional, defaults to "*")
# Usage: interpolate_directory "templates/" "output/"
#        interpolate_directory "scripts/" "scripts/" "*.sh"
# Output (stdout): Progress messages
# Output (stderr): Error messages if any
# Return code: 0 on success
#
# Note: Preserves directory structure, creates dirs as needed
#
interpolate_directory() {
    local source_dir=$1
    local dest_dir=${2:-$source_dir}
    local pattern=${3:-*}

    if [[ ! -d "$source_dir" ]]; then
        log_error "Source directory not found: $source_dir"
        return 1
    fi

    # Create destination directory if needed
    mkdir -p "$dest_dir"

    # Find and interpolate all matching files
    while IFS= read -r -d '' file; do
        local rel_path="${file#${source_dir}/}"
        local dest_file="${dest_dir}/${rel_path}"

        # Create subdirectory if needed
        local dest_file_dir
        dest_file_dir="$(dirname "$dest_file")"
        mkdir -p "$dest_file_dir"

        # Interpolate the file
        interpolate_file "$file" "$dest_file"
    done < <(find "$source_dir" -type f -name "$pattern" -print0)

    log_success "Interpolated directory: $source_dir -> $dest_dir"
}

# Verify we're running with bash 4.0+
if [[ "${BASH_VERSINFO[0]}" -lt 4 ]]; then
    die "This script requires Bash 4.0 or higher. Current version: $BASH_VERSION"
fi

# Log library load in verbose mode
if [[ "${VERBOSE:-false}" == "true" ]]; then
    log_info "Loaded common.sh library"
fi
