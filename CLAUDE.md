# MyLiCuLa: My Linux Custom Layer

## Project Overview
MyLiCuLa is a customization layer for Ubuntu Linux that automates system setup to ensure homogeneity across all of Francisco's Linux devices. It installs applications, packages, menus, custom utilities, and configuration. The project implements the conventions described in the General Conventions documentation.

## Repository Structure
```
.
├── setup/              - Installation and configuration scripts
│   ├── apps/          - Application installation scripts
│   └── *.sh           - Setup scripts
├── uninstall/          - Uninstallation and cleanup scripts
├── resources/          - Configuration files, templates, and data
│   ├── apt/           - Package lists
│   ├── icons/         - Custom icons
│   ├── readmes/       - Post-installation documentation (14 README files)
│   ├── snap/          - Snap package lists
│   └── templates/     - File templates
├── scripts/            - Helper and utility scripts
│   └── bash/          - Bash helper scripts
├── in_review/          - Scripts under review (staging area)
├── docs/                - Documentation
│   └── adr/            - Architectural Decision Records
├── install.sh          - Main interactive installation script
├── README.md           - Project documentation
├── Testing.md          - Testing guidelines
├── TODO.md             - Pending tasks marked with TODO: tags
└── LICENSE             - Project license
```

## Bash Requirements & Versions
- Bash 4.0+ required (check with `bash --version` or `echo "${BASH_VERSION}"`)
- Python 3.X support where needed (check with `python3 --version`)
- All scripts should be bash 4.0+ compatible

## Architectural Decision Records (ADRs)

**When making significant architectural or design decisions, document them as ADRs.**

### What Requires an ADR

Create an ADR when making decisions about:
- Architecture patterns and conventions (e.g., installer interface pattern)
- Technology choices or standard tools
- Project structure and organization changes
- Key workflows and processes
- Standards and guidelines that affect multiple scripts
- Breaking changes to established patterns

### ADR Process

1. **Copy the template**: `cp docs/adr/template.md docs/adr/XXXX-decision-title.md`
2. **Fill in the sections**: Context, Decision, Consequences, Alternatives
3. **Start with status "Proposed"**: Change to "Accepted" after approval
4. **Update the ADR index**: Add entry to table in `docs/adr/README.md`

### Existing ADRs

Key architectural decisions already documented:
- [ADR-0001](docs/adr/0001-use-installer-interface-pattern.md) - Installer Interface Pattern
- [ADR-0002](docs/adr/0002-centralize-logs-in-var-log-mylicula.md) - Centralized Logging
- [ADR-0003](docs/adr/0003-configuration-driven-scripts.md) - Configuration-Driven Scripts
- [ADR-0004](docs/adr/0004-package-installation-structure.md) - Package Installation Structure
- [ADR-0005](docs/adr/0005-integrate-bash-scripts-into-repository.md) - Integrate Bash Scripts

See `docs/adr/README.md` for complete list and ADR guidelines.

## Script Development Workflow
Scripts move through a review process:
1. **Development**: Create scripts in `in_review/` directory
2. **Review**: Scripts are tested and reviewed in `in_review/`
3. **Production**: Once approved, scripts move to appropriate directories (`setup/`, `uninstall/`, or `resources/`)

Follow project conventions when creating scripts:
- Documentation header (describe purpose and usage)
- Function documentation showing parameters and return values
- Global variable naming conventions
- Consistent code style and structure
- Interpolation format: `<<<KEY_TO_INTERPOLATE>>>` for values to be replaced during installation

## Post-Installation Documentation (IMPORTANT)

**When creating or updating installation scripts in `setup/`, you MUST also maintain the corresponding README file in `resources/readmes/`.**

### README File Naming Convention

For each installation script, there must be a matching README file:

| Installation Script | README File | Component Name |
|-------------------|-------------|----------------|
| `setup/install_packages.sh` | `resources/readmes/README_packages.md` | `packages` |
| `setup/install_snap.sh` | `resources/readmes/README_snap.md` | `snap` |
| `setup/install_bash_scripts.sh` | `resources/readmes/README_bash_scripts.md` | `bash_scripts` |
| `setup/create_keyboard_shortcuts.sh` | `resources/readmes/README_keyboard.md` | `keyboard` |
| `setup/clone_gitlab_repositories.sh` | `resources/readmes/README_gitlab.md` | `gitlab` |
| `setup/clone_github_repositories.sh` | `resources/readmes/README_github.md` | `github` |
| `setup/install_icons.sh` | `resources/readmes/README_icons.md` | `icons` |
| `setup/install_templates.sh` | `resources/readmes/README_templates.md` | `templates` |
| `setup/install_set-title_function.sh` | `resources/readmes/README_set_title.md` | `set_title` |
| `setup/create_maven_global_configuration.sh` | `resources/readmes/README_maven.md` | `maven` |
| `setup/create_directory_structure.sh` | `resources/readmes/README_directory.md` | `directory` |
| `setup/apps/install_flyway.sh` | `resources/readmes/README_flyway.md` | `flyway` |
| `setup/apps/install_toolbox.sh` | `resources/readmes/README_toolbox.md` | `toolbox` |

### README File Format

Each README file MUST include:

```markdown
# Component Name

Brief description of what was installed.

## 📍 Installation Location
- **Primary Location**: /path/to/installation
- **Configuration**: /path/to/config
- **Log File**: /var/log/mylicula/<script-name>.log

## 🚀 Usage
Basic usage examples and commands

## 🔧 Configuration
How to configure or customize the component

## 🔄 Re-running / Updating
How to update or reinstall using MyLiCuLa installer

## 💡 Important Notes
- Key information users should know
- Idempotency notes
- System requirements

## 🆘 Troubleshooting
Common issues and solutions

---
For more help, see: [official documentation link]
```

### When to Update README Files

**You MUST update the corresponding README file when:**
1. Creating a new installation script in `setup/`
2. Changing installation locations or paths
3. Modifying configuration file locations
4. Adding new features or options
5. Changing usage instructions or commands
6. Updating system requirements

### Desktop README Feature

After installation completes, `install.sh` automatically:
1. Creates `~/Desktop/README MyLiCuLa/` directory
2. Copies `README_main.md` (always)
3. Copies component-specific READMEs for installed components only
4. Shows user where documentation was created

This ensures users have immediate access to documentation for what was just installed on their system.

## Installation Process
- Root script: `install.sh` - Interactive installation asking configuration questions
- **Production scripts** in `setup/` directory - Ready for Ubuntu installation
- **Resources** in `resources/` directory - Configuration files, templates, icons
- **Uninstall scripts** in `uninstall/` directory - Cleanup and removal
- **Staging area** `in_review/` contains scripts under development/testing
- Dry-run copies files to `.target` directory for review before installation
- Files are interpolated during installation

## Key Commands
- `bash -n setup/**/*.sh` - Syntax check all setup scripts
- `bash -n uninstall/**/*.sh` - Syntax check uninstall scripts
- `bash -n in_review/**/*.sh` - Syntax check scripts in review
- Check testing guidelines in `Testing.md`
- Review existing scripts in `setup/` as examples

## Git Workflow
- Create new scripts in `in_review/` directory
- Follow naming and documentation conventions from existing scripts in `setup/`
- Mark incomplete work with `TODO:` comments
- Interpolation values use `<<<KEY>>>` format
- Test thoroughly before moving scripts to production directories
- Once approved/reviewed, scripts move from `in_review/` to appropriate production directory
- Commit messages should indicate whether scripts are being added to review or promoted to production

## Important Notes
- **Setup scripts** live in `setup/` directory - Installation and configuration
- **Uninstall scripts** live in `uninstall/` directory - Cleanup and removal
- **Resources** live in `resources/` directory - Data files, configs, templates
- **Scripts under development** stay in `in_review/` until approved
- Ubuntu-focused (no artificial linux/ubuntu split)
- Interactive scripts ask for user input and configuration
- Dry-run testing verifies changes before applying to system
- Project aims for homogeneous configuration across devices
- Follow conventions from existing production scripts in `setup/`

## Contributing
- Fork the project for your favorite Linux distribution
- Start new scripts in `in_review/` directory
- Follow conventions from existing production scripts in `setup/`
- Suggest improvements, scripts, or new customizations
- Keep scripts organized: `setup/` for install, `uninstall/` for removal, `resources/` for data
- Test thoroughly and document any new patterns discovered
- Once tested and approved, scripts can be promoted to production directories