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

## Script Development Workflow
1. Identify if it's generic Linux or Ubuntu-specific
2. Create script in `in_review/linux/` or `in_review/ubuntu/`
3. Follow conventions from existing production scripts in `customize/`
4. Add documentation header describing purpose and usage
5. Add function documentation for all functions
6. Implement your customization logic
7. Test syntax: `bash -n in_review/linux/your_script.sh` or `in_review/ubuntu/`
8. Once thoroughly tested and approved, move to `customize/linux/` or `customize/ubuntu/`
9. Commit with clear message about the customization being added

## Code Review Checklist
When developing MyLiCuLa scripts, verify:
1. Script follows conventions from existing production scripts in `customize/`
2. Documentation header is complete and clear
3. All functions have parameter documentation
4. Global variable names are consistent with existing scripts
5. Syntax passes: `bash -n in_review/**/*.sh`
6. No hardcoded paths (use interpolation: <<<KEY>>>)
7. Interactive prompts are clear for user input
8. Works with bash 4.0+
9. Appropriate for either linux/ (generic) or ubuntu/ (specific)
10. Aligns with General Conventions philosophy
11. Ready to move from `in_review/` to `customize/` after approval

## Common Patterns in MyLiCuLa Scripts
- Convention-based approach: Follow existing patterns from `customize/` production scripts
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
- **Production environment**: Uses scripts from `customize/linux/` and `customize/ubuntu/`
- **Development/Testing**: Scripts in `in_review/` are not used in production installs
- Dry-run mode: Files copied to `.target` directory before actual installation
- Interpolation: Values marked with <<<KEY>>> are replaced with collected configuration
- Linux setup: Runs generic customizations first
- Ubuntu setup: Runs distribution-specific customizations second

## When Creating New Customization Scripts
1. Identify if it's generic Linux or Ubuntu-specific
2. **Start in staging area**: Create in `in_review/linux/` or `in_review/ubuntu/`
3. Study existing scripts in `customize/` as examples and conventions
4. Add documentation header with script purpose
5. Add all necessary interpolation points: `<<<KEY>>>`
6. Test syntax compliance: `bash -n your_script.sh`
7. Document in commit message what customization is being added
8. Once tested and approved, move script to `customize/linux/` or `customize/ubuntu/`
9. Update README.md if it's a major new feature

## File Structure Best Practices
**Production scripts (ready for install.sh):**
- Generic customizations: `customize/linux/`
- Ubuntu-specific customizations: `customize/ubuntu/`

**Development/Staging (under review):**
- Generic customizations in review: `in_review/linux/`
- Ubuntu-specific customizations in review: `in_review/ubuntu/`
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
- Script not being used: Check if it's in `customize/` (production) not `in_review/`
- Conventions unclear: Study existing scripts in `customize/` directory for patterns