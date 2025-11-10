#!/usr/bin/env bash
####################################################################################################
# Args           :
#                   -d, --directory     Directory to be traversed. Defaults to /$HOME/git/zulutrade/devtools/zulu-migration/zulubackend if not provided.
#                   -e, --execute       Executable scripts to run on each subdirectory. Can specify multiple executables.
#                   -f, --filter        Filters, either as text files with directory names/full paths or as scripts. Can specify multiple filters.
#                   -nf, --not-filter   "Not filters," either as text files with directory names/full paths or as scripts. Can specify multiple "not filters".
#                   --debug             Enable debug mode to include extra output in the log file.
#                   -h, --help          Display this help message.
# Usage          :
#                   ./traverse.sh -d /path/to/directory -f filter1.sh -nf notfilter1.txt -e exec1.sh --debug
#                   ./traverse.sh --directory /path/to/directory --filter filter1.sh --not-filter notfilter1.txt --execute exec1.sh --debug
#                   ./traverse.sh -d /path/to/directory -f filter1.sh -f filter2.sh -nf notfilter1.txt -e exec1.sh -e exec2.sh
#                   ./traverse.sh --help
#
# Output stdout  : Prints each subdirectory name or runs specified executables for each subdirectory.
# Output stderr  : Prints errors for invalid filter files or missing executables.
# Return code    : Returns 0 if successful, non-zero for errors or if invalid options are provided.
# Description    : This script traverses immediate subdirectories of a given directory, applying filters and executables in order.
# Author         : Francisco Güemes
# Email          : francisco@franciscoguemes.com
####################################################################################################

#==================================================================================================
# Resolve script location (handles symlinks)
#==================================================================================================
# Get the real location of this script, even if it's called through a symlink
if [[ -L "${BASH_SOURCE[0]}" ]]; then
    # Script is a symlink - resolve to actual location
    SCRIPT_REAL_PATH="$(readlink -f "${BASH_SOURCE[0]}")"
else
    # Script is the actual file
    SCRIPT_REAL_PATH="${BASH_SOURCE[0]}"
fi

# Get the directory where the actual script resides
SCRIPT_REAL_DIR="$(cd "$(dirname "$SCRIPT_REAL_PATH")" && pwd)"

# Define paths to helper directories relative to the actual script location
FILTERS_DIR="$SCRIPT_REAL_DIR/filters"
EXECUTIONERS_DIR="$SCRIPT_REAL_DIR/executioners"

# Default directory if none provided
DEFAULT_DIR="$HOME/git/zulutrade/devtools/zulu-migration/zulubackend"
LOG_FILE="/tmp/$(basename "$0").log"
DEBUG_MODE=false
FILTERS_ORDERED=()  # Stores both regular and "not" filters in order of appearance
FILTERS_TYPE=()     # Stores the type of filter (regular or "not filter") in order of appearance
EXECUTABLES=()

# Function for logging
log() {
    echo "$@" >> "$LOG_FILE"
}

# Function to add timestamp separator
add_separator() {
    TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S')
    log "************************************* $TIMESTAMP *************************************************************"
}

# Display help message
print_help() {
    echo "Usage: $0 [OPTIONS]"
    echo "Options:"
    echo "  -d, --directory      Directory to be traversed. Defaults to $DEFAULT_DIR if not provided."
    echo "  -e, --execute        Executable scripts to run on each subdirectory. Can specify multiple executables."
    echo "  -f, --filter         Filters, either as text files with directory names/full paths or as scripts. Can specify multiple filters."
    echo "  -nf, --not-filter    'Not filters,' either as text files with directory names/full paths or as scripts. Can specify multiple 'not filters'."
    echo "      --debug          Enable debug mode to include extra output in the log file."
    echo "  -h, --help           Display this help message."
    echo ""
    echo "Examples:"
    echo "  $0 -d /path/to/directory -f filter1.sh -nf notfilter1.txt -e exec1.sh --debug"
    echo "  $0 --directory /path/to/directory --filter filter1.sh --not-filter notfilter1.txt --execute exec1.sh --debug"
    echo "  $0 -d /path/to/directory -f filter1.sh -f filter2.sh -nf notfilter1.txt -e exec1.sh -e exec2.sh"
}

# Parse input arguments
while [[ "$#" -gt 0 ]]; do
    case "$1" in
        -d|--directory) DIRECTORY=$2; shift 2 ;;
        -e|--execute) EXECUTABLES+=("$2"); shift 2 ;;
        -f|--filter) FILTERS_ORDERED+=("$2"); FILTERS_TYPE+=("REGULAR"); shift 2 ;;
        -nf|--not-filter) FILTERS_ORDERED+=("$2"); FILTERS_TYPE+=("NOT_FILTER"); shift 2 ;;
        --debug) DEBUG_MODE=true; shift ;;
        -h|--help) print_help; exit 0 ;;
        *) echo "Unknown option: $1" >&2; exit 1 ;;
    esac
done

# Set default directory if not supplied
DIRECTORY=${DIRECTORY:-$DEFAULT_DIR}

#==================================================================================================
# Expand relative paths for filters and executables
#==================================================================================================
# Function to expand a path - looks in filters/ or executioners/ if just a filename is provided
expand_path() {
    local path="$1"
    local type="$2"  # "filter" or "executable"

    # If path is absolute or contains /, use it as-is
    if [[ "$path" == /* ]] || [[ "$path" == */* ]]; then
        echo "$path"
        return 0
    fi

    # It's just a filename - try to find it in the appropriate directory
    if [[ "$type" == "filter" ]]; then
        if [[ -f "$FILTERS_DIR/$path" ]] || [[ -x "$FILTERS_DIR/$path" ]]; then
            echo "$FILTERS_DIR/$path"
            return 0
        fi
    elif [[ "$type" == "executable" ]]; then
        if [[ -x "$EXECUTIONERS_DIR/$path" ]]; then
            echo "$EXECUTIONERS_DIR/$path"
            return 0
        fi
    fi

    # If not found in helper directories, return original path
    # (might be relative to current directory or will fail later with appropriate error)
    echo "$path"
}

# Expand all filter paths
for ((i=0; i<${#FILTERS_ORDERED[@]}; i++)); do
    FILTERS_ORDERED[i]=$(expand_path "${FILTERS_ORDERED[i]}" "filter")
done

# Expand all executable paths
for ((i=0; i<${#EXECUTABLES[@]}; i++)); do
    EXECUTABLES[i]=$(expand_path "${EXECUTABLES[i]}" "executable")
done

# Function to check if directory should be processed or excluded based on a filter or "not filter"
apply_filter() {
    local dir_path="$1"
    local filter_type="$2"
    local filter="$3"
    local dir_name=$(basename "$dir_path")

    if [ "$filter_type" == "REGULAR" ]; then
        $DEBUG_MODE && log "Applying filter: $filter on directory: $dir_path"
    elif [ "$filter_type" == "NOT_FILTER" ]; then
        $DEBUG_MODE && log "Applying not filter: $filter on directory: $dir_path"
    else
        echo "Invalid filter type: $filter_type" >&2
        exit 1
    fi

    # Check if filter is a script or file
    if [ -x "$filter" ]; then
        # Execute filter script
        "$filter" "$dir_path" >> "$LOG_FILE" 2>&1
        result=$?
    elif [ -f "$filter" ]; then
        # Check if directory matches any entry in the filter file
        result=1
        if grep -Fxq "$dir_path" "$filter" || grep -Fxq "$dir_name" "$filter"; then
            result=0
            $DEBUG_MODE && log "$dir_path matched in $filter_type file $filter"
        fi
    else
        echo "Invalid filter: $filter" >&2
        exit 1
    fi

    # Decide based on filter type and result
    if [ "$filter_type" == "REGULAR" ]; then
        # If a filter fails (result != 0), exclude the directory
        if [ $result -ne 0 ]; then
            log "Directory $dir_path excluded by filter: $filter"
            return 1
        fi
    elif [ "$filter_type" == "NOT_FILTER" ]; then
        # If a "not filter" passes (result == 0), exclude the directory
        if [ $result -eq 0 ]; then
            log "Directory $dir_path excluded by not filter: $filter"
            return 1
        fi
    else
        echo "Invalid filter type: $filter_type" >&2
        exit 1
    fi

    return 0
}

# Run executables in sequence
run_executables() {
    local dir_path="$1"
    for EXECUTABLE in "${EXECUTABLES[@]}"; do
        if [ -x "$EXECUTABLE" ]; then
            $DEBUG_MODE && log "Executing $EXECUTABLE on $dir_path"
            "$EXECUTABLE" "$dir_path" >> "$LOG_FILE" 2>&1
            if [ $? -ne 0 ]; then
                log "Execution of $EXECUTABLE failed on $dir_path. Skipping remaining executors for this directory."
                return 1  # Stop further executors for this subdirectory
            else
                $DEBUG_MODE && log "Execution of $EXECUTABLE succeeded on $dir_path"
            fi
        else
            echo "Executable $EXECUTABLE not found or is not executable." >&2
            log "Executable $EXECUTABLE not found or is not executable. Skipping remaining executors for this directory."
            return 1  # Stop further executors for this subdirectory
        fi
    done
    return 0
}


# Add log separator for new execution
add_separator

# Traverse subdirectories
for sub_dir in "$DIRECTORY"/*/; do
    if [ -d "$sub_dir" ]; then
        $DEBUG_MODE && log "Checking subdirectory: $sub_dir"

        # Apply each filter or "not filter" in the specified order
        for ((i=0; i<${#FILTERS_ORDERED[@]}; i++)); do
            filter="${FILTERS_ORDERED[i]}"
            filter_type="${FILTERS_TYPE[i]}"
            apply_filter "$sub_dir" "$filter_type" "$filter"
            if [ $? -ne 0 ]; then
                # If any filter excludes the directory, skip to the next directory
                continue 2
            fi
        done

        # Run executables if all filters pass
        if [ ${#EXECUTABLES[@]} -ne 0 ]; then
            run_executables "$sub_dir"
            if [ $? -eq 0 ]; then
                $DEBUG_MODE && log "All executables run successfully for $sub_dir ."
            else
                $DEBUG_MODE && log "Execution halted for $sub_dir due to a failure in executables."
            fi
        else
            # In case of not having any executable, just print the directory
            echo "$sub_dir"
        fi
    fi
done

