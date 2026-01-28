#!/usr/bin/env bash
# mypctools/lib/tools-install.sh
# Shared tool installation/uninstallation for litebash and litezsh
# v1.0.0

# Required variables from caller:
#   LOCAL_BIN - path to ~/.local/bin
#   ARCH - uname -m output
#   PKG_MGR - pacman/apt/dnf
#   PKG_INSTALL - install command string
# Required functions from caller:
#   print_status, print_success, print_warning, pkg_install

_TOOLS_LIB_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SHARED_STARSHIP_TOML="$_TOOLS_LIB_DIR/../scripts/shared/prompt/starship.toml"

# All tools installed to ~/.local/bin from GitHub releases
LOCAL_TOOLS=(zoxide lazygit tldr glow dysk dust yazi starship)

# Install from GitHub releases (generic)
_tools_install_from_github() {
    local repo="$1"
    local binary="$2"
    local pattern="$3"
    local extract_path="$4"  # Optional: path inside archive

    if command -v "$binary" &>/dev/null; then
        print_success "$binary already installed"
        return 0
    fi

    print_status "Installing $binary from GitHub ($repo)..."

    local api_url="https://api.github.com/repos/$repo/releases/latest"
    local download_url
    download_url=$(curl -fsSL "$api_url" 2>/dev/null | grep -oP "\"browser_download_url\":\s*\"\K[^\"]*${pattern}[^\"]*" | head -1)

    if [ -z "$download_url" ]; then
        print_warning "Could not find release for $binary (pattern: $pattern)"
        return 1
    fi

    local tmp_dir
    tmp_dir=$(mktemp -d)
    local filename
    filename=$(basename "$download_url")

    cd "$tmp_dir"
    if ! curl -fsSL -o "$filename" "$download_url"; then
        print_warning "Failed to download $binary"
        rm -rf "$tmp_dir"
        return 1
    fi

    # Extract based on file type
    case "$filename" in
        *.tar.gz|*.tgz)
            tar xzf "$filename"
            ;;
        *.tar.xz)
            tar xJf "$filename"
            ;;
        *.zip)
            unzip -q "$filename"
            ;;
        *)
            # Assume raw binary
            chmod +x "$filename"
            mv "$filename" "$LOCAL_BIN/$binary"
            rm -rf "$tmp_dir"
            print_success "Installed $binary"
            return 0
            ;;
    esac

    # Find and install binary
    local binary_path
    if [ -n "$extract_path" ]; then
        binary_path="$extract_path"
    else
        binary_path=$(find . -name "$binary" -type f -executable 2>/dev/null | head -1)
        [ -z "$binary_path" ] && binary_path=$(find . -name "$binary" -type f 2>/dev/null | head -1)
    fi

    if [ -n "$binary_path" ] && [ -f "$binary_path" ]; then
        chmod +x "$binary_path"
        mv "$binary_path" "$LOCAL_BIN/$binary"
        print_success "Installed $binary"
    else
        print_warning "Could not find $binary in archive"
        rm -rf "$tmp_dir"
        return 1
    fi

    rm -rf "$tmp_dir"
    return 0
}

# Install dysk (single zip, no arch-specific builds)
_tools_install_dysk() {
    if command -v dysk &>/dev/null; then
        print_success "dysk already installed"
        return 0
    fi

    print_status "Installing dysk from GitHub..."
    local api_url="https://api.github.com/repos/Canop/dysk/releases/latest"
    local download_url
    download_url=$(curl -fsSL "$api_url" 2>/dev/null | grep -oP '"browser_download_url":\s*"\K[^"]+\.zip' | head -1)

    if [ -z "$download_url" ]; then
        print_warning "Could not find dysk release"
        return 1
    fi

    local tmp_dir
    tmp_dir=$(mktemp -d)
    cd "$tmp_dir"

    curl -fsSL -o "dysk.zip" "$download_url" || { print_warning "Failed to download dysk"; rm -rf "$tmp_dir"; return 1; }
    unzip -q "dysk.zip"

    local binary_path
    binary_path=$(find . -name "dysk" -type f -executable 2>/dev/null | head -1)
    [ -z "$binary_path" ] && binary_path=$(find . -name "dysk" -type f 2>/dev/null | head -1)

    if [ -n "$binary_path" ] && [ -f "$binary_path" ]; then
        chmod +x "$binary_path"
        mv "$binary_path" "$LOCAL_BIN/dysk"
        print_success "Installed dysk"
    else
        print_warning "Could not find dysk binary in archive"
        rm -rf "$tmp_dir"
        return 1
    fi

    rm -rf "$tmp_dir"
}

# Install dust (disk usage analyzer)
_tools_install_dust() {
    if command -v dust &>/dev/null; then
        print_success "dust already installed"
        return 0
    fi

    print_status "Installing dust from GitHub..."
    local api_url="https://api.github.com/repos/bootandy/dust/releases/latest"
    local download_url
    local pattern

    case "$ARCH" in
        x86_64) pattern="x86_64-unknown-linux-musl.tar.gz" ;;
        aarch64) pattern="aarch64-unknown-linux-musl.tar.gz" ;;
        *) print_warning "Unsupported architecture for dust: $ARCH"; return 1 ;;
    esac

    download_url=$(curl -fsSL "$api_url" 2>/dev/null | grep -oP '"browser_download_url":\s*"\K[^"]*'"$pattern"'[^"]*' | head -1)

    if [ -z "$download_url" ]; then
        print_warning "Could not find dust release"
        return 1
    fi

    local tmp_dir
    tmp_dir=$(mktemp -d)
    cd "$tmp_dir"

    curl -fsSL -o "dust.tar.gz" "$download_url" || { print_warning "Failed to download dust"; rm -rf "$tmp_dir"; return 1; }
    tar xzf "dust.tar.gz"

    local binary_path
    binary_path=$(find . -name "dust" -type f -executable 2>/dev/null | head -1)
    [ -z "$binary_path" ] && binary_path=$(find . -name "dust" -type f 2>/dev/null | head -1)

    if [ -n "$binary_path" ] && [ -f "$binary_path" ]; then
        chmod +x "$binary_path"
        mv "$binary_path" "$LOCAL_BIN/dust"
        print_success "Installed dust"
    else
        print_warning "Could not find dust binary in archive"
        rm -rf "$tmp_dir"
        return 1
    fi

    rm -rf "$tmp_dir"
}

# Install starship via official script
_tools_install_starship() {
    if command -v starship &>/dev/null; then
        print_success "starship already installed"
        return 0
    fi
    print_status "Installing starship..."
    curl -fsSL https://starship.rs/install.sh | sh -s -- -y -b "$LOCAL_BIN"
    print_success "Installed starship"
}

# Install all GitHub-release tools + Debian symlinks
install_all_tools() {
    _tools_install_from_github "ajeetdsouza/zoxide" "zoxide" "${ARCH}.*linux.*musl"
    _tools_install_from_github "jesseduffield/lazygit" "lazygit" "linux_${ARCH}\.tar\.gz"
    _tools_install_from_github "tealdeer-rs/tealdeer" "tldr" "linux-${ARCH}-musl$"
    _tools_install_from_github "charmbracelet/glow" "glow" "Linux_${ARCH}\.tar\.gz"
    _tools_install_dysk
    _tools_install_dust
    _tools_install_from_github "sxyazi/yazi" "yazi" "${ARCH}-unknown-linux-musl\.zip"
    _tools_install_starship
}

# Create Debian/Ubuntu symlinks for bat/fd naming differences
create_debian_symlinks() {
    if [ "$PKG_MGR" = "apt" ]; then
        [ -f /usr/bin/batcat ] && [ ! -f "$LOCAL_BIN/bat" ] && ln -sf /usr/bin/batcat "$LOCAL_BIN/bat"
        [ -f /usr/bin/fdfind ] && [ ! -f "$LOCAL_BIN/fd" ] && ln -sf /usr/bin/fdfind "$LOCAL_BIN/fd"
    fi
}

# Install starship config symlink (points to shared location)
install_starship_config() {
    ln -sf "$SHARED_STARSHIP_TOML" "$HOME/.config/starship.toml"
}

# Uninstall all tools from ~/.local/bin + symlinks
uninstall_local_tools() {
    print_status "Removing GitHub-installed tools from ~/.local/bin..."

    for tool in "${LOCAL_TOOLS[@]}"; do
        if [ -f "$LOCAL_BIN/$tool" ]; then
            rm -f "$LOCAL_BIN/$tool"
            print_status "Removed $tool"
        fi
    done

    # Remove Debian symlinks
    [ -L "$LOCAL_BIN/bat" ] && rm -f "$LOCAL_BIN/bat"
    [ -L "$LOCAL_BIN/fd" ] && rm -f "$LOCAL_BIN/fd"

    print_success "Removed tools from ~/.local/bin"
}

# Print system package removal instructions
print_pkg_removal_instructions() {
    local extra_pkgs="${1:-}"  # Optional extra packages (e.g. "zsh")
    if command -v pacman &>/dev/null; then
        print_status "To remove system packages, run:"
        echo "  sudo pacman -Rs eza bat fzf ripgrep fd btop micro github-cli${extra_pkgs:+ $extra_pkgs}"
    elif command -v apt &>/dev/null; then
        print_status "To remove system packages, run:"
        echo "  sudo apt remove eza bat fzf ripgrep fd-find btop micro gh${extra_pkgs:+ $extra_pkgs}"
    elif command -v dnf &>/dev/null; then
        print_status "To remove system packages, run:"
        echo "  sudo dnf remove eza bat fzf ripgrep fd-find btop micro gh${extra_pkgs:+ $extra_pkgs}"
    fi
}

# Remove starship config only if it points to our shared config
uninstall_starship_config() {
    if [ -L "$HOME/.config/starship.toml" ]; then
        local target
        target=$(readlink -f "$HOME/.config/starship.toml" 2>/dev/null)
        local shared_resolved
        shared_resolved=$(readlink -f "$SHARED_STARSHIP_TOML" 2>/dev/null)
        if [[ "$target" == "$shared_resolved" ]]; then
            rm -f "$HOME/.config/starship.toml"
            print_success "Removed starship.toml"
        else
            print_status "starship.toml points elsewhere, leaving in place"
        fi
    elif [ -f "$HOME/.config/starship.toml" ]; then
        print_status "starship.toml is a regular file (not managed by us), leaving in place"
    fi
}
