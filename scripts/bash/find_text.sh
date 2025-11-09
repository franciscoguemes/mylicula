#!/usr/bin/env bash
####################################################################################################
#Args           : 
#                   -d, --directory : Directory where to search the text in all files. If no directory is supplied then current working directory (`.`) will be used.
#                   -t, --text : Text to search. If no text is provided then the script will show an error on script printing a message on how to use the script.
#                   -h, --help : Shows the typical help on how to use the script and all the available options.
#                   -i, --interactive : The script will enter on interactive mode. On this mode the script will use Zenity dialogs to ask the user for the directory to search, the text to search and a final dialog to show the results of the search.
#Usage          :   ./find_text.sh -t "search_text" -d "/path/to/directory"
#Output stdout  :   Search results or usage information.
#Output stderr  :   Error messages if any.
#Return code    :   0 on success, 1 on error.
#Description    : This script searches for specified text in all files within a given directory and logs the results.
#                                                                                                                                                           
#Author       	: Francisco Güemes                                                
#Email         	: francisco@franciscoguemes.com                                           
#See also	    : https://stackoverflow.com/questions/14008125/shell-script-common-template
#                 https://devhints.io/bash
#                 https://linuxhint.com/30_bash_script_examples/
#                 https://stackoverflow.com/questions/192249/how-do-i-parse-command-line-arguments-in-bash  
####################################################################################################

LOG_FILE="/tmp/find_text.log"
DEBUG_MODE=0

# Function to log messages
log() {
    local message="$1"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    echo "[$timestamp] $message" >> "$LOG_FILE"
    if [ "$DEBUG_MODE" -eq 1 ]; then
        echo "DEBUG: $message"
    fi
}

# Function to display help
show_help() {
    echo "Usage: $0 [-d directory] [-t text] [-h] [-i] [--debug]"
    echo "Options:"
    echo "  -d, --directory    Directory to search in (default: current directory)"
    echo "  -t, --text         Text to search for (required)"
    echo "  -h, --help         Show this help message"
    echo "  -i, --interactive   Use interactive mode with Zenity dialogs"
    echo "  --debug            Enable debug logging"
}

# Parse command line arguments
while [[ "$#" -gt 0 ]]; do
    case $1 in
        -d|--directory) DIR="$2"; shift ;;
        -t|--text) TEXT="$2"; shift ;;
        -h|--help) show_help; exit 0 ;;
        -i|--interactive) INTERACTIVE=1 ;;
        --debug) DEBUG_MODE=1 ;;
        *) echo "Unknown parameter passed: $1"; show_help; exit 1 ;;
    esac
    shift
done

# Set default values
DIR="${DIR:-.}"

# Check if text is provided unless in interactive mode
if [ -z "$TEXT" ] && [ -z "$INTERACTIVE" ]; then
    echo "Error: Text to search is required."
    show_help
    exit 1
fi

# Log the start of the script
log "Script started with directory: $DIR and text: $TEXT"

# Interactive mode
if [ "$INTERACTIVE" -eq 1 ]; then
    zenity --info --text="Interactive GUI mode. Please follow the instructions to search for the text in the selected directory."
    DIR=$(zenity --file-selection --directory --title="Select Directory to Search" --filename="$DIR/")
    TEXT=$(zenity --entry --title="Search Text" --text="Enter the text to search for:")
    
    if [ -z "$DIR" ] || [ -z "$TEXT" ]; then
        zenity --error --text="Search cancelled."
        log "Search cancelled by user."
        exit 1
    fi
fi

log "Searching directory: $DIR and text: $TEXT"
# Perform the search and capture the output
RESULTS=$(grep -rnw "$DIR" -e "$TEXT" 2>&1)

# Check if there are any results or if there was an error
if [ -z "$RESULTS" ]; then
    zenity --info --text="No results found for '$TEXT' in '$DIR'."
    log "No results found for '$TEXT' in '$DIR'."
else
    # Remove any backticks and escape necessary characters
    FORMATTED_RESULTS=$(printf '%s\n' "$RESULTS" | sed 's/\\/\\\\/g; s/\&/\\&/g; s/\$/\\$/g')

    # Debug log the formatted results
    # log "Formatted results for Zenity: $FORMATTED_RESULTS"

    # Show the results in a Zenity text info dialog using standard input
    echo "$FORMATTED_RESULTS" | zenity --text-info --title="Search Results" --width=600 --height=400 || {
        zenity --error --text="An error occurred while displaying results."
        log "Error displaying results in Zenity."
    }

    log "Results found for '$TEXT' in '$DIR': $RESULTS"
fi

# Log the end of the script
log "Script finished."
