#!/usr/bin/env bash
####################################################################################################
# Args           :
#                   $1  (Optional) Clipboard text to process. If not provided, defaults to clipboard content.
#                   -h, --help  Display usage information
# Usage          :   ./update_url_in_clipboard.sh [clipboard_text]
#                   ./update_url_in_clipboard.sh -h
# Output stdout  :   Displays debugging messages if enabled, showing whether the text is a URL and its modification status.
# Output stderr  :   Error messages if clipboard access fails or if invalid input is detected.
# Return code    :   0 if successful, 1 if clipboard access fails or if the text is not a URL.
# Description    :   This script reads text from the clipboard, checks if it is a URL, and modifies URLs
#                   from a specific domain (devtools.acme.com) to another domain
#                   (devtools.acmetrade.local). If the text is not a URL or doesn't match the specific
#                   domain, it copies the original text back to the clipboard. Debugging mode can be
#                   enabled to display detailed information about the process.
# Author         :   Francisco Güemes
# Email          :   francisco@franciscoguemes.com
# See also       :   https://stackoverflow.com/questions/14008125/shell-script-common-template
#                   https://devhints.io/bash
#                   https://linuxhint.com/30_bash_script_examples/
#                   https://stackoverflow.com/questions/192249/how-do-i-parse-command-line-arguments-in-bash
####################################################################################################

# Function to display help
show_help() {
    cat << EOF
Usage: $(basename "$0") [TEXT] [-h|--help]

Update URLs in clipboard by replacing domain names.

OPTIONS:
    TEXT             Optional text to process (defaults to clipboard content)
    -h, --help       Display this help message

DESCRIPTION:
    This script processes URLs from the clipboard and replaces:
    - devtools.acme.com → devtools.acmetrade.local

    If the text is not a URL or doesn't match the pattern, the original
    text is preserved in the clipboard.

REQUIREMENTS:
    - xclip (for clipboard access)

EXAMPLES:
    $(basename "$0")                    # Process clipboard content
    $(basename "$0") "https://..."      # Process specific URL
    $(basename "$0") --help             # Show this help

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

# Check if xclip is installed
if ! command -v xclip &> /dev/null; then
    echo "Error: xclip is not installed. Please install xclip:" >&2
    echo "  sudo nala install xclip" >&2
    exit 1
fi

set -e

# Read text from the clipboard or use provided argument
clipboard_text="${1:-$(xclip -selection clipboard -o)}"

# Trim leading and trailing whitespace
clipboard_text="$(echo -e "${clipboard_text}" | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//')"

is_git_ssh() {
    local url=$1
    # Use grep to check if the string contains a URL pattern
    if echo "$url" | grep -qE '^git@'; then
        # Output only if debugging is enabled
        [[ $DEBUG == true ]] && echo "The text is a URL: $url"
        return 0
    else
        # Output only if debugging is enabled
        [[ $DEBUG == true ]] && echo "The text is not a URL."
        return 1
    fi
}

is_devtools_git_ssh() {
    local url=$1
    # Check if the URL matches the specific pattern to be replaced
    if echo "$url" | grep -qE 'git@devtools\.acme\.com:.*'; then
        return 0
    else
        return 1
    fi
}

# Function to check if a string is a valid URL
is_url() {
    local url=$1
    # Use grep to check if the string contains a URL pattern
    if echo "$url" | grep -qE '^https?://|^ftp://|^file://'; then
        # Output only if debugging is enabled
        [[ $DEBUG == true ]] && echo "The text is a URL: $url"
        return 0
    else
        # Output only if debugging is enabled
        [[ $DEBUG == true ]] && echo "The text is not a URL."
        return 1
    fi
}

# Function to evaluate if a URL needs to be replaced
is_devtools_url() {
    local url=$1
    # Check if the URL matches the specific pattern to be replaced
    if echo "$url" | grep -qE 'https?://devtools\.acme\.com/.*|git@devtools\.acme\.com:.*'; then
        return 0
    else
        return 1
    fi
}

# Function to replace specific URLs
replace_url() {
    local url=$1
    # Perform the substitution
    modified_url=$(echo "$url" | sed 's#https://devtools\.acme\.com/#https://devtools.acmetrade.local/#' | sed 's#git@devtools\.acme\.com:#git@devtools.acmetrade.local:#')
    echo "$modified_url"
}

# Call the function to check if the clipboard text is a URL
if is_url "$clipboard_text"; then
    # If it's a URL, check if it needs to be replaced
    if is_devtools_url "$clipboard_text"; then
        # If it needs to be replaced, call the function to replace it
        modified_text=$(replace_url "$clipboard_text")
        # Update the clipboard with the modified text
        echo -n "$modified_text" | xclip -selection clipboard
        [[ $DEBUG == true ]] && echo "Modified URL copied to clipboard: $modified_text"
    fi
elif is_git_ssh "$clipboard_text"; then
    # If it's a git ssh, check if it is devtools
    if is_devtools_git_ssh "$clipboard_text"; then
        # Instead of replacing anything, show the warning text in the modified texts
        warning_text="Please use HTTPs to clone the repository instead of SSH:"
        modified_text="${warning_text} ${clipboard_text}"
        # Update the clipboard with the modified text
        echo -n "$modified_text" | xclip -selection clipboard
        [[ $DEBUG == true ]] && echo "Warning text copied to clipboard: $modified_text"
    fi
else
    # If not a URL, copy the original text back to clipboard (The text is now trimmed)
    echo -n "$clipboard_text" | xclip -selection clipboard
    [[ $DEBUG == true ]] && echo "Non-URL text copied back to clipboard: $clipboard_text"
fi
