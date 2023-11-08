#!/usr/bin/env bash
####################################################################################################
#Args           : 
#                                                                                         
#Usage          :   Simply call the script and it will install github CLI: https://cli.github.com/
#Output stdout  :   The installation process
#Output stderr  :   
#Return code    :   0 in case of success non zero in case of errors.
#Description	:   The script installs github CLI following the installation instructions for Linux: https://github.com/cli/cli/blob/trunk/docs/install_linux.md
#                                                                                                                                                           
#Author       	: Francisco Güemes                                                
#Email         	: francisco@franciscoguemes.com                                           
#See also	    : https://stackoverflow.com/questions/14008125/shell-script-common-template
#                 https://devhints.io/bash
#                 https://linuxhint.com/30_bash_script_examples/
#                 https://stackoverflow.com/questions/192249/how-do-i-parse-command-line-arguments-in-bash  
####################################################################################################


command gh &> /dev/null
if [ $? -eq 0 ]; then
    echo "The application gh is already installed"
    exit 0
fi


# Download the pgp key and adding the github repository
curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg | sudo dd of=/usr/share/keyrings/githubcli-archive-keyring.gpg
echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | sudo tee /etc/apt/sources.list.d/github-cli.list > /dev/null


# Update repositories
sudo apt update

# Install github CLI
sudo apt install gh

