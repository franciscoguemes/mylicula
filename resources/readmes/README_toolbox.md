# JetBrains Toolbox

JetBrains Toolbox has been installed to manage your JetBrains IDEs (IntelliJ IDEA, PyCharm, WebStorm, etc.).

__NOTE:__ Using Toolbox is the recommended way of installing any JetBrains IDE. You should refer to this tool to 
install and update your JetBrains IDEs in your system.

## 📍 Installation Location

- **Installation Directory**: `~/development/jetbrains-toolbox/jetbrains-toolbox-<version>/`
- **Log File**: `/var/log/mylicula/install_toolbox.log`

## 🚀 Launching Toolbox

### First Time
Navigate to the installation directory and run:
```bash
cd ~/development/jetbrains-toolbox/jetbrains-toolbox-*/
./jetbrains-toolbox
```

Or use the installer with the `--launch` flag:
```bash
~/git/${USER}/github/mylicula/setup/apps/install_toolbox.sh --launch
```

### After First Launch
JetBrains Toolbox will:
- Add itself to your system's application menu
- Run in the background and appear in your system tray
- Auto-update itself when new versions are available

## 🛠️ Using Toolbox

Once launched, JetBrains Toolbox allows you to:
1. **Install IDEs**: IntelliJ IDEA, PyCharm, WebStorm, CLion, etc.
2. **Manage Versions**: Install multiple versions side-by-side
3. **Update Automatically**: Keep your IDEs up-to-date
4. **Launch Projects**: Quick access to recent projects
5. **Manage Settings**: Configure IDE settings and plugins

## 📖 Documentation

- **Official Website**: https://www.jetbrains.com/toolbox-app/
- **User Guide**: https://www.jetbrains.com/help/toolbox-app/

## 🔄 Updating

JetBrains Toolbox auto-updates itself. However, if you need to reinstall:
```bash
cd ~/git/${USER}/github/mylicula
./install.sh
# Select: "3rd party apps: Toolbox"
```

MyLiCuLa will detect if the latest version is already installed and skip if up-to-date.

## 💡 Important Notes

- Toolbox is installed per-user (not system-wide)
- The application auto-updates itself
- IDEs installed through Toolbox are stored in `~/.local/share/JetBrains/Toolbox/apps/`
- Toolbox settings are stored in `~/.local/share/JetBrains/Toolbox/`

## 🆘 Troubleshooting

### Toolbox not appearing in system tray
Try launching it manually from the installation directory:
```bash
cd ~/development/jetbrains-toolbox/jetbrains-toolbox-*/
./jetbrains-toolbox &
```

### Finding your installation
```bash
ls -la ~/development/jetbrains-toolbox/
```

---

For more help, see: https://www.jetbrains.com/help/toolbox-app/
