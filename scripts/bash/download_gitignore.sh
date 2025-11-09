#!/bin/bash
####################################################################################################
# Args           :
#                   $1  Programming language (case insensitive) whose .gitignore file should be downloaded.
# Usage          :   ./download_gitignore <programming_language>
# Output stdout  :   Success message if file is downloaded.
# Output stderr  :   Error messages if the programming language's .gitignore file does not exist, or if jq is missing.
# Return code    :   0 on success, 1 on failure.
# Description    :   This script downloads the .gitignore file for a given programming language
#                   from the GitHub repository at https://github.com/franciscoguemes/gitignore.
#                   It dynamically fetches the available languages (directories) from the GitHub API.
#                   Requires 'jq' to be installed to parse JSON data from the GitHub API.
# Dependencies   :   jq (Install: sudo apt-get install jq or sudo yum install jq)
# Author         :   Francisco Güemes
# Email          :   franciscoguemes@franciscoguemes.com
####################################################################################################

# Define the GitHub API URL to get the list of directories (languages)
GITHUB_API_URL="https://api.github.com/repos/franciscoguemes/gitignore/contents"
GITHUB_RAW_BASE_URL="https://raw.githubusercontent.com/franciscoguemes/gitignore/main"

# Check if jq is installed
if ! command -v jq &> /dev/null; then
    echo "Error: 'jq' is not installed. Please install 'jq' to run this script."
    echo "You can install jq by running:"
    echo "  - On Debian/Ubuntu: sudo apt-get install jq"
    echo "  - On RHEL/CentOS: sudo yum install jq"
    exit 1
fi

# Check if a programming language was provided as an argument
if [ -z "$1" ]; then
    echo "Error: No programming language provided."
    echo "Usage: $0 <programming_language>"
    exit 1
fi

# Convert the provided argument to lowercase
LANGUAGE=$(echo "$1" | tr '[:upper:]' '[:lower:]')

# Function to fetch available languages (directories) from the GitHub repository using jq
get_available_languages() {
    curl -s "$GITHUB_API_URL" | jq -r '.[] | select(.type == "dir") | .name'
}

# Fetch available languages dynamically from the GitHub repository
AVAILABLE_LANGUAGES=$(get_available_languages)

# Convert available languages to an array
LANGUAGE_ARRAY=($(echo "$AVAILABLE_LANGUAGES"))

# Check if the requested language exists in the available languages
if [[ ! " ${LANGUAGE_ARRAY[@]} " =~ " ${LANGUAGE} " ]]; then
    echo "Error: .gitignore file for '$LANGUAGE' does not exist in the repository."
    echo -e "Available languages are:\n${LANGUAGE_ARRAY[*]}"
    echo "Feel free to contribute by adding the missing .gitignore file here: https://github.com/franciscoguemes/gitignore"
    exit 1
fi

# Construct the URL for the .gitignore file
GITIGNORE_URL="$GITHUB_RAW_BASE_URL/$LANGUAGE/.gitignore"

# Check if the .gitignore file exists and download it
if curl --output /dev/null --silent --head --fail "$GITIGNORE_URL"; then
    curl -O "$GITIGNORE_URL"
    echo ".gitignore for '$LANGUAGE' downloaded successfully."
else
    echo "Error: .gitignore file for '$LANGUAGE' could not be found at the URL."
    exit 1
fi
