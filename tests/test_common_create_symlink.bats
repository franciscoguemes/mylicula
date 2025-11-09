#!/usr/bin/env bats
# Test suite for create_symlink function in lib/common.sh
#
# Run with: bats tests/test_common_create_symlink.bats
# Or run all tests: bats tests/

# Load the common library before each test
setup() {
    # Get the base directory
    BASE_DIR="$(cd "$(dirname "$BATS_TEST_FILENAME")/.." && pwd)"
    export MYLICULA_BASE_DIR="${BASE_DIR}"

    # Source the common library
    source "${BASE_DIR}/lib/common.sh"

    # Create a temporary directory for test files
    TEST_TMP_DIR="$(mktemp -d)"

    # Note: Cannot suppress colored output as these are readonly in common.sh
    # Tests should handle colored output in assertions if needed
}

# Clean up after each test
teardown() {
    # Remove temporary directory
    if [[ -n "$TEST_TMP_DIR" ]] && [[ -d "$TEST_TMP_DIR" ]]; then
        rm -rf "$TEST_TMP_DIR"
    fi
}

#-----------------------------------------------------------------------------
# Test: Source file exists validation
#-----------------------------------------------------------------------------

@test "create_symlink: fails when source does not exist" {
    local source="${TEST_TMP_DIR}/nonexistent_file"
    local link="${TEST_TMP_DIR}/test_link"

    run create_symlink "$source" "$link" "verbose"

    [ "$status" -eq 1 ]
    [[ "$output" == *"[ERROR] Source does not exist"* ]]
}

@test "create_symlink: succeeds when source exists" {
    local source="${TEST_TMP_DIR}/existing_file"
    local link="${TEST_TMP_DIR}/test_link"

    # Create source file
    touch "$source"

    run create_symlink "$source" "$link" "verbose"

    [ "$status" -eq 0 ]
    [[ "$output" == *"[OK] Link created successfully"* ]]
    [ -L "$link" ]
    [ "$(readlink "$link")" = "$source" ]
}

#-----------------------------------------------------------------------------
# Test: Circular reference detection
#-----------------------------------------------------------------------------

@test "create_symlink: detects direct circular reference (link -> link)" {
    local link="${TEST_TMP_DIR}/circular_link"

    run create_symlink "$link" "$link" "verbose"

    [ "$status" -eq 1 ]
    [[ "$output" == *"Circular reference detected"* ]]
    [ ! -e "$link" ]
}

@test "create_symlink: detects indirect circular reference (a -> b -> a)" {
    local link_a="${TEST_TMP_DIR}/link_a"
    local link_b="${TEST_TMP_DIR}/link_b"

    # Create link_a -> link_b
    ln -s "$link_b" "$link_a"

    # Try to create link_b -> link_a (would create circular reference)
    run create_symlink "$link_a" "$link_b" "verbose"

    [ "$status" -eq 1 ]
    [[ "$output" == *"Circular reference"* ]]
}

@test "create_symlink: detects circular chain (a -> b -> c -> a)" {
    local link_a="${TEST_TMP_DIR}/link_a"
    local link_b="${TEST_TMP_DIR}/link_b"
    local link_c="${TEST_TMP_DIR}/link_c"

    # Create chain: a -> b -> c
    ln -s "$link_b" "$link_a"
    ln -s "$link_c" "$link_b"

    # Try to create c -> a (would create circular reference)
    run create_symlink "$link_a" "$link_c" "verbose"

    [ "$status" -eq 1 ]
    [[ "$output" == *"Circular reference"* ]]
}

@test "create_symlink: detects excessive symlink depth" {
    local source="${TEST_TMP_DIR}/link_0"
    local final_link="${TEST_TMP_DIR}/final_link"

    # Create a long chain of symlinks (50 levels, exceeds max of 40)
    for i in {1..50}; do
        local prev="${TEST_TMP_DIR}/link_$((i-1))"
        local curr="${TEST_TMP_DIR}/link_${i}"
        ln -s "$prev" "$curr"
    done

    # The last link in the chain points beyond max depth
    local deep_source="${TEST_TMP_DIR}/link_50"

    run create_symlink "$deep_source" "$final_link" "verbose"

    [ "$status" -eq 1 ]
    [[ "$output" == *"Too many levels of symbolic links"* ]]
}

#-----------------------------------------------------------------------------
# Test: Idempotency - link already exists
#-----------------------------------------------------------------------------

@test "create_symlink: skips when link already points to correct target" {
    local source="${TEST_TMP_DIR}/source_file"
    local link="${TEST_TMP_DIR}/test_link"

    # Create source and initial link
    touch "$source"
    ln -s "$source" "$link"

    # Try to create the same link again
    run create_symlink "$source" "$link" "verbose"

    [ "$status" -eq 2 ]  # Return code 2 indicates "skipped"
    [[ "$output" == *"[SKIP] Link already points to correct target"* ]]
    [ -L "$link" ]
    [ "$(readlink "$link")" = "$source" ]
}

@test "create_symlink: updates when link points to wrong target" {
    local source_old="${TEST_TMP_DIR}/old_source"
    local source_new="${TEST_TMP_DIR}/new_source"
    local link="${TEST_TMP_DIR}/test_link"

    # Create both sources and initial link to old source
    touch "$source_old"
    touch "$source_new"
    ln -s "$source_old" "$link"

    # Update link to point to new source
    run create_symlink "$source_new" "$link" "verbose"

    [ "$status" -eq 0 ]
    [[ "$output" == *"[UPDATE] Link points to wrong target"* ]]
    [[ "$output" == *"[OK] Link created successfully"* ]]
    [ -L "$link" ]
    [ "$(readlink "$link")" = "$source_new" ]
}

#-----------------------------------------------------------------------------
# Test: Protection against overwriting non-symlink files
#-----------------------------------------------------------------------------

@test "create_symlink: refuses to overwrite regular file" {
    local source="${TEST_TMP_DIR}/source_file"
    local existing_file="${TEST_TMP_DIR}/existing_file"

    # Create source and a regular file at link path
    touch "$source"
    echo "important data" > "$existing_file"

    run create_symlink "$source" "$existing_file" "verbose"

    [ "$status" -eq 1 ]
    [[ "$output" == *"[ERROR]"* ]]
    [[ "$output" == *"not a symlink"* ]]
    # Verify original file is unchanged
    [ -f "$existing_file" ]
    [ ! -L "$existing_file" ]
    [ "$(cat "$existing_file")" = "important data" ]
}

@test "create_symlink: refuses to overwrite directory" {
    local source="${TEST_TMP_DIR}/source_file"
    local existing_dir="${TEST_TMP_DIR}/existing_dir"

    # Create source and a directory at link path
    touch "$source"
    mkdir -p "$existing_dir"
    touch "${existing_dir}/important_file"

    run create_symlink "$source" "$existing_dir" "verbose"

    [ "$status" -eq 1 ]
    [[ "$output" == *"[ERROR]"* ]]
    [[ "$output" == *"not a symlink"* ]]
    # Verify directory is unchanged
    [ -d "$existing_dir" ]
    [ ! -L "$existing_dir" ]
    [ -f "${existing_dir}/important_file" ]
}

#-----------------------------------------------------------------------------
# Test: Parent directory creation
#-----------------------------------------------------------------------------

@test "create_symlink: creates parent directories if needed" {
    local source="${TEST_TMP_DIR}/source_file"
    local link="${TEST_TMP_DIR}/deep/nested/path/test_link"

    # Create source
    touch "$source"

    run create_symlink "$source" "$link" "verbose"

    [ "$status" -eq 0 ]
    [[ "$output" == *"[OK] Link created successfully"* ]]
    [ -L "$link" ]
    [ "$(readlink "$link")" = "$source" ]
    [ -d "${TEST_TMP_DIR}/deep/nested/path" ]
}

#-----------------------------------------------------------------------------
# Test: Relative vs absolute paths
#-----------------------------------------------------------------------------

@test "create_symlink: works with relative paths" {
    local source="${TEST_TMP_DIR}/source_file"
    local link="${TEST_TMP_DIR}/test_link"

    # Create source
    touch "$source"

    # Use relative path for source
    cd "$TEST_TMP_DIR"
    run create_symlink "./source_file" "$link" "verbose"

    [ "$status" -eq 0 ]
    [[ "$output" == *"[OK] Link created successfully"* ]]
    [ -L "$link" ]
}

@test "create_symlink: works with absolute paths" {
    local source="${TEST_TMP_DIR}/source_file"
    local link="${TEST_TMP_DIR}/test_link"

    # Create source
    touch "$source"

    # Use absolute paths
    run create_symlink "$source" "$link" "verbose"

    [ "$status" -eq 0 ]
    [[ "$output" == *"[OK] Link created successfully"* ]]
    [ -L "$link" ]
    [ "$(readlink "$link")" = "$source" ]
}

#-----------------------------------------------------------------------------
# Test: Source is a symlink (valid chain)
#-----------------------------------------------------------------------------

@test "create_symlink: works when source is a valid symlink" {
    local real_file="${TEST_TMP_DIR}/real_file"
    local intermediate_link="${TEST_TMP_DIR}/intermediate_link"
    local final_link="${TEST_TMP_DIR}/final_link"

    # Create chain: real_file <- intermediate_link <- final_link
    touch "$real_file"
    ln -s "$real_file" "$intermediate_link"

    run create_symlink "$intermediate_link" "$final_link" "verbose"

    [ "$status" -eq 0 ]
    [[ "$output" == *"[OK] Link created successfully"* ]]
    [ -L "$final_link" ]
    [ "$(readlink "$final_link")" = "$intermediate_link" ]
}

#-----------------------------------------------------------------------------
# Test: Verbose vs non-verbose mode
#-----------------------------------------------------------------------------

@test "create_symlink: verbose mode shows detailed output" {
    local source="${TEST_TMP_DIR}/source_file"
    local link="${TEST_TMP_DIR}/test_link"

    touch "$source"

    run create_symlink "$source" "$link" "verbose"

    [ "$status" -eq 0 ]
    [[ "$output" == *"[OK] Link created successfully"* ]]
}

@test "create_symlink: non-verbose mode shows minimal output" {
    local source="${TEST_TMP_DIR}/source_file"
    local link="${TEST_TMP_DIR}/test_link"

    touch "$source"

    # Call without "verbose" parameter
    run create_symlink "$source" "$link"

    [ "$status" -eq 0 ]
    # Should not have [OK] marker (that's verbose mode)
    [[ "$output" != *"[OK]"* ]]
}

#-----------------------------------------------------------------------------
# Test: Edge cases
#-----------------------------------------------------------------------------

@test "create_symlink: works with spaces in filenames" {
    local source="${TEST_TMP_DIR}/file with spaces.txt"
    local link="${TEST_TMP_DIR}/link with spaces"

    touch "$source"

    run create_symlink "$source" "$link" "verbose"

    [ "$status" -eq 0 ]
    [[ "$output" == *"[OK] Link created successfully"* ]]
    [ -L "$link" ]
    [ "$(readlink "$link")" = "$source" ]
}

@test "create_symlink: works with special characters in filenames" {
    local source="${TEST_TMP_DIR}/file-with_special.chars@123.txt"
    local link="${TEST_TMP_DIR}/link-special_chars"

    touch "$source"

    run create_symlink "$source" "$link" "verbose"

    [ "$status" -eq 0 ]
    [[ "$output" == *"[OK] Link created successfully"* ]]
    [ -L "$link" ]
}
