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

# set -ex

DESTINATION_DIR=$HOME/Templates

# Get the directory where this script is placed
#   https://stackoverflow.com/a/246128
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"

TEMPLATES_DIR=$SCRIPT_DIR/resources/templates

#TODO: Move this to a function
#TODO: Make this functionality bulletproof `ln -s kk kk` to Too many levels of symbolic links
echo "Deleting broken links..."
BROKEN_LINKS=`find $DESTINATION_DIR -xtype l`
for f in $BROKEN_LINKS
do
  echo "    $f"
  rm $f
done

#TODO: Move this to a function
echo "Installing templates..."
for f in $TEMPLATES_DIR/*
do
  TEMPLATE_NAME=$(basename "$f")
  LINK_PATH="${DESTINATION_DIR}/${TEMPLATE_NAME}"

  echo "    ${TEMPLATE_NAME}"

  # Check if link already exists
  if [[ -L "${LINK_PATH}" ]]; then
    # Link exists - verify it points to correct target
    CURRENT_TARGET=$(readlink "${LINK_PATH}")
    if [[ "${CURRENT_TARGET}" == "$f" ]]; then
      echo "        [SKIP] Link already points to correct target"
      continue
    else
      echo "        [UPDATE] Link points to wrong target, updating..."
      rm -f "${LINK_PATH}"
    fi
  elif [[ -e "${LINK_PATH}" ]]; then
    # File/directory exists but is not a symlink
    echo "        [ERROR] ${TEMPLATE_NAME} exists but is not a symlink, skipping..." >&2
    continue
  fi

  # Create the symlink
  if ln -s "$f" "${LINK_PATH}"; then
    echo "        [OK] Link created successfully"
  else
    echo "        [ERROR] Failed to create link" >&2
  fi
done