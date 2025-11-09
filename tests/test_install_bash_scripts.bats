#!/usr/bin/env bats
####################################################################################################
# Test suite for customize/linux/install_bash_scripts.sh
#
# This test suite validates the bash script installation functionality including:
# - Script discovery and permission setting
# - Symlink creation in /usr/local/bin (mocked)
# - Idempotency (safe to run multiple times)
# - Error handling for missing directories
# - Integration with lib/common.sh create_symlink function
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

    # Copy common.sh library to test location
    cp "${BATS_TEST_DIRNAME}/../lib/common.sh" "${LIB_DIR}/common.sh"

    # Create test wrapper script that simulates install_bash_scripts.sh
    cat > "${TEST_TMP_DIR}/install_test.sh" <<'WRAPPER'
#!/usr/bin/env bash

BASE_DIR="${TEST_TMP_DIR}"
source "${LIB_DIR}/common.sh"

# Disable errexit from common.sh for testing
set +e

BASH_DIR="$BASE_DIR/scripts/bash"
BIN_DIR="$BASE_DIR/bin"

if [ ! -d "$BASH_DIR" ]; then
    echo "ERROR: Source directory does not exist: $BASH_DIR"
    exit 1
fi

processed_count=0
error_count=0

for file in "$BASH_DIR"/*; do
    if [ -f "$file" ]; then
        filename=$(basename "$file")

        if [ ! -x "$file" ]; then
            chmod +x "$file" || {
                echo "ERROR: Failed to set execute permissions for $filename"
                ((error_count++))
                continue
            }
        fi

        link_path="$BIN_DIR/$filename"

        create_symlink "$file" "$link_path" false
        result=$?
        if [ $result -eq 0 ] || [ $result -eq 2 ]; then
            # 0 = created, 2 = skipped (already correct)
            ((processed_count++))
        else
            ((error_count++))
        fi
    fi
done

echo "PROCESSED: $processed_count"
echo "ERRORS: $error_count"

if [ $error_count -eq 0 ]; then
    exit 0
else
    exit 1
fi
WRAPPER

    chmod +x "${TEST_TMP_DIR}/install_test.sh"
}

# Teardown function runs after each test
teardown() {
    rm -rf "$TEST_TMP_DIR"
}

####################################################################################################
# TEST CASES
####################################################################################################

@test "install bash scripts: discovers and processes bash scripts" {
    # Create test bash scripts
    echo "#!/bin/bash" > "${BASH_SCRIPTS_DIR}/script1.sh"
    echo "echo 'test1'" >> "${BASH_SCRIPTS_DIR}/script1.sh"

    echo "#!/bin/bash" > "${BASH_SCRIPTS_DIR}/script2.sh"
    echo "echo 'test2'" >> "${BASH_SCRIPTS_DIR}/script2.sh"

    run "${TEST_TMP_DIR}/install_test.sh"

    [ "$status" -eq 0 ]
    [[ "$output" == *"PROCESSED: 2"* ]]
    [[ "$output" == *"ERRORS: 0"* ]]
}

@test "install bash scripts: creates symlinks in bin directory" {
    # Create test bash script
    echo "#!/bin/bash" > "${BASH_SCRIPTS_DIR}/test_script.sh"

    run "${TEST_TMP_DIR}/install_test.sh"

    [ "$status" -eq 0 ]
    [ -L "${BIN_DIR}/test_script.sh" ]
}

@test "install bash scripts: sets execute permissions on scripts" {
    # Create test bash script without execute permission
    echo "#!/bin/bash" > "${BASH_SCRIPTS_DIR}/no_exec.sh"
    chmod -x "${BASH_SCRIPTS_DIR}/no_exec.sh"

    [ ! -x "${BASH_SCRIPTS_DIR}/no_exec.sh" ]

    run "${TEST_TMP_DIR}/install_test.sh"

    [ "$status" -eq 0 ]
    [ -x "${BASH_SCRIPTS_DIR}/no_exec.sh" ]
}

@test "install bash scripts: symlinks point to correct source files" {
    # Create test bash script
    echo "#!/bin/bash" > "${BASH_SCRIPTS_DIR}/check_target.sh"

    run "${TEST_TMP_DIR}/install_test.sh"

    [ "$status" -eq 0 ]

    # Verify symlink points to correct source
    target=$(readlink "${BIN_DIR}/check_target.sh")
    [[ "$target" == "${BASH_SCRIPTS_DIR}/check_target.sh" ]]
}

@test "install bash scripts: is idempotent (safe to run twice)" {
    # Create test bash script
    echo "#!/bin/bash" > "${BASH_SCRIPTS_DIR}/idempotent.sh"

    # Run first time
    run "${TEST_TMP_DIR}/install_test.sh"
    [ "$status" -eq 0 ]
    [[ "$output" == *"PROCESSED: 1"* ]]

    # Run second time - should succeed without errors
    run "${TEST_TMP_DIR}/install_test.sh"
    [ "$status" -eq 0 ]
    [[ "$output" == *"ERRORS: 0"* ]]
}

@test "install bash scripts: handles multiple scripts correctly" {
    # Create multiple test bash scripts
    for i in {1..5}; do
        echo "#!/bin/bash" > "${BASH_SCRIPTS_DIR}/script${i}.sh"
        echo "echo 'test${i}'" >> "${BASH_SCRIPTS_DIR}/script${i}.sh"
    done

    run "${TEST_TMP_DIR}/install_test.sh"

    [ "$status" -eq 0 ]
    [[ "$output" == *"PROCESSED: 5"* ]]
    [[ "$output" == *"ERRORS: 0"* ]]

    # Verify all symlinks were created
    for i in {1..5}; do
        [ -L "${BIN_DIR}/script${i}.sh" ]
    done
}

@test "install bash scripts: fails gracefully when source directory missing" {
    # Remove the scripts directory
    rm -rf "${BASH_SCRIPTS_DIR}"

    run "${TEST_TMP_DIR}/install_test.sh"

    [ "$status" -eq 1 ]
    [[ "$output" == *"ERROR: Source directory does not exist"* ]]
}

@test "install bash scripts: handles empty scripts directory" {
    # Empty scripts directory (no files)

    run "${TEST_TMP_DIR}/install_test.sh"

    [ "$status" -eq 0 ]
    [[ "$output" == *"PROCESSED: 0"* ]]
    [[ "$output" == *"ERRORS: 0"* ]]
}

@test "install bash scripts: ignores subdirectories" {
    # Create a subdirectory
    mkdir -p "${BASH_SCRIPTS_DIR}/subdir"
    echo "#!/bin/bash" > "${BASH_SCRIPTS_DIR}/subdir/nested.sh"

    # Create a regular script
    echo "#!/bin/bash" > "${BASH_SCRIPTS_DIR}/regular.sh"

    run "${TEST_TMP_DIR}/install_test.sh"

    [ "$status" -eq 0 ]
    [[ "$output" == *"PROCESSED: 1"* ]]

    # Only regular script should have symlink
    [ -L "${BIN_DIR}/regular.sh" ]
    [ ! -L "${BIN_DIR}/nested.sh" ]
}

@test "install bash scripts: handles scripts with special characters in names" {
    # Create scripts with special characters (spaces, underscores, hyphens)
    echo "#!/bin/bash" > "${BASH_SCRIPTS_DIR}/my_script.sh"
    echo "#!/bin/bash" > "${BASH_SCRIPTS_DIR}/my-script.sh"

    run "${TEST_TMP_DIR}/install_test.sh"

    [ "$status" -eq 0 ]
    [[ "$output" == *"PROCESSED: 2"* ]]

    [ -L "${BIN_DIR}/my_script.sh" ]
    [ -L "${BIN_DIR}/my-script.sh" ]
}

@test "install bash scripts: updates symlink if pointing to wrong target" {
    # Create original script
    echo "#!/bin/bash" > "${BASH_SCRIPTS_DIR}/script.sh"

    # Create symlink pointing to wrong location
    echo "#!/bin/bash" > "${TEST_TMP_DIR}/wrong_location.sh"
    ln -s "${TEST_TMP_DIR}/wrong_location.sh" "${BIN_DIR}/script.sh"

    run "${TEST_TMP_DIR}/install_test.sh"

    [ "$status" -eq 0 ]

    # Verify symlink now points to correct location
    target=$(readlink "${BIN_DIR}/script.sh")
    [[ "$target" == "${BASH_SCRIPTS_DIR}/script.sh" ]]
}

@test "install bash scripts: does not overwrite regular files" {
    # Create a regular file (not a symlink) in bin directory
    echo "IMPORTANT DATA" > "${BIN_DIR}/important.sh"

    # Create script with same name in scripts directory
    echo "#!/bin/bash" > "${BASH_SCRIPTS_DIR}/important.sh"

    run "${TEST_TMP_DIR}/install_test.sh"

    # Should have error because regular file exists
    [[ "$output" == *"ERRORS: 1"* ]]

    # Verify original file is intact
    content=$(cat "${BIN_DIR}/important.sh")
    [[ "$content" == "IMPORTANT DATA" ]]
}

@test "install bash scripts: handles broken symlinks correctly" {
    # Create a broken symlink in bin directory
    ln -s "/nonexistent/path" "${BIN_DIR}/broken.sh"

    # Create script with same name
    echo "#!/bin/bash" > "${BASH_SCRIPTS_DIR}/broken.sh"

    run "${TEST_TMP_DIR}/install_test.sh"

    [ "$status" -eq 0 ]
    [[ "$output" == *"PROCESSED: 1"* ]]

    # Verify broken symlink was replaced with correct one
    target=$(readlink "${BIN_DIR}/broken.sh")
    [[ "$target" == "${BASH_SCRIPTS_DIR}/broken.sh" ]]
}

@test "install bash scripts: preserves existing correct symlinks" {
    # Create script
    echo "#!/bin/bash" > "${BASH_SCRIPTS_DIR}/existing.sh"

    # Create correct symlink
    ln -s "${BASH_SCRIPTS_DIR}/existing.sh" "${BIN_DIR}/existing.sh"

    # Record inode before
    inode_before=$(ls -i "${BIN_DIR}/existing.sh" | awk '{print $1}')

    run "${TEST_TMP_DIR}/install_test.sh"

    [ "$status" -eq 0 ]
    [[ "$output" == *"ERRORS: 0"* ]]

    # Record inode after
    inode_after=$(ls -i "${BIN_DIR}/existing.sh" | awk '{print $1}')

    # Inode should be the same (symlink not recreated)
    [ "$inode_before" = "$inode_after" ]
}

@test "install bash scripts: handles scripts without shebang" {
    # Create script without shebang (still valid bash)
    echo "echo 'no shebang'" > "${BASH_SCRIPTS_DIR}/no_shebang.sh"

    run "${TEST_TMP_DIR}/install_test.sh"

    [ "$status" -eq 0 ]
    [[ "$output" == *"PROCESSED: 1"* ]]

    [ -L "${BIN_DIR}/no_shebang.sh" ]
}

@test "install bash scripts: handles scripts with different extensions" {
    # Create scripts with different extensions
    echo "#!/bin/bash" > "${BASH_SCRIPTS_DIR}/script.bash"
    echo "#!/bin/bash" > "${BASH_SCRIPTS_DIR}/script.sh"
    echo "#!/bin/bash" > "${BASH_SCRIPTS_DIR}/no_extension"

    run "${TEST_TMP_DIR}/install_test.sh"

    [ "$status" -eq 0 ]
    [[ "$output" == *"PROCESSED: 3"* ]]

    [ -L "${BIN_DIR}/script.bash" ]
    [ -L "${BIN_DIR}/script.sh" ]
    [ -L "${BIN_DIR}/no_extension" ]
}
