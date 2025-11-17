#!/usr/bin/env bash
####################################################################################################
#Args           :
#                   --debug         Enable debug logging
#                   --dry-run       Run without making any changes
#                   --cancel        Cancel any pending automatic shutdown
#                   -h, --help      Display help message
#
#Usage          : ./automatic_shutdown.sh
#                 ./automatic_shutdown.sh --debug
#                 ./automatic_shutdown.sh --dry-run
#                 ./automatic_shutdown.sh --cancel
#
#Output stdout  : Success message confirming shutdown scheduled
#Output stderr  : Error messages if scheduling fails
#Return code    : 0   Success
#                 1   Failure (missing dependencies, user cancelled, or scheduling error)
#
#Description    : Schedules an automatic system shutdown with configurable notification.
#                 Presents a UI dialog to configure:
#                   - Time until shutdown (in minutes)
#                   - Notification warning (minutes before shutdown)
#                   - Custom notification message
#
#                 The script schedules both the shutdown and a desktop notification
#                 to warn the user before the system shuts down.
#
#                 This script requires zenity, notify-send, and shutdown to be available.
#                 If any dependency is missing, the script will fail with instructions
#                 on how to install it using nala.
#
#Author         : Francisco Güemes
#Email          : francisco@franciscoguemes.com
#See also       : https://stackoverflow.com/questions/14008125/shell-script-common-template
#                 https://devhints.io/bash
#                 https://linuxhint.com/30_bash_script_examples/
#                 https://stackoverflow.com/questions/192249/how-do-i-parse-command-line-arguments-in-bash
####################################################################################################

set -euo pipefail

#==================================================================================================
# Configuration
#==================================================================================================

# Application name for logging
APP_NAME="mylicula"

# Script metadata
SCRIPT_NAME="$(basename "${BASH_SOURCE[0]}")"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Log configuration
LOG_DIR="/var/log/${APP_NAME}"
LOG_FILE="${LOG_DIR}/${SCRIPT_NAME%.sh}.log"

# Execution modes
DEBUG_MODE=false
DRY_RUN_MODE=false
CANCEL_MODE=false

# PID file to track background notification process
PID_FILE="/tmp/mylicula_shutdown_notifier.pid"

#==================================================================================================
# Logging Functions
#==================================================================================================

#
# Function: log
# Description: Write a log message to the log file with timestamp
# Args:
#   $1 - Log level (INFO, ERROR, DEBUG)
#   $2 - Log message
#
log() {
    local level="$1"
    local message="$2"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')

    echo "[${timestamp}] [${level}] ${message}" | tee -a "$LOG_FILE"
}

#
# Function: debug
# Description: Write a debug message (only if DEBUG_MODE is enabled)
# Args:
#   $1 - Debug message
#
debug() {
    if [[ "$DEBUG_MODE" == true ]]; then
        log "DEBUG" "$1"
    fi
}

#
# Function: log_separator
# Description: Write a separator line with timestamp to the log file
#
log_separator() {
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    echo "" >> "$LOG_FILE"
    echo "================================================================================" >> "$LOG_FILE"
    echo "Script execution: ${timestamp}" >> "$LOG_FILE"
    echo "================================================================================" >> "$LOG_FILE"
}

#==================================================================================================
# Setup Functions
#==================================================================================================

#
# Function: setup_logging
# Description: Initialize logging directory and log file
#
setup_logging() {
    # Create log directory if it doesn't exist
    if [[ ! -d "$LOG_DIR" ]]; then
        if ! sudo mkdir -p "$LOG_DIR" 2>/dev/null; then
            echo "[ERROR] Failed to create log directory: $LOG_DIR" >&2
            echo "[ERROR] Please run: sudo mkdir -p $LOG_DIR && sudo chown $USER:$USER $LOG_DIR" >&2
            exit 1
        fi
        sudo chown "$USER:$USER" "$LOG_DIR"
    fi

    # Create log file if it doesn't exist
    if [[ ! -f "$LOG_FILE" ]]; then
        touch "$LOG_FILE" 2>/dev/null || {
            echo "[ERROR] Failed to create log file: $LOG_FILE" >&2
            exit 1
        }
    fi

    log_separator
}

#
# Function: check_dependencies
# Description: Check if required applications are installed
# Return: 0 if all dependencies are met, 1 otherwise
#
check_dependencies() {
    local missing_deps=()

    # Check for zenity (UI dialogs)
    if ! command -v zenity &> /dev/null; then
        missing_deps+=("zenity")
    fi

    # Check for notify-send (desktop notifications)
    if ! command -v notify-send &> /dev/null; then
        missing_deps+=("libnotify-bin")
    fi

    # Check for shutdown (system shutdown command)
    if ! command -v shutdown &> /dev/null; then
        log "ERROR" "shutdown command not found - this should be installed by default"
        return 1
    fi

    if [[ ${#missing_deps[@]} -gt 0 ]]; then
        log "ERROR" "Missing required dependencies: ${missing_deps[*]}"
        log "ERROR" "Please install them using:"
        log "ERROR" "  sudo nala install ${missing_deps[*]}"
        return 1
    fi

    debug "All dependencies are installed"
    return 0
}

#==================================================================================================
# Help Function
#==================================================================================================

#
# Function: show_help
# Description: Display help message
#
show_help() {
    cat << EOF
Automatic Shutdown Scheduler

Usage: $SCRIPT_NAME [OPTIONS]

Schedule an automatic system shutdown with configurable notification

OPTIONS:
    --debug         Enable debug logging
    --dry-run       Run without making any changes (show what would be scheduled)
    --cancel        Cancel any pending automatic shutdown
    -h, --help      Display this help message

DESCRIPTION:
    This script presents a user-friendly dialog interface to schedule
    an automatic system shutdown with advance notification.

    You will be prompted to configure:
        1. Shutdown time (minutes from now)
        2. Notification warning (minutes before shutdown)
        3. Custom notification message

    The script schedules:
        - A desktop notification to warn you before shutdown
        - An automatic system shutdown at the specified time

REQUIREMENTS:
    - zenity (install with: sudo nala install zenity)
    - libnotify-bin (install with: sudo nala install libnotify-bin)
    - sudo privileges (for shutdown command)

EXAMPLES:
    # Schedule shutdown with UI dialog
    $SCRIPT_NAME

    # Test without actually scheduling
    $SCRIPT_NAME --dry-run

    # Cancel pending shutdown
    $SCRIPT_NAME --cancel

    # Run with debug output
    $SCRIPT_NAME --debug

CANCELLATION:
    To cancel a scheduled shutdown:
        $SCRIPT_NAME --cancel
    Or use:
        sudo shutdown -c

LOG FILE:
    $LOG_FILE

AUTHOR:
    Francisco Güemes <francisco@franciscoguemes.com>

EOF
}

#==================================================================================================
# UI Dialog Functions
#==================================================================================================

#
# Function: get_shutdown_time
# Description: Show dialog to get shutdown time in minutes
# Return: Echoes the number of minutes, or empty string if cancelled
#
get_shutdown_time() {
    local minutes

    minutes=$(zenity --scale \
        --title="Automatic Shutdown - Time" \
        --text="How many minutes from now should the system shut down?" \
        --min-value=1 \
        --max-value=480 \
        --value=60 \
        --step=5 \
        2>/dev/null)

    local result=$?

    if [[ $result -eq 0 ]]; then
        echo "$minutes"
        return 0
    else
        debug "User cancelled shutdown time dialog"
        return 1
    fi
}

#
# Function: get_notification_time
# Description: Show dialog to get notification warning time
# Args:
#   $1 - Maximum notification time (shutdown time in minutes)
# Return: Echoes the number of minutes before shutdown, or empty string if cancelled
#
get_notification_time() {
    local max_time="$1"
    local default_time=$((max_time / 2))

    # Cap default at 30 minutes
    if [[ $default_time -gt 30 ]]; then
        default_time=30
    fi

    # Cap max at shutdown time - 1
    local max_notification=$((max_time - 1))
    if [[ $max_notification -lt 1 ]]; then
        max_notification=1
    fi

    local minutes

    minutes=$(zenity --scale \
        --title="Automatic Shutdown - Notification" \
        --text="How many minutes BEFORE shutdown should you be notified?\n(Shutdown in: ${max_time} minutes)" \
        --min-value=1 \
        --max-value="$max_notification" \
        --value="$default_time" \
        --step=1 \
        2>/dev/null)

    local result=$?

    if [[ $result -eq 0 ]]; then
        echo "$minutes"
        return 0
    else
        debug "User cancelled notification time dialog"
        return 1
    fi
}

#
# Function: get_notification_message
# Description: Show dialog to get custom notification message
# Args:
#   $1 - Shutdown time in minutes
#   $2 - Notification time in minutes before shutdown
# Return: Echoes the notification message, or empty string if cancelled
#
get_notification_message() {
    local shutdown_minutes="$1"
    local notify_minutes="$2"

    local default_msg="System will shut down in ${notify_minutes} minutes!"

    local message

    message=$(zenity --entry \
        --title="Automatic Shutdown - Notification Message" \
        --text="Enter the notification message:\n(Shutdown: ${shutdown_minutes} min from now, Notification: ${notify_minutes} min before)" \
        --entry-text="$default_msg" \
        --width=500 \
        2>/dev/null)

    local result=$?

    if [[ $result -eq 0 ]]; then
        # If user left it empty, use default
        if [[ -z "$message" ]]; then
            message="$default_msg"
        fi
        echo "$message"
        return 0
    else
        debug "User cancelled notification message dialog"
        return 1
    fi
}

#
# Function: show_confirmation
# Description: Show confirmation dialog with all settings
# Args:
#   $1 - Shutdown time in minutes
#   $2 - Notification time in minutes before shutdown
#   $3 - Notification message
# Return: 0 if confirmed, 1 if cancelled
#
show_confirmation() {
    local shutdown_minutes="$1"
    local notify_minutes="$2"
    local notify_message="$3"

    local shutdown_time=$(date -d "+${shutdown_minutes} minutes" '+%H:%M:%S')
    local notify_time_calc=$((shutdown_minutes - notify_minutes))
    local notify_time=$(date -d "+${notify_time_calc} minutes" '+%H:%M:%S')

    zenity --question \
        --title="Automatic Shutdown - Confirm" \
        --width=500 \
        --text="Please confirm the automatic shutdown settings:\n\n\
<b>Shutdown Time:</b> ${shutdown_time} (in ${shutdown_minutes} minutes)\n\
<b>Notification Time:</b> ${notify_time} (${notify_minutes} minutes before shutdown)\n\
<b>Notification Message:</b> ${notify_message}\n\n\
Do you want to proceed?" \
        2>/dev/null

    return $?
}

#==================================================================================================
# Shutdown Functions
#==================================================================================================

#
# Function: schedule_notification
# Description: Schedule a desktop notification before shutdown
# Args:
#   $1 - Time to wait before showing notification (in minutes)
#   $2 - Notification message
# Return: 0 on success
#
schedule_notification() {
    local wait_minutes="$1"
    local message="$2"
    local wait_seconds=$((wait_minutes * 60))

    debug "Scheduling notification in ${wait_minutes} minutes (${wait_seconds} seconds)"

    if [[ "$DRY_RUN_MODE" == true ]]; then
        log "INFO" "[DRY-RUN] Would schedule notification in ${wait_minutes} minutes"
        log "INFO" "[DRY-RUN] Notification message: $message"
        return 0
    fi

    # Create a background process to send the notification
    (
        sleep "$wait_seconds"
        notify-send --urgency=critical --icon=dialog-warning \
            "⚠️ Automatic Shutdown Warning" \
            "$message"

        # Log that notification was sent
        echo "[$(date '+%Y-%m-%d %H:%M:%S')] [INFO] Notification sent: $message" >> "$LOG_FILE"
    ) &

    # Save PID for potential cancellation
    echo $! > "$PID_FILE"

    debug "Notification process started with PID: $(cat $PID_FILE)"

    return 0
}

#
# Function: schedule_shutdown
# Description: Schedule system shutdown
# Args:
#   $1 - Time until shutdown (in minutes)
# Return: 0 on success, 1 on failure
#
schedule_shutdown() {
    local minutes="$1"

    debug "Scheduling shutdown in ${minutes} minutes"

    if [[ "$DRY_RUN_MODE" == true ]]; then
        log "INFO" "[DRY-RUN] Would schedule shutdown in ${minutes} minutes"
        log "INFO" "[DRY-RUN] Command: sudo shutdown -h +${minutes}"
        return 0
    fi

    # Schedule shutdown using shutdown command
    if sudo shutdown -h "+${minutes}" 2>&1 | tee -a "$LOG_FILE"; then
        log "INFO" "✓ Shutdown scheduled successfully for $(date -d "+${minutes} minutes" '+%H:%M:%S')"
        return 0
    else
        log "ERROR" "Failed to schedule shutdown"
        return 1
    fi
}

#
# Function: cancel_shutdown
# Description: Cancel any pending shutdown and notification
# Return: 0 on success
#
cancel_shutdown() {
    log "INFO" "Cancelling automatic shutdown..."

    # Cancel system shutdown
    if sudo shutdown -c 2>&1 | tee -a "$LOG_FILE"; then
        log "INFO" "✓ System shutdown cancelled"
    else
        log "INFO" "No shutdown was scheduled"
    fi

    # Kill notification process if exists
    if [[ -f "$PID_FILE" ]]; then
        local pid=$(cat "$PID_FILE")
        if kill -0 "$pid" 2>/dev/null; then
            debug "Killing notification process PID: $pid"
            kill "$pid" 2>/dev/null || true
            log "INFO" "✓ Notification process cancelled"
        fi
        rm -f "$PID_FILE"
    fi

    log "INFO" "All automatic shutdown tasks cancelled"

    # Show dialog notification
    if command -v zenity &> /dev/null; then
        zenity --info \
            --title="Automatic Shutdown Cancelled" \
            --text="All automatic shutdown tasks have been cancelled." \
            --width=300 \
            2>/dev/null || true
    fi

    return 0
}

#==================================================================================================
# Main Entry Point
#==================================================================================================

main() {
    # Parse command line arguments
    while [[ $# -gt 0 ]]; do
        case $1 in
            -h|--help)
                show_help
                exit 0
                ;;
            --debug)
                DEBUG_MODE=true
                shift
                ;;
            --dry-run)
                DRY_RUN_MODE=true
                shift
                ;;
            --cancel)
                CANCEL_MODE=true
                shift
                ;;
            *)
                echo "[ERROR] Unknown option: $1" >&2
                echo ""
                show_help
                exit 1
                ;;
        esac
    done

    # Setup logging
    setup_logging

    log "INFO" "Starting automatic shutdown scheduler..."
    debug "Debug mode: $DEBUG_MODE"
    debug "Dry-run mode: $DRY_RUN_MODE"
    debug "Cancel mode: $CANCEL_MODE"

    # Check dependencies
    if ! check_dependencies; then
        exit 1
    fi

    # Handle cancel mode
    if [[ "$CANCEL_MODE" == true ]]; then
        cancel_shutdown
        exit 0
    fi

    # Get shutdown time from user
    log "INFO" "Prompting user for shutdown time..."
    shutdown_minutes=$(get_shutdown_time)
    if [[ -z "$shutdown_minutes" ]]; then
        log "INFO" "User cancelled operation"
        exit 1
    fi
    debug "Shutdown time: ${shutdown_minutes} minutes"

    # Get notification time from user
    log "INFO" "Prompting user for notification time..."
    notify_minutes=$(get_notification_time "$shutdown_minutes")
    if [[ -z "$notify_minutes" ]]; then
        log "INFO" "User cancelled operation"
        exit 1
    fi
    debug "Notification time: ${notify_minutes} minutes before shutdown"

    # Get notification message from user
    log "INFO" "Prompting user for notification message..."
    notify_message=$(get_notification_message "$shutdown_minutes" "$notify_minutes")
    if [[ -z "$notify_message" ]]; then
        log "INFO" "User cancelled operation"
        exit 1
    fi
    debug "Notification message: $notify_message"

    # Show confirmation dialog
    log "INFO" "Showing confirmation dialog..."
    if ! show_confirmation "$shutdown_minutes" "$notify_minutes" "$notify_message"; then
        log "INFO" "User cancelled operation at confirmation"
        exit 1
    fi

    # Calculate when to send notification
    notification_wait_minutes=$((shutdown_minutes - notify_minutes))
    debug "Notification will be sent in ${notification_wait_minutes} minutes"

    # Schedule notification
    if ! schedule_notification "$notification_wait_minutes" "$notify_message"; then
        log "ERROR" "Failed to schedule notification"
        exit 1
    fi

    # Schedule shutdown
    if ! schedule_shutdown "$shutdown_minutes"; then
        log "ERROR" "Failed to schedule shutdown"
        # Kill notification process since shutdown failed
        if [[ -f "$PID_FILE" ]]; then
            kill "$(cat "$PID_FILE")" 2>/dev/null || true
            rm -f "$PID_FILE"
        fi
        exit 1
    fi

    # Show success message
    local shutdown_time=$(date -d "+${shutdown_minutes} minutes" '+%H:%M:%S')

    if [[ "$DRY_RUN_MODE" == false ]]; then
        zenity --info \
            --title="Automatic Shutdown Scheduled" \
            --text="✓ Automatic shutdown scheduled successfully!\n\n\
Shutdown at: ${shutdown_time}\n\
Notification: ${notify_minutes} minutes before\n\n\
To cancel, run:\n  $SCRIPT_NAME --cancel" \
            --width=400 \
            2>/dev/null || true
    fi

    log "INFO" "✓ Script completed successfully"
    log "INFO" "Shutdown scheduled for: ${shutdown_time}"
    log "INFO" "Notification scheduled: ${notify_minutes} minutes before shutdown"

    exit 0
}

# Execute main function
main "$@"
