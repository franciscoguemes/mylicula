#!/usr/bin/env bash
####################################################################################################
# This script has to go after the install_openoffice script
#
#
####################################################################################################



#TODO: Add some comments here...

#Store the current directory
CURRENT_DIR=$(pwd)


#TODO: You need to know which version has been installed:
#TODO: Download the corresponding language packs from for the installed version of OpenOffice from here: https://sourceforge.net/projects/openofficeorg.mirror/files/
#TODO: Download the SHA-256 ???
#TODO: Ask the user which languages wants ???
#      For the time being I downloaded and installed 
# Download the language packs: es, de, bg
#TODO: Store the downloaded names in an array... At the moment I do it in variables
#TODO: Verify the SHA-256 ???
LP_BG="Apache_OpenOffice_4.1.13_Linux_x86-64_langpack-deb_bg.tar.gz"
LP_DE="Apache_OpenOffice_4.1.13_Linux_x86-64_langpack-deb_de.tar.gz"
LP_ES="Apache_OpenOffice_4.1.13_Linux_x86-64_langpack-deb_es.tar.gz"



cd ~/Downloads/
tar -xvzf ${LP_BG}
tar -xvzf ${LP_DE}
tar -xvzf ${LP_ES}



# Installation
cd de/DEBS/
sudo dpkg -i *.deb
cd ../..
cd es/DEBS/
sudo dpkg -i *.deb
cd ../..
cd bg/DEBS/
sudo dpkg -i *.deb




# Cleanup
cd ~/Downloads/
#T0OD: Delete the downloaded files
rm ${LP_BG}
rm ${LP_DE}
rm ${LP_ES}
#TODO: Delete the extracted directories
rm -Rf bg
rm -Rf de
rm -Rf es





# Go back to the current directory
cd ${CURRENT_DIR}
