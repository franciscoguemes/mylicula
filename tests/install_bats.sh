#!/usr/bin/env bash
####################################################################################################
#Args           : None - This script does not accept any arguments.
#Usage          :   ./tests/install_bats.sh
#                   Run this script to install BATS (Bash Automated Testing System).
#Output stdout  :   Installation progress messages.
#Output stderr  :   Error messages if installation fails.
#Return code    :   0 on success, non-zero on error.
#Description	: Installs BATS testing framework for bash scripts.
#                 First tries to install via apt (Ubuntu/Debian), then falls back to
#                 installing from source if package manager installation fails.
#
#Author       	: Francisco Güemes
#Email         	: francisco@franciscoguemes.com
#See also	    : https://github.com/bats-core/bats-core
#                 https://bats-core.readthedocs.io/
#                 tests/README.md
####################################################################################################

set -euo pipefail

echo "========================================"
echo "BATS Installation Script"
echo "========================================"
echo ""

# Check if BATS is already installed
if command -v bats &> /dev/null; then
    BATS_VERSION=$(bats --version | head -n1)
    echo "✓ BATS is already installed: $BATS_VERSION"
    echo ""
    echo "If you want to update BATS, run: sudo apt update && sudo apt upgrade bats"
    exit 0
fi

echo "BATS not found. Installing..."
echo ""

# Try installing via apt (Ubuntu/Debian)
if command -v apt &> /dev/null; then
    echo "Installing BATS via nala..."
    sudo nala update
    sudo nala install -y bats

    if command -v bats &> /dev/null; then
        BATS_VERSION=$(bats --version | head -n1)
        echo ""
        echo "✓ BATS installed successfully: $BATS_VERSION"
        exit 0
    else
        echo "Warning: apt installation completed but bats command not found"
        echo "Falling back to source installation..."
        echo ""
    fi
else
    echo "apt package manager not found, installing from source..."
    echo ""
fi

# Install from source
REPO_CLONE_DIR="/tmp/bats-core-install"
BATS_REPO="https://github.com/bats-core/bats-core.git"

echo "Cloning BATS repository..."
if [[ -d "$REPO_CLONE_DIR" ]]; then
    rm -rf "$REPO_CLONE_DIR"
fi

git clone "$BATS_REPO" "$REPO_CLONE_DIR"

echo ""
echo "Installing BATS to /usr/local..."
cd "$REPO_CLONE_DIR"
sudo ./install.sh /usr/local

# Clean up
cd -
rm -rf "$REPO_CLONE_DIR"

# Verify installation
if command -v bats &> /dev/null; then
    BATS_VERSION=$(bats --version | head -n1)
    echo ""
    echo "========================================"
    echo "✓ BATS installed successfully!"
    echo "  Version: $BATS_VERSION"
    echo "========================================"
    echo ""
    echo "You can now run tests with:"
    echo "  bats tests/"
    echo ""
    exit 0
else
    echo ""
    echo "========================================"
    echo "✗ BATS installation failed"
    echo "========================================"
    echo ""
    echo "Please install manually:"
    echo "  git clone https://github.com/bats-core/bats-core.git"
    echo "  cd bats-core"
    echo "  sudo ./install.sh /usr/local"
    echo ""
    exit 1
fi
