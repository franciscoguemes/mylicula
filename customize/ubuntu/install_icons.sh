#!/usr/bin/env bash
####################################################################################################
#Script Name	: install_icons.sh                                                                                             
#Description	: This script installs the customization icons and set them up. All the icons in this
#                 script are free of royalties. Thanks to the uthors of the icons:
#                   https://imgur.com/gallery/n1js84s
#                                                                                 
#Args           :                                                                                           
#Author       	: Francisco Güemes                                                
#Email         	: francisco@franciscoguemes.com                                           
#See also	    : 
#                 
####################################################################################################

DESTINATION_DIR=${HOME}/Pictures/Ubuntu_customization/icons
mkdir -p ${DESTINATION_DIR}

# Get the directory where this script is placed
#   https://stackoverflow.com/a/246128
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"

ICONS_DIR=${SCRIPT_DIR}/resources/images/icons


#-----------------------------------------------------------------------------
# Create symbolic links to the icons
#-----------------------------------------------------------------------------
#TODO: Move this to a function
#TODO: Make this functionality bulletproof `ln -s kk kk` to Too many levels of symbolic links
echo "Installing icons..."
for f in ${ICONS_DIR}/*
do
  FILE_NAME=$(basename $f)
  echo "    ${FILE_NAME}"
  LINK=${DESTINATION_DIR}/${FILE_NAME}
#   if [[ -f ${LINK} ]]; then
#     rm -f ${LINK}
#   fi
  ln -fs $f ${LINK}
done


#-----------------------------------------------------------------------------
# Set the icons to the directories
#-----------------------------------------------------------------------------
# See: https://forums.linuxmint.com/viewtopic.php?t=352261
#
# gio set $DIRECTORY -t unset metadata::custom-icon
# gio set "${HOME}/Documents/Nextcloud" -t unset metadata::custom-icon

echo "${HOME}/Documents/Nextcloud"
echo "${DESTINATION_DIR}/Nextcloud_directory.png"
gio set "${HOME}/Documents/Nextcloud" -t string metadata::custom-icon "${DESTINATION_DIR}/Nextcloud_directory.png"
# gio set "${HOME}/Documents/Nextcloud" -t string metadata::custom-icon "${ICONS_DIR}/Nextcloud_directory.png"