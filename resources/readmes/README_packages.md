# System Packages Installation

System packages have been installed using `nala` (or `apt`).

## 📦 Package Categories

MyLiCuLa installs packages in two categories:

### Standard Packages
Essential development tools, utilities, and applications from Ubuntu's default repositories.

### Custom Packages
Additional software from third-party repositories (e.g., GitHub CLI).

## 📍 Configuration

- **Package Lists**: `~/git/${USER}/github/mylicula/resources/apt/`
  - `standard_packages.txt` - Default repository packages
  - `custom_packages.txt` - Third-party packages with repository configuration
- **Log File**: `/var/log/mylicula/install_packages.log`

## 📋 Viewing Installed Packages

### List all installed packages
```bash
nala list --installed
```

### Search for a specific package
```bash
nala list --installed | grep <package-name>
```

### View package information
```bash
nala show <package-name>
```

## 🔄 Updating Packages

### Update package lists
```bash
sudo nala update
```

### Upgrade all packages
```bash
sudo nala upgrade
```

### Upgrade specific package
```bash
sudo nala install --upgrade <package-name>
```

## 🗑️ Removing Packages

### Remove a package
```bash
sudo nala remove <package-name>
```

### Remove package and configuration
```bash
sudo nala purge <package-name>
```

## 🔧 Re-running Package Installation

To add new packages or update package lists:

1. Edit the package list files:
   ```bash
   nano ~/git/${USER}/github/mylicula/resources/apt/standard_packages.txt
   nano ~/git/${USER}/github/mylicula/resources/apt/custom_packages.txt
   ```

2. Run the MyLiCuLa installer:
   ```bash
   cd ~/git/${USER}/github/mylicula
   ./install.sh
   # Select: "Install packages & applications"
   ```

## 💡 Important Notes

- Package installation uses `nala` for better UI and parallel downloads
- If `nala` is not available, the script falls back to `apt`
- Custom packages require repository configuration (GPG keys, sources)
- Installation is idempotent - already installed packages are skipped

## 🆘 Troubleshooting

### Package not found
Update package lists:
```bash
sudo nala update
```

### Repository errors
Check repository configuration:
```bash
ls /etc/apt/sources.list.d/
cat /etc/apt/sources.list.d/mylicula-custom.list
```

### Failed installations
Check the log file:
```bash
tail -100 /var/log/mylicula/install_packages.log
```

---

For package management help: `nala --help` or `man nala`
