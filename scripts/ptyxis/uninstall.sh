#!/usr/bin/env bash
# Ptyxis Terminal Uninstaller
# v1.0.0

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../../lib/print.sh"

PALETTE_DIR="$HOME/.local/share/org.gnome.Ptyxis/palettes"
THEME_SENTINEL="$HOME/.config/ptyxis/.theme"
XDG_TERMINALS="$HOME/.config/xdg-terminals.list"
BACKUP_FILE="$HOME/.config/xdg-terminals.list.ptyxis-backup"

# Remove the four mypctools palette symlinks
remove_palettes() {
    for name in mypctools-catppuccin-mocha mypctools-tokyo-night mypctools-hackthebox mypctools-ubuntu; do
        local f="$PALETTE_DIR/$name.palette"
        if [ -L "$f" ] || [ -f "$f" ]; then
            rm "$f"
            print_success "Removed $name.palette"
        fi
    done

    if [ -d "$PALETTE_DIR" ] && [ -z "$(ls -A "$PALETTE_DIR")" ]; then
        rmdir "$PALETTE_DIR"
        print_success "Removed empty palettes directory"
    fi

    if [ -f "$THEME_SENTINEL" ]; then
        rm "$THEME_SENTINEL"
        print_success "Removed theme sentinel"
    fi
}

# Reset the ptyxis palette setting back to the default
reset_palette() {
    if ! command -v gsettings &>/dev/null; then
        return 0
    fi

    local profile_uuid
    profile_uuid=$(gsettings get org.gnome.Ptyxis default-profile-uuid 2>/dev/null | tr -d "'")
    if [ -n "$profile_uuid" ]; then
        gsettings reset org.gnome.Ptyxis.Profile:/org/gnome/Ptyxis/Profiles/${profile_uuid}/ \
            palette 2>/dev/null || true
        print_success "Reset ptyxis palette to default"
    fi
}

# Restore default terminal settings
restore_default_terminal() {
    if [ -f "$BACKUP_FILE" ]; then
        mv "$BACKUP_FILE" "$XDG_TERMINALS"
        print_success "Restored original xdg-terminals.list"
    elif [ -f "$XDG_TERMINALS" ]; then
        if grep -q "^org.gnome.Ptyxis.desktop$" "$XDG_TERMINALS"; then
            grep -v "^org.gnome.Ptyxis.desktop$" "$XDG_TERMINALS" > "$XDG_TERMINALS.tmp" || true
            if [ -s "$XDG_TERMINALS.tmp" ]; then
                mv "$XDG_TERMINALS.tmp" "$XDG_TERMINALS"
            else
                rm -f "$XDG_TERMINALS" "$XDG_TERMINALS.tmp"
            fi
            print_success "Removed ptyxis from xdg-terminals.list"
        fi
    fi

    local cosmic_shortcuts="$HOME/.config/cosmic/com.system76.CosmicSettings.Shortcuts/v1/custom"
    if [ -f "$cosmic_shortcuts" ] && grep -q "ptyxis" "$cosmic_shortcuts"; then
        rm "$cosmic_shortcuts"
        print_success "Removed COSMIC keybinding"
    fi
}

# Main
main() {
    echo "Ptyxis Uninstaller"
    echo "=================="
    echo ""

    remove_palettes
    reset_palette
    restore_default_terminal

    echo ""
    print_success "Uninstall complete!"
    echo ""
    echo "Note: The ptyxis package was not removed."
    echo "To remove it, run:"
    echo "  Arch:   sudo pacman -R ptyxis"
    echo "  Fedora: sudo dnf remove ptyxis"
    echo ""
    echo "Fonts were left in place. To remove manually:"
    echo "  rm -rf ~/.local/share/fonts/Iosevka*"
}

main "$@"
