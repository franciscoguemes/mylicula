#!/usr/bin/env bash
####################################################################################################
#Script Name	: create_directory_structure.sh                                                                                             
#Description	: Creates the directory structure on which the rest of the installation will rely.
#                                                                                 
#Args           :                                                                                           
#Author       	: Francisco Güemes                                                
#Email         	: francisco@franciscoguemes.com                                           
#See also	    : 
#                   https://stackoverflow.com/questions/17674406/creating-a-full-directory-tree-at-once
#
####################################################################################################

# Create global directories (Execute script as sudo)
mkdir -p /usr/lib/jvm

# Create user directories
mkdir -p $HOME/{Downloads,Templates,Documents/{Nextcloud,$COMPANY},Videos,Music,Pictures}
mkdir -p $HOME/{bin,.config}
mkdir -p $HOME/development/{apache-ant,apache-maven,flyway,eclipse,netbeans,gradle}
mkdir -p $HOME/git/{$COMPANY,$USER,other}
mkdir -p $HOME/workspaces/{eclipse,netbeans,intellij}