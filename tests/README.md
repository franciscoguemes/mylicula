# MyLiCuLa Test Suite

This directory contains automated tests for the MyLiCuLa project using the BATS (Bash Automated Testing System) framework.

## Prerequisites

### Install BATS

**Ubuntu/Debian:**
```bash
sudo nala update
sudo nala install bats
```

**From source (latest version):**
```bash
git clone https://github.com/bats-core/bats-core.git
cd bats-core
sudo ./install.sh /usr/local
```

**Verify installation:**
```bash
bats --version
```

## Running Tests

### Run all tests
```bash
# From project root
bats tests/

# Or from tests directory
cd tests
bats .
```

### Run specific test file
```bash
bats tests/test_common_create_symlink.bats
```

### Run with verbose output
```bash
bats --tap tests/test_common_create_symlink.bats
```

### Run with timing information
```bash
bats --timing tests/
```

## Test Structure

```
tests/
├── README.md                          # This file
├── test_common_create_symlink.bats    # Tests for create_symlink function
└── test_*.bats                        # Additional test files
```

## Writing New Tests

### Test File Template

```bash
#!/usr/bin/env bats
# Test suite for <component>

setup() {
    # Load the common library
    BASE_DIR="$(cd "$(dirname "$BATS_TEST_FILENAME")/.." && pwd)"
    source "${BASE_DIR}/lib/common.sh"

    # Create temporary directory
    TEST_TMP_DIR="$(mktemp -d)"
}

teardown() {
    # Clean up
    if [[ -n "$TEST_TMP_DIR" ]] && [[ -d "$TEST_TMP_DIR" ]]; then
        rm -rf "$TEST_TMP_DIR"
    fi
}

@test "description of test" {
    # Test code here
    run your_command

    [ "$status" -eq 0 ]
    [[ "$output" == *"expected"* ]]
}
```

### BATS Assertions

Common assertions used in tests:

```bash
# Exit status
[ "$status" -eq 0 ]        # Command succeeded
[ "$status" -ne 0 ]        # Command failed
[ "$status" -eq 1 ]        # Specific exit code

# Output matching
[[ "$output" == "exact match" ]]           # Exact match
[[ "$output" == *"substring"* ]]           # Contains substring
[[ "$output" =~ ^pattern$ ]]               # Regex match

# File/directory checks
[ -f "$file" ]             # File exists
[ -d "$dir" ]              # Directory exists
[ -L "$link" ]             # Symlink exists
[ -e "$path" ]             # Path exists (any type)
[ ! -e "$path" ]           # Path does not exist

# Symlink specific
[ "$(readlink "$link")" = "$target" ]      # Symlink points to target
```

## Test Coverage

### `test_common_create_symlink.bats`

Tests for the `create_symlink()` function in `lib/common.sh`:

- ✅ Source file validation
- ✅ Direct circular reference detection
- ✅ Indirect circular reference detection
- ✅ Excessive symlink depth detection
- ✅ Idempotency (skip when correct)
- ✅ Update when link points to wrong target
- ✅ Protection against overwriting files/directories
- ✅ Parent directory creation
- ✅ Relative and absolute path handling
- ✅ Symlink chains (source is a symlink)
- ✅ Verbose vs non-verbose modes
- ✅ Edge cases (spaces, special characters)

**Total: 20 test cases**

## Continuous Integration

To integrate with CI/CD:

```yaml
# Example for GitHub Actions
test:
  runs-on: ubuntu-latest
  steps:
    - uses: actions/checkout@v2
    - name: Install BATS
      run: sudo apt-get install -y bats
    - name: Run tests
      run: bats tests/
```

## Troubleshooting

### Tests fail with "command not found"

Make sure BATS is installed:
```bash
which bats
```

### Tests fail with "No such file or directory"

Run tests from the project root directory:
```bash
cd /path/to/mylicula
bats tests/
```

### Tests create files that aren't cleaned up

Each test uses a temporary directory (`$TEST_TMP_DIR`) that is automatically cleaned up in the `teardown()` function. If cleanup fails, check that the teardown function is executing.

## Adding More Tests

To add tests for other components:

1. Create a new test file: `tests/test_<component>.bats`
2. Follow the template structure above
3. Add `setup()` and `teardown()` functions
4. Write test cases with `@test` decorator
5. Run the tests to verify they pass

## Best Practices

1. **Isolate tests**: Each test should be independent
2. **Clean up**: Always clean up resources in `teardown()`
3. **Use descriptive names**: Test names should clearly describe what is being tested
4. **Test edge cases**: Include tests for error conditions and boundary cases
5. **Keep tests fast**: Avoid unnecessary delays or large file operations
6. **Document complex tests**: Add comments for non-obvious test logic

## Resources

- [BATS Documentation](https://bats-core.readthedocs.io/)
- [BATS GitHub](https://github.com/bats-core/bats-core)
- [Bash Testing Guide](https://github.com/bats-core/bats-core#writing-tests)
