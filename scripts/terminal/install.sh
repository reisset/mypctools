#!/usr/bin/env bash
# LiteBash Terminal (foot) Installer
# v1.7.0 - Uses shared terminal-install.sh

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../../lib/terminal-install.sh"

# Only need sudo for first-time package install; skip during config-only re-sync
if ! command -v foot &>/dev/null; then
    init_sudo
fi

# Wayland check - only block first-time install; config-only re-sync doesn't need Wayland
if [ -z "$WAYLAND_DISPLAY" ] && ! command -v foot &>/dev/null; then
    print_error "Wayland not detected. foot is Wayland-only."
    echo "If you're on X11, foot will not work."
    exit 1
fi
[ -n "$WAYLAND_DISPLAY" ] && print_success "Wayland detected"

# Install foot
install_foot() {
    if command -v foot &>/dev/null; then
        print_success "foot already installed"
        return 0
    fi

    print_status "Installing foot..."
    case "$PKG_MGR" in
        pacman) $PKG_INSTALL foot ;;
        apt) $PKG_INSTALL foot ;;
        dnf) $PKG_INSTALL foot ;;
    esac
    print_success "Installed foot"
}

# Create foot config (symlink to repo config)
create_config() {
    local config_dir="$HOME/.config/foot"
    mkdir -p "$config_dir"

    print_status "Linking foot config..."

    local config_file
    case "$THEME" in
        hackthebox) config_file="foot-hackthebox.ini" ;;
        catppuccin-mocha) config_file="foot-catppuccin-mocha.ini" ;;
        tokyo-night) config_file="foot-tokyo-night.ini" ;;
        ubuntu) config_file="foot-ubuntu.ini" ;;
        *) config_file="foot-catppuccin-mocha.ini" ;;
    esac

    safe_symlink "$SCRIPT_DIR/configs/$config_file" "$config_dir/foot.ini" "foot.ini ($config_file)"
}

# Main
main() {
    detect_distro
    THEME_FILE="$HOME/.config/foot/.theme"
    select_theme

    install_foot
    install_font
    create_config
    set_default_terminal "foot" "foot.desktop"

    echo ""
    print_success "Installation complete!"
    echo ""
    echo "Start foot terminal to see the new config."
    echo "You may need to log out and back in for font changes to take effect."
}

main "$@"
