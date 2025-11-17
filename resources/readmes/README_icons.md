# Custom Icons Installation

Custom icons have been installed to personalize your desktop environment.

## 📍 Installation Location

- **Icons Source**: `~/git/${USER}/github/mylicula/resources/icons/`
- **Installed To**: `~/.local/share/icons/` or `~/.icons/`
- **Log File**: `/var/log/mylicula/install_icons.log`

## 🎨 Using Custom Icons

### Apply icon theme (GNOME)
```bash
gsettings set org.gnome.desktop.interface icon-theme '<theme-name>'
```

### Using GNOME Tweaks
1. Open **GNOME Tweaks** (install with: `sudo nala install gnome-tweaks`)
2. Go to **Appearance** → **Icons**
3. Select your installed icon theme

### List available icon themes
```bash
ls ~/.local/share/icons/
ls /usr/share/icons/
```

## 🔄 Re-installing Icons

To update or reinstall icons:

```bash
cd ~/git/${USER}/github/mylicula
./install.sh
# Select: "Customize UI: Install icons"
```

## 💡 Important Notes

- Icons are installed per-user (not system-wide)
- Changes take effect after selecting the theme
- Some applications may need to be restarted to show new icons
- Icon cache is automatically updated after installation

## 🔧 Customization

### Add your own icons
1. Place icon theme folder in:
   ```bash
   ~/git/${USER}/github/mylicula/resources/icons/
   ```

2. Re-run the installer

### Manual installation
```bash
cp -r /path/to/icon-theme ~/.local/share/icons/
gtk-update-icon-cache ~/.local/share/icons/<theme-name>
```

## 🆘 Troubleshooting

### Icons not appearing
Update icon cache:
```bash
gtk-update-icon-cache ~/.local/share/icons/<theme-name>
```

### Reset to default icons
```bash
gsettings reset org.gnome.desktop.interface icon-theme
```

### Check installed themes
```bash
find ~/.local/share/icons -maxdepth 1 -type d
```

---

For icon theme customization: https://wiki.gnome.org/Personalization
