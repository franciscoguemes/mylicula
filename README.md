MyLiCuLa (My Linux Customization Layer)
==========================================================================

A customization layer for Ubuntu Linux that automates system setup to ensure homogeneity across all your Linux devices. Install once, replicate everywhere.

## Overview

MyLiCuLa automatically installs and configures:
- Applications and packages
- Custom utilities and scripts
- Shell functions and environment variables
- UI customizations and templates
- Development tools and non-standard installations

The entire idea is to automate the concepts from [General Conventions](/home/francisco/git/francisco/franciscoguemes.com/mdwiki/entries/setup/General%20Conventions.md), ensuring you never have to manually set up a new Linux machine again.

## Quick Start

### One-Line Installation (Recommended)

```bash
# Download and run installer directly from GitHub
curl -fsSL https://raw.githubusercontent.com/franciscoguemes/mylicula/main/bootstrap.sh | bash
```

**For security-conscious users** (review before running):
```bash
# Download the bootstrap script
curl -fsSL https://raw.githubusercontent.com/franciscoguemes/mylicula/main/bootstrap.sh -o bootstrap.sh

# Review the script
less bootstrap.sh

# Run the installer
bash bootstrap.sh
```

### Manual Installation (Clone Repository)

```bash
# Clone the repository
git clone https://github.com/franciscoguemes/mylicula.git
cd mylicula

# Run the installer
./install.sh

# Or preview changes first (dry-run mode)
./install.sh --dry-run

# Or run with verbose output
./install.sh --verbose
```

### Installation Options

Environment variables for bootstrap installer:
- `MYLICULA_DIR` - Installation directory (default: `$HOME/mylicula`)
- `MYLICULA_BRANCH` - Git branch to use (default: `main`)
- `MYLICULA_KEEP_REPO` - Keep repository after install (default: `true`)

Example with custom directory:
```bash
curl -fsSL https://raw.githubusercontent.com/franciscoguemes/mylicula/main/bootstrap.sh | MYLICULA_DIR=~/custom/path bash
```

On first run, the installer will ask for your information (name, email, company) and save it to `~/.config/mylicula/mylicula.conf` for future runs.

## Project Structure

```bash
mylicula/
├── setup/                  # Installation and configuration scripts
│   ├── apps/              # Application installation scripts
│   │   ├── install_flyway.sh
│   │   └── install_toolbox.sh
│   ├── clone_github_repositories.sh
│   ├── clone_gitlab_repositories.sh
│   ├── create_directory_structure.sh
│   ├── create_keyboard_shortcuts.sh
│   ├── create_maven_global_configuration.sh
│   ├── install_bash_scripts.sh
│   ├── install_icons.sh
│   ├── install_packages.sh
│   ├── install_set-title_function.sh
│   ├── install_snap.sh
│   └── install_templates.sh
├── uninstall/              # Uninstallation and cleanup scripts
│   ├── remove_keyboard_shortcuts.sh
│   └── uninstall_bash_scripts.sh
├── resources/              # Configuration files, templates, and data
│   ├── apt/               # Package lists
│   │   ├── standard_packages.txt  # Default repo packages
│   │   └── custom_packages.txt    # Custom repos with metadata
│   ├── config/            # Configuration templates
│   │   └── mylicula.conf.example  # Configuration blueprint
│   ├── icons/             # Custom icons
│   ├── snap/              # Snap package lists
│   │   └── list_of_snap.txt       # Snap packages with FLAGS
│   └── templates/         # File templates
├── scripts/                # Helper and utility scripts
│   └── bash/              # Bash helper scripts
│       ├── github/        # GitHub repository management
│       └── gitlab/        # GitLab repository management
├── in_review/              # Scripts under review (staging area)
├── lib/                   # Shared utility libraries
│   ├── common.sh          # Common functions (logging, prompts, symlinks)
│   └── installer_common.sh # Shared installer functions (logging, args, validation)
├── tests/                 # Automated test suite (BATS framework)
│   ├── test_*.bats        # Unit test files (52 tests)
│   ├── install_bats.sh    # BATS installation script
│   ├── run_tests.sh       # Test runner
│   └── README.md          # Testing documentation
├── bootstrap.sh           # One-line installer (downloadable from GitHub)
├── install.sh             # Main interactive installation script
├── README.md              # This file
├── Testing.md             # Testing guidelines
├── TODO.md                # Pending tasks and future enhancements
└── LICENSE                # Project license
```

### Key Directories

**`setup/`** - Installation scripts executed during setup
- Contains all installation and configuration scripts
- Organized by functionality (apps, package installation, customizations)

**`uninstall/`** - Cleanup and removal scripts
- Scripts to uninstall customizations
- Safely removes installed components

**`resources/`** - Configuration files, templates, and data
- `apt/` - Package lists for apt installation
- `config/` - Configuration templates and examples
- `icons/` - Custom directory icons
- `snap/` - Snap package lists
- `templates/` - File templates for Nautilus

**`scripts/`** - Helper scripts and utilities
- Reusable bash scripts for specific tasks
- GitHub and GitLab repository management tools

**`in_review/`** - Staging area for scripts under development
- Scripts are tested here before promotion to `setup/`
- Not executed during normal installation

**`lib/`** - Shared utility functions
- `common.sh` - Logging, prompts, file operations, symlink functions, interpolation
- `installer_common.sh` - Shared installer utilities (logging, argument parsing, validation)

**`tests/`** - Automated unit testing with BATS framework
- `test_*.bats` - Unit test files for functions
- `install_bats.sh` - BATS installation script
- `run_tests.sh` - Test runner with multiple options

## Configuration System

### User Configuration

On first run, `install.sh` creates `~/.config/mylicula/mylicula.conf` with your settings:

```bash
~/.config/mylicula/mylicula.conf    # Your actual config (DO NOT commit!)
```

This file contains:
- User information (username, email, full name)
- Company/organization name
- GitHub username
- **Future: Secrets like GitHub tokens, API keys**

**IMPORTANT:** This file may contain secrets and should NEVER be committed to version control!

### Configuration Blueprint

The repository includes `resources/config/mylicula.conf.example` as a blueprint:
- Shows all available configuration options
- Contains example values
- Safe to commit (no real secrets)

### Configuration Priority

Values are loaded in this order (first found wins):
1. `~/.config/mylicula/mylicula.conf` (user's actual config)
2. Environment variables (`MYLICULA_USERNAME`, `MYLICULA_EMAIL`, etc.)
3. System defaults (`$USER`, git config, auto-detection)

### Reconfiguration

To reconfigure MyLiCuLa:
```bash
# Delete config and run installer again
rm ~/.config/mylicula/mylicula.conf
./install.sh

# Or edit the config file directly
nano ~/.config/mylicula/mylicula.conf
```

## Installation Process

When you run `./install.sh`, it:

1. **Checks Requirements** - Verifies Bash 4.0+, Linux OS, Ubuntu version
2. **Collects Configuration** - Asks for your info or loads from `~/.config/mylicula/mylicula.conf`
3. **Saves Configuration** - Stores settings for future runs
4. **Runs Generic Linux Customizations** - Executes all `customize/linux/*.sh` scripts
5. **Runs Ubuntu Customizations** - Executes all `customize/ubuntu/*.sh` scripts
   - Package installation (apt and snap)
   - Template and icon installation
   - Custom shell functions
6. **Reports Results** - Shows what succeeded/failed

### Installation Options

```bash
./install.sh            # Normal installation
./install.sh --help     # Show help message
./install.sh --dry-run  # Preview changes without applying them
./install.sh --verbose  # Show detailed output
```

### Dry-Run Mode

When using `--dry-run`, MyLiCuLa creates `.target/` directory showing what would be installed:

```bash
./install.sh --dry-run

# Review what would change
cd .target
find . -type f                    # List all files that would be modified
cat home/francisco/.bashrc        # Preview .bashrc changes
```

The `.target/` directory mirrors your actual filesystem, letting you safely preview all changes before applying them.

## Interpolation System

Scripts can use placeholders that are replaced with your actual configuration during installation:

```bash
# In a script template:
AUTHOR_NAME="<<<FULL_NAME>>>"
AUTHOR_EMAIL="<<<EMAIL>>>"
COMPANY="<<<COMPANY>>>"
GITHUB_USER="<<<GITHUB_USER>>>"
```

During installation, these become:
```bash
AUTHOR_NAME="Francisco Guemes"
AUTHOR_EMAIL="francisco@franciscoguemes.com"
COMPANY="Personal"
GITHUB_USER="franciscoguemes"
```

Available interpolation keys:
- `<<<USERNAME>>>` - System username
- `<<<EMAIL>>>` - Email address
- `<<<FULL_NAME>>>` - Full name
- `<<<COMPANY>>>` - Company/organization
- `<<<GITHUB_USER>>>` - GitHub username
- `<<<HOME>>>` - Home directory path
- `<<<USER>>>` - Current user

## Requirements

### System Requirements
- **OS:** Ubuntu Linux (tested on 22.04)
  - Generic scripts work on any Linux distribution
  - Ubuntu-specific scripts require Ubuntu
- **Bash:** 4.0 or higher
- **Python:** 3.x (for Python-based customizations)
- **Git:** For cloning repositories and version control

### Check Your Versions

```bash
# Check Bash version
bash --version
echo "${BASH_VERSION}"

# Check Python version
python3 --version

# Check Ubuntu version (if on Ubuntu)
lsb_release -a
```

## Development Workflow

### Creating New Scripts

1. **Decide Scope** - Generic Linux (`customize/linux/`) or Ubuntu-specific (`customize/ubuntu/`)
2. **Start in Review** - Create script in `in_review/linux/` or `in_review/ubuntu/`
3. **Use Templates** - Follow conventions from existing scripts in `customize/`
4. **Add Documentation** - Include header with description, args, usage, author
5. **Make Executable** - `chmod +x your_script.sh`
6. **Test Syntax** - `bash -n your_script.sh`
7. **Test in Dry-Run** - Move to `customize/` and run `./install.sh --dry-run`
8. **Promote to Production** - Once tested, keep in `customize/` and commit

### Script Conventions

All scripts should follow these conventions:

**1. Documentation Header:**
```bash
#!/bin/bash
#
# Script Name: install_something.sh
# Description: What this script does
#
# Args:
#   $1 - First argument description (if any)
#
# Usage: ./install_something.sh [options]
#
# Output (stdout): What gets printed to stdout
# Output (stderr): What gets printed to stderr
# Return code: 0 on success, non-zero on failure
#
# Author: Your Name
# Email: your.email@example.com
```

**2. Error Handling:**
```bash
set -euo pipefail  # Exit on error, undefined vars, pipe failures
```

**3. Source Common Library:**
```bash
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" &>/dev/null && pwd)"
BASE_DIR="$(cd "$SCRIPT_DIR/../.." &>/dev/null && pwd)"

if [[ -f "${BASE_DIR}/lib/common.sh" ]]; then
    source "${BASE_DIR}/lib/common.sh"
fi
```

**4. Use Logging Functions:**
```bash
log_info "Installing package..."
log_success "Installation complete"
log_warning "Package already installed"
log_error "Failed to install package"
```

**5. Idempotency:**
Scripts should be safe to run multiple times:
```bash
# Check if already installed
if command -v some_command &>/dev/null; then
    log_info "Already installed, skipping"
    return 0
fi
```

**6. Function Documentation:**
```bash
#
# Function: my_function
# Description: What this function does
# Args:
#   $1 - First parameter description
# Usage: my_function "param1"
# Output (stdout): What it outputs
# Return code: 0 on success, 1 on failure
#
my_function() {
    # implementation
}
```

### TODOs

Mark incomplete work with TODO comments:
```bash
# TODO: Add error handling for network failures
# TODO: Support other Linux distributions
```

Major TODOs should also be added to `TODO.md`.

## Shared Libraries

### Common Library (lib/common.sh)

The common library provides utility functions used across all scripts:

### Installer Common Library (lib/installer_common.sh)

Shared functions for package installation scripts:

**Logging:**
- `init_logging()` - Initialize logging infrastructure
- `log \"LEVEL\" \"message\"` - Log with level (INFO, ERROR, DEBUG)
- `debug \"message\"` - Debug logging (only when DEBUG_MODE=true)

**Validation:**
- `check_required_app \"app\" \"install_cmd\"` - Check if command exists
- `require_root()` - Ensure script runs as root

**Argument Parsing:**
- `parse_common_args \"$1\" \"usage_function\"` - Parse --debug, --dry-run, -h

**Setup:**
- `setup_installer_common()` - One-line setup (root check + logging)

### Logging
- `log_info "message"` - Blue informational message
- `log_success "message"` - Green success message
- `log_warning "message"` - Yellow warning message
- `log_error "message"` - Red error message (to stderr)
- `die "message" [exit_code]` - Log error and exit

### User Prompts
- `prompt_user "Enter value"` - Prompt for input
- `prompt_with_default "Enter value" "default"` - Prompt with default
- `prompt_yes_no "Continue?" "y"` - Yes/no question

### File Operations
- `add_to_file_once "content" "file"` - Add if not exists (idempotent)
- `backup_file "file"` - Create timestamped backup
- `create_symlink "source" "link"` - Create symlink (idempotent)
- `ensure_directory "path"` - Create directory if doesn't exist

### Interpolation
- `interpolate_string "string"` - Replace <<<KEY>>> patterns
- `interpolate_file "source" "dest"` - Interpolate entire file
- `interpolate_directory "source" "dest"` - Interpolate all files in directory

### System Detection
- `command_exists "command"` - Check if command available
- `is_ubuntu` - Returns 0 if running Ubuntu
- `get_ubuntu_version` - Returns Ubuntu version (e.g., "22.04")
- `get_script_dir` - Get directory of calling script

## Testing

MyLiCuLa includes comprehensive testing at multiple levels. See `Testing.md` for complete testing guidelines.

### Unit Tests (BATS)

Automated unit tests for individual functions using BATS (Bash Automated Testing System):

```bash
# Install BATS testing framework
./tests/install_bats.sh

# Run all unit tests
./tests/run_tests.sh

# Run specific test file
./tests/run_tests.sh test_common_create_symlink.bats

# Run with verbose output
./tests/run_tests.sh --verbose

# Run with timing information
./tests/run_tests.sh --timing
```

**Current Coverage (52 tests total):**
- `create_symlink()` function: 18 tests
  - Circular reference detection (direct and indirect)
  - Idempotency validation
  - Data protection checks
  - Path handling (relative/absolute, spaces, special characters)
- `install_packages.sh` parsing: 18 tests
  - Standard and custom package parsing
  - Metadata extraction (REPO, GPG, KEYRING)
  - Real-world examples (appimagelauncher, xournalpp, GitHub CLI)
- `install_snap.sh` parsing: 16 tests
  - FLAGS metadata extraction
  - Package groups with different flags
  - Real-world examples (heroku --classic)

### Integration Tests

```bash
# Syntax check all scripts
bash -n customize/**/*.sh
bash -n in_review/**/*.sh

# Dry-run test (preview changes)
./install.sh --dry-run

# Verbose test
./install.sh --dry-run --verbose

# Full integration test in VM/Docker
# See Testing.md for Docker and VM setup
```

## Contributing

Contributions are welcome! Here's how to contribute:

1. **Fork the Repository** - Create your own fork for your Linux distribution
2. **Follow Conventions** - Use existing scripts as templates
3. **Start in Review** - New scripts go in `in_review/`
4. **Test Thoroughly** - Use dry-run mode and test on fresh system
5. **Document** - Include clear documentation headers
6. **Submit PR** - Once tested, submit a pull request

### Contribution Ideas

- Support for other Linux distributions (Fedora, Arch, etc.)
- New customization scripts
- Improved templates
- Better error handling
- Additional utility functions in `lib/common.sh`
- CI/CD improvements

## Project Status

### ✅ Working Features
- **Core Installation System:**
  - Interactive installation with configuration collection
  - Configuration persistence in `~/.config/mylicula/`
  - Dry-run mode with `.target/` preview
  - Generic Linux and Ubuntu orchestration
  - Interpolation system for `<<<KEY>>>` patterns

- **Package Management:**
  - APT package installation with hybrid metadata format
  - Snap package installation with FLAGS support
  - Custom repository handling with automatic GPG key import
  - GitHub CLI integration via package lists
  - 80+ apt packages, 10+ snap packages

- **Code Quality & Testing:**
  - Comprehensive testing suite with BATS (52 tests, all passing)
  - Shared library system (`lib/common.sh`, `lib/installer_common.sh`)
  - Idempotent operations (safe to run multiple times)
  - Circular reference detection for symlinks
  - Error handling and detailed logging

- **Customizations:**
  - Icon installation with custom directory icons
  - Terminal function installation (set-title)
  - File template system for Nautilus
  - Safe symlink management with data protection

### 🚧 In Development
- SSH key generation
- Custom bash scripts deployment from separate repository
- Additional package installers (if needed)

### 📋 Planned Features
- CI/CD testing with GitHub Actions
- Docker-based testing environment
- Support for additional Linux distributions
- Man pages for scripts
- PlantUML documentation diagrams
- Secrets management (GitHub tokens, API keys)

## Troubleshooting

### Configuration Issues

**Problem:** Need to reconfigure
```bash
rm ~/.config/mylicula/mylicula.conf
./install.sh
```

**Problem:** Config file corrupted
```bash
cp resources/config/mylicula.conf.example ~/.config/mylicula/mylicula.conf
nano ~/.config/mylicula/mylicula.conf  # Edit with your values
```

### Installation Issues

**Problem:** Script fails with "command not found"
```bash
# Check if required tools installed
command -v git
command -v bash
bash --version  # Must be 4.0+
```

**Problem:** Permission denied
```bash
# Some scripts require sudo for system-wide changes
# Others should run as regular user for ~/.config
```

**Problem:** Want to skip a script
```bash
# Temporarily move it out of customize/
mv customize/ubuntu/problematic_script.sh in_review/ubuntu/
./install.sh
```

### Debugging

```bash
# Run with verbose output
./install.sh --verbose

# Check syntax of specific script
bash -n customize/linux/my_script.sh

# Test script individually
bash customize/linux/my_script.sh

# Use dry-run to preview
./install.sh --dry-run
cd .target && tree  # Inspect what would change
```

## License

See `LICENSE` file for details.

## Author

**Francisco Güemes**
- Email: francisco@franciscoguemes.com
- GitHub: [@franciscoguemes](https://github.com/franciscoguemes)

## Links

- [General Conventions (mdwiki)](https://mdwiki.franciscoguemes.com/)
- [Manual Setup Steps](https://mdwiki.franciscoguemes.com/#!NEW.md)
- [GitHub Repository](https://github.com/franciscoguemes/mylicula)

---

**Last Updated:** January 2025 - Package Management & Testing Infrastructure Complete
