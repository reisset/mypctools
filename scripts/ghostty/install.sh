#!/usr/bin/env bash
# Ghostty Terminal Installer
# v1.1.0 - Uses shared terminal-install.sh

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../../lib/terminal-install.sh"

init_sudo

# Install ghostty
install_ghostty() {
    if command -v ghostty &>/dev/null; then
        print_success "ghostty already installed"
        return 0
    fi

    print_status "Installing ghostty..."
    case "$PKG_MGR" in
        pacman) $PKG_INSTALL ghostty ;;
        apt)
            # Ghostty may not be in default apt repos, try snap as fallback
            if apt-cache show ghostty &>/dev/null; then
                $PKG_INSTALL ghostty
            elif command -v snap &>/dev/null; then
                print_status "Ghostty not in apt repos, trying snap..."
                sudo snap install ghostty --classic
            else
                print_warning "Ghostty not available via apt or snap"
                print_warning "Please install ghostty manually from https://ghostty.org"
                return 1
            fi
            ;;
        dnf) $PKG_INSTALL ghostty ;;
    esac

    if command -v ghostty &>/dev/null; then
        print_success "Installed ghostty"
    else
        print_warning "Ghostty installation may have failed"
        print_warning "Please install ghostty manually from https://ghostty.org"
    fi
}

# Create ghostty config (symlink to repo config)
create_config() {
    local config_dir="$HOME/.config/ghostty"
    mkdir -p "$config_dir"

    print_status "Linking ghostty config..."

    local config_file
    case "$THEME" in
        hackthebox) config_file="ghostty-hackthebox" ;;
        catppuccin-mocha) config_file="ghostty-catppuccin-mocha" ;;
        tokyo-night) config_file="ghostty-tokyo-night" ;;
        *) config_file="ghostty-catppuccin-mocha" ;;
    esac

    safe_symlink "$SCRIPT_DIR/configs/$config_file" "$config_dir/config" "config ($config_file)"
}

# Main
main() {
    detect_distro
    select_theme

    install_ghostty
    install_font
    create_config
    set_default_terminal "ghostty" "com.mitchellh.ghostty.desktop"

    echo ""
    print_success "Installation complete!"
    echo ""
    echo "Start ghostty terminal to see the new config."
    echo "You may need to log out and back in for font changes to take effect."
}

main "$@"
