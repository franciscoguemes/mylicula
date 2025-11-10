#!/usr/bin/env bash
####################################################################################################
# Args           :
#                   $1  (Optional) Name or ID of the network connection to bring up. Default is "ZuluVPN".
#                   -h, --help  Display usage information
# Usage          :   ./connect_to_Zulutrade_VPN.sh [connection_name]
#                   ./connect_to_Zulutrade_VPN.sh -h
# Output stdout  :   Detailed execution trace of the nmcli command to bring up the specified connection.
# Output stderr  :   Error messages if the specified connection does not exist or fails to bring up.
# Return code    :   0 on success, non-zero on failure.
# Description    :   This script uses nmcli to bring up a specified network connection. If no connection
#                    name is provided, it defaults to "ZuluVPN". The script runs in verbose and debug
#                    mode to provide detailed output.
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
Usage: $(basename "$0") [CONNECTION_NAME] [-h|--help]

Connect to a VPN using NetworkManager's nmcli command.

OPTIONS:
    CONNECTION_NAME  Name of the VPN connection (default: ZuluVPN)
    -h, --help       Display this help message

DESCRIPTION:
    This script connects to a VPN using nmcli. If no connection name is
    provided, it defaults to "ZuluVPN". The script runs with verbose output
    to show the connection process.

EXAMPLES:
    $(basename "$0")              # Connect to ZuluVPN
    $(basename "$0") MyVPN        # Connect to MyVPN
    $(basename "$0") --help       # Show this help

REQUIREMENTS:
    - nmcli (NetworkManager command-line interface)
    - VPN connection must be configured in NetworkManager

AUTHOR:
    Francisco Güemes <francisco@franciscoguemes.com>
EOF
}

# Check if nmcli is installed
if ! command -v nmcli &> /dev/null; then
    echo "Error: nmcli is not installed. Please install NetworkManager:" >&2
    echo "  sudo nala install network-manager" >&2
    exit 1
fi

# Parse arguments
if [ "$#" -eq 1 ]; then
    case "$1" in
        -h|--help)
            show_help
            exit 0
            ;;
        *)
            CONNECTION_NAME="$1"
            ;;
    esac
elif [ "$#" -eq 0 ]; then
    CONNECTION_NAME="ZuluVPN"
else
    echo "Error: Too many arguments." >&2
    show_help
    exit 1
fi

set -ex

# Bring up the specified network connection
nmcli con up id "$CONNECTION_NAME"
