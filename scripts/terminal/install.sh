#!/usr/bin/env bash
# LiteBash Terminal (foot) Installer
# v1.7.0 - Uses shared terminal-install.sh

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../../lib/terminal-install.sh"

init_sudo

# Wayland check
if [ -z "$WAYLAND_DISPLAY" ]; then
    print_error "Wayland not detected. foot is Wayland-only."
    echo "If you're on X11, foot will not work."
    exit 1
fi
print_success "Wayland detected"

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
        *) config_file="foot-hackthebox.ini" ;;
    esac

    safe_symlink "$SCRIPT_DIR/configs/$config_file" "$config_dir/foot.ini" "foot.ini ($config_file)"
}

# Main
main() {
    detect_distro
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
