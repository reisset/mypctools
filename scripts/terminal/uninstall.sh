#!/usr/bin/env bash
# LiteBash Terminal (foot) Uninstaller
# v1.4.0 - Removed set -e for reliability

FOOT_CONFIG="$HOME/.config/foot/foot.ini"
FOOT_DIR="$HOME/.config/foot"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../../lib/print.sh"

# Remove foot config (including broken symlinks)
if [ -f "$FOOT_CONFIG" ] || [ -L "$FOOT_CONFIG" ]; then
    # Check if there are other files in the foot config dir (exclude our config from count)
    file_count=$(find "$FOOT_DIR" -maxdepth 1 -type f ! -name "foot.ini" | wc -l)

    if [ "$file_count" -eq 0 ]; then
        # Only our config exists, remove the whole directory
        print_status "Removing foot config directory..."
        rm -rf "$FOOT_DIR"
        print_success "Removed $FOOT_DIR"
    else
        # Other configs exist, only remove our file
        print_status "Removing foot.ini (keeping other configs)..."
        rm -f "$FOOT_CONFIG"
        print_success "Removed foot.ini"
    fi
else
    print_warning "No foot config found at $FOOT_CONFIG"
fi

# Restore original default terminal
restore_default_terminal() {
    local xdg_terminals="$HOME/.config/xdg-terminals.list"
    local backup_file="$HOME/.config/xdg-terminals.list.litebash-backup"

    if [ -f "$backup_file" ]; then
        print_status "Restoring original default terminal..."
        mv "$backup_file" "$xdg_terminals"
        print_success "Restored original terminal config"
    elif [ -f "$xdg_terminals" ]; then
        # No backup but foot is set - remove foot entry
        if grep -q "^foot.desktop$" "$xdg_terminals"; then
            grep -v "^foot.desktop$" "$xdg_terminals" > "$xdg_terminals.tmp" 2>/dev/null || true
            if [ -s "$xdg_terminals.tmp" ]; then
                mv "$xdg_terminals.tmp" "$xdg_terminals"
                print_success "Removed foot from default terminals"
            else
                rm -f "$xdg_terminals.tmp" "$xdg_terminals"
                print_status "Removed xdg-terminals.list (was foot only)"
            fi
        fi
    fi
}

restore_default_terminal

# Remove COSMIC keybinding if it points to foot
remove_cosmic_keybinding() {
    local cosmic_shortcuts="$HOME/.config/cosmic/com.system76.CosmicSettings.Shortcuts/v1/custom"
    if [ -f "$cosmic_shortcuts" ] && grep -q "foot" "$cosmic_shortcuts"; then
        rm "$cosmic_shortcuts"
        print_success "Removed COSMIC keybinding"
    fi
}

remove_cosmic_keybinding

# Note about fonts
print_status "Fonts left in place (~/.local/share/fonts)"

echo ""
print_success "foot config removed."
echo ""
echo "To remove foot itself, run:"
if command -v pacman &>/dev/null; then
    echo "  sudo pacman -Rs foot"
elif command -v apt &>/dev/null; then
    echo "  sudo apt remove foot"
elif command -v dnf &>/dev/null; then
    echo "  sudo dnf remove foot"
fi
