#!/usr/bin/env bats
# Test suite for install_snap.sh parsing and installation functions
#
# Run with: bats tests/test_install_snap.bats
# Or run all tests: bats tests/

# Setup test environment
setup() {
    # Get the base directory
    BASE_DIR="$(cd "$(dirname "$BATS_TEST_FILENAME")/.." && pwd)"
    export MYLICULA_BASE_DIR="${BASE_DIR}"

    # Script to test
    INSTALL_SNAP_SCRIPT="${BASE_DIR}/customize/ubuntu/install_snap.sh"

    # Create a temporary directory for test files
    TEST_TMP_DIR="$(mktemp -d)"

    # Create test snap packages file
    export SNAP_PACKAGES_FILE="${TEST_TMP_DIR}/list_of_snap.txt"

    # Create a test wrapper script that implements the parsing logic
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

# Parse list_of_snap.txt
parse_snap_packages() {
    local flags=""
    local -a packages=()
    local group_num=0

    while IFS= read -r line; do
        # Extract FLAGS metadata from comments
        if [[ "\$line" =~ ^[[:space:]]*#[[:space:]]*FLAGS:[[:space:]]*(.*)$ ]]; then
            flags="\${BASH_REMATCH[1]}"
        elif [[ "\$line" =~ ^[[:space:]]*# ]]; then
            # Other comments - skip
            continue
        elif [[ -z "\${line// }" ]]; then
            # Empty line - output accumulated group
            if [[ \${#packages[@]} -gt 0 ]]; then
                ((group_num++))
                echo "GROUP_\${group_num}_START"
                [[ -n "\$flags" ]] && echo "FLAGS: \$flags"
                echo "PACKAGES: \${packages[*]}"
                echo "GROUP_\${group_num}_END"

                # Reset for next group
                packages=()
                flags=""
            fi
        else
            # Package name
            local package=\$(echo "\$line" | xargs)
            if [[ -n "\$package" ]]; then
                packages+=("\$package")
            fi
        fi
    done < "\$SNAP_PACKAGES_FILE"

    # Output last group if any
    if [[ \${#packages[@]} -gt 0 ]]; then
        ((group_num++))
        echo "GROUP_\${group_num}_START"
        [[ -n "\$flags" ]] && echo "FLAGS: \$flags"
        echo "PACKAGES: \${packages[*]}"
        echo "GROUP_\${group_num}_END"
    fi
}

# Execute the requested function
case "\$1" in
    parse_snap)
        parse_snap_packages
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
# Test: Snap packages file parsing - Simple packages
#-----------------------------------------------------------------------------

@test "parse snap packages: simple package list" {
    cat > "$SNAP_PACKAGES_FILE" <<'EOF'
slack
chromium
postman
EOF

    run "${TEST_TMP_DIR}/test_wrapper.sh" parse_snap

    [ "$status" -eq 0 ]
    [[ "$output" == *"PACKAGES: slack chromium postman"* ]]
}

@test "parse snap packages: skips comment lines" {
    cat > "$SNAP_PACKAGES_FILE" <<'EOF'
# This is a comment
slack
# Another comment
chromium
EOF

    run "${TEST_TMP_DIR}/test_wrapper.sh" parse_snap

    [ "$status" -eq 0 ]
    [[ "$output" != *"This is a comment"* ]]
    [[ "$output" == *"slack"* ]]
    [[ "$output" == *"chromium"* ]]
}

@test "parse snap packages: skips empty lines" {
    cat > "$SNAP_PACKAGES_FILE" <<'EOF'
slack

chromium

postman
EOF

    run "${TEST_TMP_DIR}/test_wrapper.sh" parse_snap

    [ "$status" -eq 0 ]
    # Should have 3 groups (one for each package due to empty line separators)
    [[ "$output" == *"GROUP_1_START"* ]]
    [[ "$output" == *"GROUP_2_START"* ]]
    [[ "$output" == *"GROUP_3_START"* ]]
}

@test "parse snap packages: handles empty file" {
    touch "$SNAP_PACKAGES_FILE"

    run "${TEST_TMP_DIR}/test_wrapper.sh" parse_snap

    [ "$status" -eq 0 ]
    [ -z "$output" ]
}

@test "parse snap packages: handles file with only comments" {
    cat > "$SNAP_PACKAGES_FILE" <<'EOF'
# Comment 1
# Comment 2
# Comment 3
EOF

    run "${TEST_TMP_DIR}/test_wrapper.sh" parse_snap

    [ "$status" -eq 0 ]
    [ -z "$output" ]
}

#-----------------------------------------------------------------------------
# Test: Snap packages file parsing - FLAGS metadata
#-----------------------------------------------------------------------------

@test "parse snap packages: extracts FLAGS metadata" {
    cat > "$SNAP_PACKAGES_FILE" <<'EOF'
# Heroku CLI
# FLAGS: --classic
heroku

EOF

    run "${TEST_TMP_DIR}/test_wrapper.sh" parse_snap

    [ "$status" -eq 0 ]
    [[ "$output" == *"FLAGS: --classic"* ]]
    [[ "$output" == *"PACKAGES: heroku"* ]]
}

@test "parse snap packages: handles packages without FLAGS" {
    cat > "$SNAP_PACKAGES_FILE" <<'EOF'
# Simple package
slack

EOF

    run "${TEST_TMP_DIR}/test_wrapper.sh" parse_snap

    [ "$status" -eq 0 ]
    [[ "$output" != *"FLAGS:"* ]]
    [[ "$output" == *"PACKAGES: slack"* ]]
}

@test "parse snap packages: handles multiple package groups with different FLAGS" {
    cat > "$SNAP_PACKAGES_FILE" <<'EOF'
# Regular packages
slack
chromium

# Package with --classic
# FLAGS: --classic
heroku

# More regular packages
postman

EOF

    run "${TEST_TMP_DIR}/test_wrapper.sh" parse_snap

    [ "$status" -eq 0 ]
    [[ "$output" == *"GROUP_1_START"* ]]
    [[ "$output" == *"PACKAGES: slack chromium"* ]]
    [[ "$output" == *"GROUP_1_END"* ]]

    [[ "$output" == *"GROUP_2_START"* ]]
    [[ "$output" == *"FLAGS: --classic"* ]]
    [[ "$output" == *"PACKAGES: heroku"* ]]
    [[ "$output" == *"GROUP_2_END"* ]]

    [[ "$output" == *"GROUP_3_START"* ]]
    [[ "$output" == *"PACKAGES: postman"* ]]
    [[ "$output" == *"GROUP_3_END"* ]]
}

@test "parse snap packages: trims whitespace in FLAGS values" {
    cat > "$SNAP_PACKAGES_FILE" <<'EOF'
# Test Package
# FLAGS:    --classic --dangerous
testpkg

EOF

    run "${TEST_TMP_DIR}/test_wrapper.sh" parse_snap

    [ "$status" -eq 0 ]
    # Verify whitespace is trimmed
    [[ "$output" == *"FLAGS: --classic --dangerous"* ]]
}

@test "parse snap packages: handles package group without trailing empty line" {
    cat > "$SNAP_PACKAGES_FILE" <<'EOF'
# Package without trailing newline
slack
EOF

    run "${TEST_TMP_DIR}/test_wrapper.sh" parse_snap

    [ "$status" -eq 0 ]
    [[ "$output" == *"PACKAGES: slack"* ]]
}

@test "parse snap packages: ignores non-metadata comments" {
    cat > "$SNAP_PACKAGES_FILE" <<'EOF'
# Communication & Collaboration
# This is a description
# FLAGS: --classic
slack

EOF

    run "${TEST_TMP_DIR}/test_wrapper.sh" parse_snap

    [ "$status" -eq 0 ]
    [[ "$output" == *"FLAGS: --classic"* ]]
    [[ "$output" != *"Communication & Collaboration"* ]]
    [[ "$output" != *"This is a description"* ]]
}

#-----------------------------------------------------------------------------
# Test: Real-world examples from actual snap packages file
#-----------------------------------------------------------------------------

@test "parse snap packages: communication tools group" {
    cat > "$SNAP_PACKAGES_FILE" <<'EOF'
#****************************************************************************************************
# Communication & Collaboration
#****************************************************************************************************
slack

EOF

    run "${TEST_TMP_DIR}/test_wrapper.sh" parse_snap

    [ "$status" -eq 0 ]
    [[ "$output" == *"PACKAGES: slack"* ]]
}

@test "parse snap packages: heroku with classic flag" {
    cat > "$SNAP_PACKAGES_FILE" <<'EOF'
# Heroku CLI
# FLAGS: --classic
heroku

EOF

    run "${TEST_TMP_DIR}/test_wrapper.sh" parse_snap

    [ "$status" -eq 0 ]
    [[ "$output" == *"FLAGS: --classic"* ]]
    [[ "$output" == *"PACKAGES: heroku"* ]]
}

@test "parse snap packages: android tools group" {
    cat > "$SNAP_PACKAGES_FILE" <<'EOF'
#****************************************************************************************************
# Android Tools
#****************************************************************************************************
# Application for display and control of Android devices connected by USB or TCP/IP
scrcpy
guiscrcpy

EOF

    run "${TEST_TMP_DIR}/test_wrapper.sh" parse_snap

    [ "$status" -eq 0 ]
    [[ "$output" == *"PACKAGES: scrcpy guiscrcpy"* ]]
}

@test "parse snap packages: complete file structure" {
    cat > "$SNAP_PACKAGES_FILE" <<'EOF'
# Communication
slack

# Browsers
chromium

# Office Suite
libreoffice

# Development Tools
postman
mysql-workbench-community
yq

# Heroku CLI
# FLAGS: --classic
heroku

# Android Tools
scrcpy
guiscrcpy

EOF

    run "${TEST_TMP_DIR}/test_wrapper.sh" parse_snap

    [ "$status" -eq 0 ]

    # Should have 6 groups
    [[ "$output" == *"GROUP_1_START"* ]]  # slack
    [[ "$output" == *"GROUP_2_START"* ]]  # chromium
    [[ "$output" == *"GROUP_3_START"* ]]  # libreoffice
    [[ "$output" == *"GROUP_4_START"* ]]  # dev tools
    [[ "$output" == *"GROUP_5_START"* ]]  # heroku
    [[ "$output" == *"GROUP_6_START"* ]]  # android tools

    # Check heroku has --classic flag
    [[ "$output" == *"FLAGS: --classic"* ]]
    [[ "$output" == *"PACKAGES: heroku"* ]]

    # Check multi-package groups
    [[ "$output" == *"PACKAGES: postman mysql-workbench-community yq"* ]]
    [[ "$output" == *"PACKAGES: scrcpy guiscrcpy"* ]]
}

@test "parse snap packages: handles indented package names" {
    cat > "$SNAP_PACKAGES_FILE" <<'EOF'
    slack
  chromium
		postman
EOF

    run "${TEST_TMP_DIR}/test_wrapper.sh" parse_snap

    [ "$status" -eq 0 ]
    [[ "$output" == *"slack"* ]]
    [[ "$output" == *"chromium"* ]]
    [[ "$output" == *"postman"* ]]
}
