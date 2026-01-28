#!/usr/bin/env bash
# LiteBash Shell Installer
# v1.1.0 - Added dust utility

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LITEBASH_DIR="$HOME/.local/share/litebash"
LOCAL_BIN="$HOME/.local/bin"
ARCH=$(uname -m)

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

print_status() { echo -e "${BLUE}[*]${NC} $1"; }
print_success() { echo -e "${GREEN}[✓]${NC} $1"; }
print_warning() { echo -e "${YELLOW}[!]${NC} $1"; }
print_error() { echo -e "${RED}[✗]${NC} $1"; }

# Sudo check
echo "This installer requires sudo privileges to function properly."
echo "Read the entire script if you do not trust the author."
echo ""
sudo -v || { print_error "Sudo access required. Aborting."; exit 1; }

# Keep sudo alive
while true; do sudo -n true; sleep 60; kill -0 "$$" || exit; done 2>/dev/null &

# Detect package manager
detect_distro() {
    if command -v pacman &>/dev/null; then
        PKG_MGR="pacman"
        PKG_INSTALL="sudo pacman -S --noconfirm --needed"
        PKG_UPDATE="sudo pacman -Sy"
    elif command -v apt &>/dev/null; then
        PKG_MGR="apt"
        PKG_INSTALL="sudo apt install -y"
        PKG_UPDATE="sudo apt update"
    elif command -v dnf &>/dev/null; then
        PKG_MGR="dnf"
        PKG_INSTALL="sudo dnf install -y"
        PKG_UPDATE="sudo dnf check-update || true"
    else
        print_error "No supported package manager found (pacman/apt/dnf)"
        exit 1
    fi
    print_status "Detected package manager: $PKG_MGR"
}


# Install package via package manager
pkg_install() {
    local name="$1"
    local pacman_pkg="$2"
    local apt_pkg="$3"
    local dnf_pkg="$4"

    local pkg=""
    case "$PKG_MGR" in
        pacman) pkg="$pacman_pkg" ;;
        apt) pkg="$apt_pkg" ;;
        dnf) pkg="$dnf_pkg" ;;
    esac

    if [ -n "$pkg" ]; then
        print_status "Installing $name..."
        $PKG_INSTALL "$pkg" 2>/dev/null || print_warning "Failed to install $name via $PKG_MGR"
    fi
}

# Install from GitHub releases
install_from_github() {
    local repo="$1"
    local binary="$2"
    local pattern="$3"
    local extract_path="$4"  # Optional: path inside archive

    if command -v "$binary" &>/dev/null; then
        print_success "$binary already installed"
        return 0
    fi

    print_status "Installing $binary from GitHub ($repo)..."

    # Get latest release download URL
    local api_url="https://api.github.com/repos/$repo/releases/latest"
    local download_url
    download_url=$(curl -fsSL "$api_url" 2>/dev/null | grep -oP "\"browser_download_url\":\s*\"\K[^\"]*${pattern}[^\"]*" | head -1)

    if [ -z "$download_url" ]; then
        print_warning "Could not find release for $binary (pattern: $pattern)"
        return 1
    fi

    local tmp_dir=$(mktemp -d)
    local filename=$(basename "$download_url")

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
install_dysk() {
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

    local tmp_dir=$(mktemp -d)
    cd "$tmp_dir"

    curl -fsSL -o "dysk.zip" "$download_url" || { print_warning "Failed to download dysk"; rm -rf "$tmp_dir"; return 1; }
    unzip -q "dysk.zip"

    # Find the dysk binary (it's in build/x86_64-linux/ or similar)
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
install_dust() {
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

    local tmp_dir=$(mktemp -d)
    cd "$tmp_dir"

    curl -fsSL -o "dust.tar.gz" "$download_url" || { print_warning "Failed to download dust"; rm -rf "$tmp_dir"; return 1; }
    tar xzf "dust.tar.gz"

    # Find the dust binary (it's in dust-*/dust)
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
install_starship() {
    if command -v starship &>/dev/null; then
        print_success "starship already installed"
        return 0
    fi
    print_status "Installing starship..."
    curl -fsSL https://starship.rs/install.sh | sh -s -- -y -b "$LOCAL_BIN"
    print_success "Installed starship"
}

# Main installation
main() {
    detect_distro

    # Create directories
    mkdir -p "$LOCAL_BIN"
    mkdir -p "$LITEBASH_DIR"
    mkdir -p "$HOME/.config"

    # Update package database
    print_status "Updating package database..."
    $PKG_UPDATE

    # Install dependencies
    print_status "Installing dependencies..."
    pkg_install "curl" "curl" "curl" "curl"
    pkg_install "unzip" "unzip" "unzip" "unzip"
    pkg_install "tar" "tar" "tar" "tar"
    pkg_install "git" "git" "git" "git"

    # Install core tools via package manager
    print_status "Installing core tools..."
    pkg_install "eza" "eza" "eza" "eza"
    pkg_install "bat" "bat" "bat" "bat"
    pkg_install "fzf" "fzf" "fzf" "fzf"
    pkg_install "ripgrep" "ripgrep" "ripgrep" "ripgrep"
    pkg_install "fd" "fd" "fd-find" "fd-find"
    pkg_install "btop" "btop" "btop" "btop"
    pkg_install "micro" "micro" "micro" "micro"
    pkg_install "gh" "github-cli" "gh" "gh"

    # Create symlinks for Debian/Ubuntu naming differences
    if [ "$PKG_MGR" = "apt" ]; then
        [ -f /usr/bin/batcat ] && [ ! -f "$LOCAL_BIN/bat" ] && ln -sf /usr/bin/batcat "$LOCAL_BIN/bat"
        [ -f /usr/bin/fdfind ] && [ ! -f "$LOCAL_BIN/fd" ] && ln -sf /usr/bin/fdfind "$LOCAL_BIN/fd"
    fi

    # Install tools from GitHub
    install_from_github "ajeetdsouza/zoxide" "zoxide" "${ARCH}.*linux.*musl"
    install_from_github "jesseduffield/lazygit" "lazygit" "linux_${ARCH}\.tar\.gz"
    install_from_github "tealdeer-rs/tealdeer" "tldr" "linux-${ARCH}-musl$"
    install_from_github "charmbracelet/glow" "glow" "Linux_${ARCH}\.tar\.gz"
    install_dysk
    install_dust
    install_from_github "sxyazi/yazi" "yazi" "${ARCH}-unknown-linux-musl\.zip"

    install_starship

    # Copy config files
    print_status "Installing LiteBash config..."
    cp "$SCRIPT_DIR/litebash.sh" "$LITEBASH_DIR/"
    cp "$SCRIPT_DIR/aliases.sh" "$LITEBASH_DIR/"
    cp "$SCRIPT_DIR/functions.sh" "$LITEBASH_DIR/"
    cp "$SCRIPT_DIR/TOOLS.md" "$LITEBASH_DIR/"

    # Install starship config (symlink so edits to source file take effect)
    ln -sf "$SCRIPT_DIR/prompt/starship.toml" "$HOME/.config/starship.toml"

    # Add to bashrc (idempotent)
    if ! grep -q "litebash/litebash.sh" "$HOME/.bashrc" 2>/dev/null; then
        print_status "Adding LiteBash to ~/.bashrc..."
        echo '' >> "$HOME/.bashrc"
        echo '# LiteBash' >> "$HOME/.bashrc"
        echo '[ -f ~/.local/share/litebash/litebash.sh ] && source ~/.local/share/litebash/litebash.sh' >> "$HOME/.bashrc"
    else
        print_status "LiteBash already in ~/.bashrc"
    fi

    echo ""
    print_success "Installation complete!"
    echo ""
    echo "Restart your shell or run: source ~/.bashrc"
    echo "Type 'tools' to see the quick reference."
}

main "$@"
