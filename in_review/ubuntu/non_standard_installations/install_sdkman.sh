#!/usr/bin/env bash

#TODO: Add comment here

# https://sdkman.io/install

curl -s "https://get.sdkman.io" | bash

source "$HOME/.sdkman/bin/sdkman-init.sh"

sdk version

#############################################
# Install Java versions
#############################################
# sdk install java 21.0.1-amzn
# sdk install java 17.0.9-amzn
# sdk install java 11.0.21-amzn
# sdk install java 8.0.392-amzn

# sdk install java 21.0.1-open

# sdk install java21.0.1-tem
# sdk install java17.0.9-tem
# sdk install java11.0.21-tem 
# sdk install java8.0.392-tem


# sdk install java 21.0.1-ms
# sdk install java 17.0.9-ms 
# sdk install java 11.0.21-ms

# sdk install java 21.0.1-oracle

#############################################
# Install Maven versions
#############################################
# sdk install maven 3.9.5
# sdk install maven 3.8.8

#############################################
# Install Gradle versions
#############################################
# sdk install gradle 8.4
# sdk install gradle 7.6.3
