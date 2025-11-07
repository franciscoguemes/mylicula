#!/usr/bin/env bash
####################################################################################################
#Args           :
#                   $1  Test file pattern (optional, default: all tests)
#                       Examples: "test_common_*" or "test_common_create_symlink.bats"
#Usage          :   ./tests/run_tests.sh                      # Run all tests
#                   ./tests/run_tests.sh test_common_*         # Run common library tests
#                   ./tests/run_tests.sh --install-bats        # Install BATS first
#Output stdout  :   Test results and summary.
#Output stderr  :   Error messages if tests fail.
#Return code    :   0 if all tests pass, non-zero if any test fails.
#Description	: Test runner script for MyLiCuLa project.
#                 Checks if BATS is installed, runs test suites, and reports results.
#                 Supports running all tests or specific test files/patterns.
#
#Author       	: Francisco Güemes
#Email         	: francisco@franciscoguemes.com
#See also	    : tests/README.md
#                 tests/install_bats.sh
####################################################################################################

set -euo pipefail

# Get script directory
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
BASE_DIR="$(dirname "$SCRIPT_DIR")"

# Colors for output
readonly COLOR_GREEN='\033[0;32m'
readonly COLOR_RED='\033[0;31m'
readonly COLOR_YELLOW='\033[0;33m'
readonly COLOR_BLUE='\033[0;34m'
readonly COLOR_RESET='\033[0m'

#-----------------------------------------------------------------------------
# Function: print_usage
#-----------------------------------------------------------------------------
print_usage() {
    echo "Usage: $0 [OPTIONS] [TEST_PATTERN]"
    echo ""
    echo "Options:"
    echo "  --install-bats    Install BATS testing framework first"
    echo "  --verbose         Show detailed test output"
    echo "  --timing          Show test timing information"
    echo "  -h, --help        Show this help message"
    echo ""
    echo "Examples:"
    echo "  $0                                 # Run all tests"
    echo "  $0 test_common_*                   # Run all common library tests"
    echo "  $0 test_common_create_symlink.bats # Run specific test file"
    echo "  $0 --install-bats                  # Install BATS and run tests"
    echo ""
}

#-----------------------------------------------------------------------------
# Function: check_bats_installed
#-----------------------------------------------------------------------------
check_bats_installed() {
    if ! command -v bats &> /dev/null; then
        echo -e "${COLOR_RED}✗ BATS is not installed${COLOR_RESET}"
        echo ""
        echo "To install BATS, run:"
        echo "  ./tests/install_bats.sh"
        echo ""
        echo "Or run this script with --install-bats:"
        echo "  $0 --install-bats"
        echo ""
        return 1
    fi

    local bats_version
    bats_version=$(bats --version | head -n1)
    echo -e "${COLOR_BLUE}ℹ Using BATS: $bats_version${COLOR_RESET}"
    echo ""
    return 0
}

#-----------------------------------------------------------------------------
# Parse arguments
#-----------------------------------------------------------------------------
INSTALL_BATS=false
VERBOSE=false
TIMING=false
TEST_PATTERN=""

while [[ $# -gt 0 ]]; do
    case $1 in
        --install-bats)
            INSTALL_BATS=true
            shift
            ;;
        --verbose)
            VERBOSE=true
            shift
            ;;
        --timing)
            TIMING=true
            shift
            ;;
        -h|--help)
            print_usage
            exit 0
            ;;
        *)
            TEST_PATTERN="$1"
            shift
            ;;
    esac
done

#-----------------------------------------------------------------------------
# Main execution
#-----------------------------------------------------------------------------

echo "========================================"
echo "MyLiCuLa Test Runner"
echo "========================================"
echo ""

# Install BATS if requested
if [[ "$INSTALL_BATS" == "true" ]]; then
    echo "Installing BATS..."
    "${SCRIPT_DIR}/install_bats.sh"
    echo ""
fi

# Check if BATS is installed
if ! check_bats_installed; then
    exit 1
fi

# Change to project root
cd "$BASE_DIR"

# Build bats command with options
BATS_CMD="bats"

if [[ "$VERBOSE" == "true" ]]; then
    BATS_CMD="$BATS_CMD --tap"
fi

if [[ "$TIMING" == "true" ]]; then
    BATS_CMD="$BATS_CMD --timing"
fi

# Determine what to test
if [[ -n "$TEST_PATTERN" ]]; then
    echo -e "${COLOR_BLUE}Running tests matching: ${TEST_PATTERN}${COLOR_RESET}"
    echo ""
    TEST_FILES="${SCRIPT_DIR}/${TEST_PATTERN}"
else
    echo -e "${COLOR_BLUE}Running all tests...${COLOR_RESET}"
    echo ""
    TEST_FILES="${SCRIPT_DIR}"
fi

# Run the tests
if $BATS_CMD "$TEST_FILES"; then
    echo ""
    echo "========================================"
    echo -e "${COLOR_GREEN}✓ All tests passed!${COLOR_RESET}"
    echo "========================================"
    exit 0
else
    EXIT_CODE=$?
    echo ""
    echo "========================================"
    echo -e "${COLOR_RED}✗ Some tests failed${COLOR_RESET}"
    echo "========================================"
    echo ""
    echo "To see more details, run with --verbose:"
    echo "  $0 --verbose $TEST_PATTERN"
    echo ""
    exit $EXIT_CODE
fi
