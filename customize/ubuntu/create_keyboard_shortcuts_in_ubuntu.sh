#!/usr/bin/env bash
####################################################################################################
# Args           :
#                   None
# Usage          :   ./create_keyboard_shortcuts_in_ubuntu.sh
# Output stdout  :   Messages indicating the creation of keyboard shortcuts.
# Output stderr  :   Error messages if shortcut creation fails or if links are missing.
# Return code    :   0 on success, 1 on failure.
# Description    :   This script creates GNOME keyboard shortcuts for bash scripts that were
#                   installed by install_bash_scripts.sh. It checks for the existence of
#                   symbolic links in /usr/local/bin before creating shortcuts.
# Author         :   Francisco Güemes
# Email          :   francisco@franciscoguemes.com
# See also       :   https://askubuntu.com/questions/597395/how-to-create-custom-keyboard-shortcuts-from-terminal
#                   https://unix.stackexchange.com/questions/396399/set-keyboard-shortcut-from-command-line-in-ubuntu
####################################################################################################

# Ensure the script runs from the correct location regardless of where it's executed
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BASE_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"

# Source common library for colored output
source "${BASE_DIR}/lib/common.sh"

INSTALL_DIR="/usr/local/bin"

# Scripts that will have keyboard shortcuts
LINKS=(
    "generate_link.sh"
    "code_2_markdown_in_clipboard.sh"
    "find_text.sh"
)

# Function to check if a symbolic link exists
check_links() {
    local all_links_exist=true
    echo "${COLOR_BLUE}[INFO]${COLOR_RESET} Checking for required script symlinks..."

    for link in "${LINKS[@]}"; do
        if [ ! -L "$INSTALL_DIR/$link" ]; then
            echo "${COLOR_RED}[ERROR]${COLOR_RESET} Symbolic link for $link does not exist in $INSTALL_DIR"
            echo "${COLOR_YELLOW}[HINT]${COLOR_RESET} Please run: sudo customize/linux/install_bash_scripts.sh"
            all_links_exist=false
        else
            echo "${COLOR_GREEN}[OK]${COLOR_RESET} Found: $link"
        fi
    done

    if [ "$all_links_exist" = false ]; then
        echo ""
        echo "${COLOR_RED}[ERROR]${COLOR_RESET} Missing required scripts. Cannot create keyboard shortcuts."
        exit 1
    fi

    echo "${COLOR_GREEN}[SUCCESS]${COLOR_RESET} All required scripts are installed."
    echo ""
}

# Function to create a keyboard shortcut
create_shortcut() {
    local name="$1"
    local command="$2"
    local binding="$3"

    # Check if the binding is already used by a custom shortcut
    existing_bindings=$(gsettings get org.gnome.settings-daemon.plugins.media-keys custom-keybindings)
    if [[ "$existing_bindings" != "@as []" ]]; then
        existing_binding_paths=$(echo "$existing_bindings" | grep -o "'/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom[0-9]*/'")
        for binding_path in $existing_binding_paths; do
            binding_path=${binding_path#\'}
            binding_path=${binding_path%\'}
            if [ "$(gsettings get org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:$binding_path binding)" == "'$binding'" ]; then
                shortcut_name=$(gsettings get org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:$binding_path name)
                echo "${COLOR_RED}[ERROR]${COLOR_RESET} The keybinding $binding is already in use by: $shortcut_name"
                return 1
            fi
        done
    fi

    # Find an empty slot in custom keybindings
    for i in {0..100}; do
        existing_binding=$(echo "$existing_bindings" | grep -o "'/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom$i/'")
        if [ -z "$existing_binding" ]; then
            break
        fi
    done

    # Define the new custom keybinding path
    new_binding_path="/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom$i/"

    # Add the new binding path to the list of custom keybindings
    current_bindings=$(gsettings get org.gnome.settings-daemon.plugins.media-keys custom-keybindings)
    if [[ "$current_bindings" == "@as []" ]]; then
        new_bindings="['$new_binding_path']"
    else
        # Remove outer brackets and spaces from current_bindings
        current_bindings=${current_bindings#[}
        current_bindings=${current_bindings%]}
#        current_bindings=$(echo "$current_bindings" | sed 's/^\[//; s/\]$//')
        new_bindings="[$current_bindings, '$new_binding_path']"
    fi

    gsettings set org.gnome.settings-daemon.plugins.media-keys custom-keybindings "$new_bindings"

    # Set the name, command, and binding for the new custom keybinding
    gsettings set org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:"$new_binding_path" name "$name"
    gsettings set org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:"$new_binding_path" command "$command"
    gsettings set org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:"$new_binding_path" binding "$binding"

    echo "${COLOR_GREEN}[SUCCESS]${COLOR_RESET} Created shortcut: $name ($binding) -> $command"
}

# Check if the symbolic links exist
check_links

# To see the existing shortcuts and their key combinations:
# gsettings list-recursively | grep -i -E 'media-keys|keybindings' should help to get you started here.

# Create the keyboard shortcuts
create_shortcut "Generate link" "generate_link.sh" "<Shift>L"
create_shortcut "Text to Markdown code" "code_2_markdown_in_clipboard.sh" "<Primary>Above_Tab"
create_shortcut "Find text in files" "find_text.sh" "<Alt>F"
#create_shortcut "Connect to Zulutrade VPN" "connect_to_Zulutrade_VPN.sh" "<Shift>KP_Add"
#create_shortcut "Disconnect from Zulutrade VPN" "disconnect_from_Zulutrade_VPN.sh" "<Shift>KP_Subtract"

echo ""
echo "${COLOR_GREEN}[SUCCESS]${COLOR_RESET} All keyboard shortcuts created successfully."
echo ""
echo "${COLOR_BLUE}[INFO]${COLOR_RESET} Useful commands:"
echo "  ${COLOR_YELLOW}View all custom shortcuts:${COLOR_RESET}"
echo "    gsettings get org.gnome.settings-daemon.plugins.media-keys custom-keybindings"
echo ""
echo "  ${COLOR_YELLOW}View specific shortcut details (example for custom0):${COLOR_RESET}"
echo "    gsettings get org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom0/ name"
echo "    gsettings get org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom0/ command"
echo "    gsettings get org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom0/ binding"
echo ""
echo "  ${COLOR_YELLOW}Remove shortcuts:${COLOR_RESET}"
echo "    ./customize/ubuntu/remove_keyboard_shortcuts_in_ubuntu.sh"
echo ""
echo "  ${COLOR_YELLOW}Reset all custom shortcuts:${COLOR_RESET}"
echo "    gsettings reset org.gnome.settings-daemon.plugins.media-keys custom-keybindings"
