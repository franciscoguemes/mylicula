#!/usr/bin/env bash
####################################################################################################
# Args           :
#                   $1  ON or OFF (optional) - Action to perform
#                   -h, --help  Display usage information
# Usage          :   ./maven_config_toggle.sh [ON|OFF]
#                   ./maven_config_toggle.sh -h
# Output stdout  :   Status messages indicating the action performed (e.g., "Custom configuration ON.")
# Output stderr  :   Error messages if source or target files do not exist
# Return code    :   0 on success, 1 on error
# Description    :   This script toggles between Custom and Vanilla configurations for Maven settings.
#                    If no argument is provided, it toggles based on the last action state stored in a file.
#                    If "ON" is provided, it switches to the Custom configuration.
#                    If "OFF" is provided, it switches to the Vanilla configuration.
# Author         : Francisco Güemes
# Email          : francisco@franciscoguemes.com
# See also       : https://stackoverflow.com/questions/14008125/shell-script-common-template
#                 https://devhints.io/bash
#                 https://linuxhint.com/30_bash_script_examples/
#                 https://stackoverflow.com/questions/192249/how-do-i-parse-command-line-arguments-in-bash
####################################################################################################

# Define paths
CUSTOM_CONFIG_FILE="$HOME/.m2/settings.custom.xml"
VANILLA_CONFIG_FILE="$HOME/.m2/settings.vanilla.xml"
TARGET_FILE="$HOME/.m2/settings.xml"
STATE_FILE="$HOME/.m2/.custom_last_action_state"

# Function to display help
show_help() {
    cat << EOF
Usage: $(basename "$0") [ON|OFF] [-h|--help]

Toggle between Custom and Vanilla Maven configurations.

OPTIONS:
    ON              Switch to Custom configuration
    OFF             Switch to Vanilla configuration
    (no argument)   Toggle based on last state
    -h, --help      Display this help message

DESCRIPTION:
    This script manages Maven settings by switching between two configurations:
    - Custom: $CUSTOM_CONFIG_FILE
    - Vanilla:   $VANILLA_CONFIG_FILE

    The active configuration is copied to: $TARGET_FILE
    The last action state is stored in: $STATE_FILE

EXAMPLES:
    $(basename "$0")        # Toggle configuration
    $(basename "$0") ON     # Switch to Custom
    $(basename "$0") OFF    # Switch to Vanilla

AUTHOR:
    Francisco Güemes <francisco@franciscoguemes.com>
EOF
}

# Function to validate if a file exists
validate_file() {
    local file="$1"
    local file_desc="$2"

    if [ ! -f "$file" ]; then
        echo "$file_desc $file does not exist." >&2
        exit 1
    fi
}

# Function to perform the ON action
on_action() {
    validate_file "$CUSTOM_CONFIG_FILE" "Source file"
    cp "$CUSTOM_CONFIG_FILE" "$TARGET_FILE"
    echo "ON" > "$STATE_FILE"
    echo "Custom configuration ON."
}

# Function to perform the OFF action
off_action() {
    validate_file "$VANILLA_CONFIG_FILE" "Source file"
    cp "$VANILLA_CONFIG_FILE" "$TARGET_FILE"
    echo "OFF" > "$STATE_FILE"
    echo "Custom configuration OFF."
}

# Function to toggle action based on last state
toggle_action() {
    if [ -f "$STATE_FILE" ]; then
        LAST_ACTION=$(cat "$STATE_FILE")
        if [ "$LAST_ACTION" == "ON" ]; then
            off_action
        else
            on_action
        fi
    else
        # Default action if no state file exists
        on_action
    fi
}

# Main script logic
if [ "$#" -eq 1 ]; then
    case "$1" in
        ON)
            on_action
            ;;
        OFF)
            off_action
            ;;
        -h|--help)
            show_help
            exit 0
            ;;
        *)
            echo "Invalid parameter. Use ON, OFF, or -h for help." >&2
            show_help
            exit 1
            ;;
    esac
elif [ "$#" -eq 0 ]; then
    toggle_action
else
    echo "Error: Too many arguments." >&2
    show_help
    exit 1
fi
