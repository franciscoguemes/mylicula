#!/usr/bin/env bash
####################################################################################################
#Script Name	: install_templates.sh                                                                                             
#Description	: This script installs the templates in Ubuntu so when you do right click inside Nautilus
#                 and you select "New Document" you can see the different options.
#
#                 The script basically takes the scripts from the "templates" folder and creates symbolic
#                 links inside the foldre ~/Templates.
#                                                                                 
#Args           :                                                                                           
#Author       	: Francisco Güemes                                                
#Email         	: francisco@franciscoguemes.com                                           
#See also	    : https://devhints.io/bash
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
  echo "    `basename $f`"
  #TODO: Check if the link already existes
  #       if it exists check if the destination is the same
  ln -s $f $DESTINATION_DIR/
done