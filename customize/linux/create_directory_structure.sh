#!/usr/bin/env bash
####################################################################################################
#Args           : None - This script does not accept any arguments.
#Usage          :   ./create_directory_structure.sh
#                   Run this script to create the standard directory structure for MyLiCuLa installation.
#                   Requires COMPANY environment variable to be set (can be empty string).
#Output stdout  :   No output on successful execution.
#Output stderr  :   Error messages if directory creation fails.
#Return code    :   0 on success, non-zero on error.
#Description	: Creates the directory structure on which the rest of the installation will rely.
#                 Creates system directories (/usr/lib/jvm) and user directories (Downloads, Documents,
#                 Templates, Videos, Music, Pictures, bin, .config, development, git, workspaces).
#                 Uses COMPANY variable to create company-specific directories if set.
#
#Author       	: Francisco Güemes
#Email         	: francisco@franciscoguemes.com
#See also	    : https://stackoverflow.com/questions/14008125/shell-script-common-template
#                 https://devhints.io/bash
#                 https://linuxhint.com/30_bash_script_examples/
#                 https://stackoverflow.com/questions/192249/how-do-i-parse-command-line-arguments-in-bash
#                 https://stackoverflow.com/questions/17674406/creating-a-full-directory-tree-at-once
####################################################################################################

# Create global directories (Execute script as sudo)
mkdir -p /usr/lib/jvm

# Create user directories
mkdir -p ${HOME}/{Downloads,Templates,Documents/{Mega,${COMPANY}},Videos,Music,Pictures}
mkdir -p ${HOME}/{bin,.config}
mkdir -p ${HOME}/development/{flyway,eclipse,netbeans,intellij-community}
mkdir -p ${HOME}/git/{${COMPANY},${USER},other}
mkdir -p ${HOME}/workspaces/{eclipse,netbeans,intellij}