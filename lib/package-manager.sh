#!/usr/bin/env bash
# mypctools/lib/package-manager.sh
# Package installation logic (apt/pacman primary, flatpak fallback)
# v0.1.0

# Source distro detection
_PKG_MGR_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$_PKG_MGR_DIR/distro-detect.sh"
source "$_PKG_MGR_DIR/helpers.sh"

# Get the appropriate package manager
get_package_manager() {
    case "$DISTRO_TYPE" in
        arch)
            echo "pacman"
            ;;
        debian)
            echo "apt"
            ;;
        fedora)
            echo "dnf"
            ;;
        *)
            echo "unknown"
            ;;
    esac
}

# Check if flatpak is available
has_flatpak() {
    command_exists flatpak
}

# Check if a package is already installed
# Usage: is_installed "pacman_pkg" "apt_pkg" "flatpak_id"
is_installed() {
    local pacman_pkg="$1"
    local apt_pkg="$2"
    local flatpak_id="$3"

    local pkg_manager
    pkg_manager=$(get_package_manager)

    # Check via package manager
    case "$pkg_manager" in
        pacman)
            [[ -n "$pacman_pkg" ]] && pacman -Q "$pacman_pkg" &>/dev/null && return 0
            ;;
        apt)
            [[ -n "$apt_pkg" ]] && dpkg -s "$apt_pkg" &>/dev/null && return 0
            ;;
    esac

    # Check flatpak
    if [[ -n "$flatpak_id" ]] && has_flatpak; then
        flatpak list --app --columns=application 2>/dev/null | grep -q "^${flatpak_id}$" && return 0
    fi

    # Check if command exists (catches non-standard installs)
    # Derive command name from package name
    local cmd=""
    if [[ -n "$pacman_pkg" ]]; then
        cmd="${pacman_pkg%-bin}"  # brave-bin -> brave
        cmd="${cmd%-git}"         # some-git -> some
        command -v "$cmd" &>/dev/null && return 0
    fi
    if [[ -n "$apt_pkg" ]]; then
        cmd="${apt_pkg%-browser}"  # brave-browser -> brave
        cmd="${cmd%-client}"       # spotify-client -> spotify
        command -v "$cmd" &>/dev/null && return 0
        # Also check original name
        command -v "$apt_pkg" &>/dev/null && return 0
    fi

    return 1
}

# =============================================================================
# Fallback install functions for packages needing special handling
# =============================================================================

# Brave Browser - official installer works on any distro
install_brave_fallback() {
    curl -fsS https://dl.brave.com/install.sh | sh
}

# VSCode - Debian repo setup (Arch uses AUR 'code' package)
install_vscode_fallback() {
    if [[ "$DISTRO_TYPE" != "debian" ]]; then
        print_error "VSCode fallback only supports Debian-based distros"
        return 1
    fi

    sudo apt-get install -y wget gpg
    wget -qO- https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor > /tmp/microsoft.gpg
    sudo install -D -o root -g root -m 644 /tmp/microsoft.gpg /usr/share/keyrings/microsoft.gpg
    rm -f /tmp/microsoft.gpg
    echo "deb [arch=amd64,arm64,armhf signed-by=/usr/share/keyrings/microsoft.gpg] https://packages.microsoft.com/repos/code stable main" | sudo tee /etc/apt/sources.list.d/vscode.list
    sudo apt-get update
    sudo apt-get install -y code
}

# Spotify - Debian repo setup (Arch uses AUR, flatpak works everywhere)
install_spotify_fallback() {
    if [[ "$DISTRO_TYPE" != "debian" ]]; then
        print_error "Spotify deb fallback only supports Debian-based distros. Try flatpak."
        return 1
    fi

    curl -sS https://download.spotify.com/debian/pubkey_5384CE82BA52C83A.asc | sudo gpg --dearmor --yes -o /etc/apt/trusted.gpg.d/spotify.gpg
    echo "deb https://repository.spotify.com stable non-free" | sudo tee /etc/apt/sources.list.d/spotify.list
    sudo apt-get update
    sudo apt-get install -y spotify-client
}

# =============================================================================

# Install a package
# Usage: install_package "Display Name" "apt_pkg" "pacman_pkg" "flatpak_id" "fallback_function"
# Any package field can be empty string "" to skip that method
install_package() {
    local display_name="$1"
    local apt_pkg="$2"
    local pacman_pkg="$3"
    local flatpak_id="$4"
    local fallback_fn="$5"

    local pkg_manager
    pkg_manager=$(get_package_manager)

    # Check if already installed
    if is_installed "$pacman_pkg" "$apt_pkg" "$flatpak_id"; then
        print_success "$display_name is already installed"
        return 0
    fi

    print_info "Installing $display_name..."

    # Try native package manager first
    case "$pkg_manager" in
        apt)
            if [[ -n "$apt_pkg" ]]; then
                if sudo apt install -y $apt_pkg; then
                    print_success "$display_name installed successfully"
                    return 0
                fi
                print_warning "apt install failed, trying fallback..."
            fi
            ;;
        pacman)
            if [[ -n "$pacman_pkg" ]]; then
                if sudo pacman -S --noconfirm $pacman_pkg; then
                    print_success "$display_name installed successfully"
                    return 0
                fi
                print_warning "pacman install failed, trying fallback..."
            fi
            ;;
    esac

    # Flatpak fallback
    if [[ -n "$flatpak_id" ]] && has_flatpak; then
        if flatpak install -y flathub $flatpak_id; then
            print_success "$display_name installed via Flatpak"
            return 0
        fi
        print_warning "Flatpak install failed..."
    fi

    # Manual fallback function
    if [[ -n "$fallback_fn" ]] && declare -f "$fallback_fn" &>/dev/null; then
        print_info "Running custom install for $display_name..."
        if $fallback_fn; then
            print_success "$display_name installed via fallback"
            return 0
        fi
    fi

    print_error "No installation method available for $display_name"
    return 1
}

# Batch install packages from a list
# Usage: install_packages "pkg1" "pkg2" "pkg3"
install_packages() {
    local failed=0
    for pkg in "$@"; do
        if ! install_package "$pkg" "$pkg" "$pkg" "" ""; then
            ((failed++))
        fi
    done
    return $failed
}
