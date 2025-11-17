# Directory Structure Created

MyLiCuLa has created a standardized directory structure in your home directory.

## 📂 Created Directories

The following directories have been created (if they didn't already exist):

```
~/
├── development/          # Development tools and applications
├── git/                  # Git repositories root
│   └── ${USER}/         # Your personal repositories
│       ├── github/      # GitHub repositories
│       └── gitlab/      # GitLab repositories
├── projects/            # Active projects
├── Documents/           # Personal documents
├── Downloads/           # Downloaded files
└── Desktop/             # Desktop files
```

## 📍 Configuration

- **Directory List**: `~/git/${USER}/github/mylicula/resources/directories.txt`
- **Log File**: `/var/log/mylicula/create_directory_structure.log`

## 🎯 Purpose of Each Directory

### development/
Third-party development tools and applications:
- JetBrains Toolbox
- Language SDKs
- Development utilities

### git/${USER}/
Your Git repositories organized by source:
- `github/` - Cloned GitHub repositories
- `gitlab/` - Cloned GitLab repositories

### projects/
Active development projects and workspaces.

### Documents/
Personal documents, notes, and files.

### Downloads/
Browser downloads and temporary files.

### Desktop/
Desktop shortcuts and files.

## 🔧 Customizing Directory Structure

To add more directories:

1. Edit the directory list:
   ```bash
   nano ~/git/${USER}/github/mylicula/resources/directories.txt
   ```

2. Add new directories (one per line):
   ```
   workspace/personal
   workspace/company
   temp
   ```

3. Re-run the installer:
   ```bash
   cd ~/git/${USER}/github/mylicula
   ./install.sh
   # Select: "Create directory structure"
   ```

## 💡 Important Notes

- The script is idempotent - existing directories are not modified
- Permissions are set to 755 (rwxr-xr-x) for new directories
- Empty directories may be hidden in some file managers
- Directory structure helps maintain consistency across multiple machines

## 🔍 Viewing Directory Structure

### List all created directories
```bash
tree -L 3 ~/ -d | grep -E "development|git|projects"
```

### Check specific directory
```bash
ls -la ~/development/
ls -la ~/git/${USER}/
```

## 🆘 Troubleshooting

### Permission denied
Ensure you have write permissions to your home directory:
```bash
ls -ld ~/
```

### Directory not created
Check the log file:
```bash
tail -50 /var/log/mylicula/create_directory_structure.log
```

### Manual creation
To manually create a directory:
```bash
mkdir -p ~/path/to/directory
chmod 755 ~/path/to/directory
```

---

For directory management help: `man mkdir` or `man chmod`
