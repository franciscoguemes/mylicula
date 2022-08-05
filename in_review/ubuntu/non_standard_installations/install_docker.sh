####################################################################################################
# This script has to go after the install_packages script
#
# See:
#       https://docs.docker.com/engine/install/ubuntu/#installation-methods
####################################################################################################

sudo apt-get update
sudo apt-get upgrade

# Install pre-requieremetns
sudo apt-get install \
    apt-transport-https \
    ca-certificates \
    curl \
    gnupg \
    lsb-release

# Docker official GPG key
 curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg


 # Docker repository
echo \
  "deb [arch=amd64 signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu \
  $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

sudo apt-get update


# Install docker
sudo apt-get install docker-ce docker-ce-cli containerd.io


#Verify that docker works
#TODO: Test that docker has successfuly installed
sudo docker run hello-world