#!/usr/bin/env bash
####################################################################################################
# Args           :
#                   -h, --help  Display usage information
# Usage          : ./list_installed_jdks.sh
#                  ./list_installed_jdks.sh -h
# Output stdout  : Prints the identifiers of installed JDKs managed by SDKMan.
# Output stderr  : Prints error messages if SDKMan initialization script is not found.
# Return code    : 0 on success, 1 on failure (e.g., SDKMan initialization script not found).
# Description   : This script lists the identifiers of installed JDKs managed by SDKMan on the system.
#
# Author         : Francisco Güemes
# Email          : francisco@franciscoguemes.com
# See also       : https://stackoverflow.com/questions/14008125/shell-script-common-template
#                 https://devhints.io/bash
#                 https://linuxhint.com/30_bash_script_examples/
#                 https://stackoverflow.com/questions/192249/how-do-i-parse-command-line-arguments-in-bash
####################################################################################################

# Function to display help
show_help() {
    cat << EOF
Usage: $(basename "$0") [-h|--help]

List all JDK installations managed by SDKMan.

OPTIONS:
    -h, --help       Display this help message

DESCRIPTION:
    This script lists the identifiers of all installed JDKs managed by SDKMan.
    The output can be used with other scripts to perform operations on all JDKs.

REQUIREMENTS:
    - SDKMan (SDK Manager for Java and other SDKs)
    - awk (text processing)

EXAMPLES:
    $(basename "$0")          # List all installed JDKs
    $(basename "$0") --help   # Show this help

AUTHOR:
    Francisco Güemes <francisco@franciscoguemes.com>
EOF
}

# Parse arguments
if [ "$#" -eq 1 ]; then
    case "$1" in
        -h|--help)
            show_help
            exit 0
            ;;
        *)
            echo "Error: Unknown argument '$1'" >&2
            show_help
            exit 1
            ;;
    esac
elif [ "$#" -gt 1 ]; then
    echo "Error: Too many arguments." >&2
    show_help
    exit 1
fi

# Check if awk is installed
if ! command -v awk &> /dev/null; then
    echo "Error: awk is not installed. Please install gawk:" >&2
    echo "  sudo nala install gawk" >&2
    exit 1
fi

# Check if SDKMan is installed
if [ ! -s "$HOME/.sdkman/bin/sdkman-init.sh" ]; then
    echo "Error: SDKMan is not installed. Please install SDKMan:" >&2
    echo "  curl -s 'https://get.sdkman.io' | bash" >&2
    echo "  source \"\$HOME/.sdkman/bin/sdkman-init.sh\"" >&2
    exit 1
fi

# Source the SDKMan initialization script
if [ -s "$HOME/.sdkman/bin/sdkman-init.sh" ]; then
    source "$HOME/.sdkman/bin/sdkman-init.sh"
else
    echo "Error: SDKMan initialization script not found."
    exit 1
fi

# Get list of installed JDK identifiers
sdk list java | awk '/^[[:space:]]*\|/ && /installed|local only/ {print $NF}'

