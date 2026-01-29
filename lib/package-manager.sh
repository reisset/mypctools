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
    gum spin --spinner dot --show-error --title "$title" -- "$@" < /dev/null
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
            # Fedora names sometimes match Debian, sometimes Arch - try both
            [[ -n "$apt_pkg" ]] && rpm -q "$apt_pkg" &>/dev/null && return 0
            [[ -n "$pacman_pkg" ]] && rpm -q "$pacman_pkg" &>/dev/null && return 0
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
        # Special case: dotnet SDK uses 'dotnet' command
        [[ "$apt_pkg" == dotnet-sdk-* ]] && command -v dotnet &>/dev/null && return 0
    fi

    return 1
}

# =============================================================================
# Fallback install functions for packages needing special handling
# =============================================================================

# Brave Browser - official installer works on any distro
install_brave_fallback() {
    local installer
    installer=$(mktemp)
    if ! curl -fsS --retry 3 --connect-timeout 10 https://dl.brave.com/install.sh -o "$installer"; then
        print_error "Failed to download Brave installer"
        rm -f "$installer"
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

    ensure_sudo || return 1
    sudo apt-get install -y wget gpg || return 1
    local gpg_key gpg_dearmored
    gpg_key=$(mktemp)
    gpg_dearmored=$(mktemp)
    if ! wget --timeout=10 --tries=3 -qO "$gpg_key" https://packages.microsoft.com/keys/microsoft.asc; then
        print_error "Failed to download Microsoft GPG key"
        rm -f "$gpg_key" "$gpg_dearmored"
        return 1
    fi
    gpg --dearmor < "$gpg_key" > "$gpg_dearmored"
    sudo install -D -o root -g root -m 644 "$gpg_dearmored" /usr/share/keyrings/microsoft.gpg
    rm -f "$gpg_key" "$gpg_dearmored"
    echo "deb [arch=amd64,arm64,armhf signed-by=/usr/share/keyrings/microsoft.gpg] https://packages.microsoft.com/repos/code stable main" | sudo tee /etc/apt/sources.list.d/vscode.list
    sudo apt-get update && sudo apt-get install -y code
}

# .NET SDK - Ubuntu 24.04+ has .NET in default repos, fallback uses backports PPA
install_dotnet_fallback() {
    if [[ "$DISTRO_TYPE" != "debian" ]]; then
        print_error ".NET SDK fallback only supports Debian-based distros"
        return 1
    fi

    ensure_sudo || return 1

    # Ubuntu 24.04+ includes .NET in default repos - just need apt update
    print_info "Updating package lists..."
    sudo apt-get update || return 1

    # Try installing from default repos first
    if sudo apt-get install -y dotnet-sdk-10.0; then
        return 0
    fi

    # Fallback: Ubuntu .NET backports PPA (maintained by Canonical)
    print_warning "Default repos failed, trying backports PPA..."
    sudo add-apt-repository -y ppa:dotnet/backports || return 1
    sudo apt-get update && sudo apt-get install -y dotnet-sdk-10.0
}

# Discord - direct .deb download (Arch has official package, flatpak works everywhere)
install_discord_fallback() {
    if [[ "$DISTRO_TYPE" != "debian" ]]; then
        print_error "Discord deb fallback only supports Debian-based distros. Try flatpak."
        return 1
    fi

    local tmp_deb
    tmp_deb=$(mktemp --suffix=.deb)
    if ! curl -fsSL "https://discord.com/api/download?platform=linux&format=deb" -o "$tmp_deb"; then
        print_error "Failed to download Discord .deb"
        rm -f "$tmp_deb"
        return 1
    fi
    ensure_sudo || { rm -f "$tmp_deb"; return 1; }
    sudo dpkg -i "$tmp_deb"
    sudo apt-get install -f -y  # Fix any dependency issues
    rm -f "$tmp_deb"
}

# Spotify - Debian repo setup (Arch uses AUR, flatpak works everywhere)
install_spotify_fallback() {
    if [[ "$DISTRO_TYPE" != "debian" ]]; then
        print_error "Spotify deb fallback only supports Debian-based distros. Try flatpak."
        return 1
    fi

    local gpg_key
    gpg_key=$(mktemp)
    if ! curl -sS --retry 3 --connect-timeout 10 https://download.spotify.com/debian/pubkey_5384CE82BA52C83A.asc -o "$gpg_key"; then
        print_error "Failed to download Spotify GPG key"
        rm -f "$gpg_key"
        return 1
    fi
    ensure_sudo || { rm -f "$gpg_key"; return 1; }
    sudo gpg --dearmor --yes -o /etc/apt/trusted.gpg.d/spotify.gpg < "$gpg_key"
    rm -f "$gpg_key"
    echo "deb https://repository.spotify.com stable non-free" | sudo tee /etc/apt/sources.list.d/spotify.list
    sudo apt-get update && sudo apt-get install -y spotify-client
}

# LazyDocker - binary download from GitHub releases
install_lazydocker_fallback() {
    local version
    if command -v jq &>/dev/null; then
        version=$(curl -s https://api.github.com/repos/jesseduffield/lazydocker/releases/latest | jq -r '.tag_name' | sed 's/^v//')
    else
        version=$(curl -s https://api.github.com/repos/jesseduffield/lazydocker/releases/latest | grep -Po '"tag_name": "v\K[^"]*')
    fi
    if [[ -z "$version" ]]; then
        print_error "Failed to fetch LazyDocker version"
        return 1
    fi
    local arch
    case "$(uname -m)" in
        x86_64)  arch="x86_64" ;;
        aarch64) arch="arm64" ;;
        armv7*)  arch="armv7" ;;
        *)       print_error "Unsupported architecture: $(uname -m)"; return 1 ;;
    esac
    curl -Lo /tmp/lazydocker.tar.gz "https://github.com/jesseduffield/lazydocker/releases/download/v${version}/lazydocker_${version}_Linux_${arch}.tar.gz" || return 1
    tar -xzf /tmp/lazydocker.tar.gz -C /tmp lazydocker || return 1
    ensure_sudo || return 1
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

# LM Studio - AppImage download (~1GB)
install_lmstudio_fallback() {
    local appimage_url="https://lmstudio.ai/download/latest/linux/x64"
    mkdir -p "$HOME/.local/bin"
    print_warning "LM Studio is ~1GB - this may take a while..."
    if ! curl -L -o "$HOME/.local/bin/lmstudio.AppImage" "$appimage_url"; then
        print_error "Failed to download LM Studio"
        return 1
    fi
    chmod +x "$HOME/.local/bin/lmstudio.AppImage"
    print_info "LM Studio installed to ~/.local/bin/lmstudio.AppImage"
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
                ensure_sudo || return 1
                if run_with_spinner "Installing $display_name..." sudo apt install -y "$apt_pkg"; then
                    print_success "$display_name installed successfully"
                    return 0
                fi
                print_warning "apt install failed, trying fallback..."
            fi
            ;;
        pacman)
            if [[ -n "$pacman_pkg" ]]; then
                ensure_sudo || return 1
                if run_with_spinner "Installing $display_name..." sudo pacman -S --noconfirm "$pacman_pkg"; then
                    print_success "$display_name installed successfully"
                    return 0
                fi
                print_warning "pacman install failed, trying fallback..."
            fi
            ;;
        dnf)
            # Fedora names sometimes match Debian, sometimes Arch - try both
            ensure_sudo || return 1
            if [[ -n "$apt_pkg" ]]; then
                if run_with_spinner "Installing $display_name..." sudo dnf install -y "$apt_pkg"; then
                    print_success "$display_name installed successfully"
                    return 0
                fi
            fi
            if [[ -n "$pacman_pkg" && "$pacman_pkg" != "$apt_pkg" ]]; then
                if run_with_spinner "Installing $display_name..." sudo dnf install -y "$pacman_pkg"; then
                    print_success "$display_name installed successfully"
                    return 0
                fi
            fi
            [[ -n "$apt_pkg" || -n "$pacman_pkg" ]] && print_warning "dnf install failed, trying fallback..."
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

