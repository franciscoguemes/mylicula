# Set-Title Function Installation

The `set-title` bash function has been installed to customize your terminal window titles.

## 📍 Installation Location

- **Function File**: Injected into `~/.bashrc`
- **Log File**: `/var/log/mylicula/install_set-title_function.log`

## 🚀 Usage

### Basic Usage
```bash
set-title "My Custom Title"
```

This sets your terminal window title to "My Custom Title".

### Common Use Cases

**Set title for current project:**
```bash
cd ~/projects/myapp
set-title "MyApp Development"
```

**Set title with command:**
```bash
set-title "Running Tests" && ./run-tests.sh
```

**Set title in SSH sessions:**
```bash
ssh user@server
set-title "Production Server"
```

## 💡 How It Works

The `set-title` function sends escape sequences to your terminal emulator to update the window title. It works with most terminal emulators including:
- GNOME Terminal
- Konsole
- xterm
- Tilix
- Terminator

## 🔧 Customization

### View the function
```bash
type set-title
```

### Edit the function
```bash
nano ~/.bashrc
# Find the set-title function and modify
```

After editing, reload your bash configuration:
```bash
source ~/.bashrc
```

## 🔄 Re-installing

To update or reinstall the set-title function:

```bash
cd ~/git/${USER}/github/mylicula
./install.sh
# Select: "Others: Install set-title function"
```

## 💡 Important Notes

- The function is added to your `.bashrc` file
- Changes take effect in new terminal windows or after `source ~/.bashrc`
- The function is idempotent - re-running won't create duplicates
- Works in local terminals and SSH sessions

## 🎨 Advanced Usage

### Auto-set title based on directory
Add to your `.bashrc`:
```bash
cd() {
    builtin cd "$@"
    set-title "$(basename "$PWD")"
}
```

### Set title with git branch
```bash
set-git-title() {
    local branch=$(git branch --show-current 2>/dev/null)
    if [[ -n "$branch" ]]; then
        set-title "$(basename "$PWD") [$branch]"
    else
        set-title "$(basename "$PWD")"
    fi
}
```

## 🆘 Troubleshooting

### Function not found
Reload your bash configuration:
```bash
source ~/.bashrc
```

Or open a new terminal window.

### Title not changing
Check if your terminal emulator supports title changes:
```bash
echo -ne "\033]0;Test Title\007"
```

If this doesn't work, your terminal may not support title changes.

### Remove the function
Edit `~/.bashrc` and remove the `set-title` function definition:
```bash
nano ~/.bashrc
# Search for "set-title" and delete the function
source ~/.bashrc
```

---

For terminal customization: Check your terminal emulator's documentation
