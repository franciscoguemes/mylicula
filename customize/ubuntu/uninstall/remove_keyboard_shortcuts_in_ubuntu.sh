#!/usr/bin/env bash
####################################################################################################
# Args           :
#                   None
# Usage          :   ./remove_keyboard_shortcuts_in_ubuntu.sh
# Output stdout  :   Messages indicating the removal of keyboard shortcuts.
# Output stderr  :   Error messages if shortcut removal fails.
# Return code    :   0 on success, 1 on failure.
# Description    :   This script removes GNOME keyboard shortcuts that were created by
#                   create_keyboard_shortcuts_in_ubuntu.sh. It matches shortcuts by name
#                   and removes them from gsettings.
# Author         :   Francisco Güemes
# Email          :   francisco@franciscoguemes.com
# See also       :   https://askubuntu.com/questions/597395/how-to-create-custom-keyboard-shortcuts-from-terminal
#                   https://unix.stackexchange.com/questions/396399/set-keyboard-shortcut-from-command-line-in-ubuntu
####################################################################################################

# Ensure the script runs from the correct location regardless of where it's executed
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BASE_DIR="$(cd "$SCRIPT_DIR/../../.." && pwd)"

# Source common library for colored output
source "${BASE_DIR}/lib/common.sh"

# Shortcuts descriptions to be removed (must match the names in create script)
SHORTCUT_DESCRIPTIONS=(
    "Generate link"
    "Text to Markdown code"
    "Find text in files"
)

# Function to remove a keyboard shortcut
remove_shortcut() {
    local description="$1"

    # Find the custom keybinding path for the given description
    existing_binding=$(gsettings get org.gnome.settings-daemon.plugins.media-keys custom-keybindings | grep -o "'/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom[0-9]*/'")

    for binding_path in $existing_binding; do
        binding_path=${binding_path#\'}
        binding_path=${binding_path%\'}

        if [ "$(gsettings get org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:$binding_path name)" == "'$description'" ]; then
            # Get binding details for display
            local binding_key=$(gsettings get org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:$binding_path binding)
            binding_key=${binding_key#\'}
            binding_key=${binding_key%\'}

            # Remove the binding path from the list of custom keybindings
            current_bindings=$(gsettings get org.gnome.settings-daemon.plugins.media-keys custom-keybindings)
            new_bindings=$(echo "$current_bindings" | sed "s|, '$binding_path'| |; s|'$binding_path', | |; s|'$binding_path'| |")
            gsettings set org.gnome.settings-daemon.plugins.media-keys custom-keybindings "$new_bindings"

            # Clean up the custom keybinding settings
            gsettings reset org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:"$binding_path" name
            gsettings reset org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:"$binding_path" command
            gsettings reset org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:"$binding_path" binding

            echo "${COLOR_GREEN}[SUCCESS]${COLOR_RESET} Removed shortcut: $description ($binding_key)"
            return 0
        fi
    done

    echo "${COLOR_YELLOW}[SKIP]${COLOR_RESET} Shortcut not found: $description"
    return 1
}

# Remove the keyboard shortcuts
echo "${COLOR_BLUE}[INFO]${COLOR_RESET} Removing keyboard shortcuts..."
echo ""

removed_count=0
skipped_count=0

for description in "${SHORTCUT_DESCRIPTIONS[@]}"; do
    if remove_shortcut "$description"; then
        ((removed_count++))
    else
        ((skipped_count++))
    fi
done

echo ""
echo "${COLOR_GREEN}[SUMMARY]${COLOR_RESET} Removed: $removed_count | Skipped: $skipped_count"

if [ $removed_count -gt 0 ]; then
    echo "${COLOR_GREEN}[SUCCESS]${COLOR_RESET} Keyboard shortcuts removed successfully."
else
    echo "${COLOR_YELLOW}[INFO]${COLOR_RESET} No shortcuts were removed (none found)."
fi
