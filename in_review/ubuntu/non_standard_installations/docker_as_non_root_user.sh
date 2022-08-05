#!/usr/bin/env bash
####################################################################################################
#Script Name	: docker_as_non_root_user.sh                                                                                             
#Description	: This script assumes that docker is installed in your system
#                                                                                 
#Args           :                                                                                           
#Author       	: Francisco Güemes                                                
#Email         	: francisco@franciscoguemes.com                                           
#See also	    : https://docs.docker.com/engine/install/linux-postinstall/#manage-docker-as-a-non-root-user
#                 https://docs.docker.com/engine/install/ubuntu/#installation-methods
####################################################################################################

# TODO: In the description add the link to my article


# TODO: Verify that docker is installed in the system



sudo groupadd docker
# TODO: Verify that the word 'docker' is in the output
grep 'docker' /etc/group

sudo usermod -aG docker $USER
# TODO: Verify that the group 'docker' is in the output
groups $USER

newgrp docker