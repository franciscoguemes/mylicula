# 0004. Package Installation Structure with Metadata Comments

**Date:** 2025-01-23

**Status:** Accepted

**Deciders:** Francisco Güemes

## Context

Ubuntu package installation involves three interconnected components that must be managed together:

1. **Packages** - Software to install via `apt`/`nala`
2. **Repositories** - APT sources that must be added before packages
3. **GPG Keys** - Cryptographic keys for repository verification

### Initial Challenge

The original structure used three separate files:
```
resources/apt/
├── list_of_packages.txt
├── list_of_repositories.txt
└── list_of_GPG_keys.txt
```

**Problems with this approach:**
- No clear relationship between packages, repositories, and keys
- Error-prone: easy to add package without corresponding repository
- Synchronization issues across three files
- Manual tracking of which package needs which repository
- Difficult to maintain consistency

### Requirements

- Must maintain relationship between packages and their repositories
- Should be human-readable and easy to edit
- No external dependencies (no `jq`, `yq`, etc.)
- Git-friendly (clear diffs, no binary files)
- Simple for common case (standard Ubuntu packages)
- Structured for complex case (custom repositories)

## Decision

**Use a hybrid approach with two files and structured metadata comments:**

```
resources/apt/
├── standard_packages.txt    # Default Ubuntu repository packages
└── custom_packages.txt      # Packages with custom repositories
```

**Format for `custom_packages.txt`:**
```bash
# Package Group Name / Description
# REPO: repository URL or PPA
# GPG: GPG key URL (if needed)
# KEYRING: keyring file path (if needed)
package-name-1
package-name-2

# Next Package Group
# REPO: ...
package-name-3
```

**Example:**
```bash
# GitHub CLI
# Command-line tool for GitHub
# https://cli.github.com/
# https://github.com/cli/cli/blob/trunk/docs/install_linux.md
# REPO: deb [signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main
# GPG: https://cli.github.com/packages/githubcli-archive-keyring.gpg
# KEYRING: /usr/share/keyrings/githubcli-archive-keyring.gpg
gh

# Docker
# REPO: deb [arch=amd64] https://download.docker.com/linux/ubuntu jammy stable
# GPG: https://download.docker.com/linux/ubuntu/gpg
# KEYRING: /usr/share/keyrings/docker-archive-keyring.gpg
docker-ce
docker-ce-cli
containerd.io
```

## Consequences

### Positive

- **Maintains Relationships**: Clear grouping shows which packages need which repositories
- **Simple Format**: Plain text files, no special tools required
- **Self-Documenting**: Comments explain configuration and provide links
- **Git-Friendly**: Text files show clear diffs, easy to review changes
- **Parseable**: Scripts can extract metadata from structured comments
- **Progressive Enhancement**: Simple scripts can ignore comments, advanced scripts can parse them
- **Best of Both Worlds**: Simple for standard packages, structured for complex ones
- **Visual Grouping**: Related packages grouped together in file
- **No Dependencies**: Standard bash tools sufficient for parsing

### Negative

- **Comment Parsing Required**: Must parse specially-formatted comments with regex
- **Custom Convention**: Not a standard format, must be documented
- **Potential Duplication**: Same repository might appear for multiple package groups
- **No Built-in Validation**: Typos in comments won't be caught automatically
- **Manual Maintenance**: Must keep comments in sync with package lists

### Neutral

- **Metadata Format**: Uses comment-based metadata (common in shell scripts)
- **Two Files**: Separates standard from custom packages for clarity

## Alternatives Considered

### Alternative 1: Separate Files (Original Approach)

**Description:** Three separate files for packages, repositories, and GPG keys

**Rejected because:**
- No relationship tracking between components
- Error-prone: easy to get out of sync
- Manual maintenance of relationships across files
- Difficult to see complete picture
- No way to ensure correct installation order

### Alternative 2: Structured Configuration (JSON/YAML)

**Description:** Use JSON or YAML to define packages with nested metadata

```json
{
  "packages_with_repos": [
    {
      "name": "gh",
      "repository": "deb [...] https://cli.github.com/packages stable main",
      "gpg_key": "https://cli.github.com/packages/githubcli-archive-keyring.gpg",
      "gpg_keyring": "/usr/share/keyrings/githubcli-archive-keyring.gpg"
    }
  ]
}
```

**Rejected because:**
- Requires external parser (`jq` or `yq`)
- Added dependency and complexity
- Less familiar for shell scripts
- More verbose than simple text
- Harder to edit manually (syntax errors)
- Overkill for the use case

### Alternative 3: Shell Script as Configuration

**Description:** Define packages in bash associative arrays

```bash
declare -A GITHUB_CLI_CONFIG=(
    [packages]="gh"
    [repository]="deb [...] https://cli.github.com/packages stable main"
    [gpg_key]="https://cli.github.com/packages/githubcli-archive-keyring.gpg"
)
```

**Rejected because:**
- More verbose than text files
- Requires sourcing (security concern - executes code)
- Bash-specific, less portable
- Not as intuitive for simple package lists
- Good alternative, but text format preferred for simplicity

### Alternative 4: Database (SQLite)

**Description:** Use SQLite database with tables for packages, repositories, relationships

**Rejected because:**
- Massive overkill for the use case
- Binary format not git-friendly
- Requires SQLite installed
- Can't edit with text editor
- Can't see diffs in version control
- Adds complexity without significant benefit

## References

- `resources/apt/standard_packages.txt` - Standard package list
- `resources/apt/custom_packages.txt` - Custom packages with metadata
- `setup/install_packages.sh` - Implementation of parsing logic
- Original draft: `docs/draft/Install_packages.md`

## Notes

### Parsing Implementation

The `install_packages.sh` script parses metadata comments using bash regex:

```bash
while IFS= read -r line; do
    if [[ "$line" =~ ^#\ REPO:\ (.*)$ ]]; then
        repo="${BASH_REMATCH[1]}"
    elif [[ "$line" =~ ^#\ GPG:\ (.*)$ ]]; then
        gpg_key="${BASH_REMATCH[1]}"
    elif [[ "$line" =~ ^#\ KEYRING:\ (.*)$ ]]; then
        keyring="${BASH_REMATCH[1]}"
    elif [[ "$line" =~ ^#.*$ ]]; then
        continue  # Other comments (descriptions, links)
    elif [[ -z "$line" ]]; then
        # Empty line: install accumulated packages
        install_package_group "$repo" "$gpg_key" "$keyring" "${packages[@]}"
    else
        packages+=("$line")
    fi
done < custom_packages.txt
```

### Standard vs Custom Packages

**Standard packages** (in `standard_packages.txt`):
- Available in default Ubuntu repositories
- No additional configuration needed
- Simple one-package-per-line format
- Installed with straightforward `nala install`

**Custom packages** (in `custom_packages.txt`):
- Require additional APT repositories
- May require GPG key configuration
- Grouped with metadata comments
- Installed with repository setup first

### Comment Format Convention

Recognized metadata comments:
- `# REPO:` - APT repository line to add
- `# GPG:` - GPG key URL to download
- `# KEYRING:` - Path where keyring should be stored
- Other comments (no colon) are treated as descriptions/documentation

### Idempotency

The installer handles idempotency by:
- Checking if repository already exists before adding
- Verifying GPG key already imported
- Skipping package installation if already installed
- Safe to run multiple times

### Migration from Original Structure

The migration from three separate files was straightforward:
1. Created `standard_packages.txt` with default repository packages
2. Created `custom_packages.txt` with grouped packages and metadata
3. Updated `install_packages.sh` to parse both formats
4. Tested thoroughly with dry-run
5. Removed old `list_of_repositories.txt` and `list_of_GPG_keys.txt`

### Future Enhancements

Potential improvements:
- **Validation script**: Check metadata comment format
- **Auto-deduplication**: Detect and merge duplicate repositories
- **Conditional installation**: Support for Ubuntu version-specific packages
- **Package groups**: Tag packages by category (dev, multimedia, etc.)
