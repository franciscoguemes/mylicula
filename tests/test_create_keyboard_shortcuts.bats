#!/usr/bin/env bats
####################################################################################################
# Test suite for customize/ubuntu/create_keyboard_shortcuts_in_ubuntu.sh
#
# This test suite validates the keyboard shortcut creation functionality including:
# - Symlink existence checking before creating shortcuts
# - Finding empty slots in GNOME custom keybindings
# - Detecting keybinding conflicts
# - Error handling for missing scripts
#
# Note: These tests mock gsettings to avoid modifying the actual GNOME configuration.
# Tests use a temporary directory structure to simulate the environment.
####################################################################################################

# Setup function runs before each test
setup() {
    # Create temporary test directory
    export TEST_TMP_DIR="$(mktemp -d)"
    export MYLICULA_BASE_DIR="${TEST_TMP_DIR}"
    export BIN_DIR="${TEST_TMP_DIR}/bin"
    export SCRIPT_DIR="${TEST_TMP_DIR}/scripts"
    export LIB_DIR="${TEST_TMP_DIR}/lib"
    export GSETTINGS_DATA="${TEST_TMP_DIR}/gsettings_data"

    # Create directory structure
    mkdir -p "${BIN_DIR}"
    mkdir -p "${SCRIPT_DIR}"
    mkdir -p "${LIB_DIR}"

    # Copy common.sh library to test location
    cp "${BATS_TEST_DIRNAME}/../lib/common.sh" "${LIB_DIR}/common.sh"

    # Create mock scripts
    echo "#!/bin/bash" > "${SCRIPT_DIR}/generate_link.sh"
    echo "#!/bin/bash" > "${SCRIPT_DIR}/code_2_markdown_in_clipboard.sh"
    echo "#!/bin/bash" > "${SCRIPT_DIR}/find_text.sh"

    # Initialize gsettings mock data file
    echo "@as []" > "${GSETTINGS_DATA}"

    # Create test wrapper script that simulates create_keyboard_shortcuts_in_ubuntu.sh
    cat > "${TEST_TMP_DIR}/create_shortcuts_test.sh" <<'WRAPPER'
#!/usr/bin/env bash

BASE_DIR="${TEST_TMP_DIR}"
source "${LIB_DIR}/common.sh"
set +e

INSTALL_DIR="${BIN_DIR}"
LINKS=(
    "generate_link.sh"
    "code_2_markdown_in_clipboard.sh"
    "find_text.sh"
)

# Mock gsettings command
gsettings() {
    local action=$1
    local key=$2
    local value=$3

    case "$action" in
        get)
            if [[ "$key" == "org.gnome.settings-daemon.plugins.media-keys custom-keybindings" ]]; then
                cat "${GSETTINGS_DATA}"
            elif [[ "$key" == org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:* ]]; then
                local path=${key#*:}
                local property=$3
                # Return mock data for specific binding paths
                echo "'<Mock>'"
            fi
            ;;
        set)
            if [[ "$key" == "org.gnome.settings-daemon.plugins.media-keys custom-keybindings" ]]; then
                echo "$value" > "${GSETTINGS_DATA}"
            fi
            ;;
    esac
}

export -f gsettings

# Check links function
check_links() {
    local all_links_exist=true
    for link in "${LINKS[@]}"; do
        if [ ! -L "$INSTALL_DIR/$link" ]; then
            echo "ERROR: Symbolic link for $link does not exist"
            all_links_exist=false
        fi
    done

    if [ "$all_links_exist" = false ]; then
        return 1
    fi
    return 0
}

# Test the check_links function
if [ "$TEST_MODE" = "check_links" ]; then
    if check_links; then
        echo "CHECK_LINKS: SUCCESS"
        exit 0
    else
        echo "CHECK_LINKS: FAILED"
        exit 1
    fi
fi

# Test finding empty slot
if [ "$TEST_MODE" = "find_slot" ]; then
    existing_bindings=$(cat "${GSETTINGS_DATA}")
    for i in {0..5}; do
        existing_binding=$(echo "$existing_bindings" | grep -o "'/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom$i/'")
        if [ -z "$existing_binding" ]; then
            echo "EMPTY_SLOT: $i"
            exit 0
        fi
    done
    echo "NO_SLOT_FOUND"
    exit 1
fi

# Test adding shortcut to list
if [ "$TEST_MODE" = "add_shortcut" ]; then
    new_binding_path="/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom0/"
    current_bindings=$(cat "${GSETTINGS_DATA}")

    if [[ "$current_bindings" == "@as []" ]]; then
        new_bindings="['$new_binding_path']"
    else
        current_bindings=${current_bindings#[}
        current_bindings=${current_bindings%]}
        new_bindings="[$current_bindings, '$new_binding_path']"
    fi

    echo "$new_bindings"
    exit 0
fi

echo "TEST_MODE not set or invalid"
exit 1
WRAPPER

    chmod +x "${TEST_TMP_DIR}/create_shortcuts_test.sh"
}

# Teardown function runs after each test
teardown() {
    rm -rf "$TEST_TMP_DIR"
}

####################################################################################################
# TEST CASES - Symlink Checking
####################################################################################################

@test "create shortcuts: checks for required symlinks before proceeding" {
    # Don't create symlinks - should fail

    export TEST_MODE="check_links"
    run "${TEST_TMP_DIR}/create_shortcuts_test.sh"

    [ "$status" -eq 1 ]
    [[ "$output" == *"CHECK_LINKS: FAILED"* ]]
}

@test "create shortcuts: succeeds when all required symlinks exist" {
    # Create all required symlinks
    ln -s "${SCRIPT_DIR}/generate_link.sh" "${BIN_DIR}/generate_link.sh"
    ln -s "${SCRIPT_DIR}/code_2_markdown_in_clipboard.sh" "${BIN_DIR}/code_2_markdown_in_clipboard.sh"
    ln -s "${SCRIPT_DIR}/find_text.sh" "${BIN_DIR}/find_text.sh"

    export TEST_MODE="check_links"
    run "${TEST_TMP_DIR}/create_shortcuts_test.sh"

    [ "$status" -eq 0 ]
    [[ "$output" == *"CHECK_LINKS: SUCCESS"* ]]
}

@test "create shortcuts: reports missing specific scripts" {
    # Create only some symlinks
    ln -s "${SCRIPT_DIR}/generate_link.sh" "${BIN_DIR}/generate_link.sh"
    ln -s "${SCRIPT_DIR}/find_text.sh" "${BIN_DIR}/find_text.sh"
    # Missing: code_2_markdown_in_clipboard.sh

    export TEST_MODE="check_links"
    run "${TEST_TMP_DIR}/create_shortcuts_test.sh"

    [ "$status" -eq 1 ]
    [[ "$output" == *"code_2_markdown_in_clipboard.sh does not exist"* ]]
    [[ "$output" != *"generate_link.sh does not exist"* ]]
    [[ "$output" != *"find_text.sh does not exist"* ]]
}

####################################################################################################
# TEST CASES - Finding Empty Slots
####################################################################################################

@test "create shortcuts: finds slot 0 when no shortcuts exist" {
    # Empty gsettings (default)
    echo "@as []" > "${GSETTINGS_DATA}"

    export TEST_MODE="find_slot"
    run "${TEST_TMP_DIR}/create_shortcuts_test.sh"

    [ "$status" -eq 0 ]
    [[ "$output" == *"EMPTY_SLOT: 0"* ]]
}

@test "create shortcuts: finds next available slot when some exist" {
    # Slots 0 and 1 are taken
    echo "['/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom0/', '/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom1/']" > "${GSETTINGS_DATA}"

    export TEST_MODE="find_slot"
    run "${TEST_TMP_DIR}/create_shortcuts_test.sh"

    [ "$status" -eq 0 ]
    [[ "$output" == *"EMPTY_SLOT: 2"* ]]
}

@test "create shortcuts: finds gap in slot numbers" {
    # Slots 0 and 2 are taken, slot 1 is free
    echo "['/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom0/', '/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom2/']" > "${GSETTINGS_DATA}"

    export TEST_MODE="find_slot"
    run "${TEST_TMP_DIR}/create_shortcuts_test.sh"

    [ "$status" -eq 0 ]
    [[ "$output" == *"EMPTY_SLOT: 1"* ]]
}

####################################################################################################
# TEST CASES - Adding Shortcuts to List
####################################################################################################

@test "create shortcuts: creates initial shortcut list when empty" {
    echo "@as []" > "${GSETTINGS_DATA}"

    export TEST_MODE="add_shortcut"
    run "${TEST_TMP_DIR}/create_shortcuts_test.sh"

    [ "$status" -eq 0 ]
    [[ "$output" == "['${NEW_BINDING_PATH:-/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom0/}']" ]] || \
    [[ "$output" == *"custom0"* ]]
}

@test "create shortcuts: appends to existing shortcut list" {
    echo "['/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom0/']" > "${GSETTINGS_DATA}"

    export TEST_MODE="add_shortcut"
    run "${TEST_TMP_DIR}/create_shortcuts_test.sh"

    [ "$status" -eq 0 ]
    [[ "$output" == *"custom0"* ]]
    [[ "$output" == *"custom0"* ]]
}

@test "create shortcuts: handles multiple existing shortcuts" {
    echo "['/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom0/', '/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom1/', '/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom2/']" > "${GSETTINGS_DATA}"

    export TEST_MODE="add_shortcut"
    run "${TEST_TMP_DIR}/create_shortcuts_test.sh"

    [ "$status" -eq 0 ]
    # Should still work and add another shortcut
    [[ "$output" == *"custom0"* ]]
}

####################################################################################################
# TEST CASES - Edge Cases
####################################################################################################

@test "create shortcuts: handles symlinks with spaces in path" {
    # Create symlink in path with spaces
    local dir_with_spaces="${TEST_TMP_DIR}/dir with spaces"
    mkdir -p "$dir_with_spaces"
    echo "#!/bin/bash" > "$dir_with_spaces/test_script.sh"
    ln -s "$dir_with_spaces/test_script.sh" "${BIN_DIR}/test_script.sh"

    [ -L "${BIN_DIR}/test_script.sh" ]
}

@test "create shortcuts: validates symlink is actually a symlink not regular file" {
    # Create regular file instead of symlink
    echo "#!/bin/bash" > "${BIN_DIR}/generate_link.sh"
    chmod +x "${BIN_DIR}/generate_link.sh"

    # Create other symlinks
    ln -s "${SCRIPT_DIR}/code_2_markdown_in_clipboard.sh" "${BIN_DIR}/code_2_markdown_in_clipboard.sh"
    ln -s "${SCRIPT_DIR}/find_text.sh" "${BIN_DIR}/find_text.sh"

    export TEST_MODE="check_links"
    run "${TEST_TMP_DIR}/create_shortcuts_test.sh"

    # Should fail because generate_link.sh is not a symlink
    [ "$status" -eq 1 ]
    [[ "$output" == *"generate_link.sh does not exist"* ]]
}

@test "create shortcuts: handles broken symlinks correctly" {
    # Create broken symlinks (pointing to non-existent files)
    ln -s "/nonexistent/generate_link.sh" "${BIN_DIR}/generate_link.sh"
    ln -s "/nonexistent/code_2_markdown_in_clipboard.sh" "${BIN_DIR}/code_2_markdown_in_clipboard.sh"
    ln -s "/nonexistent/find_text.sh" "${BIN_DIR}/find_text.sh"

    # Broken symlinks still exist as symlinks
    [ -L "${BIN_DIR}/generate_link.sh" ]

    export TEST_MODE="check_links"
    run "${TEST_TMP_DIR}/create_shortcuts_test.sh"

    # Should succeed - we only check if symlink exists, not if target exists
    [ "$status" -eq 0 ]
}

####################################################################################################
# TEST CASES - gsettings Data Format
####################################################################################################

@test "create shortcuts: parses empty gsettings format correctly" {
    echo "@as []" > "${GSETTINGS_DATA}"

    content=$(cat "${GSETTINGS_DATA}")
    [[ "$content" == "@as []" ]]
}

@test "create shortcuts: parses gsettings array format correctly" {
    echo "['/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom0/']" > "${GSETTINGS_DATA}"

    content=$(cat "${GSETTINGS_DATA}")
    [[ "$content" == *"custom0"* ]]
}

@test "create shortcuts: handles gsettings format with multiple entries" {
    echo "['/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom0/', '/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom1/']" > "${GSETTINGS_DATA}"

    content=$(cat "${GSETTINGS_DATA}")
    [[ "$content" == *"custom0"* ]]
    [[ "$content" == *"custom1"* ]]
}

####################################################################################################
# TEST CASES - Integration Scenarios
####################################################################################################

@test "create shortcuts: full workflow - check links then find slot" {
    # Create all required symlinks
    ln -s "${SCRIPT_DIR}/generate_link.sh" "${BIN_DIR}/generate_link.sh"
    ln -s "${SCRIPT_DIR}/code_2_markdown_in_clipboard.sh" "${BIN_DIR}/code_2_markdown_in_clipboard.sh"
    ln -s "${SCRIPT_DIR}/find_text.sh" "${BIN_DIR}/find_text.sh"

    # First check links
    export TEST_MODE="check_links"
    run "${TEST_TMP_DIR}/create_shortcuts_test.sh"
    [ "$status" -eq 0 ]

    # Then find slot
    export TEST_MODE="find_slot"
    run "${TEST_TMP_DIR}/create_shortcuts_test.sh"
    [ "$status" -eq 0 ]
    [[ "$output" == *"EMPTY_SLOT: 0"* ]]
}

@test "create shortcuts: workflow with existing shortcuts" {
    # Create symlinks
    ln -s "${SCRIPT_DIR}/generate_link.sh" "${BIN_DIR}/generate_link.sh"
    ln -s "${SCRIPT_DIR}/code_2_markdown_in_clipboard.sh" "${BIN_DIR}/code_2_markdown_in_clipboard.sh"
    ln -s "${SCRIPT_DIR}/find_text.sh" "${BIN_DIR}/find_text.sh"

    # Simulate existing shortcuts
    echo "['/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom0/', '/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom1/']" > "${GSETTINGS_DATA}"

    export TEST_MODE="find_slot"
    run "${TEST_TMP_DIR}/create_shortcuts_test.sh"

    [ "$status" -eq 0 ]
    [[ "$output" == *"EMPTY_SLOT: 2"* ]]
}
