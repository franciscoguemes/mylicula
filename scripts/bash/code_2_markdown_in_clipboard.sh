#!/usr/bin/env bash
####################################################################################################
#Args           :
#                   $1  Optional text to process. If not provided, text is taken from the clipboard.
#Usage          :   ./code_2_markdown_in_clipboard.sh [-e] [--debug] [--help] [text_to_process]
#Output stdout  :   When the `-e` option is used, outputs the formatted Markdown to the console.
#Output stderr  :   Error messages for invalid usage or missing dependencies.
#Return code    :   0 for success, non-zero for failure.
#Description    :   Formats input text as Markdown (inline code or code snippet) and handles clipboard.
#                   Logs operations and supports debug mode.
#
#Author         : Francisco Güemes
#Email          : francisco@franciscoguemes.com
#See also       : https://stackoverflow.com/questions/14008125/shell-script-common-template
#                 https://devhints.io/bash
#                 https://linuxhint.com/30_bash_script_examples/
#                 https://stackoverflow.com/questions/192249/how-do-i-parse-command-line-arguments-in-bash
####################################################################################################

# Constants
LOG_FILE="/tmp/$(basename "$0" .sh).log"
TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S')

# Initialize variables
DEBUG=0
ECHO_OUTPUT=0
TEXT_INPUT=""

# Functions
log() {
    local message="$1"
    echo "$TIMESTAMP | $message" >> "$LOG_FILE"
    [[ $DEBUG -eq 1 ]] && echo "DEBUG: $message"
}

usage() {
    echo "Usage: $(basename "$0") [-e] [--debug] [--help] [text_to_process]"
    echo "Formats text as Markdown (inline code or code snippet) and handles clipboard."
    echo "Options:"
    echo "  -e           Echo the formatted Markdown to the console."
    echo "  --debug      Enable debug logging."
    echo "  -h, --help   Show this help message."
}

# Parse arguments
while [[ "$#" -gt 0 ]]; do
    case $1 in
        -e) ECHO_OUTPUT=1 ;;
        --debug) DEBUG=1 ;;
        -h|--help) usage; exit 0 ;;
        --*) echo "Unknown option: $1"; exit 1 ;;
        *) TEXT_INPUT="$1" ;;
    esac
    shift
done

# Log start of execution
log "Script execution started."

# Ensure required tools are available
if ! command -v xclip &>/dev/null; then
    echo "Error: xclip is required but not installed." >&2
    log "Error: xclip is missing."
    exit 1
fi

# If no input text is provided, get it from the clipboard
if [[ -z "$TEXT_INPUT" ]]; then
    TEXT_INPUT=$(xclip -selection clipboard -o 2>/dev/null || echo "")
    log "Read text from clipboard."
    if [[ -z "$TEXT_INPUT" ]]; then
        echo "Error: Clipboard is empty or xclip failed to read content." >&2
        log "Error: Clipboard is empty or unreadable."
        exit 1
    fi
else
    log "Received text as argument: \"$TEXT_INPUT\""
fi

# Format text as Markdown
if [[ $(echo "$TEXT_INPUT" | wc -l) -eq 1 ]]; then
    if [[ "$TEXT_INPUT" =~ ^\`\`\`.*\`\`\`$ ]]; then
        TEXT_INPUT=${TEXT_INPUT:3:-3} # Remove the three backticks from the beginning and the end
        FORMATTED_TEXT="\`\`\`\n$TEXT_INPUT\n\`\`\`"
        FORMATTED_TEXT="$FORMATTED_TEXT\n"
        log "Formatted inline code snippet to a Markdown code snippet."
    elif [[ "$TEXT_INPUT" =~ ^\`.*\`$ ]]; then
        # Text is already inline code, convert to a code snippet
        TEXT_INPUT=${TEXT_INPUT:1:-1} # Remove the backticks
        FORMATTED_TEXT="\`\`\`\n$TEXT_INPUT\n\`\`\`"
        FORMATTED_TEXT="$FORMATTED_TEXT\n"
        log "Converted inline Markdown to a code snippet."
    else
        # Text is plain single-line, format as inline code
        FORMATTED_TEXT="\`$TEXT_INPUT\`"
        log "Formatted text as Markdown inline code."
    fi
else
    # Multiline text, format as a code snippet
    FORMATTED_TEXT="\`\`\`\n$TEXT_INPUT\n\`\`\`"
    FORMATTED_TEXT="$FORMATTED_TEXT\n"
    log "Formatted text as a Markdown code snippet."
fi

# Output the result
if [[ $ECHO_OUTPUT -eq 1 ]]; then
    echo -ne "$FORMATTED_TEXT"
    log "Printed formatted text to the console."
else
    echo -ne "$FORMATTED_TEXT" | xclip -selection clipboard
    log "Placed formatted text in the clipboard."
fi

# Log end of execution
log "Script execution finished."
