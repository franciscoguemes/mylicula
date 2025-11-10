#!/usr/bin/env bash
####################################################################################################
# Args           :
#                   $1  Path to the subdirectory to check.
# Usage          : ./maven.sh /path/to/subdirectory
# Output stdout  : None
# Output stderr  : Debug or error messages.
# Return code    : 0 if directory meets filter criteria (does not meet security criteria), 1 otherwise.
# Description    : This script verifies if the supplied directory is a Maven project:
#                  - The directory contains a file named `pom.xml`
# Author         : Francisco Güemes
# Email          : francisco@franciscoguemes.com
####################################################################################################

# Check if directory path is provided
if [ -z "$1" ]; then
    echo "Error: No directory specified." >&2
    exit 1
fi

dir="$1"

# 1. Check if directory is a Maven project
if [ ! -f "$dir/pom.xml" ]; then
    echo "Directory $dir is not a Maven project" >&2
    exit 1
fi