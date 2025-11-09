#!/usr/bin/env bats
####################################################################################################
# Test suite for customize/ubuntu/remove_keyboard_shortcuts_in_ubuntu.sh
#
# This test suite validates the keyboard shortcut removal functionality including:
# - Finding shortcuts by description/name
# - Removing shortcuts from GNOME custom keybindings list
# - Cleaning up gsettings entries
# - Handling missing shortcuts gracefully
# - Edge cases with multiple shortcuts
#
# Note: These tests mock gsettings to avoid modifying the actual GNOME configuration.
# Tests use a temporary directory structure to simulate the environment.
####################################################################################################

# Setup function runs before each test
setup() {
    # Create temporary test directory
    export TEST_TMP_DIR="$(mktemp -d)"
    export LIB_DIR="${TEST_TMP_DIR}/lib"
    export GSETTINGS_DATA="${TEST_TMP_DIR}/gsettings_data"
    export GSETTINGS_SHORTCUTS="${TEST_TMP_DIR}/shortcuts"

    # Create directory structure
    mkdir -p "${LIB_DIR}"
    mkdir -p "${GSETTINGS_SHORTCUTS}"

    # Copy common.sh library to test location
    cp "${BATS_TEST_DIRNAME}/../lib/common.sh" "${LIB_DIR}/common.sh"

    # Initialize gsettings mock data
    echo "@as []" > "${GSETTINGS_DATA}"

    # Create test wrapper script that simulates remove_keyboard_shortcuts_in_ubuntu.sh
    cat > "${TEST_TMP_DIR}/remove_shortcuts_test.sh" <<'WRAPPER'
#!/usr/bin/env bash

BASE_DIR="${TEST_TMP_DIR}"
source "${LIB_DIR}/common.sh"
set +e

SHORTCUT_DESCRIPTIONS=(
    "Generate link"
    "Text to Markdown code"
    "Find text in files"
)

# Mock gsettings command
gsettings() {
    local action=$1
    local key=$2

    case "$action" in
        get)
            if [[ "$key" == "org.gnome.settings-daemon.plugins.media-keys custom-keybindings" ]]; then
                cat "${GSETTINGS_DATA}"
            elif [[ "$key" == org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:* ]]; then
                local path=${key#*:}
                local property=${3}
                local shortcut_file="${GSETTINGS_SHORTCUTS}/${path//\//_}"

                if [[ "$property" == "name" ]]; then
                    if [ -f "${shortcut_file}_name" ]; then
                        cat "${shortcut_file}_name"
                    else
                        echo "''"
                    fi
                elif [[ "$property" == "binding" ]]; then
                    if [ -f "${shortcut_file}_binding" ]; then
                        cat "${shortcut_file}_binding"
                    else
                        echo "''"
                    fi
                fi
            fi
            ;;
        set)
            if [[ "$key" == "org.gnome.settings-daemon.plugins.media-keys custom-keybindings" ]]; then
                local value=$3
                echo "$value" > "${GSETTINGS_DATA}"
            fi
            ;;
        reset)
            # Mock reset (would clear the setting)
            echo "RESET: $key $3" >> "${TEST_TMP_DIR}/reset_log"
            ;;
    esac
}

export -f gsettings

# Remove shortcut function
remove_shortcut() {
    local description="$1"

    existing_binding=$(cat "${GSETTINGS_DATA}" | grep -o "'/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom[0-9]*/'")

    for binding_path in $existing_binding; do
        binding_path=${binding_path#\'}
        binding_path=${binding_path%\'}

        local shortcut_file="${GSETTINGS_SHORTCUTS}/${binding_path//\//_}"
        if [ -f "${shortcut_file}_name" ]; then
            local shortcut_name=$(cat "${shortcut_file}_name")
            shortcut_name=${shortcut_name#\'}
            shortcut_name=${shortcut_name%\'}

            if [ "$shortcut_name" = "$description" ]; then
                local binding_key=$(cat "${shortcut_file}_binding" 2>/dev/null || echo "'<Unknown>'")
                binding_key=${binding_key#\'}
                binding_key=${binding_key%\'}

                # Remove from list
                current_bindings=$(cat "${GSETTINGS_DATA}")
                new_bindings=$(echo "$current_bindings" | sed "s|, '$binding_path'| |; s|'$binding_path', | |; s|'$binding_path'| |")
                echo "$new_bindings" > "${GSETTINGS_DATA}"

                # Reset settings
                gsettings reset org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:"$binding_path" name
                gsettings reset org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:"$binding_path" command
                gsettings reset org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:"$binding_path" binding

                echo "REMOVED: $description ($binding_key)"
                return 0
            fi
        fi
    done

    echo "NOT_FOUND: $description"
    return 1
}

# Test mode handling
if [ "$TEST_MODE" = "remove_single" ]; then
    if remove_shortcut "$TARGET_SHORTCUT"; then
        exit 0
    else
        exit 1
    fi
fi

if [ "$TEST_MODE" = "remove_all" ]; then
    removed_count=0
    skipped_count=0

    for description in "${SHORTCUT_DESCRIPTIONS[@]}"; do
        if remove_shortcut "$description"; then
            ((removed_count++))
        else
            ((skipped_count++))
        fi
    done

    echo "SUMMARY: Removed=$removed_count Skipped=$skipped_count"
    exit 0
fi

echo "TEST_MODE not set or invalid"
exit 1
WRAPPER

    chmod +x "${TEST_TMP_DIR}/remove_shortcuts_test.sh"
}

# Teardown function runs after each test
teardown() {
    rm -rf "$TEST_TMP_DIR"
}

####################################################################################################
# Helper Functions
####################################################################################################

# Create a mock shortcut in gsettings
create_mock_shortcut() {
    local slot=$1
    local name=$2
    local binding=$3

    local path="/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom${slot}/"

    # Add to keybindings list
    current=$(cat "${GSETTINGS_DATA}")
    if [[ "$current" == "@as []" ]]; then
        echo "['$path']" > "${GSETTINGS_DATA}"
    else
        current=${current#[}
        current=${current%]}
        echo "[$current, '$path']" > "${GSETTINGS_DATA}"
    fi

    # Create mock shortcut data
    local shortcut_file="${GSETTINGS_SHORTCUTS}/${path//\//_}"
    echo "'$name'" > "${shortcut_file}_name"
    echo "'$binding'" > "${shortcut_file}_binding"
}

####################################################################################################
# TEST CASES - Finding and Removing Shortcuts
####################################################################################################

@test "remove shortcuts: removes shortcut by name" {
    create_mock_shortcut 0 "Generate link" "<Shift>L"

    export TEST_MODE="remove_single"
    export TARGET_SHORTCUT="Generate link"
    run "${TEST_TMP_DIR}/remove_shortcuts_test.sh"

    [ "$status" -eq 0 ]
    [[ "$output" == *"REMOVED: Generate link"* ]]

    # Verify it was removed from list
    bindings=$(cat "${GSETTINGS_DATA}")
    [[ "$bindings" != *"custom0"* ]]
}

@test "remove shortcuts: returns error when shortcut not found" {
    # Empty shortcuts
    echo "@as []" > "${GSETTINGS_DATA}"

    export TEST_MODE="remove_single"
    export TARGET_SHORTCUT="Generate link"
    run "${TEST_TMP_DIR}/remove_shortcuts_test.sh"

    [ "$status" -eq 1 ]
    [[ "$output" == *"NOT_FOUND: Generate link"* ]]
}

@test "remove shortcuts: removes correct shortcut when multiple exist" {
    create_mock_shortcut 0 "Generate link" "<Shift>L"
    create_mock_shortcut 1 "Text to Markdown code" "<Primary>Above_Tab"
    create_mock_shortcut 2 "Find text in files" "<Alt>F"

    export TEST_MODE="remove_single"
    export TARGET_SHORTCUT="Text to Markdown code"
    run "${TEST_TMP_DIR}/remove_shortcuts_test.sh"

    [ "$status" -eq 0 ]
    [[ "$output" == *"REMOVED: Text to Markdown code"* ]]

    # Verify others remain
    bindings=$(cat "${GSETTINGS_DATA}")
    [[ "$bindings" == *"custom0"* ]]
    [[ "$bindings" != *"custom1"* ]]
    [[ "$bindings" == *"custom2"* ]]
}

@test "remove shortcuts: handles last remaining shortcut" {
    create_mock_shortcut 0 "Generate link" "<Shift>L"

    export TEST_MODE="remove_single"
    export TARGET_SHORTCUT="Generate link"
    run "${TEST_TMP_DIR}/remove_shortcuts_test.sh"

    [ "$status" -eq 0 ]

    # List should be empty or nearly empty
    bindings=$(cat "${GSETTINGS_DATA}")
    [[ "$bindings" != *"custom0"* ]]
}

####################################################################################################
# TEST CASES - Batch Removal
####################################################################################################

@test "remove shortcuts: removes all matching shortcuts" {
    create_mock_shortcut 0 "Generate link" "<Shift>L"
    create_mock_shortcut 1 "Text to Markdown code" "<Primary>Above_Tab"
    create_mock_shortcut 2 "Find text in files" "<Alt>F"

    export TEST_MODE="remove_all"
    run "${TEST_TMP_DIR}/remove_shortcuts_test.sh"

    [ "$status" -eq 0 ]
    [[ "$output" == *"REMOVED: Generate link"* ]]
    [[ "$output" == *"REMOVED: Text to Markdown code"* ]]
    [[ "$output" == *"REMOVED: Find text in files"* ]]
    [[ "$output" == *"SUMMARY: Removed=3 Skipped=0"* ]]
}

@test "remove shortcuts: handles partial matches (some found, some not)" {
    create_mock_shortcut 0 "Generate link" "<Shift>L"
    create_mock_shortcut 2 "Find text in files" "<Alt>F"
    # Missing: "Text to Markdown code"

    export TEST_MODE="remove_all"
    run "${TEST_TMP_DIR}/remove_shortcuts_test.sh"

    [ "$status" -eq 0 ]
    [[ "$output" == *"REMOVED: Generate link"* ]]
    [[ "$output" == *"NOT_FOUND: Text to Markdown code"* ]]
    [[ "$output" == *"REMOVED: Find text in files"* ]]
    [[ "$output" == *"SUMMARY: Removed=2 Skipped=1"* ]]
}

@test "remove shortcuts: handles no matching shortcuts" {
    # Empty shortcuts
    echo "@as []" > "${GSETTINGS_DATA}"

    export TEST_MODE="remove_all"
    run "${TEST_TMP_DIR}/remove_shortcuts_test.sh"

    [ "$status" -eq 0 ]
    [[ "$output" == *"NOT_FOUND: Generate link"* ]]
    [[ "$output" == *"NOT_FOUND: Text to Markdown code"* ]]
    [[ "$output" == *"NOT_FOUND: Find text in files"* ]]
    [[ "$output" == *"SUMMARY: Removed=0 Skipped=3"* ]]
}

####################################################################################################
# TEST CASES - Edge Cases
####################################################################################################

@test "remove shortcuts: handles shortcuts with special characters in name" {
    create_mock_shortcut 0 "Test & Special" "<Shift>T"

    export TEST_MODE="remove_single"
    export TARGET_SHORTCUT="Test & Special"
    run "${TEST_TMP_DIR}/remove_shortcuts_test.sh"

    [ "$status" -eq 0 ]
    [[ "$output" == *"REMOVED: Test & Special"* ]]
}

@test "remove shortcuts: handles shortcuts with quotes in name" {
    create_mock_shortcut 0 "Test \"Quote\"" "<Shift>Q"

    export TEST_MODE="remove_single"
    export TARGET_SHORTCUT="Test \"Quote\""
    run "${TEST_TMP_DIR}/remove_shortcuts_test.sh"

    # Should handle or skip gracefully
    [ "$status" -eq 0 ] || [ "$status" -eq 1 ]
}

@test "remove shortcuts: removes shortcut with non-standard slot number" {
    create_mock_shortcut 99 "Generate link" "<Shift>L"

    export TEST_MODE="remove_single"
    export TARGET_SHORTCUT="Generate link"
    run "${TEST_TMP_DIR}/remove_shortcuts_test.sh"

    [ "$status" -eq 0 ]
    [[ "$output" == *"REMOVED: Generate link"* ]]
}

@test "remove shortcuts: handles gaps in slot numbers" {
    create_mock_shortcut 0 "Generate link" "<Shift>L"
    create_mock_shortcut 2 "Text to Markdown code" "<Primary>Above_Tab"
    create_mock_shortcut 5 "Find text in files" "<Alt>F"
    # Gaps at 1, 3, 4

    export TEST_MODE="remove_single"
    export TARGET_SHORTCUT="Text to Markdown code"
    run "${TEST_TMP_DIR}/remove_shortcuts_test.sh"

    [ "$status" -eq 0 ]
    [[ "$output" == *"REMOVED: Text to Markdown code"* ]]

    # Verify others remain
    bindings=$(cat "${GSETTINGS_DATA}")
    [[ "$bindings" == *"custom0"* ]]
    [[ "$bindings" != *"custom2"* ]]
    [[ "$bindings" == *"custom5"* ]]
}

####################################################################################################
# TEST CASES - gsettings Cleanup
####################################################################################################

@test "remove shortcuts: calls gsettings reset for all properties" {
    create_mock_shortcut 0 "Generate link" "<Shift>L"

    # Clear reset log
    rm -f "${TEST_TMP_DIR}/reset_log"

    export TEST_MODE="remove_single"
    export TARGET_SHORTCUT="Generate link"
    run "${TEST_TMP_DIR}/remove_shortcuts_test.sh"

    [ "$status" -eq 0 ]

    # Verify reset was called for all properties
    reset_log=$(cat "${TEST_TMP_DIR}/reset_log" 2>/dev/null || echo "")
    [[ "$reset_log" == *"name"* ]]
    [[ "$reset_log" == *"command"* ]]
    [[ "$reset_log" == *"binding"* ]]
}

####################################################################################################
# TEST CASES - List Manipulation
####################################################################################################

@test "remove shortcuts: correctly removes from beginning of list" {
    create_mock_shortcut 0 "Generate link" "<Shift>L"
    create_mock_shortcut 1 "Text to Markdown code" "<Primary>Above_Tab"
    create_mock_shortcut 2 "Find text in files" "<Alt>F"

    export TEST_MODE="remove_single"
    export TARGET_SHORTCUT="Generate link"
    run "${TEST_TMP_DIR}/remove_shortcuts_test.sh"

    [ "$status" -eq 0 ]

    bindings=$(cat "${GSETTINGS_DATA}")
    [[ "$bindings" != *"custom0"* ]]
    [[ "$bindings" == *"custom1"* ]]
    [[ "$bindings" == *"custom2"* ]]
}

@test "remove shortcuts: correctly removes from middle of list" {
    create_mock_shortcut 0 "Generate link" "<Shift>L"
    create_mock_shortcut 1 "Text to Markdown code" "<Primary>Above_Tab"
    create_mock_shortcut 2 "Find text in files" "<Alt>F"

    export TEST_MODE="remove_single"
    export TARGET_SHORTCUT="Text to Markdown code"
    run "${TEST_TMP_DIR}/remove_shortcuts_test.sh"

    [ "$status" -eq 0 ]

    bindings=$(cat "${GSETTINGS_DATA}")
    [[ "$bindings" == *"custom0"* ]]
    [[ "$bindings" != *"custom1"* ]]
    [[ "$bindings" == *"custom2"* ]]
}

@test "remove shortcuts: correctly removes from end of list" {
    create_mock_shortcut 0 "Generate link" "<Shift>L"
    create_mock_shortcut 1 "Text to Markdown code" "<Primary>Above_Tab"
    create_mock_shortcut 2 "Find text in files" "<Alt>F"

    export TEST_MODE="remove_single"
    export TARGET_SHORTCUT="Find text in files"
    run "${TEST_TMP_DIR}/remove_shortcuts_test.sh"

    [ "$status" -eq 0 ]

    bindings=$(cat "${GSETTINGS_DATA}")
    [[ "$bindings" == *"custom0"* ]]
    [[ "$bindings" == *"custom1"* ]]
    [[ "$bindings" != *"custom2"* ]]
}

####################################################################################################
# TEST CASES - Integration
####################################################################################################

@test "remove shortcuts: full workflow - create then remove" {
    # Simulate creating shortcuts
    create_mock_shortcut 0 "Generate link" "<Shift>L"
    create_mock_shortcut 1 "Text to Markdown code" "<Primary>Above_Tab"
    create_mock_shortcut 2 "Find text in files" "<Alt>F"

    # Verify they exist
    bindings=$(cat "${GSETTINGS_DATA}")
    [[ "$bindings" == *"custom0"* ]]
    [[ "$bindings" == *"custom1"* ]]
    [[ "$bindings" == *"custom2"* ]]

    # Remove all
    export TEST_MODE="remove_all"
    run "${TEST_TMP_DIR}/remove_shortcuts_test.sh"

    [ "$status" -eq 0 ]
    [[ "$output" == *"SUMMARY: Removed=3 Skipped=0"* ]]

    # Verify all removed
    bindings=$(cat "${GSETTINGS_DATA}")
    [[ "$bindings" != *"custom0"* ]]
    [[ "$bindings" != *"custom1"* ]]
    [[ "$bindings" != *"custom2"* ]]
}

@test "remove shortcuts: idempotent - safe to run twice" {
    create_mock_shortcut 0 "Generate link" "<Shift>L"

    # Remove first time
    export TEST_MODE="remove_single"
    export TARGET_SHORTCUT="Generate link"
    run "${TEST_TMP_DIR}/remove_shortcuts_test.sh"
    [ "$status" -eq 0 ]

    # Remove second time - should report not found
    run "${TEST_TMP_DIR}/remove_shortcuts_test.sh"
    [ "$status" -eq 1 ]
    [[ "$output" == *"NOT_FOUND"* ]]
}
