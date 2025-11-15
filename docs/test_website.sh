#!/usr/bin/env bash
####################################################################################################
# Script Name: test_website.sh
# Description: Launch a local Python 3 HTTP server to test the GitHub Pages website
# Usage: ./test_website.sh [PORT]
# Args:
#   PORT - Optional port number (default: 8000)
# Output (stdout): Server startup messages
# Output (stderr): Error messages
# Return code: 0 on success, 1 on error
#
# Author: Francisco Güemes
# Email: francisco@franciscoguemes.com
####################################################################################################

set -euo pipefail

# Get the directory where this script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" &>/dev/null && pwd)"

# Default port
PORT="${1:-8000}"

# Colors for output
readonly COLOR_GREEN='\033[0;32m'
readonly COLOR_BLUE='\033[0;34m'
readonly COLOR_YELLOW='\033[1;33m'
readonly COLOR_RESET='\033[0m'

echo ""
echo "=========================================="
echo "  MyLiCuLa Website Local Test Server"
echo "=========================================="
echo ""
echo "Starting HTTP server on port ${PORT}..."
echo ""
echo -e "${COLOR_BLUE}Server URL:${COLOR_RESET} http://localhost:${PORT}"
echo -e "${COLOR_BLUE}Directory:${COLOR_RESET} ${SCRIPT_DIR}"
echo ""
echo -e "${COLOR_YELLOW}Press Ctrl+C to stop the server${COLOR_RESET}"
echo ""

# Change to the script directory
cd "$SCRIPT_DIR"

# Check if Python 3 is available
if ! command -v python3 &> /dev/null; then
    echo "Error: python3 is not installed or not in PATH" >&2
    exit 1
fi

# Launch the HTTP server
python3 -m http.server "$PORT"
