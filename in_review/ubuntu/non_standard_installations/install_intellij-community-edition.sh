#!/usr/bin/env bash

####################################################################################################
# This script requires to have Java installed in your computer for IntelliJ to run!!!
#
#
####################################################################################################

## Download the right executable from https://www.jetbrains.com/idea/download/other.html and pass the file as argument for the script


## The following TODOs are to fully automate the script.

# TODO: Scrape the website https://www.jetbrains.com/idea/download/other.html in order to get the latest version number i.e. 2023.2.4

# TODO: Compose the name of the text of the link. i.e. "2023.2.4 - Linux x86_64 (tar.gz)"

# TODO: Get the web element `<a>`` that holds the given text. i.e. 
# <a class="wt-link" href="https://download.jetbrains.com/idea/ideaIC-2023.2.4-aarch64.tar.gz">2023.2.4 - Linux aarch64 (tar.gz)</a>

# TODO: From the web element get the value of the attribute `href`

# TODO: Download the executable file and assign the absolute path of the file to the variable `DOWNLOADED_FILE`

# TODO: Download the sha256 verification sum by adding the text `.sha256` at the end of the URL. i.e. 
# https://download.jetbrains.com/idea/ideaIC-2023.2.4-aarch64.tar.gz.sha256

# TODO: From the downloaded file that contains the .sha256 extract the sha verification sum and assign it to the variable `SUM`

# TODO: At the end of the script do the cleanup is something fails. I.e. Delete the downloaded files.


# Harcoded values to simulate all the previous TODOs
DOWNLOADED_FILE=/home/francisco/Downloads/ideaIC-2023.2.4.tar.gz
SUM=6c05b527a5c762e7247e302541f712d005e1f8bd9ca8b03d52475dc9aef6afe2

## Verify the downloaded artifact
echo "$SUM $DOWNLOADED_FILE" | sha256sum -c
if [ $? -ne 0 ]; then
    echo "The checksum does not match!!!"; 
    exit 1
fi


# This line get the directory name inside the tar.gz --> https://unix.stackexchange.com/questions/229504/find-extracted-directory-name-from-tar-file
IDEA_DIR_NAME=`tar -tzf $DOWNLOADED_FILE | head -1 | cut -f1 -d"/"`

tar -xzf $DOWNLOADED_FILE -C /home/francisco/development/intellij-community
IDEA_DIR_PATH=/home/francisco/development/intellij-community/$IDEA_DIR_NAME
cd $IDEA_DIR_PATH


## Create the desktop shotcut
DESKTOP_FILE_NAME=IntelliJ.desktop
DESKTOP_FILE_PATH=~/Desktop/$DESKTOP_FILE_NAME
touch $DESKTOP_FILE_PATH
cat << EOF > $DESKTOP_FILE_PATH
#!/usr/bin/env xdg-open
[Desktop Entry]
Version=1.0
Type=Application
Terminal=false
Exec=$IDEA_DIR_PATH/bin/idea.sh
Name=IntelliJ
Comment=IntelliJ
Icon=$IDEA_DIR_PATH/bin/idea.png
EOF

chmod +x $DESKTOP_FILE_PATH
gio set $DESKTOP_FILE_PATH metadata::trusted true

## Add application to the Dash
cd /usr/share/applications
sudo cp $DESKTOP_FILE_PATH .
sudo chown root $DESKTOP_FILE_NAME
sudo chmod 644 $DESKTOP_FILE_NAME


## Cleanup
#rm $DOWNLOADED_FILE