# Directory Structure Created

MyLiCuLa has created a standardized directory structure in your home directory.

## 📂 Created Directories

The following directories have been created (if they didn't already exist):

### System Directories
```
/usr/lib/jvm/            # Java Virtual Machine installations
```

### User Base Directories
```
~/Downloads/             # Browser downloads
~/Templates/             # File templates
~/Documents/Mega/        # Cloud storage
~/Books/                 # Books
~/Ebooks/                # Ebooks
~/Videos/                # Video files
~/Music/                 # Music files
~/Pictures/              # Image files
~/bin/                   # User scripts
~/.config/               # Configuration files
```

### Development Directories
```
~/development/
├── flyway/              # Flyway database migration tool
├── eclipse/             # Eclipse IDE
├── netbeans/            # NetBeans IDE
└── intellij-community/  # IntelliJ IDEA Community Edition
```

### Git Repositories
```
~/git/
├── ${USER}/
│   ├── github/          # Your GitHub repositories
│   └── gitlab/          # Your GitLab repositories
├── ${COMPANY}/          # Company repositories (if MYLICULA_COMPANY set)
└── other/               # Other Git repositories
```

### IDE Workspaces
```
~/workspaces/
├── eclipse/             # Eclipse workspaces
├── netbeans/            # NetBeans projects
└── intellij/            # IntelliJ IDEA projects
```

### Company-Specific (Optional)
```
~/Documents/${COMPANY}/  # Company documents (if MYLICULA_COMPANY set)
~/git/${COMPANY}/        # Company repositories (if MYLICULA_COMPANY set)
```

## 📍 Configuration

- **Script Location**: `~/git/${USER}/github/mylicula/setup/create_directory_structure.sh`
- **Log File**: `/var/log/mylicula/create_directory_structure.log`
- **Configuration**: Directories are defined in bash arrays within the script

## 🎯 Directory Categories

The script creates directories in five main categories:

1. **System Directories**: Require root privileges (e.g., `/usr/lib/jvm/`)
2. **User Base Directories**: Standard user directories for documents, downloads, media files
3. **Development Directories**: Tools like Flyway, Eclipse, NetBeans, IntelliJ
4. **Git Repositories**: Organized by source (GitHub, GitLab, company, other)
5. **IDE Workspaces**: Separate workspace directories for each IDE

All directories are created with 755 permissions (rwxr-xr-x) and are owned by the target user.

## 🔧 Customizing Directory Structure

Directories are defined in bash arrays within the script. To add more directories:

1. Edit the script:
   ```bash
   nano ~/git/${USER}/github/mylicula/setup/create_directory_structure.sh
   ```

2. Find the relevant array and add your directories. For example, to add user directories:
   ```bash
   # Around line 81-92
   declare -a USER_BASE_DIRS=(
       "${TARGET_HOME}/Downloads"
       "${TARGET_HOME}/Templates"
       # ... existing directories ...
       "${TARGET_HOME}/MyNewFolder"    # Add your custom directory
   )
   ```

3. Available arrays to customize:
   - `SYSTEM_DIRS` (line 76): System directories like `/usr/lib/jvm`
   - `USER_BASE_DIRS` (line 81): Base user directories
   - `DEV_DIRS` (line 95): Development tool directories
   - `GIT_DIRS` (line 103): Git repository directories
   - `WORKSPACE_DIRS` (line 110): IDE workspace directories

4. Re-run the installer:
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
- **Company-specific directories**: If you set `MYLICULA_COMPANY` environment variable during installation, the script creates:
  - `~/Documents/${COMPANY}/` for company documents
  - `~/git/${COMPANY}/` for company repositories

## 🔍 Viewing Directory Structure

### List all created directories
```bash
tree -L 3 ~/ -d | grep -E "development|git|workspaces"
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
