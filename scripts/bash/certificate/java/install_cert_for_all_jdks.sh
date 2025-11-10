#!/usr/bin/env bash
####################################################################################################
# Args           :
#                   $1  Certificate alias
#                   $2  Path to the certificate file
#                   -h, --help  Display usage information
# Usage          : ./install_cert_for_all_jdks.sh ACME_CA /path/to/certificate.pem
#                  ./install_cert_for_all_jdks.sh -h
# Output stdout  : Prints installation status messages for each JDK where the certificate is installed.
# Output stderr  : Prints error messages if the certificate file is not found or JDK installation is not found.
# Return code    : 0 on success, 1 on failure (e.g., certificate file not found, JDK installation not found).
# Description   : This script installs a certificate in all installed JDKs managed by SDKMan on the system,
#                 identified by their respective JDK identifiers.
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
Usage: $(basename "$0") CERT_ALIAS CERT_PATH [-h|--help]

Install a certificate into all JDKs managed by SDKMan.

ARGUMENTS:
    CERT_ALIAS       Alias name for the certificate (e.g., ZuluTradeCA, ACME_CA)
    CERT_PATH        Full path to the certificate file (*.pem)

OPTIONS:
    -h, --help       Display this help message

DESCRIPTION:
    This script installs a certificate into ALL installed JDKs managed by SDKMan.
    It:
    - Lists all installed JDKs via SDKMan
    - Installs the certificate in each JDK's cacerts keystore
    - Reports success/failure for each installation

REQUIREMENTS:
    - SDKMan (SDK Manager for Java)
    - Helper scripts: list_installed_jdks.sh, install_cert_in_jdk.sh

EXAMPLES:
    $(basename "$0") ZuluTradeCA ./zulutrade-CA.pem
    $(basename "$0") ACME_CA /path/to/acme-certificate.pem
    $(basename "$0") --help

AUTHOR:
    Francisco Güemes <francisco@franciscoguemes.com>
EOF
}

# Parse arguments for help flag
if [ "$#" -eq 1 ]; then
    case "$1" in
        -h|--help)
            show_help
            exit 0
            ;;
    esac
fi

# Check if required arguments are provided
if [ $# -ne 2 ]; then
    echo "Error: Incorrect number of arguments" >&2
    show_help
    exit 1
fi

CERT_ALIAS="$1"
CERT_PATH="$2"

# Get the directory where this script is located (for finding helper scripts)
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"

# Check if SDKMan is installed
if [ ! -s "$HOME/.sdkman/bin/sdkman-init.sh" ]; then
    echo "Error: SDKMan is not installed. Please install SDKMan:" >&2
    echo "  curl -s 'https://get.sdkman.io' | bash" >&2
    echo "  source \"\$HOME/.sdkman/bin/sdkman-init.sh\"" >&2
    exit 1
fi

# Check if helper scripts exist
if [ ! -f "$SCRIPT_DIR/list_installed_jdks.sh" ]; then
    echo "Error: Helper script 'list_installed_jdks.sh' not found in $SCRIPT_DIR" >&2
    exit 1
fi

if [ ! -x "$SCRIPT_DIR/list_installed_jdks.sh" ]; then
    echo "Error: Helper script 'list_installed_jdks.sh' is not executable" >&2
    echo "  chmod +x $SCRIPT_DIR/list_installed_jdks.sh" >&2
    exit 1
fi

if [ ! -f "$SCRIPT_DIR/install_cert_in_jdk.sh" ]; then
    echo "Error: Helper script 'install_cert_in_jdk.sh' not found in $SCRIPT_DIR" >&2
    exit 1
fi

if [ ! -x "$SCRIPT_DIR/install_cert_in_jdk.sh" ]; then
    echo "Error: Helper script 'install_cert_in_jdk.sh' is not executable" >&2
    echo "  chmod +x $SCRIPT_DIR/install_cert_in_jdk.sh" >&2
    exit 1
fi

# Validate certificate file
if [ ! -f "$CERT_PATH" ]; then
    echo "Error: Certificate file '$CERT_PATH' not found."
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
jdk_identifiers=$("$SCRIPT_DIR"/list_installed_jdks.sh)

# Install certificate for each JDK
for jdk_identifier in $jdk_identifiers; do
    echo "Installing certificate '$CERT_ALIAS' in JDK '$jdk_identifier'..."
    "$SCRIPT_DIR"/install_cert_in_jdk.sh "$jdk_identifier" "$CERT_ALIAS" "$CERT_PATH"
    echo "Installation completed for JDK '$jdk_identifier'."
    echo
done

