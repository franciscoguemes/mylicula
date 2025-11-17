# GitLab Repositories Cloned

Your GitLab repositories have been cloned to your local machine.

## 📍 Clone Location

- **Base Directory**: `~/git/${USER}/gitlab/`
- **Log File**: `/var/log/mylicula/clone_gitlab_repositories.log`

## 📂 Repository Structure

Repositories are organized by namespace:
```
~/git/${USER}/gitlab/
├── <namespace1>/
│   ├── project1/
│   ├── project2/
│   └── ...
├── <namespace2>/
│   └── project3/
└── ...
```

## 🔍 Finding Your Repositories

List all cloned repositories:
```bash
find ~/git/${USER}/gitlab -maxdepth 2 -type d -name ".git" | sed 's/\/.git$//'
```

Count total repositories:
```bash
find ~/git/${USER}/gitlab -maxdepth 2 -type d -name ".git" | wc -l
```

## 🔧 Configuration

The cloning script uses your GitLab Personal Access Token (PAT) from:
```
~/.config/mylicula/mylicula.conf
```

Variable: `CONFIG[GITLAB_PAT]`

## 🔄 Updating / Re-cloning

To clone new repositories or update the list:

```bash
cd ~/git/${USER}/github/mylicula
./install.sh
# Select: "Clone GitLab repositories"
```

The script will:
- Skip repositories that already exist
- Clone new repositories
- Preserve your local changes

## 💡 Important Notes

- The script is idempotent - existing repositories are not overwritten
- Only repositories you have access to are cloned
- Private repositories require a valid PAT with appropriate scopes
- Large numbers of repositories may take time to clone

## 🔐 GitLab PAT Setup

Your PAT should have these scopes:
- `read_repository` - Read repository content
- `read_api` - Read API for repository list

To create or update your PAT:
1. Go to: https://gitlab.com/-/user_settings/personal_access_tokens
2. Create token with required scopes
3. Update your config:
   ```bash
   nano ~/.config/mylicula/mylicula.conf
   # Update: CONFIG[GITLAB_PAT]="your-token-here"
   ```

## 🆘 Troubleshooting

### Authentication failed
Check your PAT in the config file:
```bash
grep "GITLAB_PAT" ~/.config/mylicula/mylicula.conf
```

### Repositories not cloning
Check the log file for errors:
```bash
tail -100 /var/log/mylicula/clone_gitlab_repositories.log
```

### Manual clone
To manually clone a repository:
```bash
cd ~/git/${USER}/gitlab/<namespace>/
git clone https://gitlab.com/<namespace>/<project>.git
```

---

For more on GitLab: https://docs.gitlab.com/
