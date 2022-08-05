#!/usr/bin/env bash
####################################################################################################
#Script Name	: yourscriptname.sh                                                                                             
#Description	: Here it goes your description
#                                                                                 
#Args           :                                                                                           
#Author         : Francisco Güemes
#Email          : francisco@franciscoguemes.com                                          
#See also	    : https://devhints.io/bash
#                 https://linuxhint.com/30_bash_script_examples/
#                 https://stackoverflow.com/questions/192249/how-do-i-parse-command-line-arguments-in-bash  
####################################################################################################

#TODO: The entire script!!!

#set -ex


#–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––
# This function prints the directory where the script that calls the function is located.
# i.e:
#   "/home/user1/my_scripts/script1.sh"   ---> "/home/user1/my_scripts"
#   "cd /home/user1; ./my_scripts/script1.sh"   ---> "/home/user1/my_scripts"
#
# OUTPUTS:
#   The function will print the directory where the script that calls this function is located.
#–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––
function get_script_directory {
#  SOURCE="${BASH_SOURCE[0]}"
  SOURCE=$0
  while [ -h "$SOURCE" ]; do # resolve $SOURCE until the file is no longer a symlink
    DIR="$( cd -P "$( dirname "$SOURCE" )" >/dev/null 2>&1 && pwd )"
    SOURCE="$(readlink "$SOURCE")"
    [[ $SOURCE != /* ]] && SOURCE="$DIR/$SOURCE" # if $SOURCE was a relative symlink, we need to resolve it relative to the path where the symlink file was located
  done
  DIR="$( cd -P "$( dirname "$SOURCE" )" >/dev/null 2>&1 && pwd )"
  echo $DIR
}


#The base directory (absolute path ) for this project i.e. (/home/francisco/git/francisco/github/bash_scripts)
BASE_DIR=$(get_script_directory)

#-----------------------------------------------------------------------------
# Load functions from the commons/paths.sh file
#-----------------------------------------------------------------------------
#source $BASE_DIR/commons/paths.sh


echo ${BASE_DIR}

${BASE_DIR}/customize/linux_setup.sh
${BASE_DIR}/customize/ubuntu_setup.sh


# for filename in /Data/*.txt; do
#     for ((i=0; i<=3; i++)); do
#         ./MyProgram.exe "$filename" "Logs/$(basename "$filename" .txt)_Log$i.txt"
#     done
# done


# Go through each script on the folders:
#    - ./general_purpose/bash
#    - ./general_purpose/python
# And create a simbolic link in the folder $HOME/bin (Skip the creation if the link already exists)


# Add the directory $HOME/bin to the PATH variable in the of your OS (Skip this if it is already in the PATH)

# Add the following text at the end of the $HOME/.profile file

# Add a proper separator

# Add a text explaining that this was added with the customization scripts

# Add the following text:

# # set PATH so it includes user's private bin if it exists
# if [ -d "$HOME/bin" ] ; then
#     PATH="$HOME/bin:$PATH"
# fi


