#!/usr/bin/env bash
# Fastfetch Config Installer
# v1.0.0

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../../lib/terminal-install.sh"

# Install fastfetch
install_fastfetch() {
    if command -v fastfetch &>/dev/null; then
        print_success "fastfetch already installed"
        return 0
    fi

    detect_distro

    print_status "Installing fastfetch..."
    case "$PKG_MGR" in
        pacman) $PKG_INSTALL fastfetch ;;
        apt) $PKG_INSTALL fastfetch ;;
        dnf) $PKG_INSTALL fastfetch ;;
    esac

    if command -v fastfetch &>/dev/null; then
        print_success "Installed fastfetch"
    else
        print_error "Failed to install fastfetch"
        return 1
    fi
}

# Link config
create_config() {
    local config_dir="$HOME/.config/fastfetch"
    mkdir -p "$config_dir"

    print_status "Linking fastfetch config..."
    safe_symlink "$SCRIPT_DIR/config.jsonc" "$config_dir/config.jsonc" "config.jsonc"
}

# Main
main() {
    install_fastfetch
    create_config

    echo ""
    print_success "Installation complete!"
    echo ""
    echo "Run 'fastfetch' to see the result."
}

main "$@"
