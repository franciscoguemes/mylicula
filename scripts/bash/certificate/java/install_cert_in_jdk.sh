#!/usr/bin/env bash
####################################################################################################
# Args           :
#                   $1  JDK identifier in SDKMan (e.g., 21.0.3-tem)
#                   $2  Alias for the certificate installation (e.g., ACME_CA)
#                   $3  Full path to the certificate file (*.pem)
#                   -h, --help  Display usage information
# Usage          :   ./install_cert_in_jdk.sh <JDK identifier> <certificate alias> <path to certificate file>
#                   ./install_cert_in_jdk.sh 8.0.412-tem ZuluTradeCA ./zulutrade-CONTROLLER-CA.pem
#                   ./install_cert_in_jdk.sh 8.0.265-open ZuluTradeCA ./zulutrade-CONTROLLER-CA.pem
#                   ./install_cert_in_jdk.sh -h
# Output stdout  :   Success or status messages indicating the progress of the script.
# Output stderr  :   Error messages in case of failures.
# Return code    :   0 if the script completes successfully, non-zero if it fails.
# Description   : This script installs a given certificate into the specified JDK's cacerts keystore
#                  using SDKMan. The script verifies if the certificate is already installed before
#                  proceeding.
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
Usage: $(basename "$0") JDK_IDENTIFIER CERT_ALIAS CERT_PATH [-h|--help]

Install a certificate into a specific JDK's cacerts keystore.

ARGUMENTS:
    JDK_IDENTIFIER   JDK version from SDKMan (e.g., 21.0.3-tem, 8.0.412-tem)
    CERT_ALIAS       Alias name for the certificate (e.g., ZuluTradeCA)
    CERT_PATH        Full path to the certificate file (*.pem)

OPTIONS:
    -h, --help       Display this help message

DESCRIPTION:
    This script installs a certificate into a specific JDK's cacerts keystore
    using the keytool utility. It:
    - Checks if the certificate is already installed
    - Locates the cacerts file in the JDK installation
    - Imports the certificate with the specified alias

REQUIREMENTS:
    - SDKMan (SDK Manager for Java)
    - find (file search utility)
    - Target JDK must be installed via SDKMan

EXAMPLES:
    $(basename "$0") 8.0.412-tem ZuluTradeCA ./zulutrade-CA.pem
    $(basename "$0") 21.0.3-tem ACME_CA /path/to/certificate.pem
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

# Function to display usage
usage() {
    echo "Error: Incorrect number of arguments" >&2
    show_help
    exit 1
}

# Check for the correct number of arguments
if [ "$#" -ne 3 ]; then
    usage
fi

# Assign arguments to variables
JDK_IDENTIFIER=$1
CERT_ALIAS=$2
CERT_PATH=$3

# Check if find is installed
if ! command -v find &> /dev/null; then
    echo "Error: find is not installed. Please install findutils:" >&2
    echo "  sudo nala install findutils" >&2
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

# Check if the certificate file exists and is readable
if [ ! -f "$CERT_PATH" ] || [ ! -r "$CERT_PATH" ]; then
    echo "Error: Certificate file does not exist or is not readable."
    exit 1
fi

# Check if the JDK installation exists using SDKMan
JDK_HOME=$(sdk home java $JDK_IDENTIFIER 2>/dev/null)
if [ -z "$JDK_HOME" ]; then
    echo "Error: JDK installation not found for identifier '$JDK_IDENTIFIER'."
    exit 1
fi

# Define the keystore password (default is 'changeit')
KEYSTORE_PASSWORD="changeit"

# Find the cacerts file in the JDK installation directory
CACERTS_PATH=$(find "$JDK_HOME" -type f -name cacerts 2>/dev/null | head -n 1)

# Check if the cacerts file was found
if [ -z "$CACERTS_PATH" ]; then
    echo "Error: cacerts file not found in JDK installation."
    exit 1
fi

# Find the keytool executable in the JDK installation directory
KEYTOOL=$(find "$JDK_HOME" -type f -name keytool 2>/dev/null | head -n 1)

# Check if the keytool executable was found
if [ -z "$KEYTOOL" ]; then
    echo "Error: keytool executable not found in JDK installation."
    exit 1
fi

# Check if the certificate is already installed
"$KEYTOOL" -list -keystore "$CACERTS_PATH" -storepass "$KEYSTORE_PASSWORD" -alias "$CERT_ALIAS" >/dev/null 2>&1
if [ $? -eq 0 ]; then
    echo "Certificate with alias '$CERT_ALIAS' is already installed."
    exit 0
fi

# Install the certificate
"$KEYTOOL" -import -trustcacerts -keystore "$CACERTS_PATH" -storepass "$KEYSTORE_PASSWORD" -noprompt -alias "$CERT_ALIAS" -file "$CERT_PATH"
if [ $? -eq 0 ]; then
    echo "Certificate installed successfully."
else
    echo "Error: Failed to install certificate."
    exit 1
fi

