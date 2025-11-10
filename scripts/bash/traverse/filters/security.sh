#!/usr/bin/env bash
####################################################################################################
# Args           :
#                   $1  Path to the subdirectory to check.
# Usage          : ./security.sh /path/to/subdirectory
# Output stdout  : None
# Output stderr  : Debug or error messages.
# Return code    : 0 if directory meets filter criteria (meets security criteria), 1 otherwise.
# Description    : This script verifies if a Zulutrade project uses Spring Boot Security:
#                  - The script has any of the specified Spring Security dependencies in pom.xml.
#                  - A SecurityConfiguration.java file.
#                  - A usage of HttpSecurity class.
#                  The script will flag the directory if it lacks any of these security elements.
# Author         : Francisco Güemes
# Email          : francisco@franciscoguemes.com
####################################################################################################

# Check if directory path is provided
if [ -z "$1" ]; then
    echo "Error: No directory specified." >&2
    exit 1
fi

dir="$1"

# 1. Includes Spring Boot Security Auto-configuration
if grep -q 'spring-boot-starter-security' "$dir/pom.xml"; then
    exit 0
fi

# 2. Includes Spring Boot Security OAuth2
if grep -q 'spring-security-oauth2' "$dir/pom.xml"; then
    exit 0
fi

# 3. Includes Spring Boot Security JWT
if grep -q 'spring-security-jwt' "$dir/pom.xml"; then
    exit 0
fi

# 4. Check for SecurityConfiguration.java file
if find "$dir" -type f -name "SecurityConfiguration.java" | grep -q '.'; then
    exit 0
fi

# 5. Check for HttpSecurity usage in Java files
if grep -rl 'org.springframework.security.config.annotation.web.builders.HttpSecurity' "$dir" --include="*.java" | grep -q '.'; then
    exit 0
fi

echo "Directory $dir does not use Spring Boot Security dependencies in pom.xml or any security configuration in the project." >&2
exit 1