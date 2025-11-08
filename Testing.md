# Testing MyLiCuLa

This document describes how to test the MyLiCuLa customization scripts at different levels before installing them on your machine.

## Testing Strategy

MyLiCuLa employs a **multi-level testing approach**:

1. **Unit Tests** - Automated tests for individual functions (BATS framework)
2. **Integration Tests** - Testing scripts in isolated environments (Docker/VM)
3. **Dry-Run Tests** - Preview changes before applying them
4. **Syntax Validation** - Ensure scripts are syntactically correct

---

## 1. Unit Tests (BATS)

### Overview

Unit tests validate individual functions in isolation using the **BATS (Bash Automated Testing System)** framework. These tests run quickly (seconds) and catch bugs early in development.

**Location:** `tests/` directory

**Current Coverage:**
- `create_symlink()` function: 20 comprehensive test cases
  - Source validation
  - Circular reference detection (direct & indirect)
  - Excessive symlink depth detection
  - Idempotency checks
  - Data protection (won't overwrite files/directories)
  - Edge cases (spaces, special characters)

### Installing BATS

```bash
# Automated installation
./tests/install_bats.sh

# Or manual installation
sudo nala update
sudo nala install bats

# Verify installation
bats --version
```

### Running Unit Tests

```bash
# Run all unit tests
./tests/run_tests.sh

# Run specific test file
./tests/run_tests.sh test_common_create_symlink.bats

# Run with verbose output (see each test case)
./tests/run_tests.sh --verbose

# Run with timing information
./tests/run_tests.sh --timing

# Install BATS and run tests in one command
./tests/run_tests.sh --install-bats
```

### Expected Output

```
MyLiCuLa Test Runner
========================================

ℹ Using BATS: Bats 1.10.0

Running all tests...

 ✓ create_symlink: fails when source does not exist
 ✓ create_symlink: succeeds when source exists
 ✓ create_symlink: detects direct circular reference (link -> link)
 ✓ create_symlink: detects indirect circular reference (a -> b -> a)
 ✓ create_symlink: detects circular chain (a -> b -> c -> a)
 ✓ create_symlink: detects excessive symlink depth
 ✓ create_symlink: skips when link already points to correct target
 ...

20 tests, 0 failures

========================================
✓ All tests passed!
========================================
```

### Writing New Unit Tests

See `tests/README.md` for detailed instructions on writing BATS tests.

**Quick example:**
```bash
@test "my_function: does something correctly" {
    # Arrange
    local input="test_value"

    # Act
    run my_function "$input"

    # Assert
    [ "$status" -eq 0 ]
    [[ "$output" == *"expected"* ]]
}
```

### When to Write Unit Tests

Write unit tests when:
- Creating new utility functions in `lib/common.sh`
- Implementing complex logic with edge cases
- Fixing bugs (add test to prevent regression)
- Refactoring existing code

---

## 2. Integration Tests

Integration tests verify that scripts work correctly in realistic environments. MyLiCuLa supports two approaches:

### A. Docker Container Testing

Best for testing **Linux System scripts** (packages, environment variables, terminal functions).

**Advantages:**
- Fast to set up and tear down
- Lightweight
- Perfect for CI/CD pipelines
- Isolates tests from host system 


**Prerequisites:**
- Docker installed and configured

**Steps:**

1. Create a Docker container of the Linux System you want to test (e.g., [Ubuntu 22.04](https://hub.docker.com/_/ubuntu)):
```bash
docker run -it --name mylicula-test ubuntu:22.04 /bin/bash
```

2. Inside the container, install prerequisites:
```bash
apt update
apt install -y git bash
```

3. Clone MyLiCuLa:
```bash
git clone https://github.com/franciscoguemes/mylicula.git
cd mylicula
```

4. Test the installation:
```bash
./install.sh --dry-run
```

5. Clean up after testing:
```bash
# Exit container
exit

# Remove container
docker rm mylicula-test
```

**TODO:** Create automated Docker test script

### B. Virtual Machine Testing

Best for testing **Ubuntu UI customizations** (icons, menus, desktop environment).

**Advantages:**
- Full GUI environment
- Test visual customizations
- Complete Ubuntu experience
- Can test multiple snapshots

**Steps:**

1. **Install VirtualBox** on your host OS

2. **Download Ubuntu image** from [OSBOXES](https://www.osboxes.org/)
   - Check the __Info__ tab for username/password

3. **Verify SHA256 checksum:**
```bash
sha256sum DOWNLOADED_FILE.7z
```

4. **Extract the file:**
```bash
sudo apt-get install p7zip-full
7z e DOWNLOADED_FILE.7z
```

5. **Copy to VirtualBox directory:**
```bash
mv EXTRACTED_FILE.vdi ~/VirtualBox\ VMs/
```

6. **Create VM in VirtualBox:**
   - Machine → New
   - At "Hard disk" section, choose "Use an existing virtual hard disk file"
   - Select the .vdi file

7. **Configure shared folders:**
   - Mount MyLiCuLa project as shared folder
   - Devices → Shared Folders → Add folder

8. **Initial setup:**
   - Start VM
   - Configure language, keyboard
   - Install VirtualBox Guest Additions
   - Test that system is usable

9. **Create snapshot:**
   - Machine → Take Snapshot
   - Name: "Clean Ubuntu - Pre MyLiCuLa"

10. **Test installation:**
```bash
cd /path/to/mylicula
./install.sh --dry-run
./install.sh
```

11. **After testing:**
   - Restore snapshot to test again
   - Or create new snapshot if changes are good

---

## 3. Dry-Run Tests

The safest way to test before making real changes to your system.

### What is Dry-Run?

Dry-run mode creates a `.target/` directory showing exactly what would be installed **without modifying** your actual system.

### Running Dry-Run

```bash
# Preview all changes
./install.sh --dry-run

# Preview with verbose output
./install.sh --dry-run --verbose

# Inspect what would change
cd .target
tree                           # See directory structure
find . -type f                 # List all files
cat home/francisco/.bashrc     # Preview specific file
```

### Dry-Run Directory Structure

```
.target/
├── home/
│   └── francisco/
│       ├── .bashrc            # Modified shell config
│       ├── .config/           # Configuration files
│       ├── Templates/         # File templates
│       └── bin/               # Custom scripts
└── etc/
    └── environment            # System environment
```

### When to Use Dry-Run

- Before first installation on a new machine
- After making changes to scripts
- When unsure what a script will do
- Before proposing changes to production

---

## 4. Syntax Validation

Always validate syntax before running scripts.

### Check All Scripts

```bash
# Check all production scripts
bash -n customize/**/*.sh

# Check scripts in review
bash -n in_review/**/*.sh

# Check specific script
bash -n customize/linux/my_script.sh

# Check library
bash -n lib/common.sh
```

### What Syntax Check Catches

✅ Missing quotes
✅ Unclosed brackets
✅ Invalid function definitions
✅ Typos in bash keywords

❌ Logic errors (use unit tests)
❌ Runtime errors (use dry-run/integration tests)

---

## Testing Workflow

Recommended testing sequence when developing:

1. **Write Code** - Create/modify scripts
2. **Syntax Check** - `bash -n script.sh`
3. **Unit Tests** - `./tests/run_tests.sh` (for lib functions)
4. **Dry-Run** - `./install.sh --dry-run` (preview changes)
5. **Integration Test** - Test in Docker or VM
6. **Manual Verification** - Run on actual system (if confident)

## Continuous Integration

### Future: GitHub Actions

```yaml
# Example .github/workflows/test.yml
name: Test MyLiCuLa

on: [push, pull_request]

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v2

      - name: Install BATS
        run: ./tests/install_bats.sh

      - name: Run unit tests
        run: ./tests/run_tests.sh

      - name: Syntax check
        run: bash -n customize/**/*.sh

      - name: Dry-run test
        run: ./install.sh --dry-run
```

---

## Troubleshooting Tests

### BATS Tests Fail

```bash
# Install/update BATS
./tests/install_bats.sh

# Run with verbose output
./tests/run_tests.sh --verbose

# Check BATS version
bats --version
```

### Docker Tests Fail

```bash
# Ensure Docker is running
docker ps

# Check container logs
docker logs mylicula-test

# Interactive debugging
docker run -it ubuntu:22.04 /bin/bash
```

### Syntax Errors Not Caught

```bash
# Use shellcheck for advanced checking
sudo apt install shellcheck
shellcheck customize/**/*.sh
```

---

## Resources

- [BATS Documentation](https://bats-core.readthedocs.io/)
- [Testing Bash Scripts](https://github.com/bats-core/bats-core)
- [Shellcheck](https://www.shellcheck.net/)
- [Docker Testing](https://docs.docker.com/get-started/)

---

**Last Updated:** November 2024 - Unit testing added