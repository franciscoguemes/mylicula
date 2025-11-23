# 0002. Centralize Logs in /var/log/mylicula

**Date:** 2025-01-23

**Status:** Accepted

**Deciders:** Francisco Güemes

## Context

MyLiCuLa includes both:
- **Installation scripts** (in `setup/`) that run with `sudo` privileges
- **User scripts** (in `scripts/bash/`) that run as regular user without `sudo`

Initially, logging was inconsistent:
- Some scripts logged to `/var/log/mylicula/` (owned by root)
- User scripts failed with "Permission denied" when trying to write logs
- Workaround attempted: user scripts logged to `~/.local/share/mylicula/logs/`

This split approach created problems:
- Logs scattered across multiple locations
- Difficult to troubleshoot issues
- Inconsistent behavior between script types
- User confusion about where to find logs

## Decision

**Centralize all MyLiCuLa logs in `/var/log/mylicula/` with proper permissions.**

### Implementation

1. **Directory Setup**: `install.sh` creates `/var/log/mylicula/` owned by the actual user
   ```bash
   sudo mkdir -p /var/log/mylicula
   sudo chown -R $MYLICULA_USERNAME:$MYLICULA_USERNAME /var/log/mylicula
   sudo chmod 755 /var/log/mylicula
   ```

2. **All Scripts Log to Same Location**: Both sudo and non-sudo scripts write to:
   ```
   /var/log/mylicula/<script-name>.log
   ```

3. **Consistent Permissions**: Directory owned by user, not root

### Log File Naming Convention

```
/var/log/mylicula/install.log
/var/log/mylicula/install_packages.log
/var/log/mylicula/create_keyboard_shortcuts.log
/var/log/mylicula/insert_signature_in_clipboard.log
/var/log/mylicula/automatic_shutdown.log
```

## Consequences

### Positive

- **Single Source of Truth**: All logs in one predictable location
- **Easy Troubleshooting**: `tail -f /var/log/mylicula/*.log` shows everything
- **No Permission Issues**: Both sudo and non-sudo scripts can write
- **Consistent Behavior**: Same logging approach for all scripts
- **System Administrator Friendly**: Follows FHS (Filesystem Hierarchy Standard)
- **Log Rotation Ready**: Can use `logrotate` for automatic cleanup

### Negative

- **Requires sudo**: Initial directory creation needs sudo during installation
- **Non-Standard Owner**: `/var/log/` directories typically owned by root
- **Multi-User Limitation**: Only works well for single-user systems

### Neutral

- **Log Location**: `/var/log/` is standard for system logs on Linux
- **Naming**: Application-specific subdirectory follows common practice

## Alternatives Considered

### Alternative 1: Split Logging (Attempted)

**Description:**
- Sudo scripts → `/var/log/mylicula/` (root-owned)
- User scripts → `~/.local/share/mylicula/logs/` (user-owned)

**Rejected because:**
- Logs scattered across multiple locations
- Difficult to get complete picture during troubleshooting
- Inconsistent behavior confuses users
- No single command to view all logs
- Breaks "Principle of Least Surprise"

### Alternative 2: All Logs in User Home

**Description:** Store all logs in `~/.local/share/mylicula/logs/`

**Rejected because:**
- Not discoverable - hidden directory
- Inconsistent with system administration expectations
- Harder to access for troubleshooting system-level issues
- Doesn't follow FHS conventions
- Lost on user deletion

### Alternative 3: Systemd Journal

**Description:** Use `systemd-cat` or `logger` to send logs to journald

**Rejected because:**
- Over-complicated for the use case
- Requires learning `journalctl` commands
- Harder to grep/search specific script logs
- Not all scripts run as services
- Preference for simple text files

### Alternative 4: Syslog

**Description:** Send all logs to syslog (`/var/log/syslog`)

**Rejected because:**
- Mixes MyLiCuLa logs with system logs
- Harder to isolate application-specific logs
- No control over log rotation
- Pollutes system logs with application details

## References

- [Filesystem Hierarchy Standard](https://refspecs.linuxfoundation.org/FHS_3.0/fhs/ch05s13.html) - `/var/log/` specification
- `install.sh` - Implementation of `setup_log_directory()`
- `lib/installer_common.sh` - Logging functions

## Notes

### Implementation Details

The `setup_log_directory()` function in `install.sh` (lines 149-177):

```bash
setup_log_directory() {
    local log_dir="/var/log/mylicula"
    local actual_user="${MYLICULA_USERNAME:-${USER}}"

    sudo mkdir -p "$log_dir"
    sudo chown -R "$actual_user:$actual_user" "$log_dir"
    sudo chmod 755 "$log_dir"
}
```

Called early in installation process before any script execution.

### Log Format

All scripts use consistent timestamp format:
```
[YYYY-MM-DD HH:MM:SS] [LEVEL] Message
```

Example:
```
[2025-01-23 14:32:15] [INFO] Starting installation...
[2025-01-23 14:32:16] [DEBUG] Debug mode: true
[2025-01-23 14:32:20] [ERROR] Failed to install package
```

### Security Considerations

- Directory is 755 (readable by all, writable only by owner)
- Log files created with user's default umask
- No sensitive information (passwords, tokens) should be logged
- Suitable for single-user desktop systems

### Multi-User Systems

For multi-user systems, consider:
- Per-user log directories: `/var/log/mylicula/<username>/`
- Or: User-specific logs in home directories
- Current approach optimized for single-user desktop environments

### Log Rotation

To implement log rotation, create `/etc/logrotate.d/mylicula`:

```
/var/log/mylicula/*.log {
    weekly
    rotate 4
    compress
    missingok
    notifempty
}
```
