#!/usr/bin/env bash
####################################################################################################
# Args           :
#                   $1  Certificate alias (e.g., CompanyCA, ACME_CA)
#                   $2  Path to the certificate file (*.pem)
#                   -h, --help  Display usage information
# Usage          : ./install_certificate_in_Java.sh <cert_alias> <cert_path>
#                  ./install_certificate_in_Java.sh ACME_CA /path/to/certificate.pem
#                  ./install_certificate_in_Java.sh -h
# Output stdout  : Prints installation status messages for each JDK where the certificate is installed.
# Output stderr  : Prints error messages if the certificate file is not found or any script fails.
# Return code    : 0 on success, 1 on failure (e.g., certificate file not found, script execution failed).
# Description    : This script installs a certificate in all installed JDKs managed by SDKMan on the system.
#                  It acts as a convenient wrapper around install_cert_for_all_jdks.sh.
#
# Author         : Francisco Güemes
# Email          : francisco@franciscoguemes.com
# See also       : https://stackoverflow.com/questions/14008125/shell-script-common-template
#                  https://devhints.io/bash
#                  https://linuxhint.com/30_bash_script_examples/
#                  https://stackoverflow.com/questions/192249/how-do-i-parse-command-line-arguments-in-bash
####################################################################################################

# Function to display help
show_help() {
    cat << EOF
Usage: $(basename "$0") <CERT_ALIAS> <CERT_PATH> [-h|--help]

Install a certificate into all JDKs managed by SDKMan.

ARGUMENTS:
    CERT_ALIAS       Alias name for the certificate (e.g., CompanyCA, ACME_CA)
    CERT_PATH        Full path to the certificate file (*.pem)

OPTIONS:
    -h, --help       Display this help message

DESCRIPTION:
    This script installs a certificate into ALL installed JDKs managed by SDKMan.
    It is a convenience wrapper that calls the install_cert_for_all_jdks.sh script
    with the provided certificate alias and path.

    The script will:
    - Validate the certificate file exists
    - Call install_cert_for_all_jdks.sh to install in all JDKs
    - Report success/failure for each installation

REQUIREMENTS:
    - SDKMan (SDK Manager for Java)
    - Helper script: certificate/java/install_cert_for_all_jdks.sh

EXAMPLES:
    $(basename "$0") CompanyCA ./company-CA.pem
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

#==================================================================================================
# Resolve script location (handles symlinks)
#==================================================================================================
# Get the real location of this script, even if it's called through a symlink
if [[ -L "${BASH_SOURCE[0]}" ]]; then
    # Script is a symlink - resolve to actual location
    SCRIPT_REAL_PATH="$(readlink -f "${BASH_SOURCE[0]}")"
else
    # Script is the actual file
    SCRIPT_REAL_PATH="${BASH_SOURCE[0]}"
fi

# Get the directory where the actual script resides
SCRIPT_REAL_DIR="$(cd "$(dirname "$SCRIPT_REAL_PATH")" && pwd)"

# Define path to the helper script
HELPER_SCRIPT="$SCRIPT_REAL_DIR/certificate/java/install_cert_for_all_jdks.sh"

# Check if helper script exists
if [ ! -f "$HELPER_SCRIPT" ]; then
    echo "Error: Helper script 'install_cert_for_all_jdks.sh' not found at: $HELPER_SCRIPT" >&2
    exit 1
fi

# Check if helper script is executable
if [ ! -x "$HELPER_SCRIPT" ]; then
    echo "Error: Helper script 'install_cert_for_all_jdks.sh' is not executable" >&2
    echo "  chmod +x $HELPER_SCRIPT" >&2
    exit 1
fi

# Validate certificate file exists
if [ ! -f "$CERT_PATH" ]; then
    echo "Error: Certificate file '$CERT_PATH' not found." >&2
    exit 1
fi

# Run install_cert_for_all_jdks.sh script
echo "Installing certificate '$CERT_ALIAS' from '$CERT_PATH' into all JDKs..."
echo ""
"$HELPER_SCRIPT" "$CERT_ALIAS" "$CERT_PATH"
