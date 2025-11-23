# 0003. Configuration-Driven Scripts

**Date:** 2025-01-23

**Status:** Accepted

**Deciders:** Francisco Güemes

## Context

MyLiCuLa includes both installation scripts and user-facing utility scripts. Initially, scripts had configuration values hardcoded:

```bash
# Hardcoded approach
SIGNATURE_TEXT="Kind regards,

Francisco Güemes"
```

This approach had several problems:
- Scripts were not reusable across different users
- Changing configuration required editing scripts directly
- No single source of truth for user preferences
- Difficult to manage across multiple machines
- Scripts couldn't share configuration

The project needed a way to:
- Store user preferences in one central location
- Allow scripts to read configuration at runtime
- Support fallback values for missing configuration
- Keep configuration separate from code

## Decision

**Implement a configuration-driven approach using a central configuration file.**

### Configuration File

**Location:** `~/.config/mylicula/mylicula.conf`

**Format:** Bash associative array

```bash
# Configuration associative array
declare -A CONFIG

# User Information
CONFIG[USERNAME_FULL_NAME]="Francisco Güemes"
CONFIG[EMAIL]="francisco@franciscoguemes.com"
CONFIG[COMPANY]="Acme Corp"

# GitHub Configuration
CONFIG[GITHUB_USERNAME]="myusername"
CONFIG[GITHUB_PAT]="ghp_xxxxxxxxxxxx"

# GitLab Configuration
CONFIG[GITLAB_USERNAME]="myusername"
CONFIG[GITLAB_PAT]="glpat-xxxxxxxxxxxx"
```

### Script Pattern

Scripts load and use configuration with fallbacks:

```bash
# Load configuration file
CONFIG_FILE="${HOME}/.config/mylicula/mylicula.conf"
declare -A CONFIG

if [[ -f "$CONFIG_FILE" ]]; then
    source "$CONFIG_FILE"
fi

# Use configuration with fallback
USER_FULL_NAME="${CONFIG[USERNAME_FULL_NAME]:-$(git config --global user.name)}"
USER_FULL_NAME="${USER_FULL_NAME:-$USER}"
```

### Fallback Priority

Scripts follow a priority chain:
1. Configuration file value
2. Environment variable or system default
3. Hardcoded fallback

Example from `insert_signature_in_clipboard.sh`:
1. `CONFIG[USERNAME_FULL_NAME]` from config file
2. `git config --global user.name`
3. `$USER` system username

## Consequences

### Positive

- **Reusability**: Same scripts work for different users
- **Centralization**: One place to manage all configuration
- **Flexibility**: Scripts work even without config file (fallbacks)
- **Maintainability**: Changing preferences doesn't require editing scripts
- **Security**: Sensitive data (API tokens) stored separately from code
- **Portability**: Config file can be backed up/synced across machines
- **Documentation**: Config file serves as self-documenting preferences

### Negative

- **Indirection**: Must look at config file to understand script behavior
- **Security Risk**: Config file contains secrets (must be in `.gitignore`)
- **Validation**: Scripts must validate config values exist and are valid
- **Debugging**: Harder to trace where values come from (config vs fallback)

### Neutral

- **Bash-Native**: Uses bash associative arrays (requires bash 4.0+)
- **XDG Base Directory**: Follows `~/.config/` standard
- **Not Encrypted**: Secrets stored in plain text (acceptable for desktop use)

## Alternatives Considered

### Alternative 1: Environment Variables Only

**Description:** Use environment variables for all configuration

```bash
export MYLICULA_FULL_NAME="Francisco Güemes"
export MYLICULA_EMAIL="francisco@franciscoguemes.com"
```

**Rejected because:**
- Must set variables in shell profile (`.bashrc`, `.zshrc`)
- Pollutes user's environment namespace
- Harder to manage many configuration values
- No single file to backup/sync
- Less discoverable for users

### Alternative 2: INI or TOML Configuration

**Description:** Use structured configuration format

```ini
[user]
full_name = Francisco Güemes
email = francisco@franciscoguemes.com

[github]
username = myusername
pat = ghp_xxxxxxxxxxxx
```

**Rejected because:**
- Requires external parser (Python, `toml-cli`, etc.)
- Added dependencies and complexity
- Bash can't natively parse INI/TOML
- Over-engineered for the use case
- Bash associative arrays sufficient

### Alternative 3: JSON Configuration

**Description:** Use JSON file with `jq` parser

```json
{
  "user": {
    "full_name": "Francisco Güemes",
    "email": "francisco@franciscoguemes.com"
  }
}
```

**Rejected because:**
- Requires `jq` dependency (already in project, but still overhead)
- More verbose than bash arrays
- Harder to edit manually
- Slower to parse at runtime
- Bash arrays more natural for bash scripts

### Alternative 4: Per-Script Configuration

**Description:** Each script has its own config file

```
~/.config/mylicula/insert_signature.conf
~/.config/mylicula/automatic_shutdown.conf
~/.config/mylicula/github_clone.conf
```

**Rejected because:**
- Configuration scattered across many files
- Duplicate values (username appears in multiple files)
- Harder to maintain consistency
- More files to backup/sync
- Violates DRY principle

## References

- [XDG Base Directory Specification](https://specifications.freedesktop.org/basedir-spec/basedir-spec-latest.html)
- `resources/config/mylicula.conf.example` - Example configuration
- `scripts/bash/insert_signature_in_clipboard.sh` - Example usage
- `install.sh` - Creates config file during installation

## Notes

### Configuration File Creation

The `install.sh` script creates `~/.config/mylicula/mylicula.conf` during installation by:
1. Prompting user for configuration values
2. Copying from `resources/config/mylicula.conf.example`
3. Substituting `<<<PLACEHOLDER>>>` values with user input

### Example: insert_signature_in_clipboard.sh

The signature script demonstrates the pattern:

```bash
# Load configuration
CONFIG_FILE="${HOME}/.config/mylicula/mylicula.conf"
declare -A CONFIG

load_configuration() {
    if [[ -f "$CONFIG_FILE" ]]; then
        source "$CONFIG_FILE"
    fi
}

get_user_full_name() {
    # Priority 1: Configuration file
    if [[ -n "${CONFIG[USERNAME_FULL_NAME]:-}" ]]; then
        USER_FULL_NAME="${CONFIG[USERNAME_FULL_NAME]}"
        return 0
    fi

    # Priority 2: Git user.name
    if command -v git &> /dev/null; then
        git_name=$(git config --global user.name 2>/dev/null || echo "")
        if [[ -n "$git_name" ]]; then
            USER_FULL_NAME="$git_name"
            return 0
        fi
    fi

    # Priority 3: System username
    USER_FULL_NAME="$USER"
}
```

### Security Considerations

**Sensitive Data:**
- Config file contains API tokens (GitHub PAT, GitLab PAT)
- File permissions should be 600 (readable only by owner)
- File must be in `.gitignore` to prevent accidental commits
- Consider using environment variables for CI/CD

**Recommended permissions:**
```bash
chmod 600 ~/.config/mylicula/mylicula.conf
```

### Documentation in Config File

The example config file (`resources/config/mylicula.conf.example`) includes:

```bash
# USAGE: This configuration file is used by:
#   - install.sh (during installation to configure the system)
#   - Installed bash scripts (scripts/bash/*) that need user configuration
#   - Example scripts: insert_signature_in_clipboard.sh reads USERNAME_FULL_NAME
```

This documents which scripts use the configuration file.

### Config File Not Only for Installer

**Important distinction**: The config file is NOT just for installation. It's a **runtime configuration** used by:
- Installation process (`install.sh`)
- Installed scripts (`scripts/bash/*`)
- User utilities that need preferences

This dual-purpose nature is explicitly documented in the config file comments.

### Future Enhancements

Potential improvements:
- **Validation script**: `validate-config.sh` to check config file
- **Config editor**: Interactive tool to modify configuration
- **Encryption**: Optional encryption for sensitive values
- **Schema**: Define required vs optional configuration keys
- **Migration**: Script to migrate old config to new format
