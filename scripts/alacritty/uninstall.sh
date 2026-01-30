#!/usr/bin/env bash
# Alacritty Terminal Uninstaller
# v1.1.0 - Fixed Alacritty.desktop capitalization

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

print_status() { echo -e "${BLUE}[*]${NC} $1"; }
print_success() { echo -e "${GREEN}[✓]${NC} $1"; }
print_warning() { echo -e "${YELLOW}[!]${NC} $1"; }
print_error() { echo -e "${RED}[✗]${NC} $1"; }

CONFIG_DIR="$HOME/.config/alacritty"
XDG_TERMINALS="$HOME/.config/xdg-terminals.list"
BACKUP_FILE="$HOME/.config/xdg-terminals.list.alacritty-backup"

# Remove alacritty config
remove_config() {
    if [ -L "$CONFIG_DIR/alacritty.toml" ]; then
        rm "$CONFIG_DIR/alacritty.toml"
        print_success "Removed alacritty.toml symlink"
    elif [ -f "$CONFIG_DIR/alacritty.toml" ]; then
        rm "$CONFIG_DIR/alacritty.toml"
        print_success "Removed alacritty.toml"
    else
        print_status "No alacritty.toml found"
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
        # Remove alacritty entry if no backup exists
        if grep -q "^Alacritty.desktop$" "$XDG_TERMINALS"; then
            grep -v "^Alacritty.desktop$" "$XDG_TERMINALS" > "$XDG_TERMINALS.tmp" || true
            if [ -s "$XDG_TERMINALS.tmp" ]; then
                mv "$XDG_TERMINALS.tmp" "$XDG_TERMINALS"
            else
                rm -f "$XDG_TERMINALS" "$XDG_TERMINALS.tmp"
            fi
            print_success "Removed alacritty from xdg-terminals.list"
        fi
    fi

    # Remove COSMIC custom keybinding if exists
    local cosmic_shortcuts="$HOME/.config/cosmic/com.system76.CosmicSettings.Shortcuts/v1/custom"
    if [ -f "$cosmic_shortcuts" ] && grep -q "alacritty" "$cosmic_shortcuts"; then
        rm "$cosmic_shortcuts"
        print_success "Removed COSMIC keybinding"
    fi
}

# Main
main() {
    echo "Alacritty Uninstaller"
    echo "====================="
    echo ""

    remove_config
    restore_default_terminal

    echo ""
    print_success "Uninstall complete!"
    echo ""
    echo "Note: The alacritty package was not removed."
    echo "To remove it, run:"
    echo "  Arch:   sudo pacman -R alacritty"
    echo "  Debian: sudo apt remove alacritty"
    echo "  Fedora: sudo dnf remove alacritty"
    echo ""
    echo "Fonts were left in place. To remove manually:"
    echo "  rm -rf ~/.local/share/fonts/Iosevka*"
}

main "$@"
