#!/usr/bin/env bash
####################################################################################################
#Args           : None - This script does not accept any arguments.
#Usage          :   ./install_templates.sh
#                   Run this script to install templates for Nautilus "New Document" menu.
#                   Script must be run from its installation directory to locate resources/templates.
#Output stdout  :   Messages indicating broken links deletion and template installation progress.
#Output stderr  :   Error messages if template operations fail.
#Return code    :   0 on success, non-zero on error.
#Description	: This script installs the templates in Ubuntu so when you do right click inside Nautilus
#                 and you select "New Document" you can see the different options.
#
#                 The script basically takes the scripts from the "templates" folder and creates symbolic
#                 links inside the folder ~/Templates.
#
#Author       	: Francisco Güemes
#Email         	: francisco@franciscoguemes.com
#See also	    : https://stackoverflow.com/questions/14008125/shell-script-common-template
#                 https://devhints.io/bash
#                 https://linuxhint.com/30_bash_script_examples/
#                 https://stackoverflow.com/questions/192249/how-do-i-parse-command-line-arguments-in-bash
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
DESTINATION_DIR=$HOME/Templates
TEMPLATES_DIR=$SCRIPT_DIR/resources/templates

# Ensure destination directory exists
mkdir -p "$DESTINATION_DIR"

# Remove broken symbolic links
remove_broken_links "$DESTINATION_DIR" "verbose"

# Install templates by creating symbolic links
echo "Installing templates..."
for f in "$TEMPLATES_DIR"/*
do
  TEMPLATE_NAME=$(basename "$f")
  LINK_PATH="${DESTINATION_DIR}/${TEMPLATE_NAME}"

  echo "    ${TEMPLATE_NAME}"
  create_symlink "$f" "$LINK_PATH" "verbose"
done