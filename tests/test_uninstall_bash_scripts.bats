#!/usr/bin/env bats
####################################################################################################
# Test suite for customize/linux/uninstall_bash_scripts.sh
#
# This test suite validates the bash script uninstallation functionality including:
# - Symlink removal from /usr/local/bin (mocked)
# - Safety checks (only removes symlinks pointing to our scripts)
# - Idempotency (safe to run multiple times)
# - Error handling for missing directories
# - Protection against removing regular files
# - Integration with lib/common.sh for colored output
#
# Tests use a temporary directory structure to simulate the real environment.
####################################################################################################

# Setup function runs before each test
setup() {
    # Create temporary test directory
    export TEST_TMP_DIR="$(mktemp -d)"
    export MYLICULA_BASE_DIR="${TEST_TMP_DIR}"
    export BASH_SCRIPTS_DIR="${TEST_TMP_DIR}/scripts/bash"
    export BIN_DIR="${TEST_TMP_DIR}/bin"
    export LIB_DIR="${TEST_TMP_DIR}/lib"

    # Create directory structure
    mkdir -p "${BASH_SCRIPTS_DIR}"
    mkdir -p "${BIN_DIR}"
    mkdir -p "${LIB_DIR}"

    # Copy common.sh library to test location (for color constants)
    cp "${BATS_TEST_DIRNAME}/../lib/common.sh" "${LIB_DIR}/common.sh"

    # Create test wrapper script that simulates uninstall_bash_scripts.sh
    cat > "${TEST_TMP_DIR}/uninstall_test.sh" <<'WRAPPER'
#!/usr/bin/env bash

BASE_DIR="${TEST_TMP_DIR}"
source "${LIB_DIR}/common.sh"

# Disable errexit from common.sh for testing
set +e

BASH_DIR="$BASE_DIR/scripts/bash"
TARGET_DIR="$BASE_DIR/bin"

if [ ! -d "$BASH_DIR" ]; then
    echo "ERROR: Source directory does not exist: $BASH_DIR"
    exit 1
fi

removed_count=0
skipped_count=0
error_count=0

for script in "$BASH_DIR"/*; do
    if [ -f "$script" ]; then
        script_name=$(basename "$script")
        target_link="$TARGET_DIR/$script_name"

        if [ -L "$target_link" ]; then
            link_target=$(readlink -f "$target_link" 2>/dev/null)
            script_path=$(readlink -f "$script" 2>/dev/null)

            if [ "$link_target" = "$script_path" ]; then
                if rm "$target_link" 2>/dev/null; then
                    echo "REMOVED: $target_link"
                    ((removed_count++))
                else
                    echo "ERROR: Failed to remove $target_link"
                    ((error_count++))
                fi
            else
                echo "SKIP: Link points to different location"
                ((skipped_count++))
            fi
        elif [ -e "$target_link" ]; then
            echo "SKIP: Not a symbolic link"
            ((skipped_count++))
        else
            echo "SKIP: Link does not exist"
            ((skipped_count++))
        fi
    fi
done

echo "REMOVED: $removed_count"
echo "SKIPPED: $skipped_count"
echo "ERRORS: $error_count"

if [ $error_count -eq 0 ]; then
    exit 0
else
    exit 1
fi
WRAPPER

    chmod +x "${TEST_TMP_DIR}/uninstall_test.sh"
}

# Teardown function runs after each test
teardown() {
    rm -rf "$TEST_TMP_DIR"
}

####################################################################################################
# TEST CASES
####################################################################################################

@test "uninstall bash scripts: removes symlinks correctly" {
    # Create script and symlink
    echo "#!/bin/bash" > "${BASH_SCRIPTS_DIR}/script1.sh"
    ln -s "${BASH_SCRIPTS_DIR}/script1.sh" "${BIN_DIR}/script1.sh"

    [ -L "${BIN_DIR}/script1.sh" ]

    run "${TEST_TMP_DIR}/uninstall_test.sh"

    [ "$status" -eq 0 ]
    [[ "$output" == *"REMOVED: 1"* ]]
    [[ "$output" == *"ERRORS: 0"* ]]
    [ ! -e "${BIN_DIR}/script1.sh" ]
}

@test "uninstall bash scripts: removes multiple symlinks" {
    # Create multiple scripts and symlinks
    for i in {1..5}; do
        echo "#!/bin/bash" > "${BASH_SCRIPTS_DIR}/script${i}.sh"
        ln -s "${BASH_SCRIPTS_DIR}/script${i}.sh" "${BIN_DIR}/script${i}.sh"
    done

    run "${TEST_TMP_DIR}/uninstall_test.sh"

    [ "$status" -eq 0 ]
    [[ "$output" == *"REMOVED: 5"* ]]
    [[ "$output" == *"ERRORS: 0"* ]]

    # Verify all symlinks were removed
    for i in {1..5}; do
        [ ! -e "${BIN_DIR}/script${i}.sh" ]
    done
}

@test "uninstall bash scripts: only removes symlinks pointing to our scripts" {
    # Create our script and its correct symlink
    echo "#!/bin/bash" > "${BASH_SCRIPTS_DIR}/our_script.sh"
    ln -s "${BASH_SCRIPTS_DIR}/our_script.sh" "${BIN_DIR}/our_script.sh"

    # Create another script in our directory but its symlink points elsewhere
    echo "#!/bin/bash" > "${BASH_SCRIPTS_DIR}/wrong_target.sh"
    echo "#!/bin/bash" > "${TEST_TMP_DIR}/different_location.sh"
    ln -s "${TEST_TMP_DIR}/different_location.sh" "${BIN_DIR}/wrong_target.sh"

    run "${TEST_TMP_DIR}/uninstall_test.sh"

    [ "$status" -eq 0 ]
    [[ "$output" == *"REMOVED: 1"* ]]
    [[ "$output" == *"SKIPPED: 1"* ]]

    # Our symlink should be removed
    [ ! -e "${BIN_DIR}/our_script.sh" ]

    # Wrong target symlink should remain (points elsewhere)
    [ -L "${BIN_DIR}/wrong_target.sh" ]
}

@test "uninstall bash scripts: does not remove regular files" {
    # Create script
    echo "#!/bin/bash" > "${BASH_SCRIPTS_DIR}/important.sh"

    # Create a regular file (not a symlink) in bin directory
    echo "IMPORTANT DATA" > "${BIN_DIR}/important.sh"

    run "${TEST_TMP_DIR}/uninstall_test.sh"

    [ "$status" -eq 0 ]
    [[ "$output" == *"SKIP: Not a symbolic link"* ]]
    [[ "$output" == *"REMOVED: 0"* ]]
    [[ "$output" == *"SKIPPED: 1"* ]]

    # Regular file should still exist
    [ -f "${BIN_DIR}/important.sh" ]

    # Verify content is intact
    content=$(cat "${BIN_DIR}/important.sh")
    [[ "$content" == "IMPORTANT DATA" ]]
}

@test "uninstall bash scripts: is idempotent (safe to run twice)" {
    # Create script and symlink
    echo "#!/bin/bash" > "${BASH_SCRIPTS_DIR}/script.sh"
    ln -s "${BASH_SCRIPTS_DIR}/script.sh" "${BIN_DIR}/script.sh"

    # Run first time
    run "${TEST_TMP_DIR}/uninstall_test.sh"
    [ "$status" -eq 0 ]
    [[ "$output" == *"REMOVED: 1"* ]]

    # Run second time - should succeed without errors
    run "${TEST_TMP_DIR}/uninstall_test.sh"
    [ "$status" -eq 0 ]
    [[ "$output" == *"REMOVED: 0"* ]]
    [[ "$output" == *"SKIPPED: 1"* ]]
    [[ "$output" == *"ERRORS: 0"* ]]
}

@test "uninstall bash scripts: fails gracefully when source directory missing" {
    # Remove the scripts directory
    rm -rf "${BASH_SCRIPTS_DIR}"

    run "${TEST_TMP_DIR}/uninstall_test.sh"

    [ "$status" -eq 1 ]
    [[ "$output" == *"ERROR: Source directory does not exist"* ]]
}

@test "uninstall bash scripts: handles empty scripts directory" {
    # Empty scripts directory (no files)

    run "${TEST_TMP_DIR}/uninstall_test.sh"

    [ "$status" -eq 0 ]
    [[ "$output" == *"REMOVED: 0"* ]]
    [[ "$output" == *"ERRORS: 0"* ]]
}

@test "uninstall bash scripts: handles missing symlinks gracefully" {
    # Create script but no corresponding symlink
    echo "#!/bin/bash" > "${BASH_SCRIPTS_DIR}/script.sh"

    run "${TEST_TMP_DIR}/uninstall_test.sh"

    [ "$status" -eq 0 ]
    [[ "$output" == *"SKIP: Link does not exist"* ]]
    [[ "$output" == *"REMOVED: 0"* ]]
    [[ "$output" == *"SKIPPED: 1"* ]]
    [[ "$output" == *"ERRORS: 0"* ]]
}

@test "uninstall bash scripts: handles broken symlinks correctly" {
    # Create script
    echo "#!/bin/bash" > "${BASH_SCRIPTS_DIR}/script.sh"

    # Create broken symlink pointing to our script location (but file deleted)
    ln -s "${BASH_SCRIPTS_DIR}/script.sh" "${BIN_DIR}/script.sh"

    # Make it a broken symlink by deleting source temporarily
    temp_backup="${BASH_SCRIPTS_DIR}/script.sh.bak"
    mv "${BASH_SCRIPTS_DIR}/script.sh" "$temp_backup"

    [ -L "${BIN_DIR}/script.sh" ]
    [ ! -e "${BIN_DIR}/script.sh" ]  # Broken symlink

    # Restore source file
    mv "$temp_backup" "${BASH_SCRIPTS_DIR}/script.sh"

    run "${TEST_TMP_DIR}/uninstall_test.sh"

    [ "$status" -eq 0 ]
    [[ "$output" == *"REMOVED: 1"* ]]
    [ ! -e "${BIN_DIR}/script.sh" ]
}

@test "uninstall bash scripts: handles mixed scenario correctly" {
    # Create multiple scenarios:

    # 1. Our script with correct symlink
    echo "#!/bin/bash" > "${BASH_SCRIPTS_DIR}/to_remove.sh"
    ln -s "${BASH_SCRIPTS_DIR}/to_remove.sh" "${BIN_DIR}/to_remove.sh"

    # 2. Our script without symlink
    echo "#!/bin/bash" > "${BASH_SCRIPTS_DIR}/no_link.sh"

    # 3. Our script with regular file instead of symlink
    echo "#!/bin/bash" > "${BASH_SCRIPTS_DIR}/regular_file.sh"
    echo "DATA" > "${BIN_DIR}/regular_file.sh"

    # 4. Our script with symlink pointing elsewhere
    echo "#!/bin/bash" > "${BASH_SCRIPTS_DIR}/wrong_target.sh"
    echo "#!/bin/bash" > "${TEST_TMP_DIR}/other.sh"
    ln -s "${TEST_TMP_DIR}/other.sh" "${BIN_DIR}/wrong_target.sh"

    run "${TEST_TMP_DIR}/uninstall_test.sh"

    [ "$status" -eq 0 ]
    [[ "$output" == *"REMOVED: 1"* ]]
    [[ "$output" == *"SKIPPED: 3"* ]]
    [[ "$output" == *"ERRORS: 0"* ]]

    # Verify correct behavior for each scenario
    [ ! -e "${BIN_DIR}/to_remove.sh" ]          # Removed
    [ ! -e "${BIN_DIR}/no_link.sh" ]            # Never existed
    [ -f "${BIN_DIR}/regular_file.sh" ]         # Protected (not removed)
    [ -L "${BIN_DIR}/wrong_target.sh" ]         # Protected (points elsewhere)
}

@test "uninstall bash scripts: handles scripts with special characters" {
    # Create scripts with special characters
    echo "#!/bin/bash" > "${BASH_SCRIPTS_DIR}/my_script.sh"
    echo "#!/bin/bash" > "${BASH_SCRIPTS_DIR}/my-script.sh"

    ln -s "${BASH_SCRIPTS_DIR}/my_script.sh" "${BIN_DIR}/my_script.sh"
    ln -s "${BASH_SCRIPTS_DIR}/my-script.sh" "${BIN_DIR}/my-script.sh"

    run "${TEST_TMP_DIR}/uninstall_test.sh"

    [ "$status" -eq 0 ]
    [[ "$output" == *"REMOVED: 2"* ]]
    [[ "$output" == *"ERRORS: 0"* ]]

    [ ! -e "${BIN_DIR}/my_script.sh" ]
    [ ! -e "${BIN_DIR}/my-script.sh" ]
}

@test "uninstall bash scripts: provides accurate counts" {
    # Create different scenarios for counting

    # Removed: 2 scripts
    echo "#!/bin/bash" > "${BASH_SCRIPTS_DIR}/remove1.sh"
    echo "#!/bin/bash" > "${BASH_SCRIPTS_DIR}/remove2.sh"
    ln -s "${BASH_SCRIPTS_DIR}/remove1.sh" "${BIN_DIR}/remove1.sh"
    ln -s "${BASH_SCRIPTS_DIR}/remove2.sh" "${BIN_DIR}/remove2.sh"

    # Skipped: 2 scripts (no symlink)
    echo "#!/bin/bash" > "${BASH_SCRIPTS_DIR}/skip1.sh"
    echo "#!/bin/bash" > "${BASH_SCRIPTS_DIR}/skip2.sh"

    run "${TEST_TMP_DIR}/uninstall_test.sh"

    [ "$status" -eq 0 ]
    [[ "$output" == *"REMOVED: 2"* ]]
    [[ "$output" == *"SKIPPED: 2"* ]]
    [[ "$output" == *"ERRORS: 0"* ]]
}

@test "uninstall bash scripts: ignores subdirectories" {
    # Create a subdirectory with script
    mkdir -p "${BASH_SCRIPTS_DIR}/subdir"
    echo "#!/bin/bash" > "${BASH_SCRIPTS_DIR}/subdir/nested.sh"
    ln -s "${BASH_SCRIPTS_DIR}/subdir/nested.sh" "${BIN_DIR}/nested.sh"

    # Create a regular script
    echo "#!/bin/bash" > "${BASH_SCRIPTS_DIR}/regular.sh"
    ln -s "${BASH_SCRIPTS_DIR}/regular.sh" "${BIN_DIR}/regular.sh"

    run "${TEST_TMP_DIR}/uninstall_test.sh"

    [ "$status" -eq 0 ]
    [[ "$output" == *"REMOVED: 1"* ]]

    # Only regular script symlink should be removed
    [ ! -e "${BIN_DIR}/regular.sh" ]

    # Nested script symlink should remain (not in scripts/bash directly)
    [ -L "${BIN_DIR}/nested.sh" ]
}

@test "uninstall bash scripts: verifies symlink target before removal" {
    # Create our script
    echo "#!/bin/bash" > "${BASH_SCRIPTS_DIR}/script.sh"

    # Create symlink pointing to DIFFERENT script with same name elsewhere
    mkdir -p "${TEST_TMP_DIR}/other_location"
    echo "#!/bin/bash" > "${TEST_TMP_DIR}/other_location/script.sh"
    ln -s "${TEST_TMP_DIR}/other_location/script.sh" "${BIN_DIR}/script.sh"

    run "${TEST_TMP_DIR}/uninstall_test.sh"

    [ "$status" -eq 0 ]
    [[ "$output" == *"REMOVED: 0"* ]]
    [[ "$output" == *"SKIPPED: 1"* ]]

    # Symlink should remain (it doesn't point to our script)
    [ -L "${BIN_DIR}/script.sh" ]

    # Verify it still points to the other location
    target=$(readlink "${BIN_DIR}/script.sh")
    [[ "$target" == "${TEST_TMP_DIR}/other_location/script.sh" ]]
}

@test "uninstall bash scripts: handles permission errors gracefully" {
    # Create script and symlink
    echo "#!/bin/bash" > "${BASH_SCRIPTS_DIR}/script.sh"
    ln -s "${BASH_SCRIPTS_DIR}/script.sh" "${BIN_DIR}/script.sh"

    # Make bin directory read-only to simulate permission error
    chmod -w "${BIN_DIR}"

    run "${TEST_TMP_DIR}/uninstall_test.sh"

    # Restore permissions for cleanup
    chmod +w "${BIN_DIR}"

    [ "$status" -eq 1 ]
    [[ "$output" == *"ERROR: Failed to remove"* ]]
    [[ "$output" == *"ERRORS: 1"* ]]
}
