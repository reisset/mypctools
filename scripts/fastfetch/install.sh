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
        dnf) $PKG_INSTALL fastfetch ;;
        apt)
            $PKG_INSTALL fastfetch 2>/dev/null || install_fastfetch_deb
            ;;
    esac

    if command -v fastfetch &>/dev/null; then
        print_success "Installed fastfetch"
    else
        print_error "Failed to install fastfetch"
        return 1
    fi
}

# Download latest .deb from GitHub releases (for Debian/Ubuntu/Pop where apt lacks fastfetch)
install_fastfetch_deb() {
    print_status "Package not in repos, downloading from GitHub..."
    local arch
    arch=$(dpkg --print-architecture 2>/dev/null || echo "amd64")
    local api_url="https://api.github.com/repos/fastfetch-cli/fastfetch/releases/latest"
    local deb_url
    deb_url=$(curl -fsSL "$api_url" 2>/dev/null | grep -oP '"browser_download_url":\s*"\K[^"]*linux-'"$arch"'\.deb' | head -1)

    if [ -z "$deb_url" ]; then
        print_error "Could not find fastfetch .deb download URL"
        return 1
    fi

    local tmp
    tmp=$(mktemp --suffix=.deb)
    curl -fsSL -o "$tmp" "$deb_url" || { rm -f "$tmp"; return 1; }
    sudo dpkg -i "$tmp"
    rm -f "$tmp"
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
    install_fastfetch || { echo ""; return 1; }
    create_config

    echo ""
    print_success "Installation complete!"
    echo ""
    echo "Run 'fastfetch' to see the result."
}

main "$@"
