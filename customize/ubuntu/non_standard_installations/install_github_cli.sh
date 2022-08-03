#!/usr/bin/env bash

#TODO: Add a proper header...


# NOTE: This script is tested and works like a charm!


# Download the pgp key and adding the github repository
curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg | sudo dd of=/usr/share/keyrings/githubcli-archive-keyring.gpg
echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | sudo tee /etc/apt/sources.list.d/github-cli.list > /dev/null


# Update repositories
sudo apt update

# Install github CLI
sudo apt install gh

