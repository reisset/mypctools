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
    install_palettes
    apply_palette
    set_default_terminal "ptyxis" "org.gnome.Ptyxis.desktop"

    echo ""
    print_success "Installation complete!"
    echo ""
    echo "All four mypctools palettes are available in Ptyxis → Preferences → Appearance."
    echo "You may need to log out and back in for font changes to take effect."
}

main "$@"
