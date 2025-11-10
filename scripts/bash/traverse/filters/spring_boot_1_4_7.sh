#!/usr/bin/env bash
####################################################################################################
# Name          : spring_boot_1_4_7.sh
# Description   : Filter script to detect if a directory is:
#                   - A Spring Boot project version 1.4.7.
#                   - A project with `microservices-parent` version 0.0.8 as its parent (You may have to adjust this to your pom.xml inheritance logic).
# Arguments     : Directory path to check (provided as the first argument).
# Return Code   :
#                   0 - The directory is a matching project.
#                   1 - The directory does not match the criteria.
# Usage         : ./spring_boot_1_4_7.sh /path/to/project
####################################################################################################

# Check if xmllint is installed
if ! command -v xmllint &>/dev/null; then
    echo "Error: 'xmllint' is not installed. Please install it to use this script." >&2
    exit 1
fi

# Validate input
if [[ -z "$1" ]]; then
    echo "Error: No directory provided." >&2
    exit 1
fi

DIR="$1"

# Check if the directory exists
if [[ ! -d "$DIR" ]]; then
    echo "Error: Directory '$DIR' does not exist." >&2
    exit 1
fi

# Function to extract version from Maven pom.xml
check_pom_xml() {
    local pom_file="$DIR/pom.xml"
    if [[ -f "$pom_file" ]]; then
        # Debug: log the content of the POM file
        echo "Checking POM file: $pom_file"

        # Check for Spring Boot version 1.4.7
        local spring_version
        spring_version=$(xmllint --xpath "string(//dependency[artifactId='spring-boot-starter']/version)" "$pom_file" 2>/dev/null)
        if [[ "$spring_version" == "1.4.7.RELEASE" ]]; then
            return 0
        fi

        # Check for microservices-parent version 0.0.8
        local parent_group parent_artifact parent_version
#        parent_group=$(xmllint --xpath "string(//parent/groupId)" "$pom_file" 2>/dev/null)
#        parent_artifact=$(xmllint --xpath "string(//parent/artifactId)" "$pom_file" 2>/dev/null)
#        parent_version=$(xmllint --xpath "string(//parent/version)" "$pom_file" 2>/dev/null)


        # The pom.xml file uses XML namespaces `xmlns` and therefore this has to be taken into account in the queries with xmllint
        #parent_group=$(xmllint --xpath "string(//*[local-name()='parent']/*[local-name()='groupId'])" "$pom_file" 2>/dev/null)
        parent_artifact=$(xmllint --xpath "string(//*[local-name()='parent']/*[local-name()='artifactId'])" "$pom_file" 2>/dev/null)
        parent_version=$(xmllint --xpath "string(//*[local-name()='parent']/*[local-name()='version'])" "$pom_file" 2>/dev/null)


        echo "Detected parent: groupId=$parent_group, artifactId=$parent_artifact, version=$parent_version"

        if [[ "$parent_artifact" == "microservices-parent" && "$parent_version" == "0.0.8" ]]; then
            return 0
        fi
    fi
    return 1
}

# Function to extract version from Gradle build.gradle
check_build_gradle() {
    local gradle_file="$DIR/build.gradle"
    if [[ -f "$gradle_file" ]]; then
        # Check for Spring Boot version 1.4.7
        local version
        version=$(grep -oP "(?<=spring-boot-starter:)[^']+" "$gradle_file" | grep "1.4.7.RELEASE")
        [[ -n "$version" ]] && return 0
    fi
    return 1
}

# Check for Spring Boot version 1.4.7 or microservices-parent 0.0.8
if check_pom_xml || check_build_gradle; then
    exit 0  # The directory is a matching project
else
    exit 1  # The directory does not match the criteria
fi
