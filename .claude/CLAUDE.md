# MyLiCuLa: My Linux Custom Layer

## Quick Reference
This file configures Claude Code for developing MyLiCuLa customization scripts.

## Project Context
MyLiCuLa automates Linux (Ubuntu) customization through bash scripts. The project ensures homogeneity across multiple machines by installing packages, configurations, custom utilities, and environment customizations.

## Before & After Hooks
- Before edits: Validate syntax with `bash -n`
- After edits: Check conventions are being followed and syntax is valid

## Custom Commands
Define in `.claude/commands/`:
- `/review-conventions` - Check script follows project conventions from production scripts
- `/interpolate` - Check for proper <<<KEY>>> interpolation syntax
- `/test-dry-run` - Simulate installation with .target directory review
- `/check-syntax` - Validate bash syntax for all scripts

## Installer Interface (REQUIRED)

**All scripts in `setup/` MUST implement the standard installer interface.**

The interface is **enforced at runtime**. Scripts that don't implement it will be rejected with a clear error message.

### Required Functions (3):
1. `get_installer_name()` - Return human-readable installer name
2. `validate_environment()` - Check prerequisites and readiness (return 0=ready, 1=failed, 2=already installed)
3. `run_installation()` - Perform the actual installation (return 0=success, 1=failure)

### Optional Functions (1):
4. `cleanup_on_failure()` - Clean up after installation failure (default implementation does nothing)

### Template and Documentation:
- **Template**: `setup/template_installer.sh` - Complete example implementation
- **Documentation**: `setup/README.md` - Full interface specification
- **Library**: `lib/installer_common.sh` - Interface definition and execution flow

### Script Structure:
```bash
#!/usr/bin/env bash
set -euo pipefail

# Find BASE_DIR and source libraries
source "${BASE_DIR}/lib/common.sh"
source "${BASE_DIR}/lib/installer_common.sh"

# Implement required functions
get_installer_name() { echo "My Installer"; }
validate_environment() { ...; return 0; }
run_installation() { ...; return 0; }

# Main function: parse args and call execute_installer
main() {
    setup_installer_common  # Initialize logging
    execute_installer       # Run standard flow
}

main "$@"
```

## Script Development Workflow
1. Determine script type: installation (`setup/`), uninstall (`uninstall/`), or resources (`resources/`)
2. Create script in `in_review/` directory using `setup/template_installer.sh` as base
3. **Implement the installer interface** (get_installer_name, validate_environment, run_installation)
4. Follow conventions from existing production scripts in `setup/`
5. Add documentation header describing purpose and usage
6. Add function documentation for all functions
7. Test syntax: `bash -n in_review/your_script.sh`
8. Test with dry-run: `sudo in_review/your_script.sh --dry-run --debug`
9. Once thoroughly tested and approved, move to appropriate production directory (`setup/`, `uninstall/`, or `resources/`)
10. Commit with clear message about the customization being added

## Code Review Checklist
When developing MyLiCuLa scripts, verify:
1. **Implements installer interface** (REQUIRED for setup/ scripts):
   - ✓ `get_installer_name()` implemented
   - ✓ `validate_environment()` implemented with proper return codes (0/1/2)
   - ✓ `run_installation()` implemented
   - ✓ `cleanup_on_failure()` implemented if cleanup needed
   - ✓ Sources `lib/common.sh` and `lib/installer_common.sh`
   - ✓ Calls `execute_installer` in main function
2. Script follows conventions from existing production scripts in `setup/`
3. Documentation header is complete and clear
4. All functions have parameter documentation
5. Global variable names are consistent with existing scripts
6. Syntax passes: `bash -n in_review/**/*.sh` and `bash -n setup/**/*.sh`
7. No hardcoded paths (use interpolation: <<<KEY>>>)
8. Interactive prompts are clear for user input
9. Works with bash 4.0+
10. Appropriate directory: `setup/` for install, `uninstall/` for removal, `resources/` for data
11. Dry-run and debug modes work correctly (`--dry-run`, `--debug`)
12. Idempotency: Safe to run multiple times
13. Aligns with General Conventions philosophy
14. Ready to move from `in_review/` to production after approval

## Common Patterns in MyLiCuLa Scripts
- Convention-based approach: Follow existing patterns from `setup/` production scripts
- Interpolation pattern:
  ```bash
  # Configuration values to be interpolated
  CONFIG_VALUE="<<<CONFIG_VALUE>>>"
  INSTALL_PATH="<<<INSTALL_PATH>>>"
  ```

- Interactive setup pattern (from linux_setup.sh / ubuntu_setup.sh):
  ```bash
  read -p "Enter configuration: " user_input
  # Process user input
  ```

- Documentation header (from production scripts):
  ```bash
  #!/bin/bash
  # Script: script_name
  # Description: What this script customizes
  # Parameters: List of parameters if applicable
  ```

## Installation Process Understanding
- Main entry: `install.sh` (interactive, gathers configuration)
- **Production environment**: Uses scripts from `setup/` directory
- **Resources**: Configuration files, templates, icons in `resources/` directory
- **Uninstall**: Removal scripts in `uninstall/` directory
- **Development/Testing**: Scripts in `in_review/` are not used in production installs
- Dry-run mode: Files copied to `.target` directory before actual installation
- Interpolation: Values marked with <<<KEY>>> are replaced with collected configuration
- Ubuntu-focused: No artificial linux/ubuntu split

## When Creating New Customization Scripts
1. Determine purpose: installation, uninstallation, or data/resources
2. **Start in staging area**: Create in `in_review/` directory
3. Study existing scripts in `setup/` as examples and conventions
4. Add documentation header with script purpose
5. Add all necessary interpolation points: `<<<KEY>>>`
6. Test syntax compliance: `bash -n your_script.sh`
7. Document in commit message what customization is being added
8. Once tested and approved, move script to appropriate production directory (`setup/`, `uninstall/`, or `resources/`)
9. Update README.md if it's a major new feature

## File Structure Best Practices
**Production directories:**
- Installation scripts: `setup/`
- Uninstall scripts: `uninstall/`
- Resources (data, configs, templates): `resources/`
- Helper utilities: `scripts/bash/`

**Development/Staging (under review):**
- All new scripts start in: `in_review/`
- Setup scripts in review: `in_review/linux_setup.sh`, `in_review/ubuntu_setup.sh`
- Git configurations in review: `in_review/git/`

## Environment Assumptions
- Bash 4.0 or higher available
- Running on Ubuntu Linux (or Linux for generic scripts)
- User has appropriate permissions for customization
- Python 3.X available if Python scripts needed

## Troubleshooting
- Bash version too old: Script requires 4.0+ (check with `bash --version`)
- Interpolation not working: Check format is <<<KEY>>> not {{KEY}} or ${KEY}
- Syntax errors: Run `bash -n script.sh` to identify issues
- Test with dry-run first: Uses `.target` directory to preview changes
- Script not being used: Check if it's in production directories (`setup/`, `uninstall/`, `resources/`) not `in_review/`
- Conventions unclear: Study existing scripts in `setup/` directory for patterns