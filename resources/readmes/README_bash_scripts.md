# Bash Scripts Installation

Custom bash scripts have been installed and symlinked to `/usr/local/bin/` for system-wide access.

## 📍 Installation

- **Scripts Source**: `~/git/${USER}/github/mylicula/scripts/bash/`
- **Symlinks Location**: `/usr/local/bin/`
- **Log File**: `/var/log/mylicula/install_bash_scripts.log`

## 🔗 Installed Scripts

All executable bash scripts from the MyLiCuLa repository are now available system-wide. Common scripts include:

### Networking & VPN
```bash
connect_to_VPN.sh              # Connect to VPN
disconnect_from_VPN.sh         # Disconnect from VPN
```

### Development Tools
```bash
generate_link.sh               # Generate symbolic links
find_text.sh                   # Search for text in files
code_2_markdown_in_clipboard.sh # Convert code to markdown format
update_url_in_clipboard.sh     # Update URLs in clipboard
```

### Java/Certificate Management
```bash
install_cert_in_jdk.sh         # Install certificate in JDK
install_cert_for_all_jdks.sh   # Install certificate in all JDKs
list_installed_jdks.sh         # List all installed JDKs
```

### Repository Management
```bash
list_GitHub_repositories.sh    # List your GitHub repositories
clone_GitHub_repositories.sh   # Clone GitHub repositories
```

## 🚀 Usage

All scripts are available system-wide. Just type the script name:

```bash
connect_to_VPN.sh
find_text.sh "search term"
list_GitHub_repositories.sh
```

## 📖 Help

Most scripts support a `-h` or `--help` flag:
```bash
connect_to_VPN.sh --help
```

## 🔍 Viewing Installed Scripts

List all symlinked scripts:
```bash
ls -lh /usr/local/bin/*.sh
```

View script source:
```bash
cat /usr/local/bin/<script-name>.sh
```

## 🔄 Updating

When you update MyLiCuLa scripts, re-run the installer:
```bash
cd ~/git/${USER}/github/mylicula
./install.sh
# Select: "Install bash scripts"
```

The installer is idempotent and will update symlinks as needed.

## 💡 Important Notes

- Scripts are owned by your user but accessible to all users
- Execute permissions are preserved from source
- Symlinks point to the actual scripts in the repository
- Changes to source scripts are immediately reflected

## 🆘 Troubleshooting

### Script not found
Ensure `/usr/local/bin` is in your PATH:
```bash
echo $PATH | grep -q "/usr/local/bin" && echo "✓ In PATH" || echo "✗ Not in PATH"
```

### Permission denied
Check script permissions:
```bash
ls -la /usr/local/bin/<script-name>.sh
```

If needed, the script source should have execute permissions:
```bash
ls -la ~/git/${USER}/github/mylicula/scripts/bash/<script-name>.sh
```

---

For script-specific help, run: `<script-name>.sh --help`
