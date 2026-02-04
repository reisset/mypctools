#!/usr/bin/env bash
# Alacritty Terminal Installer
# v1.3.0 - Uses shared terminal-install.sh

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../../lib/terminal-install.sh"

init_sudo

# Install alacritty
install_alacritty() {
    if command -v alacritty &>/dev/null; then
        print_success "alacritty already installed"
        return 0
    fi

    print_status "Installing alacritty..."
    case "$PKG_MGR" in
        pacman) $PKG_INSTALL alacritty ;;
        apt) $PKG_INSTALL alacritty ;;
        dnf) $PKG_INSTALL alacritty ;;
    esac
    print_success "Installed alacritty"
}

# Create alacritty config (symlink to repo config)
create_config() {
    local config_dir="$HOME/.config/alacritty"
    mkdir -p "$config_dir"

    print_status "Linking alacritty config..."

    local config_file
    case "$THEME" in
        hackthebox) config_file="alacritty-hackthebox.toml" ;;
        catppuccin-mocha) config_file="alacritty-catppuccin-mocha.toml" ;;
        tokyo-night) config_file="alacritty-tokyo-night.toml" ;;
        *) config_file="alacritty-catppuccin-mocha.toml" ;;
    esac

    safe_symlink "$SCRIPT_DIR/configs/$config_file" "$config_dir/alacritty.toml" "alacritty.toml ($config_file)"
}

# Main
main() {
    detect_distro
    select_theme

    install_alacritty
    install_font
    create_config
    set_default_terminal "alacritty" "Alacritty.desktop"

    echo ""
    print_success "Installation complete!"
    echo ""
    echo "Start alacritty terminal to see the new config."
    echo "You may need to log out and back in for font changes to take effect."
}

main "$@"
