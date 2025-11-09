#!/usr/bin/env bash
####################################################################################################
#Script Name	: show_keyboard_layout.sh                                                                                             
#Description	: This script shows on the screen the current keyboard layout.
#                                                                                 
#Args           :                                                                                           
#Author       	: Francisco Güemes                                                
#Email         	: francisco@franciscoguemes.com                                           
#See also	    : https://unix.stackexchange.com/questions/111624/how-to-display-the-current-keyboard-layout
#                 https://askubuntu.com/questions/973257/how-to-get-keyboard-layout-language-in-terminal-console-command-line
####################################################################################################

# set -ex


#–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––
# This function returns the selected keyboard layout in the system.
# The function is based in the command `gsettings get org.gnome.desktop.input-sources mru-sources`
# that returns an output in the form: `[('xkb', 'us'), ('xkb', 'de'), ('xkb', 'es')]`
# where the first element in the array is the selected keyboard layout.
# This funciton basically parses the array and returns the first keyboard layout in the array.
# i.e:
#   us   ---> "English (US) keyboard layout"
#   de   ---> "German (DE) keyboard layout"
#   es   ---> "Spanish (ES) keyboard layout"
#
# OUTPUTS:
#   The function will print the selected keyboard layout.
#–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––
function get_selected_keyboard_layout {
  output=`gsettings get org.gnome.desktop.input-sources mru-sources`
  layouts="$(echo $output | sed 's/\[//g' | sed 's/\]//g' | sed 's|[\(\)]||g' | tr -d \' | sed -e "s/xkb, //g" | sed 's/,//g')"
  read -r -a array <<< "$layouts"
  echo "${array[0]}"
}


#-----------------------------------------------------------------------------
#-----------------------------------------------------------------------------
#-----------------------------------------------------------------------------
# Start of the script
#-----------------------------------------------------------------------------
LAYOUT="$(get_selected_keyboard_layout)"

gkbd-keyboard-display -l $LAYOUT


