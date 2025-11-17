# GNOME Keyboard Shortcuts

Custom keyboard shortcuts have been created in your GNOME desktop environment.

## ⌨️ Installed Shortcuts

| Shortcut | Command | Action |
|----------|---------|--------|
| `Shift + L` | generate_link.sh | Generate symbolic links |
| `Ctrl + Above_Tab` | code_2_markdown_in_clipboard.sh | Convert code to Markdown |
| `Alt + F` | find_text.sh | Find text in files |
| `Ctrl + U` | update_url_in_clipboard.sh | Update URL in clipboard |
| `Shift + Keypad_Plus` | connect_to_VPN.sh | Connect to VPN |
| `Shift + Keypad_Minus` | disconnect_from_VPN.sh | Disconnect from VPN |

## 📍 Configuration

- **Settings Location**: User's dconf database (`~/.config/dconf/`)
- **Log File**: `/var/log/mylicula/create_keyboard_shortcuts.log`

## 🔧 Managing Shortcuts

### View in GNOME Settings
```
Settings → Keyboard → View and Customize Shortcuts → Custom Shortcuts
```

### Using gsettings command
List all custom shortcuts:
```bash
gsettings get org.gnome.settings-daemon.plugins.media-keys custom-keybindings
```

View specific shortcut:
```bash
gsettings get org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom0/ name
gsettings get org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom0/ command
gsettings get org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom0/ binding
```

## ✏️ Customizing Shortcuts

You can modify shortcuts through GNOME Settings or re-run the MyLiCuLa installer:

```bash
cd ~/git/${USER}/github/mylicula
./install.sh
# Select: "Create keyboard shortcuts"
```

## 💡 Important Notes

- Shortcuts are created per-user (not system-wide)
- They invoke bash scripts installed in `/usr/local/bin/`
- Some shortcuts require the bash scripts to be installed first
- Shortcuts persist across reboots

## 🆘 Troubleshooting

### Shortcut not working
1. **Check if the script exists**:
   ```bash
   which <script-name>.sh
   ```

2. **Check if the script is executable**:
   ```bash
   ls -la /usr/local/bin/<script-name>.sh
   ```

3. **Test the command manually**:
   ```bash
   <script-name>.sh
   ```

### Conflict with existing shortcuts
If a keyboard shortcut conflicts with an existing one:
1. Open GNOME Settings → Keyboard
2. Search for the conflicting shortcut
3. Disable or modify one of them

### Reset all custom shortcuts
```bash
gsettings reset org.gnome.settings-daemon.plugins.media-keys custom-keybindings
```

Then re-run the MyLiCuLa installer to recreate them.

---

For more on GNOME keyboard shortcuts: https://help.gnome.org/users/gnome-help/stable/keyboard-shortcuts-set.html
