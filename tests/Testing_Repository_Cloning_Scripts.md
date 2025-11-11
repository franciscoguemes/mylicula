# Testing Guide: Repository Cloning Scripts

This guide provides step-by-step instructions for manually testing the GitLab and GitHub repository cloning scripts.

## Table of Contents

- [Prerequisites](#prerequisites)
- [Test Environment Setup](#test-environment-setup)
- [Testing Approach](#testing-approach)
- [Testing GitLab Script](#testing-gitlab-script)
- [Testing GitHub Script](#testing-github-script)
- [Verification](#verification)
- [Troubleshooting](#troubleshooting)
- [Advanced Testing Scenarios](#advanced-testing-scenarios)

---

## Prerequisites

### Required Tools

Ensure the following tools are installed:

```bash
# Check if required tools are installed
command -v git && echo "✓ git installed" || echo "✗ git not installed"
command -v jq && echo "✓ jq installed" || echo "✗ jq not installed"
command -v gh && echo "✓ gh (GitHub CLI) installed" || echo "✗ gh not installed"
command -v curl && echo "✓ curl installed" || echo "✗ curl not installed"
```

Install missing tools:

```bash
# Install all required tools
sudo nala install git jq gh curl
```

### Required Credentials

You'll need Personal Access Tokens (PAT) from both platforms:

#### GitLab PAT
1. Go to: https://gitlab.com/-/profile/personal_access_tokens
2. Create a token with scope: `read_repository`
3. Save the token (starts with `glpat-`)

#### GitHub PAT
1. Go to: https://github.com/settings/tokens
2. Create a token with scope: `repo` (for private repos) or `public_repo` (public only)
3. Save the token (starts with `ghp_`)

### Target Directories

The scripts will clone repositories to these directories:
- **GitLab**: `$HOME/git/francisco/gitlab`
- **GitHub**: `$HOME/git/francisco/github`

These directories will be created automatically if they don't exist.

---

## Test Environment Setup

### 1. Navigate to Project Root

```bash
cd /home/francisco/git/francisco/github/mylicula
```

### 2. Verify Script Locations

```bash
# Check GitLab script exists
ls -lh customize/linux/clone_gitlab_repositories.sh

# Check GitHub script exists
ls -lh scripts/bash/github/clone_GitHub_repositories.sh
```

### 3. Ensure Scripts are Executable

```bash
# Make scripts executable if needed
chmod +x customize/linux/clone_gitlab_repositories.sh
chmod +x scripts/bash/github/clone_GitHub_repositories.sh
```

### 4. Verify Syntax

```bash
# Check for syntax errors
bash -n customize/linux/clone_gitlab_repositories.sh
bash -n scripts/bash/github/clone_GitHub_repositories.sh

# If no output, syntax is valid
echo "✓ Syntax check passed"
```

---

## Testing Approach

### Important: Dry-Run Behavior

**The `--dry-run` flag fetches real data but doesn't clone repositories.**

When you use `--dry-run`:
- ✅ **Does**: Connect to GitLab/GitHub and fetch your actual repository list
- ✅ **Does**: Show which repositories would be cloned
- ✅ **Does**: Show directory structure that would be created
- ❌ **Does NOT**: Actually clone any repositories
- ❌ **Does NOT**: Create directories or make any changes to disk

This allows you to verify exactly what would happen before running the real cloning operation.

### Important: Authentication Behavior

**PAT tokens are automatically injected into clone URLs for seamless authentication.**

When cloning repositories:
- The scripts automatically modify HTTPS URLs to include your PAT token
- **GitHub**: `https://github.com/owner/repo` → `https://token@github.com/owner/repo`
- **GitLab**: `https://gitlab.com/owner/repo` → `https://oauth2:token@gitlab.com/owner/repo`
- Git will **NOT** prompt for username/password
- Tokens are **never** written to disk or shown in output
- Cloning happens silently with proper authentication

### Credential Methods

There are two ways to provide credentials to the scripts:

### Method 1: Environment Variables (Recommended)

This method matches how `install.sh` calls these scripts:

```bash
export MYLICULA_GITLAB_USER="your-gitlab-username"
export MYLICULA_GITLAB_PAT="glpat-xxxxxxxxxxxx"
export MYLICULA_GITHUB_USER="your-github-username"
export MYLICULA_GITHUB_PAT="ghp_xxxxxxxxxxxx"
```

**Pros:**
- Cleaner command lines
- Matches installation behavior
- Credentials not visible in process list
- Can be set once and reused

**Cons:**
- Credentials remain in shell environment until unset

### Method 2: Command-Line Parameters

Pass credentials directly to scripts:

```bash
# GitLab
script.sh -p "token" -u "username"

# GitHub
script.sh -p "token"
```

**Pros:**
- Explicit and clear
- No environment pollution
- Easy to change between runs

**Cons:**
- Credentials visible in command history
- Longer command lines

**Both methods are valid** - choose based on your preference. This guide shows both.

---

## Testing GitLab Script

### Script Location
```
customize/linux/clone_gitlab_repositories.sh
```

### Quick Reference

```bash
# View help
customize/linux/clone_gitlab_repositories.sh --help

# Key parameters:
#   -p, --pat          GitLab PAT token
#   -u, --user         GitLab username
#   -d, --directory    Target directory
#   -g, --gitlab-url   GitLab URL (default: https://gitlab.com)
#   --dry-run          Preview without cloning
#   --debug            Enable debug logging
```

### Test 1: Dry-Run with Environment Variables

**Purpose**: Preview what would be cloned without making changes

```bash
# Set credentials
export MYLICULA_GITLAB_USER="franciscoguemes"
export MYLICULA_GITLAB_PAT="glpat-xxxxxxxxxxxx"

# Run dry-run
customize/linux/clone_gitlab_repositories.sh \
  -d ~/git/francisco/gitlab \
  --dry-run

# Expected output:
# - Banner with configuration
# - "Fetching repositories from GitLab..." message
# - Real list of YOUR repositories from GitLab (not dummy data!)
# - Directory structure that would be created
# - "[DRY-RUN] Would clone: ..." messages for each repo
```

**Important**: Dry-run mode now fetches real repository data from GitLab/GitHub. You'll see your actual repositories, not example data. This allows you to verify what would be cloned before actually cloning.

### Test 2: Dry-Run with Command-Line Parameters

```bash
customize/linux/clone_gitlab_repositories.sh \
  -p "glpat-xxxxxxxxxxxx" \
  -u "franciscoguemes" \
  -d ~/git/francisco/gitlab \
  --dry-run
```

### Test 3: Real Execution with Debug

**Purpose**: Clone repositories with detailed logging

```bash
# Using environment variables
customize/linux/clone_gitlab_repositories.sh \
  -d ~/git/francisco/gitlab \
  --debug

# OR using parameters
customize/linux/clone_gitlab_repositories.sh \
  -p "glpat-xxxxxxxxxxxx" \
  -u "franciscoguemes" \
  -d ~/git/francisco/gitlab \
  --debug
```

**What to watch for:**
- Progress messages for each repository
- Directory creation messages
- Clone status (success/skip/error)
- Final summary

### Test 4: Different GitLab Instance

If you use a self-hosted GitLab:

```bash
customize/linux/clone_gitlab_repositories.sh \
  -g "https://gitlab.company.com" \
  -p "glpat-xxxxxxxxxxxx" \
  -u "franciscoguemes" \
  -d ~/git/francisco/gitlab-company \
  --dry-run
```

### Test 5: Re-run (Skip Existing)

**Purpose**: Verify that existing repositories are skipped

```bash
# Run the script again on same directory
customize/linux/clone_gitlab_repositories.sh \
  -d ~/git/francisco/gitlab

# Expected behavior:
# - Existing repos show: "Repository X already exists, skipping"
# - Only new repos are cloned
```

---

## Testing GitHub Script

### Script Location
```
scripts/bash/github/clone_GitHub_repositories.sh
```

### Quick Reference

```bash
# View help
scripts/bash/github/clone_GitHub_repositories.sh --help

# Key parameters:
#   -p, --pat           GitHub PAT token
#   -d, --directory       Target directory (required)
#   -u, --user            GitHub username (optional)
#   -i, --include-owners  Include only these owners
#   -e, --exclude-owners  Exclude these owners
#   --skip-forks          Skip forked repositories
#   --skip-archived       Skip archived repositories
#   --dry-run             Preview without cloning
#   --debug               Enable debug logging
```

### Test 1: Dry-Run with Environment Variables

**Purpose**: Preview what would be cloned

```bash
# Set credentials
export MYLICULA_GITHUB_PAT="ghp_xxxxxxxxxxxx"
export MYLICULA_GITHUB_USER="franciscoguemes"  # Optional

# Run dry-run
scripts/bash/github/clone_GitHub_repositories.sh \
  -d ~/git/francisco/github \
  --dry-run

# Expected output:
# - Configuration banner
# - "Fetching repositories from GitHub..." message
# - Real list of YOUR repositories from GitHub (not dummy data!)
# - "[DRY-RUN] Would clone: owner/repo" messages for each repo
```

**Important**: Dry-run mode fetches real repository data from GitHub. You'll see your actual repositories and can verify the exact list before cloning.

### Test 2: Dry-Run with Command-Line Parameters

```bash
scripts/bash/github/clone_GitHub_repositories.sh \
  -p "ghp_xxxxxxxxxxxx" \
  -d ~/git/francisco/github \
  --dry-run
```

### Test 3: Clone Specific User's Repositories

```bash
# Clone repos from a specific GitHub user/organization
scripts/bash/github/clone_GitHub_repositories.sh \
  -p "ghp_xxxxxxxxxxxx" \
  -u "octocat" \
  -d ~/git/github-octocat \
  --dry-run
```

### Test 4: Skip Forks and Archived Repos

**Purpose**: Clone only original, active repositories

```bash
scripts/bash/github/clone_GitHub_repositories.sh \
  -p "ghp_xxxxxxxxxxxx" \
  -d ~/git/francisco/github \
  --skip-forks \
  --skip-archived \
  --dry-run
```

### Test 5: Real Execution with Debug

```bash
# Using environment variables
scripts/bash/github/clone_GitHub_repositories.sh \
  -d ~/git/francisco/github \
  --debug

# OR using parameters
scripts/bash/github/clone_GitHub_repositories.sh \
  -p "ghp_xxxxxxxxxxxx" \
  -d ~/git/francisco/github \
  --debug
```

### Test 6: Filter by Owners

**Purpose**: Clone only repositories from specific owners

```bash
# Include only specific owners
scripts/bash/github/clone_GitHub_repositories.sh \
  -p "ghp_xxxxxxxxxxxx" \
  -d ~/git/github-filtered \
  -i "franciscoguemes,myorg" \
  --dry-run

# Exclude specific owners
scripts/bash/github/clone_GitHub_repositories.sh \
  -p "ghp_xxxxxxxxxxxx" \
  -d ~/git/github-filtered \
  -e "other-org,test-user" \
  --dry-run
```

---

## Verification

### Check Directory Structure

After running the scripts, verify the directory structure:

```bash
# GitLab structure
tree -L 1 ~/git/francisco/gitlab/

# Expected:
# gitlab/
# ├── project1/
# ├── project2/
# └── project3/

# GitHub structure
tree -L 1 ~/git/francisco/github/

# Expected:
# github/
# ├── repo1/
# ├── repo2/
# └── mylicula/
```

**Note**: Repositories are cloned directly into the target directory (flat structure), not into owner/namespace subdirectories.

### Verify Git Repositories

```bash
# Check a few repositories are valid git repos
cd ~/git/francisco/gitlab/
ls -d */ | head -3 | while read dir; do
    echo "Checking $dir"
    git -C "$dir" status
done

cd ~/git/francisco/github/
ls -d */ | head -3 | while read dir; do
    echo "Checking $dir"
    git -C "$dir" status
done
```

### Check Remote URLs

```bash
# Verify remote URLs are correct
cd ~/git/francisco/gitlab/some-repo
git remote -v

cd ~/git/francisco/github/some-repo
git remote -v
```

### Count Cloned Repositories

```bash
# Count GitLab repos
echo "GitLab repos: $(find ~/git/francisco/gitlab -maxdepth 1 -type d -name ".git" -o -type d | grep -v "^.$" | wc -l)"

# Count GitHub repos
echo "GitHub repos: $(find ~/git/francisco/github -maxdepth 1 -type d -name ".git" -o -type d | grep -v "^.$" | wc -l)"
```

### Check Logs

```bash
# GitLab script log
tail -50 /var/log/mylicula/clone_gitlab_repositories.log
# Or:
tail -50 /tmp/clone_gitlab_repositories.log

# GitHub script log
tail -50 /var/log/mylicula/clone_GitHub_repositories.log
# Or:
tail -50 /tmp/clone_GitHub_repositories.log
```

---

## Troubleshooting

### Issue: "gh: command not found"

**Solution:**
```bash
sudo nala install gh
```

### Issue: "jq: command not found"

**Solution:**
```bash
sudo nala install jq
```

### Issue: Authentication Failed

**Symptoms:**
- "Error: Failed to fetch repositories"
- "Authentication required"
- "Invalid credentials"

**Solutions:**

1. **Verify token is correct:**
   ```bash
   # Test GitLab token
   curl --header "PRIVATE-TOKEN: glpat-xxxxxxxxxxxx" \
     "https://gitlab.com/api/v4/user" | jq

   # Test GitHub token (using gh CLI)
   export GH_TOKEN="ghp_xxxxxxxxxxxx"
   gh auth status
   ```

2. **Check token permissions:**
   - GitLab: Must have `read_repository` scope
   - GitHub: Must have `repo` or `public_repo` scope

3. **Check token expiration:**
   - Tokens may have expired
   - Generate new tokens if needed

### Issue: Permission Denied on Log Files

**Symptoms:**
```
/var/log/mylicula/clone_XXX.log: Permission denied
```

**Solution:**
This is normal and expected. The script automatically falls back to `/tmp/`:
```bash
# Check fallback log location
tail -f /tmp/clone_gitlab_repositories.log
tail -f /tmp/clone_GitHub_repositories.log
```

### Issue: Script Hangs or Runs Very Slowly

**Possible causes:**
- Large number of repositories
- Slow network connection
- Large repositories being cloned

**Solutions:**

1. **Use dry-run to see count:**
   ```bash
   customize/linux/clone_gitlab_repositories.sh \
     -d ~/test --dry-run | grep "Would clone"
   ```

2. **Monitor progress:**
   ```bash
   # In another terminal, watch the log
   tail -f /tmp/clone_gitlab_repositories.log
   ```

3. **Clone to faster storage:**
   ```bash
   # Use local SSD instead of network drive
   scripts/bash/github/clone_GitHub_repositories.sh \
     -p "token" -d /tmp/github-repos
   ```

### Issue: Some Repositories Failed to Clone

**Check the logs:**
```bash
# Look for errors in logs
grep -i error /tmp/clone_gitlab_repositories.log
grep -i error /tmp/clone_GitHub_repositories.log
```

**Common causes:**
- Network timeout
- Repository too large
- Insufficient disk space
- Repository archived or deleted

**Solutions:**
- Re-run the script (existing repos will be skipped)
- Clone specific repos manually
- Increase disk space

### Issue: Wrong Repositories Cloned

**For GitLab:**
```bash
# Verify the correct user/namespace
customize/linux/clone_gitlab_repositories.sh \
  -u "correct-username" \
  -d ~/git/francisco/gitlab
```

**For GitHub:**
```bash
# Use -u flag for specific user
scripts/bash/github/clone_GitHub_repositories.sh \
  -p "token" \
  -u "correct-username" \
  -d ~/git/francisco/github
```

---

## Advanced Testing Scenarios

### Scenario 1: Test with Minimal Repos (Dry-Run Only)

**Purpose**: Quick validation without cloning

```bash
# GitLab
customize/linux/clone_gitlab_repositories.sh \
  -d /tmp/gitlab-test --dry-run | head -50

# GitHub
scripts/bash/github/clone_GitHub_repositories.sh \
  -p "token" -d /tmp/github-test --dry-run | head -50
```

### Scenario 2: Clone to Temporary Directory

**Purpose**: Test without affecting your main git directory

```bash
# Create temp directory
mkdir -p /tmp/test-cloning/{gitlab,github}

# Test GitLab
customize/linux/clone_gitlab_repositories.sh \
  -d /tmp/test-cloning/gitlab

# Test GitHub
scripts/bash/github/clone_GitHub_repositories.sh \
  -p "token" -d /tmp/test-cloning/github

# Verify
tree -L 2 /tmp/test-cloning/

# Clean up
rm -rf /tmp/test-cloning/
```

### Scenario 3: Performance Testing

**Purpose**: Measure cloning time and performance

```bash
# Time the GitLab cloning
time customize/linux/clone_gitlab_repositories.sh \
  -d /tmp/gitlab-perf

# Time the GitHub cloning
time scripts/bash/github/clone_GitHub_repositories.sh \
  -p "token" -d /tmp/github-perf

# Check disk usage
du -sh /tmp/gitlab-perf
du -sh /tmp/github-perf
```

### Scenario 4: Test with Different Options Combinations

```bash
# GitHub: Skip forks only
scripts/bash/github/clone_GitHub_repositories.sh \
  -p "token" -d /tmp/no-forks --skip-forks --dry-run

# GitHub: Skip archived only
scripts/bash/github/clone_GitHub_repositories.sh \
  -p "token" -d /tmp/no-archived --skip-archived --dry-run

# GitHub: Both filters
scripts/bash/github/clone_GitHub_repositories.sh \
  -p "token" -d /tmp/filtered --skip-forks --skip-archived --dry-run
```

### Scenario 5: Test Error Handling

**Purpose**: Verify script behavior with invalid inputs

```bash
# Test with invalid token (should fail gracefully)
customize/linux/clone_gitlab_repositories.sh \
  -p "invalid-token" -u "user" -d /tmp/test

# Test with missing token
customize/linux/clone_gitlab_repositories.sh \
  -d /tmp/test

# Test with non-existent user
scripts/bash/github/clone_GitHub_repositories.sh \
  -p "token" -u "nonexistent-user-12345" -d /tmp/test --dry-run
```

---

## Clean Up After Testing

After testing, you may want to clean up:

```bash
# Remove test directories (if you used temporary directories)
rm -rf /tmp/test-cloning/
rm -rf /tmp/gitlab-test/
rm -rf /tmp/github-test/

# Unset environment variables
unset MYLICULA_GITLAB_USER
unset MYLICULA_GITLAB_PAT
unset MYLICULA_GITHUB_USER
unset MYLICULA_GITHUB_PAT

# Clear sensitive data from shell history (optional)
history -d $(history | grep "GITLAB_PAT\|GITHUB_PAT" | awk '{print $1}')
```

---

## Testing Checklist

Use this checklist to ensure comprehensive testing:

### GitLab Script Testing

- [ ] Syntax check passes (`bash -n`)
- [ ] Help displays correctly (`--help`)
- [ ] Dry-run works with environment variables
- [ ] Dry-run works with command-line parameters
- [ ] Real execution clones repositories
- [ ] Existing repositories are skipped on re-run
- [ ] Correct directory structure created (`namespace/project`)
- [ ] Debug mode provides detailed logs
- [ ] Error handling works (invalid token, etc.)
- [ ] Logs written successfully

### GitHub Script Testing

- [ ] Syntax check passes (`bash -n`)
- [ ] Help displays correctly (`--help`)
- [ ] Dry-run works with environment variables
- [ ] Dry-run works with command-line parameters
- [ ] Real execution clones repositories
- [ ] `--skip-forks` filters correctly
- [ ] `--skip-archived` filters correctly
- [ ] Existing repositories are skipped on re-run
- [ ] Correct directory structure created (`owner/repository`)
- [ ] Debug mode provides detailed logs
- [ ] Error handling works
- [ ] Logs written successfully

### Integration Testing

- [ ] Both scripts can run using same environment variables
- [ ] Directory structures don't conflict
- [ ] Both work when called from `install.sh` context
- [ ] Configuration file values are read correctly

---

## Summary

This guide covered:

1. **Prerequisites**: Tools and credentials needed
2. **Setup**: Preparing the test environment
3. **Testing Methods**: Environment variables vs command-line parameters
4. **GitLab Testing**: 5 different test scenarios
5. **GitHub Testing**: 6 different test scenarios
6. **Verification**: How to confirm everything works
7. **Troubleshooting**: Common issues and solutions
8. **Advanced Scenarios**: Performance and edge case testing

**Recommended Testing Order:**

1. Start with dry-runs to understand behavior
2. Test with environment variables (matches production)
3. Try different options (debug, filters, etc.)
4. Verify directory structure and logs
5. Test error conditions
6. Clean up

**Key Safety Features:**

- Always use `--dry-run` first
- Existing repositories are never overwritten
- Scripts fail gracefully with clear error messages
- Logs provide audit trail

For additional help, consult:
- Script help: `script.sh --help`
- Project README: `README.md`
- GitLab scripts README: `scripts/bash/gitlab/API_Intro.md`
- GitHub scripts README: `scripts/bash/github/README.md`
