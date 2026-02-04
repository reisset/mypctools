#!/usr/bin/env bash
# Ghostty Terminal Uninstaller
# v1.0.0

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../../lib/print.sh"

CONFIG_DIR="$HOME/.config/ghostty"
XDG_TERMINALS="$HOME/.config/xdg-terminals.list"
BACKUP_FILE="$HOME/.config/xdg-terminals.list.ghostty-backup"

# Remove ghostty config
remove_config() {
    if [ -L "$CONFIG_DIR/config" ]; then
        rm "$CONFIG_DIR/config"
        print_success "Removed config symlink"
    elif [ -f "$CONFIG_DIR/config" ]; then
        rm "$CONFIG_DIR/config"
        print_success "Removed config"
    else
        print_status "No config found"
    fi

    # Remove config dir if empty
    if [ -d "$CONFIG_DIR" ] && [ -z "$(ls -A "$CONFIG_DIR")" ]; then
        rmdir "$CONFIG_DIR"
        print_success "Removed empty config directory"
    elif [ -d "$CONFIG_DIR" ]; then
        print_status "Config directory not empty, keeping it"
    fi
}

# Restore default terminal settings
restore_default_terminal() {
    # Restore xdg-terminals.list backup
    if [ -f "$BACKUP_FILE" ]; then
        mv "$BACKUP_FILE" "$XDG_TERMINALS"
        print_success "Restored original xdg-terminals.list"
    elif [ -f "$XDG_TERMINALS" ]; then
        # Remove ghostty entry if no backup exists
        if grep -q "^com.mitchellh.ghostty.desktop$" "$XDG_TERMINALS"; then
            grep -v "^com.mitchellh.ghostty.desktop$" "$XDG_TERMINALS" > "$XDG_TERMINALS.tmp" || true
            if [ -s "$XDG_TERMINALS.tmp" ]; then
                mv "$XDG_TERMINALS.tmp" "$XDG_TERMINALS"
            else
                rm -f "$XDG_TERMINALS" "$XDG_TERMINALS.tmp"
            fi
            print_success "Removed ghostty from xdg-terminals.list"
        fi
    fi

    # Remove COSMIC custom keybinding if exists
    local cosmic_shortcuts="$HOME/.config/cosmic/com.system76.CosmicSettings.Shortcuts/v1/custom"
    if [ -f "$cosmic_shortcuts" ] && grep -q "ghostty" "$cosmic_shortcuts"; then
        rm "$cosmic_shortcuts"
        print_success "Removed COSMIC keybinding"
    fi
}

# Main
main() {
    echo "Ghostty Uninstaller"
    echo "==================="
    echo ""

    remove_config
    restore_default_terminal

    echo ""
    print_success "Uninstall complete!"
    echo ""
    echo "Note: The ghostty package was not removed."
    echo "To remove it, run:"
    echo "  Arch:   sudo pacman -R ghostty"
    echo "  Debian: sudo apt remove ghostty"
    echo "  Fedora: sudo dnf remove ghostty"
    echo ""
    echo "Fonts were left in place. To remove manually:"
    echo "  rm -rf ~/.local/share/fonts/Iosevka*"
}

main "$@"
