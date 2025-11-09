#!/usr/bin/env bash
####################################################################################################
#Args           : None - This script does not accept any arguments.
#Usage          :   ./install_icons.sh
#                   Run this script to install custom directory icons for Ubuntu customization.
#                   Script must be run from its installation directory to locate resources/images/icons.
#Output stdout  :   Messages indicating icon installation progress for each icon file.
#Output stderr  :   Error messages if icon operations fail.
#Return code    :   0 on success, non-zero on error.
#Description	: This script installs the customization icons and sets them up. All the icons in this
#                 script are free of royalties. Thanks to the authors of the icons:
#                   https://imgur.com/gallery/n1js84s
#
#                 The script creates symbolic links from resources/images/icons to
#                 ~/Pictures/Ubuntu_customization/icons and sets custom icons for directories
#                 using the gio command.
#
#Author       	: Francisco Güemes
#Email         	: francisco@franciscoguemes.com
#See also	    : https://stackoverflow.com/questions/14008125/shell-script-common-template
#                 https://devhints.io/bash
#                 https://linuxhint.com/30_bash_script_examples/
#                 https://stackoverflow.com/questions/192249/how-do-i-parse-command-line-arguments-in-bash
#                 https://askubuntu.com/questions/1044358/is-it-possible-to-insert-icons-on-folders-with-the-gio-set-command
#                 https://forums.linuxmint.com/viewtopic.php?t=352261
####################################################################################################

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Find BASE_DIR - Priority 1: env var, Priority 2: search for lib/common.sh
if [[ -n "${MYLICULA_BASE_DIR:-}" ]]; then
    BASE_DIR="$MYLICULA_BASE_DIR"
else
    # Search upwards for lib/common.sh (max 3 levels)
    BASE_DIR="$SCRIPT_DIR"
    for i in {1..3}; do
        if [[ -f "${BASE_DIR}/lib/common.sh" ]]; then
            break
        fi
        BASE_DIR="$(dirname "$BASE_DIR")"
    done

    if [[ ! -f "${BASE_DIR}/lib/common.sh" ]]; then
        echo "[ERROR] Cannot find MyLiCuLa project root" >&2
        echo "Please set MYLICULA_BASE_DIR environment variable or run via install.sh" >&2
        exit 1
    fi
fi

# Source common utilities
if [[ -f "${BASE_DIR}/lib/common.sh" ]]; then
    # shellcheck disable=SC1091
    source "${BASE_DIR}/lib/common.sh"
else
    echo "ERROR: Cannot find lib/common.sh" >&2
    exit 1
fi

# Configuration
DESTINATION_DIR=${HOME}/Pictures/Ubuntu_customization/icons
ICONS_DIR=${SCRIPT_DIR}/resources/images/icons

# Ensure destination directory exists
mkdir -p "$DESTINATION_DIR"

#-----------------------------------------------------------------------------
# Create symbolic links to the icons
#-----------------------------------------------------------------------------
echo "Installing icons..."
for f in "$ICONS_DIR"/*
do
  FILE_NAME=$(basename "$f")
  LINK_PATH="${DESTINATION_DIR}/${FILE_NAME}"

  echo "    ${FILE_NAME}"
  create_symlink "$f" "$LINK_PATH" "verbose"
done


#-----------------------------------------------------------------------------
# Set the icons to the directories
#-----------------------------------------------------------------------------
# See:  https://askubuntu.com/questions/1044358/is-it-possible-to-insert-icons-on-folders-with-the-gio-set-command
#       https://forums.linuxmint.com/viewtopic.php?t=352261
#
# Set the default icon back:
#   gio set $DIRECTORY -t unset metadata::custom-icon
#   gio set "${HOME}/Documents/Mega" -t unset metadata::custom-icon

#echo "${HOME}/Documents/Mega"
#echo "${DESTINATION_DIR}/Mega-nz.png"
gio set -t string "${HOME}/Documents/Mega" metadata::custom-icon "file://${DESTINATION_DIR}/Mega-nz.png"
