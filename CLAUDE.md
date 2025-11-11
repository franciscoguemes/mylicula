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
│   ├── snap/          - Snap package lists
│   └── templates/     - File templates
├── scripts/            - Helper and utility scripts
│   └── bash/          - Bash helper scripts
├── in_review/          - Scripts under review (staging area)
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