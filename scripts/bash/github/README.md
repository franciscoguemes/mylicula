# GitHub Scripts

This directory contains scripts for interacting with GitHub, similar to the GitLab scripts in `../gitlab/`.

## Overview

These scripts help automate cloning and managing GitHub repositories using the GitHub CLI (`gh`). They follow the same conventions as the GitLab scripts but are adapted for GitHub's structure.

## Scripts

### 1. `list_GitHub_repositories.sh`

Lists all repositories a user has access to on GitHub.

**Features:**
- List repositories for authenticated user or specific username
- Output as full JSON or repository names only
- Dry-run mode with example data
- Debug logging to `/var/log/mylicula/` or `/tmp/`

**Usage:**
```bash
# List all repositories (full JSON)
./list_GitHub_repositories.sh -t ghp_xxxxxxxxxxxx

# List repositories for specific user
./list_GitHub_repositories.sh -t ghp_xxxxxxxxxxxx -u octocat

# List only repository names
./list_GitHub_repositories.sh -t ghp_xxxxxxxxxxxx -n

# Dry run with example data
./list_GitHub_repositories.sh -t fake-token --dry-run
```

### 2. `clone_GitHub_repositories.sh`

Clones all repositories from a GitHub account maintaining the owner/repository directory structure.

**Features:**
- Clone all repositories for authenticated user or specific username
- Maintain GitHub structure: `root_dir/owner/repository`
- Filter by owners (include/exclude)
- Skip forks and/or archived repositories
- Dry-run mode to preview actions
- Existing repositories are skipped (not overwritten)
- Progress logged to `/var/log/mylicula/` or `/tmp/`

**Usage:**
```bash
# Clone all repositories for authenticated user
./clone_GitHub_repositories.sh -t ghp_xxxxxxxxxxxx -d ~/github-repos

# Clone repositories for specific user
./clone_GitHub_repositories.sh -t ghp_xxxxxxxxxxxx -d ~/repos -u octocat

# Clone only from specific owners
./clone_GitHub_repositories.sh -t ghp_xxxxxxxxxxxx -d ~/repos -i "octocat,github"

# Skip forks and archived repositories
./clone_GitHub_repositories.sh -t ghp_xxxxxxxxxxxx -d ~/repos --skip-forks --skip-archived

# Dry run to preview what would be cloned
./clone_GitHub_repositories.sh -t ghp_xxxxxxxxxxxx -d ~/repos --dry-run
```

## Requirements

All scripts require:
- **GitHub CLI (`gh`)**: Official GitHub command-line tool
  - Install: `sudo nala install gh` or visit https://cli.github.com/
- **jq**: JSON processor for parsing API responses
  - Install: `sudo nala install jq`
- **git**: For cloning repositories (clone script only)
  - Install: `sudo nala install git`

## Authentication

These scripts use GitHub Personal Access Tokens (PAT) for authentication.

### Generating a Token

1. Generate a token at: https://github.com/settings/tokens
2. Required scopes: `repo` (for private repositories) or `public_repo` (for public only)

### Providing the Token

The PAT token can be provided in two ways:

1. **Command-line parameter**: `-t <token>` or `--token <token>`
   ```bash
   ./script.sh -t ghp_xxxxxxxxxxxx
   ```

2. **Environment variable**: `MYLICULA_GITHUB_PAT=<token>`
   ```bash
   export MYLICULA_GITHUB_PAT="ghp_xxxxxxxxxxxx"
   ./script.sh
   ```

When called during MyLiCuLa installation via `install.sh`, the token is automatically read from the `MYLICULA_GITHUB_PAT` environment variable. Command-line parameters override environment variables.

Internally, the scripts set `GH_TOKEN` for the GitHub CLI using the provided token.

## Comparison with GitLab Scripts

| Feature | GitLab Scripts | GitHub Scripts |
|---------|---------------|----------------|
| API Access | curl + REST API | GitHub CLI (`gh`) |
| Authentication | PAT via `-p` param or `MYLICULA_GITLAB_PAT` | PAT via `-t` param or `MYLICULA_GITHUB_PAT` |
| Internal Auth | HTTP header | `GH_TOKEN` env var |
| Structure | namespace/project | owner/repository |
| Filtering | Groups (include/exclude) | Owners (include/exclude) |
| Additional Filters | N/A | Skip forks, skip archived |
| Pagination | Manual (API pages) | Automatic (handled by `gh`) |
| Dependencies | curl, jq, git | gh, jq, git |

## Directory Structure

When cloning repositories, the scripts create the following structure:

```
root_directory/
├── owner1/
│   ├── repo1/
│   ├── repo2/
│   └── repo3/
├── owner2/
│   ├── repo1/
│   └── repo2/
└── owner3/
    └── repo1/
```

This mirrors the GitHub structure where repositories belong to owners (users or organizations).

## Logging

All scripts log their execution to:
- Primary: `/var/log/mylicula/<script_name>.log` (if writable)
- Fallback: `/tmp/<script_name>.log`

Logs include:
- Timestamp for each execution
- Actions performed (directory creation, cloning, skipping)
- Errors and warnings
- Debug information (when `--debug` is enabled)

## Error Handling

The scripts include comprehensive error handling:
- Check for required commands (gh, jq, git)
- Validate GitHub token
- Verify API responses
- Handle network errors
- Skip existing repositories gracefully

## Dry-Run Mode

Both scripts support `--dry-run` mode:
- **list_GitHub_repositories.sh**: Returns example JSON data
- **clone_GitHub_repositories.sh**: Shows what would be cloned without actually cloning

Use dry-run to:
- Test script behavior without making changes
- Preview directory structure
- Verify filtering options
- Test configuration

## Examples

### Clone Your Own Repositories

```bash
# Clone all your repositories using command-line parameter
./clone_GitHub_repositories.sh -t ghp_xxxxxxxxxxxx -d ~/my-github-repos

# Clone using environment variable (useful during installation)
export MYLICULA_GITHUB_PAT="ghp_xxxxxxxxxxxx"
./clone_GitHub_repositories.sh -d ~/my-github-repos

# Clone only non-fork repositories
./clone_GitHub_repositories.sh -t ghp_xxxxxxxxxxxx -d ~/my-repos --skip-forks

# Clone excluding archived projects
./clone_GitHub_repositories.sh -t ghp_xxxxxxxxxxxx -d ~/active-repos --skip-archived
```

### Clone Organization Repositories

```bash
# Clone all repositories from an organization
./clone_GitHub_repositories.sh -t ghp_xxxxxxxxxxxx -d ~/org-repos -u my-organization

# Clone only from specific owners
./clone_GitHub_repositories.sh -t ghp_xxxxxxxxxxxx -d ~/selected-repos -i "owner1,owner2,owner3"
```

### List Repositories

```bash
# Get full information about your repositories
./list_GitHub_repositories.sh -t ghp_xxxxxxxxxxxx

# Get just the names of another user's repositories
./list_GitHub_repositories.sh -t ghp_xxxxxxxxxxxx -u octocat -n
```

## Notes

- **Rate Limits**: GitHub has API rate limits. The authenticated limit is 5,000 requests/hour.
- **Repository Limit**: Scripts fetch up to 1,000 repositories (configurable in the code).
- **Existing Repos**: Existing repositories are skipped, not overwritten or updated.
- **Token Security**: Never commit your GitHub token to version control.
- **Permissions**: The scripts need write permission to the target directory.

## Troubleshooting

### "gh: command not found"
Install GitHub CLI: `sudo nala install gh` or visit https://cli.github.com/

### "jq: command not found"
Install jq: `sudo nala install jq`

### "Permission denied" when writing logs
The script will automatically fallback to `/tmp/` for log files.

### "Failed to fetch repositories"
- Verify your GitHub token is valid
- Check that the token has the required scopes (`repo` or `public_repo`)
- Verify the username exists (if using `-u` option)
- Check your internet connection

### Cloning fails for some repositories
- Verify you have access to the repositories (especially private ones)
- Check if SSH keys are set up if using SSH URLs
- Ensure you have sufficient disk space

## Contributing

When modifying these scripts, please follow the project conventions:
- Include comprehensive documentation header
- Add help function with examples
- Implement `--debug`, `--dry-run`, and `-h/--help` options
- Check for required commands and provide installation instructions using `nala`
- Log actions with timestamps
- Validate inputs and handle errors gracefully

## See Also

- GitLab scripts: `../gitlab/`
- Project documentation: `../../../README.md`
- GitHub CLI manual: https://cli.github.com/manual/
- GitHub API documentation: https://docs.github.com/en/rest
