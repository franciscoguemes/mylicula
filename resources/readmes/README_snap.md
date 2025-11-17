# Snap Applications Installation

Snap packages have been installed on your system.

## 📦 What are Snaps?

Snaps are containerized software packages that work across different Linux distributions. They include all dependencies and auto-update in the background.

## 📍 Configuration

- **Snap List**: `~/git/${USER}/github/mylicula/resources/snap/snap_packages.txt`
- **Log File**: `/var/log/mylicula/install_snap.log`

## 📋 Managing Snap Packages

### List installed snaps
```bash
snap list
```

### View snap information
```bash
snap info <package-name>
```

### Update a snap
```bash
sudo snap refresh <package-name>
```

### Update all snaps
```bash
sudo snap refresh
```

## 🗑️ Removing Snaps

### Remove a snap
```bash
sudo snap remove <package-name>
```

### Remove with saved data
```bash
sudo snap remove --purge <package-name>
```

## 🔧 Adding More Snaps

To install additional snap packages:

1. Edit the snap list:
   ```bash
   nano ~/git/${USER}/github/mylicula/resources/snap/snap_packages.txt
   ```

2. Add package names (one per line)

3. Re-run the installer:
   ```bash
   cd ~/git/${USER}/github/mylicula
   ./install.sh
   # Select: "Install snap applications"
   ```

## 💡 Important Notes

- Snaps auto-update by default (usually 4 times per day)
- Snap applications run in a confined environment (sandboxed)
- Some snaps may request additional permissions
- Snaps are stored in `/snap/` and `~/snap/`

## 🔍 Snap Directories

- **System snaps**: `/snap/`
- **User data**: `~/snap/<package-name>/`
- **Snap daemon**: `snapd`

## 🆘 Troubleshooting

### Snap service not running
```bash
sudo systemctl status snapd
sudo systemctl start snapd
```

### Update issues
Manually refresh snaps:
```bash
sudo snap refresh
```

### Connection issues
Check snap connections:
```bash
snap connections <package-name>
```

### Finding snaps
Search the Snap Store:
```bash
snap find <search-term>
```

Or browse: https://snapcraft.io/store

---

For snap help: `snap --help` or visit https://snapcraft.io/docs
