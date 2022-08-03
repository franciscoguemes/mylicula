#!/usr/bin/env bash
####################################################################################################
#Script Name	: linux_setup.sh                                                                                             
#Description	: Here it goes your description
#                                                                                 
#Args           :                                                                                           
#Author       	: Francisco Güemes                                                
#Email         	: francisco@franciscoguemes.com                                           
#See also	    : https://devhints.io/bash
#                 https://linuxhint.com/30_bash_script_examples/
#                 https://stackoverflow.com/questions/192249/how-do-i-parse-command-line-arguments-in-bash  
####################################################################################################

set -ex

# Get the directory where this script is placed
#   https://stackoverflow.com/a/246128
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"


# TODO: Create a DryRun option and a Verbose option
#

# TODO: Make this script interactive
# Ask for the following values:
#   author: It appears in the templates of the scripts. Use this value to interpolate the template scritps
#   email: It appears in the templates of the scripts. Use this value to interpolate the template scritps
#   company: A global variable called COMPANY will be created. This variable will be used for creating directories and other things.


