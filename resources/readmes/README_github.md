# GitHub Repositories Cloned

Your GitHub repositories have been cloned to your local machine.

## 📍 Clone Location

- **Base Directory**: `~/git/${USER}/github/`
- **Log File**: `/var/log/mylicula/clone_github_repositories.log`

## 📂 Repository Structure

Repositories are cloned directly under the GitHub directory:
```
~/git/${USER}/github/
├── repository1/
├── repository2/
├── repository3/
└── ...
```

## 🔍 Finding Your Repositories

List all cloned repositories:
```bash
find ~/git/${USER}/github -maxdepth 1 -type d -name ".git" | sed 's/\/.git$//'
```

Count total repositories:
```bash
find ~/git/${USER}/github -maxdepth 1 -type d -name ".git" | wc -l
```

## 🔧 Configuration

The cloning script uses your GitHub Personal Access Token (PAT) from:
```
~/.config/mylicula/mylicula.conf
```

Variables:
- `CONFIG[GITHUB_PAT]` - Your GitHub Personal Access Token
- `CONFIG[GITHUB_USER]` - Your GitHub username (optional, for filtering)

## 🔄 Updating / Re-cloning

To clone new repositories or update the list:

```bash
cd ~/git/${USER}/github/mylicula
./install.sh
# Select: "Clone GitHub repositories"
```

The script will:
- Skip repositories that already exist
- Clone new repositories
- Preserve your local changes

## 💡 Important Notes

- The script is idempotent - existing repositories are not overwritten
- Only repositories you have access to are cloned
- Private repositories require a valid PAT with appropriate scopes
- If `GITHUB_USER` is set, only your repositories are cloned

## 🔐 GitHub PAT Setup

Your PAT should have these scopes:
- `repo` - Full control of private repositories
- `read:org` - Read organization data (if cloning org repos)

To create or update your PAT:
1. Go to: https://github.com/settings/tokens
2. Create a new token (classic or fine-grained)
3. Select required scopes
4. Update your config:
   ```bash
   nano ~/.config/mylicula/mylicula.conf
   # Update: CONFIG[GITHUB_PAT]="your-token-here"
   # Update: CONFIG[GITHUB_USER]="your-username"
   ```

## 🆘 Troubleshooting

### Authentication failed
Check your PAT in the config file:
```bash
grep "GITHUB_PAT" ~/.config/mylicula/mylicula.conf
```

### Repositories not cloning
Check the log file for errors:
```bash
tail -100 /var/log/mylicula/clone_github_repositories.log
```

### Manual clone
To manually clone a repository:
```bash
cd ~/git/${USER}/github/
git clone https://github.com/<username>/<repository>.git
```

### Using GitHub CLI
If you have `gh` installed:
```bash
gh repo list
gh repo clone <username>/<repository>
```

---

For more on GitHub: https://docs.github.com/
