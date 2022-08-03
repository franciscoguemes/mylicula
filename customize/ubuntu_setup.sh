#!/usr/bin/env bash
####################################################################################################
#Script Name	: ubuntu_setup.sh                                                                                             
#Description	: Customization for your Ubuntu installation
#                                                                                 
#Args           :                                                                                           
#Author       	: Francisco Güemes                                                
#Email         	: francisco@franciscoguemes.com                                           
#See also	    : 
#                 https://stackoverflow.com/questions/8352851/how-to-call-one-shell-script-from-another-shell-script
#                 https://devhints.io/bash
#                 https://linuxhint.com/30_bash_script_examples/
#                 https://stackoverflow.com/questions/192249/how-do-i-parse-command-line-arguments-in-bash  
####################################################################################################

#set -ex

# Get the directory where this script is placed
#   https://stackoverflow.com/a/246128
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"

UBUNTU_DIR=$SCRIPT_DIR/ubuntu



# Install templates
$UBUNTU_DIR/install_templates.sh

# Install packages
$UBUNTU_DIR/install_packages.sh

# Install gnome-terminal functions
$UBUNTU_DIR/install_gnome-terminal_functions.sh

