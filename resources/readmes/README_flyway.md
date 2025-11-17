# Flyway - Database Migration Tool

Flyway has been installed system-wide on your machine.

## 📍 Installation Location

- **Installation Directory**: `/opt/flyway/`
- **Binary Symlink**: `/usr/local/bin/flyway`
- **Log File**: `/var/log/mylicula/install_flyway.log`

## 🚀 Usage

### Check Version
```bash
flyway -v
```

### Basic Commands
```bash
flyway info          # Show migration status
flyway migrate       # Run pending migrations
flyway clean         # Drop all objects in configured schemas
flyway validate      # Validate applied migrations
flyway baseline      # Baseline existing database
```

### Configuration
Flyway configuration is stored in:
```
/opt/flyway/conf/flyway.conf
```

## 📖 Documentation

- **Official Documentation**: https://flywaydb.org/documentation
- **Command Reference**: https://flywaydb.org/documentation/usage/commandline
- **Configuration Options**: https://flywaydb.org/documentation/configuration/parameters

## 🔄 Updating

To update Flyway to the latest version:
```bash
cd ~/git/${USER}/github/mylicula
./install.sh
# Select: "3rd party apps: Flyway"
```

MyLiCuLa will automatically check for the latest version and upgrade if available.

## 💡 Important Notes

- Flyway is installed system-wide and available to all users
- The installation is idempotent - re-running won't reinstall if already up-to-date
- Flyway Community Edition is installed (not the paid Teams/Enterprise versions)

## 🆘 Troubleshooting

### Command not found
If `flyway` command is not found, ensure `/usr/local/bin` is in your PATH:
```bash
echo $PATH | grep -q "/usr/local/bin" && echo "✓ In PATH" || echo "✗ Not in PATH"
```

### Version Check
To verify installation:
```bash
ls -la /opt/flyway/
ls -la /usr/local/bin/flyway
```

---

For more help, see: https://flywaydb.org/documentation
