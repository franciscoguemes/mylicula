#!/usr/bin/env bash
####################################################################################################
#Args           :
#                   -d | --directory <directory>   The directory where to create the Maven global configuration.
#                                                  Defaults to "$HOME/.m2" if not provided.
#                   --debug                        Enable debug logging.
#                   --dry-run                      Run script without making changes.
#                   -h | --help                    Display this help message.
#Usage          :   ./create_maven_global_configuration.sh -d /custom/path --debug
#Output stdout  :   Informational messages about script execution.
#Output stderr  :   Error messages in case of failure.
#Return code    :   0 if success, non-zero otherwise.
#Description    :   Creates a Maven global configuration directory and copies predefined settings files.
#Author         :   Francisco Güemes
#Email          :   francisco@franciscoguemes.com
#See also       :   https://stackoverflow.com/questions/14008125/shell-script-common-template
#                 https://devhints.io/bash
#                 https://linuxhint.com/30_bash_script_examples/
#                 https://stackoverflow.com/questions/192249/how-do-i-parse-command-line-arguments-in-bash
####################################################################################################

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Find BASE_DIR - Priority 1: env var, Priority 2: search for lib/common.sh
if [[ -n "${MYLICULA_BASE_DIR:-}" ]]; then
    BASE_DIR="$MYLICULA_BASE_DIR"
else
    # Search upwards for lib/common.sh (max 3 levels)
    BASE_DIR="$SCRIPT_DIR"
    for i in {1..3}; do
        if [[ -f "${BASE_DIR}/lib/common.sh" ]]; then
            break
        fi
        BASE_DIR="$(dirname "$BASE_DIR")"
    done

    if [[ ! -f "${BASE_DIR}/lib/common.sh" ]]; then
        echo "[ERROR] Cannot find MyLiCuLa project root" >&2
        echo "Please set MYLICULA_BASE_DIR environment variable or run via install.sh" >&2
        exit 1
    fi
fi

# Variables
default_dir="$HOME/.m2"
destination_dir="$default_dir"
log_file="/tmp/$(basename "$0" .sh).log"
debug=false
dry_run=false
resources_dir="$BASE_DIR/resources/maven"

# Ensure script is not run as root
if [ "$EUID" -eq 0 ]; then
    echo "This script cannot be run as root. Please run it as a regular user." >&2
    exit 1
fi

# Log separator with timestamp
echo "$(date '+%Y-%m-%d %H:%M:%S') - Script execution started" | tee -a "$log_file"

# Function to log messages
log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$log_file"
}

# Function to handle dry-run execution
dry_run_exec() {
    if [ "$dry_run" = true ]; then
        log "[DRY-RUN] $1"
    else
        eval "$1"
    fi
}

# Function to print help
usage() {
    grep "^#Args" "$0" | sed 's/#Args           : //'
    exit 0
}

# Parse arguments
while [[ "$#" -gt 0 ]]; do
    case "$1" in
        -d|--directory)
            shift
            destination_dir="$1"
            ;;
        --debug)
            debug=true
            ;;
        --dry-run)
            dry_run=true
            ;;
        -h|--help)
            usage
            ;;
        *)
            echo "Unknown option: $1" >&2
            usage
            ;;
    esac
    shift
done

if [ "$debug" = true ]; then
    log "Debug mode enabled"
    log "Target directory: $destination_dir"
    log "Dry-run mode: $dry_run"
fi

# Create directory if it does not exist
dry_run_exec "mkdir -p '$destination_dir'"

# Copy files
dry_run_exec "cp '$resources_dir/settings.vanilla.xml' '$destination_dir/'"
dry_run_exec "cp '$resources_dir/settings.custom.xml' '$destination_dir/'"
dry_run_exec "cp '$destination_dir/settings.vanilla.xml' '$destination_dir/settings.xml'"

log "Maven global configuration setup completed successfully in $destination_dir"
exit 0
