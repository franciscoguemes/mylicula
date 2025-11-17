# File Templates Installation

File templates have been installed to streamline your workflow when creating new files.

## 📍 Installation Location

- **Templates Source**: `~/git/${USER}/github/mylicula/resources/templates/`
- **Installed To**: `~/Templates/`
- **Log File**: `/var/log/mylicula/install_templates.log`

## 📝 Using Templates

### From File Manager (Nautilus)
1. Right-click in a folder
2. Select **New Document** →
3. Choose from your installed templates

### From Command Line
```bash
cp ~/Templates/<template-file> ./new-file
```

## 📋 Common Templates

Typical templates that might be installed:
- **Text files**: Empty text document
- **Shell scripts**: Bash script template with header
- **Python scripts**: Python file with shebang and imports
- **Markdown**: README.md template
- **Configuration files**: Common config file formats

## 🔄 Re-installing Templates

To update or add new templates:

```bash
cd ~/git/${USER}/github/mylicula
./install.sh
# Select: "Customize UI: Install templates"
```

## 💡 Important Notes

- Templates are stored in `~/Templates/` directory
- File manager integration is automatic in GNOME/Nautilus
- Templates are plain files that get copied when used
- You can edit templates to customize them

## 🔧 Customization

### Add your own templates

1. Create template files in:
   ```bash
   ~/git/${USER}/github/mylicula/resources/templates/
   ```

2. Re-run the installer, or manually copy:
   ```bash
   cp ~/git/${USER}/github/mylicula/resources/templates/* ~/Templates/
   ```

### Edit existing templates
```bash
nano ~/Templates/<template-file>
```

## 🆘 Troubleshooting

### Templates not appearing in file manager
Ensure the Templates directory exists:
```bash
ls -la ~/Templates/
```

Restart your file manager:
```bash
nautilus -q
```

### List all templates
```bash
ls -lh ~/Templates/
```

### Using templates without file manager
Simply copy the template file:
```bash
cp ~/Templates/bash-script.sh ./my-new-script.sh
chmod +x ./my-new-script.sh
```

---

For file manager customization: https://help.gnome.org/users/gnome-help/stable/
