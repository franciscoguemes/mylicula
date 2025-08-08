#!/usr/bin/env bash
####################################################################################################
#Args           : None  This script does not take any arguments.
#Usage          : ./install_set-title_function.sh
#                  Run the script to add the set-title function to your ~/.bashrc file.
#Output stdout  : A message indicating whether the function was added or already exists.
#Output stderr  : None.
#Return code    :
#                   0  Success
#                   1  An error occurred
#Description	  : This script appends a function named set-title to your ~/.bashrc file.
#                   The set-title function sets the terminal title to the provided arguments.
#                   If the function already exists in the ~/.bashrc file, it will not be added again.
#Author       	: Francisco Güemes
#Email         	: francisco@franciscoguemes.com
#See also	      :
#                   https://blog.programster.org/ubuntu-16-04-set-terminal-title
#                   https://askubuntu.com/questions/616404/ubuntu-15-04-fresh-install-cant-rename-gnome-terminal-tabs
#                   https://askubuntu.com/questions/22413/how-to-change-gnome-terminal-title
#                   https://unix.stackexchange.com/questions/177572/how-to-rename-terminal-tab-title-in-gnome-terminal
####################################################################################################

# Define the function to add
FUNCTION='set-title(){
  ORIG=$PS1
  TITLE="\e]2;$@\a"
  PS1=${ORIG}${TITLE}
}'

# Path to the .bashrc file
BASHRC=~/.bashrc

# Check if the function is already present in .bashrc
if ! grep -q "set-title()" "$BASHRC"; then
  # Append the function to .bashrc
  echo -e "\n# Function to set terminal title" >> "$BASHRC"
  echo "$FUNCTION" >> "$BASHRC"
  echo "The set-title function has been added to your ~/.bashrc file."
else
  echo "The set-title function is already present in your ~/.bashrc file."
fi

# Reload .bashrc to make the function available immediately
source "$BASHRC"
