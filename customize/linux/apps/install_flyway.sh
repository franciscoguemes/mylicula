#!/usr/bin/env bash
####################################################################################################
# Args           : None
# Usage          : ./install_flyway.sh
# Output stdout  : Messages indicating Flyway installation or update status.
# Output stderr  : Error messages if Flyway installation or update fails.
# Return code    : 0 if everything runs successfully, 1 if errors occur.
# Description    : This script checks if Flyway is installed, parses the latest version from the XML
#                  directory listing, and installs or updates Flyway as needed.
# Author         : Francisco Güemes
# Email          : francisco@franciscoguemes.com
# See also       : https://stackoverflow.com/questions/14008125/shell-script-common-template
#                  https://devhints.io/bash
#                  https://linuxhint.com/30_bash_script_examples/
#                  https://stackoverflow.com/questions/192249/how-do-i-parse-command-line-arguments-in-bash
####################################################################################################

set -e

FLYWAY_INSTALL_DIR="/opt/flyway"
FLYWAY_BIN="/usr/local/bin/flyway"
XML_URL="https://redgate-download.s3.eu-west-1.amazonaws.com/?delimiter=/&prefix=maven/release/com/redgate/flyway/flyway-commandline/"

# Function to check if Flyway is installed
check_flyway_installed() {
  if command -v flyway &>/dev/null; then
    return 0
  else
    return 1
  fi
}

# Function to get the installed Flyway version
get_installed_version() {
  flyway -v 2>/dev/null | awk 'FNR == 1' | awk '{print $4}'
}

# Function to get the latest Flyway version from the XML listing
get_latest_version() {
  curl -s "$XML_URL" \
    | grep -oP '(?<=<CommonPrefixes><Prefix>maven/release/com/redgate/flyway/flyway-commandline/)\d+\.\d+\.\d+(?=/)' \
    | sort -V | tail -n 1
}

# Function to download and install Flyway
install_flyway() {
  local version="$1"
  echo "Installing Flyway version ${version}..."

  sudo mkdir -p ${FLYWAY_INSTALL_DIR}
  sudo rm -rf ${FLYWAY_INSTALL_DIR}/*
  cd /tmp
  wget -qO- "https://download.red-gate.com/maven/release/com/redgate/flyway/flyway-commandline/${version}/flyway-commandline-${version}-linux-x64.tar.gz" \
    | sudo tar -xvz -C ${FLYWAY_INSTALL_DIR} --strip-components=1
  sudo chmod a+x ${FLYWAY_INSTALL_DIR}/flyway
  sudo ln -sf ${FLYWAY_INSTALL_DIR}/flyway ${FLYWAY_BIN}

  echo "Flyway version ${version} installed successfully."
}

# Main script logic
if check_flyway_installed; then
  installed_version=$(get_installed_version)
  latest_version=$(get_latest_version)

  echo "Installed Flyway version: ${installed_version}"
  echo "Latest Flyway version: ${latest_version}"

  if [[ "${installed_version}" != "${latest_version}" ]]; then
    read -p "A newer version of Flyway (${latest_version}) is available. Do you want to update? [y/N]: " confirm
    if [[ "${confirm}" =~ ^[Yy]$ ]]; then
      install_flyway "${latest_version}"
    else
      echo "Flyway update canceled."
    fi
  else
    echo "You are already using the latest version of Flyway."
  fi
else
  echo "Flyway is not installed. Installing the latest version..."
  latest_version=$(get_latest_version)
  install_flyway "${latest_version}"
fi
