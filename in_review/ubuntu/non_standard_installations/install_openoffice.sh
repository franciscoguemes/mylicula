#!/usr/bin/env bash


#TODO: Add some comments here...

#Store the current directory
CURRENT_DIR=$(pwd)


# Download

#TODO: Download the latest version of OpenOffice from here: https://sourceforge.net/projects/openofficeorg.mirror/files/
#TODO: Download the SHA-256
#TODO: Store the name of the downloaded file in the variable $FILE
#TODO: Verify the SHA-256
FILE="Apache_OpenOffice_4.1.13_Linux_x86-64_install-deb_en-US.tar.gz"
cd ~/Downloads/
tar -xvzf ${FILE}

# Installation
cd en-US/DEBS
sudo dpkg -i *.deb
cd desktop-integration/
sudo dpkg -i *.deb




# Apache_OpenOffice_4.1.13_Linux_x86-64_install-deb_en-US.tar.gz
# Apache_OpenOffice_4.1.13_Linux_x86-64_langpack-deb_bg.tar.gz
# Apache_OpenOffice_4.1.13_Linux_x86-64_langpack-deb_de.tar.gz
# Apache_OpenOffice_4.1.13_Linux_x86-64_langpack-deb_en-US.tar.gz
# Apache_OpenOffice_4.1.13_Linux_x86-64_langpack-deb_es.tar.gz


# Cleanup
cd ~/Downloads/
## Delete the downloaded $FILE
rm $FILE
## Delete the extracted directory en-US
rm -Rf en-US





# Go back to the current directory
cd ${CURRENT_DIR}
