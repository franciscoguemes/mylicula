# MyLiCuLa Setup Scripts

This directory contains installation scripts that customize and configure the Linux system. All scripts follow a standardized interface for consistency, maintainability, and predictable behavior.

## Table of Contents

- [Installer Interface](#installer-interface)
  - [Interface Enforcement](#interface-enforcement)
- [Creating New Installers](#creating-new-installers)
- [Interface Functions](#interface-functions)
- [Refactoring Status](#refactoring-status)
- [Migration Plan](#migration-plan)
- [Best Practices](#best-practices)

---

## Installer Interface

> **⚠️ IMPORTANT: INTERFACE IS NOW ENFORCED**
> As of Phase 5, the installer interface is **MANDATORY** for all scripts in this directory.
> Scripts that do not implement the required functions will be rejected at runtime with a clear error message.
> See [Interface Enforcement](#interface-enforcement) below for details.

All installation scripts in this directory **MUST** implement the standard MyLiCuLa installer interface defined in `lib/installer_common.sh`. This interface uses the Template Method pattern to provide:

- **Standardized execution flow**: Validate → Install → Cleanup on failure
- **Consistent error handling**: Predictable return codes across all installers
- **Idempotency**: Safe to run multiple times without side effects
- **Separation of concerns**: Clear boundary between validation and installation
- **Dry-run support**: Test installations without making changes
- **Debug logging**: Detailed output when troubleshooting

### Required Interface Functions

Every installer script **MUST** implement these three functions:

```bash
get_installer_name()      # Return human-readable installer name
validate_environment()    # Check prerequisites and readiness
run_installation()        # Perform the actual installation
```

### Optional Interface Functions

Installers **MAY** override this function:

```bash
cleanup_on_failure()      # Clean up partial installation (default: does nothing)
```

### Interface Enforcement

The installer interface is **automatically enforced** at runtime. When `execute_installer()` is called, it performs the following validation:

1. **Checks that all required functions are declared** - `get_installer_name()`, `validate_environment()`, `run_installation()`
2. **Verifies functions are actually implemented** - Not just the default stub implementations
3. **Provides clear error messages** - Tells you exactly which functions are missing

**What happens if a script doesn't implement the interface?**

The script will fail immediately with a detailed error message:

```
========================================
ERROR: Installer Interface Not Implemented
========================================

This script does not properly implement the MyLiCuLa installer interface.

Missing or not implemented functions:
  ✗ get_installer_name()
  ✗ validate_environment()
  ✗ run_installation()

Documentation:
  - See setup/README.md for interface documentation
  - See setup/template_installer.sh for example implementation
  - See lib/installer_common.sh for function specifications
========================================
```

**Benefits of enforcement:**

- **Prevents runtime errors** - Catches missing implementations before execution
- **Maintains consistency** - Ensures all scripts follow the same pattern
- **Guides developers** - Clear error messages point to documentation and examples
- **Self-documenting** - Interface requirements are explicit and validated

---

## Creating New Installers

### Quick Start

1. **Copy the template**:
   ```bash
   cp setup/template_installer.sh setup/install_my_feature.sh
   ```

2. **Implement the required functions**:
   - `get_installer_name()` - Give it a descriptive name
   - `validate_environment()` - Check prerequisites
   - `run_installation()` - Implement installation logic

3. **Test your installer**:
   ```bash
   # Validate syntax
   bash -n setup/install_my_feature.sh

   # Test with dry-run
   sudo setup/install_my_feature.sh --dry-run

   # Run with debug logging
   sudo setup/install_my_feature.sh --debug
   ```

4. **Add to install.sh**:
   Update `install.sh` to include your new installer in the menu

### Template Example

See [`template_installer.sh`](template_installer.sh) for a complete, documented example with:
- Standard script structure
- All required interface implementations
- Common validation patterns
- Dry-run support examples
- Comprehensive documentation

---

## Interface Functions

### 1. `get_installer_name()`

**Purpose**: Return a human-readable name for display in logs and UI

**Returns**:
- `stdout`: Human-readable installer name
- Return code: `0` on success

**Example**:
```bash
get_installer_name() {
    echo "Package Installation"
}
```

---

### 2. `validate_environment()`

**Purpose**: Check that the environment is ready for installation

**Should validate**:
- Required applications exist (`git`, `curl`, `jq`, etc.)
- Required permissions available (sudo, file access, etc.)
- Installation not already complete (idempotency check)
- Configuration values are valid
- Sufficient disk space available

**Returns**:
- Return code `0`: Validation passed, ready to install
- Return code `1`: Validation failed, cannot proceed
- Return code `2`: Already installed, skip installation (idempotent)

**Example**:
```bash
validate_environment() {
    log "INFO" "Validating environment..."

    # Check root privileges
    if [[ $EUID -ne 0 ]]; then
        log "ERROR" "Root privileges required"
        return 1
    fi

    # Check required apps
    if ! check_required_app "git" "sudo nala install git"; then
        return 1
    fi

    # Check idempotency
    if [[ -f "/etc/myapp/installed" ]]; then
        log "INFO" "Already installed"
        return 2
    fi

    return 0
}
```

---

### 3. `run_installation()`

**Purpose**: Perform the actual installation

**Should**:
- Be idempotent (safe to run multiple times)
- Respect `DRY_RUN_MODE` if set
- Provide progress feedback via log functions
- Handle errors gracefully
- Return meaningful exit codes

**Returns**:
- Return code `0`: Installation succeeded
- Return code `1`: Installation failed

**Example**:
```bash
run_installation() {
    log "INFO" "Starting installation..."

    if [[ "$DRY_RUN_MODE" == true ]]; then
        log "INFO" "[DRY-RUN] Would install packages..."
        return 0
    fi

    # Actual installation logic
    if ! nala install -y package1 package2; then
        log "ERROR" "Failed to install packages"
        return 1
    fi

    log "INFO" "Installation completed"
    return 0
}
```

---

### 4. `cleanup_on_failure()` (Optional)

**Purpose**: Clean up partial installation if `run_installation()` fails

**Should**:
- Remove partially created files
- Delete broken symlinks
- Revert configuration changes
- Leave system in clean state

**Returns**:
- Return code `0`: Cleanup succeeded
- Return code `1`: Cleanup failed

**Example**:
```bash
cleanup_on_failure() {
    log "INFO" "Cleaning up after failure..."

    # Remove partial installation
    rm -f /etc/myapp/config.conf
    rm -f /usr/local/bin/myapp

    log "INFO" "Cleanup completed"
    return 0
}
```

---

## Refactoring Status

This section tracks the migration of existing installers to the new interface.

### ✅ Implementing Interface (13 scripts)

Scripts that have been refactored to use the standard interface:

| Script | Interface Complete | Notes |
|--------|-------------------|-------|
| `install_bash_scripts.sh` | ✅ Yes | Reference implementation |
| `create_directory_structure.sh` | ✅ Yes | Directory structure creation with idempotency |
| `install_packages.sh` | ✅ Yes | Package installation with PPA/GPG support |
| `install_snap.sh` | ✅ Yes | Snap package installation with FLAGS support |
| `install_icons.sh` | ✅ Yes | Icon installation with gio support |
| `install_templates.sh` | ✅ Yes | Nautilus template installation |
| `install_set-title_function.sh` | ✅ Yes | Bash function installation to .bashrc |
| `apps/install_flyway.sh` | ✅ Yes | Flyway database migration tool installation |
| `apps/install_toolbox.sh` | ✅ Yes | JetBrains Toolbox installation with checksum verification |
| `clone_github_repositories.sh` | ✅ Yes | GitHub repository cloning with PAT authentication |
| `clone_gitlab_repositories.sh` | ✅ Yes | GitLab repository cloning with PAT authentication and custom instance support |
| `create_keyboard_shortcuts.sh` | ✅ Yes | GNOME keyboard shortcuts with gsettings integration |
| `create_maven_global_configuration.sh` | ✅ Yes | Maven settings configuration with vanilla/custom templates |

### ✅ Legacy Scripts (0 scripts)

All scripts have been successfully migrated to the standard installer interface!

### Priority Levels

- **High**: Core functionality, frequently used, or complex error handling needed
- **Medium**: Important but less frequently used
- **Low**: Nice to have, simple logic

---

## Migration Plan

The refactoring follows a phased approach to minimize disruption:

### Phase 1: Foundation ✅ COMPLETE

- [x] Create installer interface in `lib/installer_common.sh`
- [x] Create template installer `template_installer.sh`
- [x] Document interface in `setup/README.md`
- [x] Refactor reference implementation (`install_bash_scripts.sh`)

### Phase 2: High Priority Scripts ✅ COMPLETE

Refactor high-priority scripts that are frequently used:

- [x] `install_packages.sh`
- [x] `install_snap.sh`
- [x] `clone_github_repositories.sh`
- [x] `clone_gitlab_repositories.sh`

### Phase 3: Medium Priority Scripts ✅ COMPLETE

Refactor medium-priority scripts:

- [x] `create_directory_structure.sh`
- [x] `create_keyboard_shortcuts.sh`
- [x] `create_maven_global_configuration.sh`

### Phase 4: Low Priority Scripts ✅ COMPLETE

Refactor remaining scripts:

- [x] `install_icons.sh`
- [x] `install_templates.sh`
- [x] `install_set-title_function.sh`
- [x] `apps/install_flyway.sh`
- [x] `apps/install_toolbox.sh`

### Phase 5: Enforcement ✅ COMPLETE

**Interface is now mandatory** - All scripts must implement the standard interface:

- [x] **Update `execute_installer()` in `lib/installer_common.sh`**:
  - ✅ Added validation to check all required functions are implemented
  - ✅ Detects both missing functions and stub implementations
  - ✅ Provides clear, actionable error messages with documentation links
  - ✅ Includes function names, requirements, and examples in error output

- [x] **Update documentation**:
  - ✅ Added prominent warning banner in setup/README.md
  - ✅ Created "Interface Enforcement" section with examples
  - ✅ Updated table of contents
  - ✅ Marked all phases as complete

- [x] **Testing**:
  - ✅ Tested validation with compliant script (PASSED)
  - ✅ Tested rejection of non-compliant script (PASSED)
  - ✅ Verified clear error messages are displayed
  - ✅ Confirmed all 13 scripts implement the interface

**Status**: The installer interface is now **ENFORCED**. Any script that does not implement the required functions (`get_installer_name`, `validate_environment`, `run_installation`) will be rejected at runtime with a detailed error message pointing to documentation and examples.

**Migration Complete**: All 13 setup scripts successfully implement the standard interface. The project maintains 100% compliance.

---

## Best Practices

### Script Structure

1. **Standard header**: Use the documentation template from `template_installer.sh`
2. **Set strict mode**: `set -euo pipefail`
3. **Find BASE_DIR**: Use standard upward search pattern
4. **Source libraries**: Always source both `common.sh` and `installer_common.sh`
5. **Configuration section**: Define script-specific constants
6. **Help function**: Provide comprehensive help message
7. **Interface implementation**: Implement required functions
8. **Helper functions**: Add private functions as needed
9. **Main function**: Parse arguments and call `execute_installer`
10. **Entry point guard**: Only run main when executed (not sourced)

### Validation Best Practices

- **Fail early**: Check prerequisites before making any changes
- **Be specific**: Provide actionable error messages
- **Check idempotency**: Return code 2 if already installed
- **Verify permissions**: Check sudo, file access, etc.
- **Validate configuration**: Ensure required env vars are set

### Installation Best Practices

- **Support dry-run**: Check `DRY_RUN_MODE` before making changes
- **Log progress**: Use `log "INFO"` for progress messages
- **Handle errors**: Return meaningful exit codes
- **Be idempotent**: Safe to run multiple times
- **Respect configuration**: Use `MYLICULA_*` environment variables

### Error Handling

```bash
# Good: Specific error with actionable message
if ! command_exists "git"; then
    log "ERROR" "Git is not installed"
    log "ERROR" "Install with: sudo nala install git"
    return 1
fi

# Bad: Generic error without context
if ! command_exists "git"; then
    return 1
fi
```

### Logging

```bash
# Use appropriate log levels
log "INFO"  "Starting installation..."    # Progress
log "ERROR" "Failed to create directory"  # Errors
debug "Processing file: $filename"        # Debug info (only with --debug)

# Dry-run logging
if [[ "$DRY_RUN_MODE" == true ]]; then
    log "INFO" "[DRY-RUN] Would install package"
else
    nala install -y package
fi
```

---

## Example: Refactoring Checklist

When refactoring a legacy script, follow this checklist:

- [ ] Copy `template_installer.sh` or use as reference
- [ ] Update documentation header with interface references
- [ ] Source `lib/installer_common.sh`
- [ ] Implement `get_installer_name()`
- [ ] Implement `validate_environment()`
  - [ ] Check required applications
  - [ ] Check permissions
  - [ ] Check idempotency
- [ ] Implement `run_installation()`
  - [ ] Support `DRY_RUN_MODE`
  - [ ] Use log functions
  - [ ] Return proper exit codes
- [ ] Implement `cleanup_on_failure()` if needed
- [ ] Update `main()` to call `execute_installer`
- [ ] Add `show_help()` function
- [ ] Test with `bash -n`
- [ ] Test with `--dry-run`
- [ ] Test with `--debug`
- [ ] Test actual installation
- [ ] Test idempotency (run twice)
- [ ] Update this README refactoring status

---

## Additional Resources

- **Interface Definition**: `lib/installer_common.sh`
- **Template Example**: `template_installer.sh`
- **Reference Implementation**: `install_bash_scripts.sh`
- **Common Functions**: `lib/common.sh`
- **Project Documentation**: `../README.md`
- **Development Guide**: `../.claude/CLAUDE.md`

---

## Questions?

If you have questions about the installer interface:

1. Read the template: `template_installer.sh`
2. Check the reference: `install_bash_scripts.sh`
3. Review the library: `lib/installer_common.sh`
4. See project docs: `../.claude/CLAUDE.md`

---

**Last Updated**: 2025-01-14
**Maintained By**: Francisco Güemes <francisco@franciscoguemes.com>
