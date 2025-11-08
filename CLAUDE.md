# MyLiCuLa: My Linux Custom Layer

## Project Overview
MyLiCuLa is a customization layer for Ubuntu Linux that automates system setup to ensure homogeneity across all of Francisco's Linux devices. It installs applications, packages, menus, custom utilities, and configuration. The project implements the conventions described in the General Conventions documentation.

## Repository Structure
```
.
├── customize/           - Production-ready customization scripts
│   ├── linux/          - Generic Linux customizations
│   └── ubuntu/         - Ubuntu-specific customizations
├── in_review/          - Scripts under review (staging area)
│   ├── git/            - Git-related configurations (under review)
│   ├── linux/          - Generic Linux customizations (under review)
│   ├── linux_setup.sh  - Entry point for Linux setup (under review)
│   ├── ubuntu/         - Ubuntu-specific customizations (under review)
│   └── ubuntu_setup.sh - Entry point for Ubuntu setup (under review)
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
3. **Production**: Once approved, scripts move to `customize/` directory

Follow project conventions when creating scripts:
- Documentation header (describe purpose and usage)
- Function documentation showing parameters and return values
- Global variable naming conventions
- Consistent code style and structure
- Interpolation format: `<<<KEY_TO_INTERPOLATE>>>` for values to be replaced during installation

## Installation Process
- Root script: `install.sh` - Interactive installation asking configuration questions
- **Production customizations** applied from `customize/` directory:
    1. Linux customizations (generic) from `customize/linux/`
    2. Ubuntu customizations (specific) from `customize/ubuntu/`
- **Staging area** `in_review/` contains scripts under development/testing
- Dry-run copies files to `.target` directory for review before installation
- Files are interpolated during installation

## Key Commands
- `bash -n customize/**/*.sh` - Syntax check all production scripts
- `bash -n in_review/**/*.sh` - Syntax check scripts in review
- Check testing guidelines in `Testing.md`
- Review existing scripts in `customize/` as examples

## Git Workflow
- Create new scripts in `in_review/` directory
- Follow naming and documentation conventions from existing scripts in `customize/`
- Mark incomplete work with `TODO:` comments
- Interpolation values use `<<<KEY>>>` format
- Test thoroughly before moving scripts to `customize/`
- Once approved/reviewed, scripts move from `in_review/` to `customize/`
- Commit messages should indicate whether scripts are being added to review or promoted to production

## Important Notes
- **Production scripts** live in `customize/` directory
- **Scripts under development** stay in `in_review/` until approved
- Scripts can be generic (Linux) or distribution-specific (Ubuntu)
- Interactive scripts ask for user input and configuration
- Dry-run testing verifies changes before applying to system
- Project aims for homogeneous configuration across multiple machines
- Follow conventions from existing production scripts in `customize/`

## Contributing
- Fork the project for your favorite Linux distribution
- Start new scripts in `in_review/` directory
- Follow conventions from existing production scripts in `customize/`
- Suggest improvements, scripts, or new customizations
- Keep scripts organized in appropriate subdirectories (linux/ or ubuntu/)
- Test thoroughly and document any new patterns discovered
- Once tested and approved, scripts can be promoted to `customize/`