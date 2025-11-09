#!/usr/bin/env bash
####################################################################################################
# Args          :
#                   $1  URL (optional). If provided, this URL will be used for the generated HTML link file.
#                   n/a If no URL is provided as an argument, the script attempts to read the URL from the clipboard.
# Usage         :
#                   ./generate_link.sh https://www.example.com
#                       - This will create an HTML file named after the page title from the URL https://www.example.com.
#
#                   ./generate_link.sh
#                       - This will read a URL from the clipboard and create the link file based on the URL's page title.
#
# Output stdout :
#                   Prints a success message indicating the HTML file name created.
#
# Output stderr :
#                   Prints errors such as missing dependencies, invalid URL, or title not found.
#
# Return code   :
#                   0   Success
#                   1   Failure (dependency missing, invalid URL, title not found, etc.)
#
# Description   :
#                   This script generates an HTML file that redirects to a URL specified either via a command-line
#                   argument or from the clipboard. The file is named after the webpage's title as fetched from the
#                   URL (or falls back to "link" if no title found). It is based on an HTML template located in
#                   /home/$USER/Templates/link.html.
#
# Author        : Francisco Güemes
# Email         : francisco@franciscoguemes.com
####################################################################################################

LOG_FILE="/tmp/generate_link.log"
CONFIG_FILE="$HOME/.config/generate_link.conf"
exec > "$LOG_FILE" 2>&1  # Redirect all output to a log file for debugging

# Check if xclip is installed for clipboard functionality
if ! command -v xclip &> /dev/null; then
    echo "xclip is required but not installed. Exiting." >&2
    exit 1
fi

# Function to read last used directory from config file
get_last_directory() {
    if [ -f "$CONFIG_FILE" ]; then
        cat "$CONFIG_FILE"
    else
        echo "$HOME/Documents"
    fi
}

# Function to save last used directory to config file
save_last_directory() {
    local dir="$1"
    mkdir -p "$(dirname "$CONFIG_FILE")"
    echo "$dir" > "$CONFIG_FILE"
}

# Function to select target directory
select_target_directory() {
    local dir
    local last_dir

    # Attempt to get current directory with gio
    dir=$(gio info . 2>/dev/null | grep 'standard::target-uri' | cut -d ' ' -f2 | sed 's|file://||')

    # If gio failed, try xdotool
    if [ -z "$dir" ]; then
        dir=$(xdotool getwindowfocus getwindowname 2>/dev/null | sed -n 's|.*\(file://[^ ]*\)|\1|p' | sed 's|file://||')
    fi

    # If both failed, prompt the user with zenity, default to last used directory
    if [ -z "$dir" ]; then
        last_dir=$(get_last_directory)
        echo "DEBUG: Last used directory: $last_dir" >> "$LOG_FILE"
        dir=$(zenity --file-selection --directory --title="Select directory to save link" --filename="$last_dir/" 2> /dev/null)
        # Check if user clicked Cancel
        if [ $? -ne 0 ]; then
            echo "User cancelled directory selection" >&2
            return 1
        fi
        echo "DEBUG: Chosen directory by the user: $dir" >> "$LOG_FILE"
    fi

    # If no directory was selected, use last used directory
    if [ -z "$dir" ]; then
        dir="$last_dir"
    fi

    # Save the selected directory for next time
    save_last_directory "$dir"

    echo "$dir"
}

# Function to sanitize filename
sanitize_filename() {
    local filename="$1"
    # Replace spaces with underscores
    filename="${filename// /_}"
    # Replace any character that's not alphanumeric, underscore, or hyphen with underscore
    filename=$(echo "$filename" | sed 's/[^a-zA-Z0-9_-]/_/g')
    # Remove multiple consecutive underscores
    filename=$(echo "$filename" | sed 's/__*/_/g')
    # Remove leading and trailing underscores
    filename=$(echo "$filename" | sed 's/^_*//;s/_*$//')
    echo "$filename"
}

# Function to get page title by domain-specific rules
get_page_title_by_domain() {
    local url="$1"
    local domain
    local html_content
    local page_title

    # Extract domain from URL
    domain=$(echo "$url" | sed -E 's|^https?://([^/]+).*|\1|')
    echo "DEBUG: Domain extracted: $domain" >> "$LOG_FILE"

    case "$domain" in
        *alibaba.com*)
            echo "DEBUG: Processing Alibaba.com URL" >> "$LOG_FILE"
            # For Alibaba, get the title attribute from h1 inside product-title-container div
            html_content=$(curl -sL -H "User-Agent: Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36" \
                -H "Accept: text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,*/*;q=0.8" \
                -H "Accept-Language: en-US,en;q=0.5" \
                -H "Connection: keep-alive" \
                -H "Upgrade-Insecure-Requests: 1" \
                "$url")
            
            page_title=$(echo "$html_content" | grep -oP '<div[^>]*class="product-title-container"[^>]*>.*?<h1[^>]*title="\K[^"]+' | head -n 1)
            
            # If title extraction failed, try alternative method
            if [ -z "$page_title" ]; then
                page_title=$(echo "$html_content" | grep -oP '<div[^>]*class="product-title-container"[^>]*>.*?<h1[^>]*>\K[^<]+' | head -n 1)
            fi
            ;;
        *atlassian.net*)
            echo "DEBUG: Processing Jira URL" >> "$LOG_FILE"
            # For Jira, we only extract the issue key (e.g., PROJ-123) without attempting to get the full title.
            # This is by design due to several technical limitations:
            # 1. Jira's modern UI is a Single Page Application (SPA) that loads data dynamically
            # 2. The initial HTML is just a shell, with no issue data
            # 3. The actual issue title is loaded via authenticated API calls
            # 4. These API calls require:
            #    - Valid JWT tokens for authentication
            #    - Proper session cookies
            #    - Correct CSRF tokens
            # 5. Alternative approaches considered and rejected:
            #    - Using headless browsers: Would still lack authentication tokens
            #    - Storing credentials: Security risk and against best practices
            #    - Browser automation: Too complex and fragile for this use case
            # Therefore, we use just the issue key, which is:
            #    - Always available in the URL
            #    - Unique and meaningful
            #    - Sufficient for identification
            #    - Doesn't require authentication
            local issue_key=$(echo "$url" | grep -oP '/browse/([A-Z]+-[0-9]+)' | cut -d'/' -f3)
            if [ -n "$issue_key" ]; then
                page_title="$issue_key"
            fi
            ;;
        *)
            echo "DEBUG: Unknown domain, returning empty string" >> "$LOG_FILE"
            page_title=""
            ;;
    esac

    echo "DEBUG: Extracted title: '$page_title'" >> "$LOG_FILE"
    echo "$page_title"
}

# Function to create a valid filename
create_valid_filename() {
    local title="$1"
    local max_length=100  # Maximum length for the base filename (excluding .html)
    
    # Replace HTML entities with their actual characters
    title=$(echo "$title" | sed "s/&#39;/'/g")
    
    # Sanitize the filename
    local filename=$(sanitize_filename "$title")
    
    # Truncate the filename if it's too long (leaving room for .html extension)
    if [ ${#filename} -gt $max_length ]; then
        filename="${filename:0:$max_length}"
    fi
    
    # Add the .html extension
    filename="${filename}.html"
    echo "$filename"
}

# Function to fetch webpage title
get_page_title() {
    local url="$1"
    local html_content
    local page_title
    
    echo "DEBUG: Attempting domain-specific title extraction" >> "$LOG_FILE"
    page_title=$(get_page_title_by_domain "$url")
    echo "DEBUG: Domain-specific title result: '$page_title'" >> "$LOG_FILE"

    if [ -z "$page_title" ]; then
        echo "DEBUG: Domain-specific extraction failed, trying general methods" >> "$LOG_FILE"
        # Use proper browser headers to avoid 403 errors
        html_content=$(curl -sL \
            -H "User-Agent: Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36" \
            -H "Accept: text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,*/*;q=0.8" \
            -H "Accept-Language: en-US,en;q=0.5" \
            -H "Connection: keep-alive" \
            -H "Upgrade-Insecure-Requests: 1" \
            "$url")
        
        # Try to extract the <title> tag first, handling newlines and special characters
        page_title=$(echo "$html_content" | tr -d '\n' | grep -oP '<title[^>]*>\s*\K[^<]+(?=\s*</title>)' | head -n 1)
        echo "DEBUG: Title tag extraction result: '$page_title'" >> "$LOG_FILE"
    fi

    # If title is still empty, try to fetch from <meta property="og:title">
    if [ -z "$page_title" ]; then
        echo "DEBUG: Trying og:title extraction" >> "$LOG_FILE"
        page_title=$(echo "$html_content" | tr -d '\n' | grep -oP '<meta[^>]*property="og:title"[^>]*content="\K[^"]+' | head -n 1)
        echo "DEBUG: og:title extraction result: '$page_title'" >> "$LOG_FILE"
    fi

    # If title is still empty, try to fetch from <meta name="application-name">
    if [ -z "$page_title" ]; then
        echo "DEBUG: Trying application-name extraction" >> "$LOG_FILE"
        page_title=$(echo "$html_content" | tr -d '\n' | grep -oP '<meta[^>]*name="application-name"[^>]*content="\K[^"]+' | head -n 1)
        echo "DEBUG: application-name extraction result: '$page_title'" >> "$LOG_FILE"
    fi

    # If title is still empty, log an error message
    if [ -z "$page_title" ]; then
        echo "Error: Page title could not be retrieved from URL: $url" >&2
        page_title="link"  # Default to "link" if no title is found
    fi

    echo "DEBUG: Final title: '$page_title'" >> "$LOG_FILE"
    echo "$page_title"
}

# Get URL from argument or clipboard
URL="$1"
if [ -z "$URL" ]; then
    echo "No URL provided as argument. Trying to read from clipboard..."
    URL=$(xclip -o -selection clipboard)
    if [ -z "$URL" ]; then
        echo "Error: No URL found in clipboard. Clipboard content is: '$URL'" >&2
        exit 1
    fi
fi

# Clean the URL: Extract only the valid URL pattern, ignoring any extra content
# This matches from http(s):// until the first whitespace or end of line
CLEAN_URL=$(echo "$URL" | grep -oP 'https?://\S+' | head -n 1)
if [ -z "$CLEAN_URL" ]; then
    echo "Error: Invalid URL provided or found in clipboard. Content is: '$URL'" >&2
    exit 1
fi
URL="$CLEAN_URL"

# Check if URL is valid
if ! [[ "$URL" =~ ^https?:// ]]; then
    echo "Error: Invalid URL provided or found in clipboard. Content is: '$URL'" >&2
    exit 1
fi

# Get the webpage title to use as the filename
PAGE_TITLE=$(get_page_title "$URL")

# Create a valid filename with length limitation
FILENAME=$(create_valid_filename "$PAGE_TITLE")

# Get target directory
TARGET_DIR=$(select_target_directory)
if [ $? -ne 0 ]; then
    zenity --error --text="Operation cancelled by user" 2> /dev/null
    exit 1
fi

OUTPUT_FILE="$TARGET_DIR/$FILENAME"

# Copy the template from /home/$USER/Templates/link.html and replace 'YOUR_URL_HERE' with the actual URL
TEMPLATE_FILE="/home/$USER/Templates/link.html"

# Escape special characters in the URL for sed
ESCAPED_URL=$(printf '%s\n' "$URL" | sed 's/[&/\]/\\&/g')

# Before creating the file, verify the path and content
echo "DEBUG: Creating file at: $OUTPUT_FILE" >> "$LOG_FILE"
echo "DEBUG: File content will use URL: $URL" >> "$LOG_FILE"

# Add error checking for file creation
if [ -f "$TEMPLATE_FILE" ]; then
    if sed "s|YOUR_URL_HERE|$ESCAPED_URL|" "$TEMPLATE_FILE" > "$OUTPUT_FILE"; then
        echo "DEBUG: File created successfully" >> "$LOG_FILE"
        zenity --info --text="HTML link file '$OUTPUT_FILE' created successfully." 2> /dev/null
    else
        echo "DEBUG: Failed to create file" >> "$LOG_FILE"
        zenity --error --text="Failed to create file '$OUTPUT_FILE'" 2> /dev/null
        exit 1
    fi
else
    echo "Template file '$TEMPLATE_FILE' not found. Exiting." >&2
    exit 1
fi
