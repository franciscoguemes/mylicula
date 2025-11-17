# MyLiCuLa - Installation Summary

Welcome! MyLiCuLa (My Linux Custom Layer) has customized your system for homogeneity across your Linux devices.

## 📋 What Was Installed

This directory contains README files for each component you installed. Each file provides:
- Installation location
- Usage instructions
- Important notes
- Next steps

## 📂 README Files

Check the other files in this directory for component-specific information:
- `README_packages.md` - Installed system packages
- `README_bash_scripts.md` - Custom bash scripts and shortcuts
- `README_keyboard.md` - GNOME keyboard shortcuts
- `README_flyway.md` - Flyway database migration tool
- `README_toolbox.md` - JetBrains Toolbox
- `README_gitlab.md` - Cloned GitLab repositories
- `README_github.md` - Cloned GitHub repositories
- `README_maven.md` - Maven global configuration
- `README_directory.md` - Created directory structure

## 🔧 Configuration

Your MyLiCuLa configuration is stored at:
```
~/.config/mylicula/mylicula.conf
```

## 📝 Logs

Installation logs are located at:
```
/var/log/mylicula/
```

To view logs:
```bash
ls -lh /var/log/mylicula/
tail -f /var/log/mylicula/<script-name>.log
```

## 🔄 Re-running the Installer

To install additional components or update existing ones:
```bash
cd ~/git/${USER}/github/mylicula
./install.sh
```

## 📚 Documentation

- **Project Repository**: https://github.com/franciscoguemes/mylicula
- **Configuration**: `~/.config/mylicula/mylicula.conf`
- **Scripts Location**: `~/git/${USER}/github/mylicula/`

## 💡 Important Notes

- Some changes may require logging out and back in to take effect
- Check individual README files for component-specific setup
- Customize your configuration in `~/.config/mylicula/mylicula.conf`

## 🗑️ Deleting This Directory

You can safely delete this `README MyLiCuLa` directory from your desktop after reviewing the information. These README files are for your reference only.

---

**MyLiCuLa** - Ensuring homogeneity across all your Linux devices
Author: Francisco Güemes <francisco@franciscoguemes.com>
