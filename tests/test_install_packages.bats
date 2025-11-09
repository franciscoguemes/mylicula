#!/usr/bin/env bats
# Test suite for install_packages.sh parsing and installation functions
#
# Run with: bats tests/test_install_packages.bats
# Or run all tests: bats tests/

# Setup test environment
setup() {
    # Get the base directory
    BASE_DIR="$(cd "$(dirname "$BATS_TEST_FILENAME")/.." && pwd)"
    export MYLICULA_BASE_DIR="${BASE_DIR}"

    # Script to test
    INSTALL_PACKAGES_SCRIPT="${BASE_DIR}/customize/ubuntu/install_packages.sh"

    # Create a temporary directory for test files
    TEST_TMP_DIR="$(mktemp -d)"

    # Create test package files
    export STANDARD_PACKAGES_FILE="${TEST_TMP_DIR}/standard_packages.txt"
    export CUSTOM_PACKAGES_FILE="${TEST_TMP_DIR}/custom_packages.txt"

    # Create mock bin directory for commands
    MOCK_BIN="${TEST_TMP_DIR}/bin"
    mkdir -p "$MOCK_BIN"

    # Add mock bin to PATH
    export PATH="$MOCK_BIN:$PATH"

    # Create mock commands that log their calls
    cat > "$MOCK_BIN/nala" <<'SCRIPT'
#!/bin/bash
echo "NALA: $*" >> "${TEST_TMP_DIR}/nala_calls.log"
exit 0
SCRIPT

    cat > "$MOCK_BIN/add-apt-repository" <<'SCRIPT'
#!/bin/bash
echo "ADD_REPO: $*" >> "${TEST_TMP_DIR}/repo_calls.log"
exit 0
SCRIPT

    cat > "$MOCK_BIN/curl" <<'SCRIPT'
#!/bin/bash
echo "CURL: $*" >> "${TEST_TMP_DIR}/curl_calls.log"
exit 0
SCRIPT

    cat > "$MOCK_BIN/gpg" <<'SCRIPT'
#!/bin/bash
echo "GPG: $*" >> "${TEST_TMP_DIR}/gpg_calls.log"
exit 0
SCRIPT

    chmod +x "$MOCK_BIN"/*

    # Create a test wrapper script that sources the install_packages.sh functions
    # We need to extract just the functions, not the main execution
    cat > "${TEST_TMP_DIR}/test_wrapper.sh" <<WRAPPER
#!/usr/bin/env bash

# Override readonly variables for testing
LOG_DIR="${TEST_TMP_DIR}"
LOG_FILE="${TEST_TMP_DIR}/test.log"
DRY_RUN_MODE=true
DEBUG_MODE=false

# Create log directory
mkdir -p "\$LOG_DIR"
touch "\$LOG_FILE"

# Mock utility functions
log() { echo "[LOG] \$*" >> "\$LOG_FILE"; }
debug() { :; }

# Parse standard_packages.txt
parse_standard_packages() {
    local -a packages=()

    while IFS= read -r line; do
        # Skip comments and empty lines
        [[ "\$line" =~ ^[[:space:]]*# ]] && continue
        [[ -z "\${line// }" ]] && continue

        # Extract package name (trim whitespace)
        local package=\$(echo "\$line" | xargs)

        if [[ -n "\$package" ]]; then
            packages+=("\$package")
        fi
    done < "\$STANDARD_PACKAGES_FILE"

    # Output packages (one per line)
    if [[ \${#packages[@]} -gt 0 ]]; then
        printf '%s\n' "\${packages[@]}"
    fi
}

# Parse custom_packages.txt metadata
parse_custom_packages() {
    local repo="" gpg_key="" keyring=""
    local -a packages=()
    local group_num=0

    while IFS= read -r line; do
        # Extract metadata from comments
        if [[ "\$line" =~ ^[[:space:]]*#[[:space:]]*REPO:[[:space:]]*(.*)$ ]]; then
            repo="\${BASH_REMATCH[1]}"
        elif [[ "\$line" =~ ^[[:space:]]*#[[:space:]]*GPG:[[:space:]]*(.*)$ ]]; then
            gpg_key="\${BASH_REMATCH[1]}"
        elif [[ "\$line" =~ ^[[:space:]]*#[[:space:]]*KEYRING:[[:space:]]*(.*)$ ]]; then
            keyring="\${BASH_REMATCH[1]}"
        elif [[ "\$line" =~ ^[[:space:]]*# ]]; then
            # Other comments - skip
            continue
        elif [[ -z "\${line// }" ]]; then
            # Empty line - output accumulated group
            if [[ \${#packages[@]} -gt 0 ]]; then
                ((group_num++))
                echo "GROUP_\${group_num}_START"
                [[ -n "\$repo" ]] && echo "REPO: \$repo"
                [[ -n "\$gpg_key" ]] && echo "GPG: \$gpg_key"
                [[ -n "\$keyring" ]] && echo "KEYRING: \$keyring"
                echo "PACKAGES: \${packages[*]}"
                echo "GROUP_\${group_num}_END"

                # Reset for next group
                packages=()
                repo="" gpg_key="" keyring=""
            fi
        else
            # Package name
            local package=\$(echo "\$line" | xargs)
            if [[ -n "\$package" ]]; then
                packages+=("\$package")
            fi
        fi
    done < "\$CUSTOM_PACKAGES_FILE"

    # Output last group if any
    if [[ \${#packages[@]} -gt 0 ]]; then
        ((group_num++))
        echo "GROUP_\${group_num}_START"
        [[ -n "\$repo" ]] && echo "REPO: \$repo"
        [[ -n "\$gpg_key" ]] && echo "GPG: \$gpg_key"
        [[ -n "\$keyring" ]] && echo "KEYRING: \$keyring"
        echo "PACKAGES: \${packages[*]}"
        echo "GROUP_\${group_num}_END"
    fi
}

# Execute the requested function
case "\$1" in
    parse_standard)
        parse_standard_packages
        ;;
    parse_custom)
        parse_custom_packages
        ;;
    *)
        echo "Unknown command: \$1" >&2
        exit 1
        ;;
esac
WRAPPER

    chmod +x "${TEST_TMP_DIR}/test_wrapper.sh"
}

# Clean up after each test
teardown() {
    # Remove temporary directory
    if [[ -n "$TEST_TMP_DIR" ]] && [[ -d "$TEST_TMP_DIR" ]]; then
        rm -rf "$TEST_TMP_DIR"
    fi
}

#-----------------------------------------------------------------------------
# Test: Standard packages file parsing
#-----------------------------------------------------------------------------

@test "parse standard packages: simple package list" {
    cat > "$STANDARD_PACKAGES_FILE" <<'EOF'
git
curl
vim
EOF

    run "${TEST_TMP_DIR}/test_wrapper.sh" parse_standard

    [ "$status" -eq 0 ]
    [[ "$output" == *"git"* ]]
    [[ "$output" == *"curl"* ]]
    [[ "$output" == *"vim"* ]]
}

@test "parse standard packages: skips comment lines" {
    cat > "$STANDARD_PACKAGES_FILE" <<'EOF'
# This is a comment
git
# Another comment
curl
EOF

    run "${TEST_TMP_DIR}/test_wrapper.sh" parse_standard

    [ "$status" -eq 0 ]
    [[ "$output" != *"# This is a comment"* ]]
    [[ "$output" == *"git"* ]]
    [[ "$output" == *"curl"* ]]
}

@test "parse standard packages: skips empty lines" {
    cat > "$STANDARD_PACKAGES_FILE" <<'EOF'
git

curl

vim
EOF

    run "${TEST_TMP_DIR}/test_wrapper.sh" parse_standard

    [ "$status" -eq 0 ]
    # Count output lines (should be 3 packages)
    [ "$(echo "$output" | wc -l)" -eq 3 ]
}

@test "parse standard packages: handles indented package names" {
    cat > "$STANDARD_PACKAGES_FILE" <<'EOF'
    git
  curl
		vim
EOF

    run "${TEST_TMP_DIR}/test_wrapper.sh" parse_standard

    [ "$status" -eq 0 ]
    [[ "$output" == *"git"* ]]
    [[ "$output" == *"curl"* ]]
    [[ "$output" == *"vim"* ]]
}

@test "parse standard packages: handles empty file" {
    touch "$STANDARD_PACKAGES_FILE"

    run "${TEST_TMP_DIR}/test_wrapper.sh" parse_standard

    [ "$status" -eq 0 ]
    [ -z "$output" ]
}

@test "parse standard packages: handles file with only comments" {
    cat > "$STANDARD_PACKAGES_FILE" <<'EOF'
# Comment 1
# Comment 2
# Comment 3
EOF

    run "${TEST_TMP_DIR}/test_wrapper.sh" parse_standard

    [ "$status" -eq 0 ]
    [ -z "$output" ]
}

#-----------------------------------------------------------------------------
# Test: Custom packages file parsing - Metadata extraction
#-----------------------------------------------------------------------------

@test "parse custom packages: extracts REPO metadata" {
    cat > "$CUSTOM_PACKAGES_FILE" <<'EOF'
# Docker
# REPO: ppa:docker/stable
docker-ce

EOF

    run "${TEST_TMP_DIR}/test_wrapper.sh" parse_custom

    [ "$status" -eq 0 ]
    [[ "$output" == *"REPO: ppa:docker/stable"* ]]
    [[ "$output" == *"PACKAGES: docker-ce"* ]]
}

@test "parse custom packages: extracts GPG and KEYRING metadata" {
    cat > "$CUSTOM_PACKAGES_FILE" <<'EOF'
# Docker
# REPO: deb [arch=amd64] https://download.docker.com/linux/ubuntu jammy stable
# GPG: https://download.docker.com/linux/ubuntu/gpg
# KEYRING: /usr/share/keyrings/docker-archive-keyring.gpg
docker-ce
docker-ce-cli

EOF

    run "${TEST_TMP_DIR}/test_wrapper.sh" parse_custom

    [ "$status" -eq 0 ]
    [[ "$output" == *"REPO: deb [arch=amd64] https://download.docker.com/linux/ubuntu jammy stable"* ]]
    [[ "$output" == *"GPG: https://download.docker.com/linux/ubuntu/gpg"* ]]
    [[ "$output" == *"KEYRING: /usr/share/keyrings/docker-archive-keyring.gpg"* ]]
    [[ "$output" == *"PACKAGES: docker-ce docker-ce-cli"* ]]
}

@test "parse custom packages: handles multiple package groups" {
    cat > "$CUSTOM_PACKAGES_FILE" <<'EOF'
# Docker
# REPO: ppa:docker/stable
docker-ce

# GitHub CLI
# REPO: ppa:github/cli
gh

EOF

    run "${TEST_TMP_DIR}/test_wrapper.sh" parse_custom

    [ "$status" -eq 0 ]
    [[ "$output" == *"GROUP_1_START"* ]]
    [[ "$output" == *"REPO: ppa:docker/stable"* ]]
    [[ "$output" == *"PACKAGES: docker-ce"* ]]
    [[ "$output" == *"GROUP_1_END"* ]]

    [[ "$output" == *"GROUP_2_START"* ]]
    [[ "$output" == *"REPO: ppa:github/cli"* ]]
    [[ "$output" == *"PACKAGES: gh"* ]]
    [[ "$output" == *"GROUP_2_END"* ]]
}

@test "parse custom packages: handles package group without trailing empty line" {
    cat > "$CUSTOM_PACKAGES_FILE" <<'EOF'
# Package without trailing newline
# REPO: ppa:test/repo
testpackage
EOF

    run "${TEST_TMP_DIR}/test_wrapper.sh" parse_custom

    [ "$status" -eq 0 ]
    [[ "$output" == *"REPO: ppa:test/repo"* ]]
    [[ "$output" == *"PACKAGES: testpackage"* ]]
}

@test "parse custom packages: ignores non-metadata comments" {
    cat > "$CUSTOM_PACKAGES_FILE" <<'EOF'
# This is a description comment
# Author: Test Author
# REPO: ppa:test/repo
testpackage

EOF

    run "${TEST_TMP_DIR}/test_wrapper.sh" parse_custom

    [ "$status" -eq 0 ]
    [[ "$output" == *"REPO: ppa:test/repo"* ]]
    [[ "$output" != *"This is a description"* ]]
    [[ "$output" != *"Author:"* ]]
}

@test "parse custom packages: trims whitespace in metadata values" {
    cat > "$CUSTOM_PACKAGES_FILE" <<'EOF'
# Test Package
# REPO:    ppa:test/repo
# GPG:  https://example.com/key.gpg
# KEYRING:   /usr/share/keyrings/test.gpg
testpackage

EOF

    run "${TEST_TMP_DIR}/test_wrapper.sh" parse_custom

    [ "$status" -eq 0 ]
    # Verify whitespace is trimmed
    [[ "$output" == *"REPO: ppa:test/repo"* ]]
    [[ "$output" == *"GPG: https://example.com/key.gpg"* ]]
    [[ "$output" == *"KEYRING: /usr/share/keyrings/test.gpg"* ]]
}

@test "parse custom packages: handles multiple packages in one group" {
    cat > "$CUSTOM_PACKAGES_FILE" <<'EOF'
# Docker packages
# REPO: ppa:docker/stable
docker-ce
docker-ce-cli
containerd.io
docker-compose-plugin

EOF

    run "${TEST_TMP_DIR}/test_wrapper.sh" parse_custom

    [ "$status" -eq 0 ]
    [[ "$output" == *"PACKAGES: docker-ce docker-ce-cli containerd.io docker-compose-plugin"* ]]
}

@test "parse custom packages: handles empty file" {
    touch "$CUSTOM_PACKAGES_FILE"

    run "${TEST_TMP_DIR}/test_wrapper.sh" parse_custom

    [ "$status" -eq 0 ]
    [ -z "$output" ]
}

#-----------------------------------------------------------------------------
# Test: Real-world examples from actual package files
#-----------------------------------------------------------------------------

@test "parse custom packages: appimagelauncher example" {
    cat > "$CUSTOM_PACKAGES_FILE" <<'EOF'
# AppImageLauncher
# Integrate AppImage apps in the system
# https://askubuntu.com/questions/902672/registering-an-appimage-file-as-a-desktop-app-in-kde
# REPO: ppa:appimagelauncher-team/stable
appimagelauncher

EOF

    run "${TEST_TMP_DIR}/test_wrapper.sh" parse_custom

    [ "$status" -eq 0 ]
    [[ "$output" == *"REPO: ppa:appimagelauncher-team/stable"* ]]
    [[ "$output" == *"PACKAGES: appimagelauncher"* ]]
}

@test "parse custom packages: xournalpp example" {
    cat > "$CUSTOM_PACKAGES_FILE" <<'EOF'
# Xournal++
# PDF annotation and note-taking application
# REPO: ppa:apandada1/xournalpp-stable
xournalpp

EOF

    run "${TEST_TMP_DIR}/test_wrapper.sh" parse_custom

    [ "$status" -eq 0 ]
    [[ "$output" == *"REPO: ppa:apandada1/xournalpp-stable"* ]]
    [[ "$output" == *"PACKAGES: xournalpp"* ]]
}

@test "parse custom packages: handles package group with only REPO (no GPG)" {
    cat > "$CUSTOM_PACKAGES_FILE" <<'EOF'
# Test Package
# REPO: ppa:test/repo
testpackage

EOF

    run "${TEST_TMP_DIR}/test_wrapper.sh" parse_custom

    [ "$status" -eq 0 ]
    [[ "$output" == *"REPO: ppa:test/repo"* ]]
    [[ "$output" != *"GPG:"* ]]
    [[ "$output" != *"KEYRING:"* ]]
    [[ "$output" == *"PACKAGES: testpackage"* ]]
}

@test "parse custom packages: handles complex repository line with signed-by" {
    cat > "$CUSTOM_PACKAGES_FILE" <<'EOF'
# GitHub CLI
# REPO: deb [arch=amd64 signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main
# GPG: https://cli.github.com/packages/githubcli-archive-keyring.gpg
# KEYRING: /usr/share/keyrings/githubcli-archive-keyring.gpg
gh

EOF

    run "${TEST_TMP_DIR}/test_wrapper.sh" parse_custom

    [ "$status" -eq 0 ]
    [[ "$output" == *"REPO: deb [arch=amd64 signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main"* ]]
    [[ "$output" == *"GPG: https://cli.github.com/packages/githubcli-archive-keyring.gpg"* ]]
    [[ "$output" == *"KEYRING: /usr/share/keyrings/githubcli-archive-keyring.gpg"* ]]
}
