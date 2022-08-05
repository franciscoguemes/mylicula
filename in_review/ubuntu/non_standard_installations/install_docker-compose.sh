####################################################################################################
# This script has to go after the install_docker script
#
#
####################################################################################################



#TODO: Documentiation and verify that the script works
#TODO: Link this script with the corresponding entry in my blog

#TODO: BUG: Verify that docker is installed in the system

#TODO: Check that there are no docker-compose already installed

#TODO: Get the installation method (apt or using this script)

#TODO: Unninstall docker compose in case of packet manager installation
#sudo apt-get remove docker-compose

#TODO: Unninstall docker compose in case of manual installation (this script)
#sudo rm /usr/local/bin/docker-compose


# Get the docker-compose latest version from the official repository:
VERSION=$(curl --silent https://api.github.com/repos/docker/compose/releases/latest | jq .name -r)


# Install docker-compose
DESTINATION=/usr/local/bin/docker-compose
sudo curl -L https://github.com/docker/compose/releases/download/${VERSION}/docker-compose-$(uname -s)-$(uname -m) -o $DESTINATION
sudo chmod 755 $DESTINATION


#TODO: Verify that docker composed is installed correctly
#docker-compose -version