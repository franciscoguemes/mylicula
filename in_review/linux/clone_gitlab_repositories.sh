#!/usr/bin/env bash
####################################################################################################
#Script Name	: clone_gitlab_projects.sh                                                                                             
#Description	: clone my personal projects from my gitlab account
#                 You have to execute this script after the following ones:
#                       create_directory_structure.sh  
#                       create_global_variables.sh  
#                       create_ssh_keys.sh
#                                                                  
#Args           :                                                                                           
#Author       	: Francisco Güemes                                                
#Email         	: francisco@franciscoguemes.com                                           
#See also	    : 
#
####################################################################################################

# TODO: All my gitlab projects are private so I need to login first before I can access/clone any
#       repository

# TODO: Better than hardcode here all the respositories, get the repositories URL/names from
#       this url: https://gitlab.com/users/franciscoguemes/projects


# Go to the right directory
cd /home/$USER/git/$USER/gitlab

# clone all the projects
git clone git@gitlab.com:franciscoguemes/aegis-aggregator.git
git clone git@gitlab.com:franciscoguemes/coloring-site.git
git clone git@gitlab.com:franciscoguemes/customer-engagement-system.git
git clone git@gitlab.com:franciscoguemes/docker.git
git clone git@gitlab.com:franciscoguemes/mywebsite.git
git clone git@gitlab.com:franciscoguemes/mediawiki_configuration.git
git clone git@gitlab.com:franciscoguemes/in_construction_site.git
git clone git@gitlab.com:franciscoguemes/mm-customer-engagement.git
