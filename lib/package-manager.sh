#!/usr/bin/env bash
# mypctools/lib/package-manager.sh
# Package installation logic (apt/pacman primary, flatpak fallback)
# v0.2.0

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

# Run command with spinner, show output only on failure
run_with_spinner() {
    local title="$1"
    shift
    gum spin --spinner dot --show-error --title "$title" -- "$@"
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
        dnf)
            [[ -n "$apt_pkg" ]] && rpm -q "$apt_pkg" &>/dev/null && return 0
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
    local installer="/tmp/brave_install.sh"
    if ! curl -fsS --retry 3 --connect-timeout 10 https://dl.brave.com/install.sh -o "$installer"; then
        print_error "Failed to download Brave installer"
        return 1
    fi
    chmod +x "$installer"
    "$installer"
    local ret=$?
    rm -f "$installer"
    return $ret
}

# VSCode - Debian repo setup (Arch uses AUR 'code' package)
install_vscode_fallback() {
    if [[ "$DISTRO_TYPE" != "debian" ]]; then
        print_error "VSCode fallback only supports Debian-based distros"
        return 1
    fi

    sudo apt-get install -y wget gpg || return 1
    local gpg_key="/tmp/microsoft.asc"
    if ! wget --timeout=10 --tries=3 -qO "$gpg_key" https://packages.microsoft.com/keys/microsoft.asc; then
        print_error "Failed to download Microsoft GPG key"
        return 1
    fi
    gpg --dearmor < "$gpg_key" > /tmp/microsoft.gpg
    sudo install -D -o root -g root -m 644 /tmp/microsoft.gpg /usr/share/keyrings/microsoft.gpg
    rm -f "$gpg_key" /tmp/microsoft.gpg
    echo "deb [arch=amd64,arm64,armhf signed-by=/usr/share/keyrings/microsoft.gpg] https://packages.microsoft.com/repos/code stable main" | sudo tee /etc/apt/sources.list.d/vscode.list
    sudo apt-get update && sudo apt-get install -y code
}

# Caligula - ISO burner (download prebuilt binary for non-Arch)
install_caligula_fallback() {
    local version="0.4.10"
    local url="https://github.com/ifd3f/caligula/releases/download/v${version}/caligula-x86_64-linux"
    local tmp_file="/tmp/caligula"

    if ! curl -fsSL "$url" -o "$tmp_file"; then
        print_error "Failed to download caligula binary"
        return 1
    fi

    chmod +x "$tmp_file"
    sudo mv "$tmp_file" /usr/local/bin/caligula
    print_success "caligula installed to /usr/local/bin/"
}

# Spotify - Debian repo setup (Arch uses AUR, flatpak works everywhere)
install_spotify_fallback() {
    if [[ "$DISTRO_TYPE" != "debian" ]]; then
        print_error "Spotify deb fallback only supports Debian-based distros. Try flatpak."
        return 1
    fi

    local gpg_key="/tmp/spotify_pubkey.asc"
    if ! curl -sS --retry 3 --connect-timeout 10 https://download.spotify.com/debian/pubkey_5384CE82BA52C83A.asc -o "$gpg_key"; then
        print_error "Failed to download Spotify GPG key"
        return 1
    fi
    sudo gpg --dearmor --yes -o /etc/apt/trusted.gpg.d/spotify.gpg < "$gpg_key"
    rm -f "$gpg_key"
    echo "deb https://repository.spotify.com stable non-free" | sudo tee /etc/apt/sources.list.d/spotify.list
    sudo apt-get update && sudo apt-get install -y spotify-client
}

# LazyDocker - binary download from GitHub releases
install_lazydocker_fallback() {
    local version
    version=$(curl -s https://api.github.com/repos/jesseduffield/lazydocker/releases/latest | grep -Po '"tag_name": "v\K[^"]*')
    if [[ -z "$version" ]]; then
        print_error "Failed to fetch LazyDocker version"
        return 1
    fi
    curl -Lo /tmp/lazydocker.tar.gz "https://github.com/jesseduffield/lazydocker/releases/download/v${version}/lazydocker_${version}_Linux_x86_64.tar.gz" || return 1
    tar -xzf /tmp/lazydocker.tar.gz -C /tmp lazydocker || return 1
    sudo mv /tmp/lazydocker /usr/local/bin/
    rm -f /tmp/lazydocker.tar.gz
}

# Cursor - AppImage download
install_cursor_fallback() {
    local appimage_url="https://downloader.cursor.sh/linux/appImage/x64"
    mkdir -p "$HOME/.local/bin"
    curl -Lo "$HOME/.local/bin/cursor.AppImage" "$appimage_url" || return 1
    chmod +x "$HOME/.local/bin/cursor.AppImage"
    print_info "Cursor installed to ~/.local/bin/cursor.AppImage"
}

# Ollama - official install script
install_ollama_fallback() {
    curl -fsSL https://ollama.com/install.sh | sh
}

# OpenCode - official install script
install_opencode_fallback() {
    curl -fsSL https://opencode.ai/install | bash
}

# Claude Code - official install script
install_claude_code_fallback() {
    curl -fsSL https://claude.ai/install.sh | bash
}

# Mistral Vibe CLI - official install script
install_mistral_vibe_fallback() {
    curl -LsSf https://mistral.ai/vibe/install.sh | bash
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

    # Try native package manager first
    case "$pkg_manager" in
        apt)
            if [[ -n "$apt_pkg" ]]; then
                if run_with_spinner "Installing $display_name..." sudo apt install -y "$apt_pkg"; then
                    print_success "$display_name installed successfully"
                    return 0
                fi
                print_warning "apt install failed, trying fallback..."
            fi
            ;;
        pacman)
            if [[ -n "$pacman_pkg" ]]; then
                if run_with_spinner "Installing $display_name..." sudo pacman -S --noconfirm "$pacman_pkg"; then
                    print_success "$display_name installed successfully"
                    return 0
                fi
                print_warning "pacman install failed, trying fallback..."
            fi
            ;;
    esac

    # Flatpak fallback
    if [[ -n "$flatpak_id" ]] && has_flatpak; then
        if run_with_spinner "Installing $display_name (Flatpak)..." flatpak install -y flathub "$flatpak_id"; then
            print_success "$display_name installed via Flatpak"
            return 0
        fi
        print_warning "Flatpak install failed..."
    fi

    # Manual fallback function (called directly, not through gum spin)
    if [[ -n "$fallback_fn" ]] && declare -f "$fallback_fn" &>/dev/null; then
        print_info "Installing $display_name (custom)..."
        if "$fallback_fn"; then
            print_success "$display_name installed via fallback"
            return 0
        fi
    fi

    print_error "No installation method available for $display_name"
    return 1
}

