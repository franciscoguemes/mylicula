#!/usr/bin/env bash
####################################################################################################
#Script Name	: install_gnome-terminal_functions.sh                                                                                             
#Description	: This script install terminal functions that allows you to set titles in your terminal windows.
#                 
#                                                                                 
#Args           :                                                                                           
#Author       	: Francisco Güemes                                                
#Email         	: francisco@franciscoguemes.com                                           
#See also	    : 
#                 https://unix.stackexchange.com/questions/77277/how-to-append-multiple-lines-to-a-file
#                 
####################################################################################################

FILE=.bashrc
PATH=/home/$USER/$FILE

echo $PATH

echo '
####################################################################################################
# Description: The set-tile function is used to name the gnome-terminal windows.
# Use        : set-title "Here goes your title"
# 
# See: 
#   TODO: Set here the link to my wiki
#   TODO: Set here the link to the script install_gnome-terminal_functions.sh in github
####################################################################################################

set-title(){
  ORIG=$PS1
  TITLE="\e]2;$@\a"
  PS1=${ORIG}${TITLE}
}

' >> $PATH

