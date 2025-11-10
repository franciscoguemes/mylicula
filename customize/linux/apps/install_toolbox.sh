#!/usr/bin/env bash
####################################################################################################
#Args           : 
#                   None. This script does not take any arguments.
#Usage          :   
#                   ./install_toolbox.sh
#                   This will download, verify, extract, and run the latest JetBrains Toolbox.
#Output stdout  :   
#                   Messages indicating the progress of the script, such as downloading, verifying, 
#                   extracting, and running the Toolbox application.
#Output stderr  :   
#                   Error messages if required tools are missing, if the download or verification 
#                   fails, or if there is any other issue during the execution of the script.
#Return code    :   
#                   0 - Script executed successfully.
#                   1 - One or more required tools are missing.
#                   2 - Failed to fetch or parse the latest release details.
#                   3 - Failed to extract the version number from the filename.
#                   4 - SHA-256 checksum verification failed.
#                   5 - Extraction of the tarball failed.
#Description	: 
#                   This script automates the download, verification, extraction, and execution 
#                   of the latest version of JetBrains Toolbox on a Linux system. It ensures that 
#                   necessary tools (`wget`, `tar`, `sha256sum`, and `jq`) are installed, fetches 
#                   the latest release details from JetBrains, verifies the integrity of the downloaded 
#                   file, and runs the Toolbox application.
#                                                                                                                                                           
#Author       	: Francisco Güemes                                                
#Email         	: francisco@franciscoguemes.com                                           
#See also	    : https://stackoverflow.com/questions/14008125/shell-script-common-template
#                 https://devhints.io/bash
#                 https://linuxhint.com/30_bash_script_examples/
#                 https://stackoverflow.com/questions/192249/how-do-i-parse-command-line-arguments-in-bash  
####################################################################################################

# Function to check if a command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Verify that wget, tar, sha256sum, and jq are available
MISSING_TOOLS=()

for tool in wget tar sha256sum jq; do
    if ! command_exists $tool; then
        MISSING_TOOLS+=($tool)
    fi
done

if [ ${#MISSING_TOOLS[@]} -ne 0 ]; then
    echo "The following tools are missing: ${MISSING_TOOLS[@]}"
    echo "You can install them using 'apt' or 'nala' (for Debian-based systems)."
    echo "For example:"
    echo "  sudo apt update && sudo apt install ${MISSING_TOOLS[@]}"
    echo "  sudo nala install ${MISSING_TOOLS[@]}"
    exit 1
fi

# Create a temporary directory in the current working directory
TMP_DIR="$(pwd)/.tmp"
mkdir -p $TMP_DIR

# Get the current timestamp in milliseconds
TIMESTAMP=$(($(date +%s%N)/1000000))

# Step 1: Fetch the latest release details
RELEASE_URL="https://data.services.jetbrains.com/products/releases?code=TBA&latest=true&type=release&build=&_=$TIMESTAMP"
echo "Fetching latest release details..."
wget --header="User-Agent: Mozilla/5.0" -O "$TMP_DIR/release.json" "$RELEASE_URL"

# Step 2: Parse the JSON response to get the download URL and checksum URL for the Linux version
DOWNLOAD_URL=$(jq -r '.TBA[0].downloads.linux.link' "$TMP_DIR/release.json")
CHECKSUM_URL=$(jq -r '.TBA[0].downloads.linux.checksumLink' "$TMP_DIR/release.json")

if [ -z "$DOWNLOAD_URL" ] || [ -z "$CHECKSUM_URL" ]; then
    echo "Failed to extract download URL or checksum URL from the release details."
    rm -rf $TMP_DIR
    exit 2
fi

echo "Download URL: $DOWNLOAD_URL"
echo "Checksum URL: $CHECKSUM_URL"

# Step 3: Download the *.tar.gz file and its checksum
echo "Downloading JetBrains Toolbox..."
wget --header="User-Agent: Mozilla/5.0" -O "$TMP_DIR/jetbrains-toolbox.tar.gz" "$DOWNLOAD_URL"
echo "Downloading checksum file..."
wget --header="User-Agent: Mozilla/5.0" -O "$TMP_DIR/jetbrains-toolbox.sha256" "$CHECKSUM_URL"

# Step 4: Get the version number from the name of the downloaded file
FILENAME=$(basename "$DOWNLOAD_URL")
VERSION_NUMBER=$(echo $FILENAME | grep -oP '\d+\.\d+\.\d+\.\d+')

if [ -z "$VERSION_NUMBER" ]; then
    echo "Failed to extract version number from the filename."
    rm -rf $TMP_DIR
    exit 3
fi

echo "Downloaded JetBrains Toolbox version: $VERSION_NUMBER"

# Step 5: Verify the SHA-256 sum of the downloaded artifact
echo "Verifying SHA-256 checksum..."
SHA256_SUM=$(sha256sum "$TMP_DIR/jetbrains-toolbox.tar.gz" | awk '{ print $1 }')
EXPECTED_SHA256_SUM=$(cat "$TMP_DIR/jetbrains-toolbox.sha256" | awk '{ print $1 }')

if [ "$SHA256_SUM" != "$EXPECTED_SHA256_SUM" ]; then
    echo "SHA-256 checksum verification failed!"
    rm -rf $TMP_DIR
    exit 4
else
    echo "SHA-256 checksum verification passed!"
fi

# Step 6: Extract the contents of the *.tar.gz file
INSTALL_DIR="$HOME/development/jetbrains-toolbox"
mkdir -p $INSTALL_DIR
echo "Extracting JetBrains Toolbox to $INSTALL_DIR..."
tar -xzf "$TMP_DIR/jetbrains-toolbox.tar.gz" -C $INSTALL_DIR

# Get the extracted directory name
EXTRACTED_DIR=$(tar -tf "$TMP_DIR/jetbrains-toolbox.tar.gz" | head -1 | cut -f1 -d"/")
TOOLBOX_PATH="$INSTALL_DIR/$EXTRACTED_DIR"

if [ ! -d "$TOOLBOX_PATH" ]; then
    echo "Failed to extract the tarball."
    rm -rf $TMP_DIR
    exit 5
fi

# Step 7: Execute the installed application
echo "Executing JetBrains Toolbox..."
$TOOLBOX_PATH/jetbrains-toolbox &

# Clean up
rm -rf $TMP_DIR

echo "JetBrains Toolbox installation completed successfully!"

