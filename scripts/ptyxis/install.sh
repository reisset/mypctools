#!/usr/bin/env bash
# Ptyxis Terminal Installer
# v1.0.0 - Uses shared terminal-install.sh

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../../lib/terminal-install.sh"

# Only need sudo for first-time package install; skip during config-only re-sync
if ! command -v ptyxis &>/dev/null; then
    init_sudo
fi

# Install ptyxis (Arch and Fedora only)
install_ptyxis() {
    if command -v ptyxis &>/dev/null; then
        print_success "ptyxis already installed"
        return 0
    fi

    print_status "Installing ptyxis..."
    case "$PKG_MGR" in
        pacman) $PKG_INSTALL ptyxis ;;
        dnf) $PKG_INSTALL ptyxis ;;
        apt)
            print_error "ptyxis is not available in Debian/Ubuntu apt repos."
            print_error "Install Arch or Fedora, or install ptyxis manually via Flatpak:"
            echo "  flatpak install flathub org.gnome.Ptyxis"
            exit 1
            ;;
    esac
    print_success "Installed ptyxis"
}

# Install all four palette files as symlinks
install_palettes() {
    local palette_dir="$HOME/.local/share/org.gnome.Ptyxis/palettes"
    mkdir -p "$palette_dir"

    print_status "Linking ptyxis palettes..."
    safe_symlink "$SCRIPT_DIR/configs/mypctools-catppuccin-mocha.palette" \
        "$palette_dir/mypctools-catppuccin-mocha.palette" \
        "mypctools-catppuccin-mocha.palette"
    safe_symlink "$SCRIPT_DIR/configs/mypctools-tokyo-night.palette" \
        "$palette_dir/mypctools-tokyo-night.palette" \
        "mypctools-tokyo-night.palette"
    safe_symlink "$SCRIPT_DIR/configs/mypctools-hackthebox.palette" \
        "$palette_dir/mypctools-hackthebox.palette" \
        "mypctools-hackthebox.palette"
    safe_symlink "$SCRIPT_DIR/configs/mypctools-ubuntu.palette" \
        "$palette_dir/mypctools-ubuntu.palette" \
        "mypctools-ubuntu.palette"
}

# Configure Ptyxis to use UbuntuMono Nerd Font at its own font settings
# (org.gnome.Ptyxis has use-system-font + font-name keys independent of the system font)
set_ptyxis_font() {
    command -v gsettings &>/dev/null || return 0
    command -v fc-list &>/dev/null || return 0
    local family
    family=$(fc-list : family | grep -i "UbuntuMono Nerd Font Mono" | grep -v "Propo\|NFP" \
        | head -1 | sed 's/,.*//' | xargs 2>/dev/null)
    if [ -z "$family" ]; then
        print_warning "UbuntuMono Nerd Font Mono not found; skipping font config"
        return 0
    fi
    gsettings set org.gnome.Ptyxis use-system-font false 2>/dev/null
    gsettings set org.gnome.Ptyxis font-name "$family 15" 2>/dev/null
    print_success "Ptyxis font: $family 15"
}

# Patch CachyOS Hello's terminal-helper to recognize ptyxis.
# That script hardcodes a fixed terminal list and ignores xdg-terminals.list.
patch_cachyos_hello() {
    local helper="/usr/share/cachyos-hello/scripts/terminal-helper"
    [ -f "$helper" ] || return 0
    grep -q '"ptyxis"' "$helper" && {
        print_success "CachyOS Hello: ptyxis support already present"
        return 0
    }
    print_status "Adding ptyxis to CachyOS Hello terminal list..."
    local tmp
    tmp=$(mktemp)
    python3 - "$helper" "$tmp" << 'PYEOF'
import sys
with open(sys.argv[1]) as f:
    content = f.read()
content = content.replace(
    '    ["ghostty"]="ghostty -e $cmd"',
    '    ["ghostty"]="ghostty -e $cmd"\n    ["ptyxis"]="ptyxis -- $cmd"'
)
content = content.replace('    "kgx"', '    "ptyxis"\n    "kgx"', 1)
with open(sys.argv[2], 'w') as f:
    f.write(content)
PYEOF
    if grep -q '"ptyxis"' "$tmp"; then
        sudo cp "$tmp" "$helper"
        sudo chmod 755 "$helper"
        rm -f "$tmp"
        print_success "CachyOS Hello: ptyxis support added"
    else
        rm -f "$tmp"
        print_warning "Could not patch CachyOS Hello (pattern mismatch — update it manually)"
    fi
}

# Apply the selected palette to the default ptyxis profile via gsettings
apply_palette() {
    local palette_id="mypctools-$THEME"

    if ! command -v gsettings &>/dev/null; then
        print_warning "gsettings not found — cannot apply palette automatically"
        print_warning "Open Ptyxis → Preferences → Appearance and select: $palette_id"
        return 0
    fi

    local profile_uuid
    profile_uuid=$(gsettings get org.gnome.Ptyxis default-profile-uuid 2>/dev/null | tr -d "'")

    if [ -z "$profile_uuid" ]; then
        print_warning "No Ptyxis profile found. Launch Ptyxis once, then re-run this installer."
        print_warning "All four mypctools palettes are installed and available in Ptyxis → Preferences → Appearance."
        return 0
    fi

    gsettings set org.gnome.Ptyxis.Profile:/org/gnome/Ptyxis/Profiles/${profile_uuid}/ \
        palette "$palette_id" 2>/dev/null && \
        print_success "Applied $palette_id palette" || \
        print_warning "Could not apply palette via gsettings. Select '$palette_id' manually in Ptyxis → Preferences → Appearance."
}

# Main
main() {
    detect_distro
    THEME_FILE="$HOME/.config/ptyxis/.theme"
    select_theme

    install_ptyxis
    install_font
    set_ptyxis_font
    install_palettes
    apply_palette
    patch_cachyos_hello
    set_default_terminal "ptyxis" "org.gnome.Ptyxis.desktop"

    echo ""
    print_success "Installation complete!"
    echo ""
    echo "All four mypctools palettes are available in Ptyxis → Preferences → Appearance."
    echo "You may need to log out and back in for font changes to take effect."
}

main "$@"
