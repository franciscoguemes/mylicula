# 0005. Integrate Bash Scripts into Repository

**Date:** 2025-01-23

**Status:** Accepted

**Deciders:** Francisco Güemes

## Context

MyLiCuLa automates system setup and customization. A separate `bash_scripts` repository contained custom bash utilities that needed to be installed on each system:

- Custom utility scripts
- Workflow automation tools
- Keyboard shortcuts for GNOME

### The Question

Should these bash scripts:
1. **Be moved into MyLiCuLa** as part of the main repository?
2. **Remain external** and be referenced/cloned during installation?
3. **Use git submodules** to maintain independence while integrating?

### Requirements

- Scripts must be installed to `/usr/local/bin` (via symlinks)
- Keyboard shortcuts must be configured for GNOME
- Installation should be simple and reliable
- Should work for personal use case (single primary user)
- Must support idempotent installation
- Should maintain git history if possible

### MyLiCuLa's Purpose

MyLiCuLa aims to provide **complete system homogeneity** - "Install once, replicate everywhere." The bash scripts are personal utilities that are part of this system setup, not general-purpose tools for wider distribution.

## Decision

**Move bash scripts into the MyLiCuLa repository under `scripts/bash/`.**

### Structure

```
mylicula/
├── scripts/
│   └── bash/               # Custom bash scripts
│       ├── github/         # GitHub-related scripts
│       ├── gitlab/         # GitLab-related scripts
│       ├── certificate/    # Certificate management
│       ├── *.sh            # Utility scripts
│       └── README.md       # Script documentation
├── setup/
│   └── install_bash_scripts.sh   # Installer for scripts
```

### Installation Approach

- `install_bash_scripts.sh` creates symlinks from `scripts/bash/` to `/usr/local/bin/`
- Script names are preserved in symlinks
- Keyboard shortcuts configured via `create_keyboard_shortcuts.sh`
- All managed as part of main MyLiCuLa installation

## Consequences

### Positive

- **Single Source of Truth**: Everything in one repository
- **Simpler Installation**: One `git clone`, one `./install.sh` command
- **No External Dependencies**: No risk of external repository being unavailable
- **Version Consistency**: Scripts versioned together with MyLiCuLa
- **Easier Testing**: Complete system can be tested as a unit
- **Works Offline**: Once cloned, no network required for installation
- **Clearer Purpose**: All personal customizations in one place
- **Atomic Rollbacks**: Reverting MyLiCuLa version reverts scripts too
- **Simpler CI/CD**: Single repository to test and deploy
- **Complete Documentation**: README covers entire setup

### Negative

- **Loss of Script Independence**: Scripts can't be easily shared separately
- **Larger Repository**: More files in main repository
- **Mixed Concerns**: System setup + utility scripts in one repo
- **Harder to Extract**: If scripts need independence later, requires reorganization
- **Repository History**: Separate script evolution history is merged into main repo

### Neutral

- **Personal Use Case**: Optimized for single user (Francisco), not for wide distribution
- **Extraction Path Exists**: Can be extracted to separate repo later if needed
- **Git History Preserved**: Used `git merge --allow-unrelated-histories` to preserve commit history

## Alternatives Considered

### Alternative 1: External Repository Reference

**Description:** Keep `bash_scripts` as separate repository, clone during installation

```bash
# install_bash_scripts.sh would:
# 1. Clone bash_scripts repo to ~/bash_scripts
# 2. Create symlinks from ~/bash_scripts to /usr/local/bin
```

**Rejected because:**
- **Installation Complexity**: Two repositories to manage
- **Network Dependency**: Requires internet for installation
- **Synchronization Issues**: Version mismatch between MyLiCuLa and scripts
- **Configuration Complexity**: Must manage clone location, handle edge cases
- **Reliability**: Fails if external repo unavailable or deleted
- **Testing Complexity**: Can't test complete system in isolation
- **Overkill**: Unnecessary complexity for personal use case

### Alternative 2: Git Submodule

**Description:** Include `bash_scripts` as git submodule in MyLiCuLa

```
mylicula/
├── scripts/  → git submodule pointing to bash_scripts
```

**Rejected because:**
- **Submodule Complexity**: Git submodules are notoriously difficult to manage
- **Update Friction**: Updating requires extra steps (`git submodule update`)
- **Clone Complexity**: Requires `--recursive` flag or separate init step
- **Learning Curve**: Contributors must understand submodules
- **Overkill for Use Case**: Adds complexity without benefit for personal repo
- **Maintenance Burden**: More git operations for routine updates

**When this would make sense:**
- Scripts are maintained by different team
- Scripts have independent release cycle
- Scripts used in multiple projects
- Multiple contributors to scripts repo

### Alternative 3: Package Manager (apt/snap)

**Description:** Package scripts and distribute via package manager

**Rejected because:**
- **Massive Overkill**: Creating packages for personal scripts
- **Maintenance Overhead**: Package creation, updates, repository hosting
- **Distribution Complexity**: Need to host APT repository
- **Unnecessary**: Scripts are personal utilities, not public software
- **Added Dependencies**: Package manager infrastructure

## References

- `scripts/bash/` - Bash scripts directory
- `setup/install_bash_scripts.sh` - Script installer
- `setup/create_keyboard_shortcuts.sh` - Keyboard shortcut configuration
- Original draft: `docs/draft/Install_scripts.md`

## Notes

### Migration Process

Scripts were migrated from separate repository preserving history:

```bash
# In MyLiCuLa repo
git remote add bash_scripts ../bash_scripts
git fetch bash_scripts
git merge --allow-unrelated-histories bash_scripts/main
git remote remove bash_scripts
```

This preserved the complete commit history of the bash scripts.

### Script Organization

Scripts are organized by purpose:
- **github/**: GitHub repository management
- **gitlab/**: GitLab repository management
- **certificate/**: SSL/TLS certificate operations
- **root level**: General utility scripts (clipboard, VPN, etc.)

### Installation Mechanism

The `install_bash_scripts.sh` script:
1. Iterates through all `.sh` files in `scripts/bash/` (and subdirectories)
2. Creates symbolic links in `/usr/local/bin/`
3. Sets executable permissions
4. Logs all operations
5. Supports dry-run mode
6. Idempotent (safe to run multiple times)

### Keyboard Shortcuts

Separate script `create_keyboard_shortcuts.sh`:
- Configures GNOME keyboard shortcuts
- Maps shortcuts to scripts in `/usr/local/bin/`
- Uses gsettings to configure dconf
- Runs as user (not sudo) to configure user's GNOME session

### Symlink Strategy

**Why symlinks instead of copying?**
- Changes to scripts in repo immediately available
- Easy to update (git pull + no reinstall needed)
- Clear source of truth (scripts in version control)
- Disk space efficient

### Use Case Alignment

This decision aligns with MyLiCuLa's purpose:
- **Personal System Setup**: MyLiCuLa is for Francisco's machines
- **Complete Homogeneity**: Scripts are part of system configuration
- **Single Installation**: One command installs everything
- **Not General Distribution**: Not designed for public consumption

### When to Reconsider

Extract scripts to separate repository if:
- Scripts become useful to wider audience
- Scripts need independent release cycle
- Scripts used in other projects beyond MyLiCuLa
- Multiple maintainers want to contribute
- Scripts become complex enough to warrant independence

### Future Path

If extraction becomes necessary:
1. Create new `bash_scripts` repository
2. Move `scripts/bash/` with full git history
3. Convert MyLiCuLa reference to submodule or external clone
4. Update `install_bash_scripts.sh` to clone external repo
5. Document the change

**This migration path exists but is unlikely to be needed.**

### Script Documentation

Each script follows documentation standards:
- Header with description, args, usage, author
- Function documentation
- Examples in help text
- Consistent logging and error handling
