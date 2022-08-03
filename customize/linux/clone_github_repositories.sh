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


# TODO: Better than hardcode here all the respositories, get the repositories URL/names from
#       this url: https://github.com/franciscoguemes?tab=repositories

# Go to the right directory
cd /home/$USER/git/$USER/github

# clone all the projects
git clone git@github.com:franciscoguemes/sudoku.git
git clone git@github.com:franciscoguemes/bash_scripts.git
git clone git@github.com:franciscoguemes/frontend_tutorials.git
git clone git@github.com:franciscoguemes/phaser_games.git
git clone git@github.com:franciscoguemes/python_web_server.git
git clone git@github.com:franciscoguemes/python2_examples.git
git clone git@github.com:franciscoguemes/python3_examples.git
git clone git@github.com:franciscoguemes/ascii_fps.git
git clone git@github.com:franciscoguemes/DbWS.git
git clone git@github.com:franciscoguemes/iworkin.git
git clone git@github.com:franciscoguemes/chrome_bookmars.git
git clone git@github.com:franciscoguemes/tour-operator.git
git clone git@github.com:franciscoguemes/phaser_tutorials.git
git clone git@github.com:franciscoguemes/warehouse-api.git
git clone git@github.com:franciscoguemes/online-tools.git
git clone git@github.com:franciscoguemes/javamanager.git


