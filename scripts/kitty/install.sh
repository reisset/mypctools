#!/usr/bin/env bash
# Kitty Terminal Installer
# v1.1.0 - Uses shared terminal-install.sh

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../../lib/terminal-install.sh"

init_sudo

# Install kitty
install_kitty() {
    if command -v kitty &>/dev/null; then
        print_success "kitty already installed"
        return 0
    fi

    print_status "Installing kitty..."
    case "$PKG_MGR" in
        pacman) $PKG_INSTALL kitty ;;
        apt) $PKG_INSTALL kitty ;;
        dnf) $PKG_INSTALL kitty ;;
    esac
    print_success "Installed kitty"
}

# Create kitty config (symlink to repo config)
create_config() {
    local config_dir="$HOME/.config/kitty"
    mkdir -p "$config_dir"

    print_status "Linking kitty config..."

    local config_file
    case "$THEME" in
        hackthebox) config_file="kitty-hackthebox.conf" ;;
        catppuccin-mocha) config_file="kitty-catppuccin-mocha.conf" ;;
        tokyo-night) config_file="kitty-tokyo-night.conf" ;;
        *) config_file="kitty-catppuccin-mocha.conf" ;;
    esac

    safe_symlink "$SCRIPT_DIR/configs/$config_file" "$config_dir/kitty.conf" "kitty.conf ($config_file)"
}

# Main
main() {
    detect_distro
    select_theme

    install_kitty
    install_font
    create_config
    set_default_terminal "kitty" "kitty.desktop"

    echo ""
    print_success "Installation complete!"
    echo ""
    echo "Start kitty terminal to see the new config."
    echo "You may need to log out and back in for font changes to take effect."
}

main "$@"
