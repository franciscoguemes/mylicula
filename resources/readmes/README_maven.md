# Maven Global Configuration

Maven global configuration files have been created in your home directory.

## 📍 Configuration Location

- **Maven Directory**: `~/.m2/`
- **Configuration Files**:
  - `~/.m2/settings-vanilla.xml` - Clean Maven settings template
  - `~/.m2/settings-custom.xml` - Customized settings template
  - `~/.m2/settings.xml` - Active Maven configuration
- **Log File**: `/var/log/mylicula/create_maven_global_configuration.log`

## 📋 Configuration Files

### settings-vanilla.xml
Clean, default Maven settings. Use this as a reference or to reset to defaults.

### settings-custom.xml
Customized settings with company-specific configurations (proxies, mirrors, repositories).

### settings.xml
Your active Maven configuration. This is the file Maven uses by default.

## 🔧 Using the Configuration

Maven automatically uses `~/.m2/settings.xml` for all builds. No additional setup needed!

### Switch between configurations

**Use vanilla settings:**
```bash
cp ~/.m2/settings-vanilla.xml ~/.m2/settings.xml
```

**Use custom settings:**
```bash
cp ~/.m2/settings-custom.xml ~/.m2/settings.xml
```

## ✏️ Customizing Maven Settings

Edit your active settings:
```bash
nano ~/.m2/settings.xml
```

Or edit the custom template:
```bash
nano ~/.m2/settings-custom.xml
```

Common customizations:
- **Proxies**: Configure HTTP/HTTPS proxies
- **Mirrors**: Use corporate Maven mirrors
- **Servers**: Add authentication for private repositories
- **Profiles**: Define build profiles with custom repositories

## 🔄 Re-creating Configuration

To regenerate Maven configuration files:

```bash
cd ~/git/${USER}/github/mylicula
./install.sh
# Select: "Others: Create Maven global configuration"
```

The installer is idempotent:
- Existing `settings.xml` is preserved
- Template files are updated

## 💡 Important Notes

- Maven repository cache: `~/.m2/repository/`
- Local repository size can grow large over time
- Settings are per-user, not system-wide

## 🧹 Maintenance

### Clear local repository cache
```bash
rm -rf ~/.m2/repository/
```

### Check Maven settings
```bash
mvn help:effective-settings
```

### Validate settings file
```bash
mvn help:validate
```

## 🆘 Troubleshooting

### Maven not using settings
Ensure Maven is looking at the right location:
```bash
mvn -X | grep settings
```

### Connection issues
Check proxy configuration in `~/.m2/settings.xml`:
```xml
<proxies>
  <proxy>
    <id>myproxy</id>
    <active>true</active>
    <protocol>http</protocol>
    <host>proxy.example.com</host>
    <port>8080</port>
  </proxy>
</proxies>
```

### Repository authentication
Add server credentials in `~/.m2/settings.xml`:
```xml
<servers>
  <server>
    <id>my-repo</id>
    <username>your-username</username>
    <password>your-password</password>
  </server>
</servers>
```

---

For Maven help: https://maven.apache.org/guides/
