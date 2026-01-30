#!/usr/bin/env bash
# LiteZsh Shell Installer
# v1.6.0 - Removed set -e for reliability, explicit error handling

# NOTE: We intentionally do NOT use 'set -e' here.
# The script must complete all critical steps (symlinks, .zshrc, shell change)
# even if optional steps fail (individual package installs, etc.)

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LITEZSH_DIR="$HOME/.local/share/litezsh"
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

# Install zsh
install_zsh() {
    if command -v zsh &>/dev/null; then
        print_success "zsh already installed"
        return 0
    fi

    print_status "Installing zsh..."
    case "$PKG_MGR" in
        pacman) $PKG_INSTALL zsh || { print_error "Failed to install zsh"; return 1; } ;;
        apt) $PKG_INSTALL zsh || { print_error "Failed to install zsh"; return 1; } ;;
        dnf) $PKG_INSTALL zsh || { print_error "Failed to install zsh"; return 1; } ;;
    esac

    if command -v zsh &>/dev/null; then
        print_success "Installed zsh"
    else
        print_error "zsh installation failed"
        return 1
    fi
}

# Set zsh as default shell
set_default_shell() {
    local zsh_path
    zsh_path=$(which zsh)

    # Check /etc/passwd directly (more reliable than $SHELL)
    local current_shell
    current_shell=$(getent passwd "$USER" | cut -d: -f7)

    if [[ "$current_shell" == "$zsh_path" ]]; then
        print_success "zsh is already the default shell"
        return 0
    fi

    # Refresh sudo credentials (may have expired during long install)
    print_status "Requesting sudo for shell change..."
    if ! sudo -v; then
        print_error "Could not get sudo access for shell change"
        print_status "Please run manually: chsh -s $zsh_path"
        return 1
    fi

    # Ensure zsh is in /etc/shells
    if ! grep -q "^${zsh_path}$" /etc/shells 2>/dev/null; then
        print_status "Adding zsh to /etc/shells..."
        echo "$zsh_path" | sudo tee -a /etc/shells >/dev/null
    fi

    print_status "Setting zsh as default shell..."

    # Try chsh first, then usermod as fallback
    local changed=false
    if sudo chsh -s "$zsh_path" "$USER" 2>/dev/null; then
        changed=true
    elif sudo usermod -s "$zsh_path" "$USER" 2>/dev/null; then
        changed=true
    fi

    if [[ "$changed" == "true" ]]; then
        # Verify the change took effect
        local new_shell
        new_shell=$(getent passwd "$USER" | cut -d: -f7)
        if [[ "$new_shell" == "$zsh_path" ]]; then
            print_success "Set zsh as default shell"
            return 0
        fi
    fi

    # If we get here, both methods failed
    print_error "Failed to change default shell automatically"
    print_status "Please run manually: chsh -s $zsh_path"
    return 1
}

# Install zsh plugins via git
install_plugins() {
    local plugins_dir="$LITEZSH_DIR/plugins"
    mkdir -p "$plugins_dir"

    # zsh-autosuggestions
    if [[ -d "$plugins_dir/zsh-autosuggestions" ]]; then
        print_success "zsh-autosuggestions already installed"
    else
        print_status "Installing zsh-autosuggestions..."
        if git clone --depth=1 https://github.com/zsh-users/zsh-autosuggestions.git \
            "$plugins_dir/zsh-autosuggestions" 2>/dev/null; then
            print_success "Installed zsh-autosuggestions"
        else
            print_warning "Failed to install zsh-autosuggestions (optional)"
        fi
    fi

    # zsh-syntax-highlighting
    if [[ -d "$plugins_dir/zsh-syntax-highlighting" ]]; then
        print_success "zsh-syntax-highlighting already installed"
    else
        print_status "Installing zsh-syntax-highlighting..."
        if git clone --depth=1 https://github.com/zsh-users/zsh-syntax-highlighting.git \
            "$plugins_dir/zsh-syntax-highlighting" 2>/dev/null; then
            print_success "Installed zsh-syntax-highlighting"
        else
            print_warning "Failed to install zsh-syntax-highlighting (optional)"
        fi
    fi
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

# Main installation
main() {
    detect_distro

    # Source shared tool installation lib
    source "$SCRIPT_DIR/../../lib/tools-install.sh"

    # Create directories
    mkdir -p "$LOCAL_BIN"
    mkdir -p "$LITEZSH_DIR"
    mkdir -p "$HOME/.config"
    mkdir -p "$HOME/.cache/zsh"

    # Update package database
    print_status "Updating package database..."
    $PKG_UPDATE || print_warning "Package database update had issues (continuing anyway)"

    # Install zsh
    install_zsh

    # Install dependencies
    print_status "Installing dependencies..."
    pkg_install "curl" "curl" "curl" "curl"
    pkg_install "unzip" "unzip" "unzip" "unzip"
    pkg_install "tar" "tar" "tar" "tar"
    pkg_install "git" "git" "git" "git"

    # Install plugins
    install_plugins

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

    # Create Debian symlinks + install all GitHub tools
    create_debian_symlinks
    install_all_tools

    # Symlink config files (source of truth in repo, aliases and TOOLS.md are shared)
    print_status "Installing LiteZsh config..."
    local symlink_errors=0
    safe_symlink "$SCRIPT_DIR/litezsh.zsh" "$LITEZSH_DIR/litezsh.zsh" "litezsh.zsh" || ((symlink_errors++))
    safe_symlink "$SCRIPT_DIR/../shared/shell/aliases.sh" "$LITEZSH_DIR/aliases.sh" "aliases.sh" || ((symlink_errors++))
    safe_symlink "$SCRIPT_DIR/functions.zsh" "$LITEZSH_DIR/functions.zsh" "functions.zsh" || ((symlink_errors++))
    safe_symlink "$SCRIPT_DIR/completions.zsh" "$LITEZSH_DIR/completions.zsh" "completions.zsh" || ((symlink_errors++))
    safe_symlink "$SCRIPT_DIR/../shared/shell/TOOLS.md" "$LITEZSH_DIR/TOOLS.md" "TOOLS.md" || ((symlink_errors++))

    # Verify ALL symlinks were created and point to valid targets
    local expected_links=("litezsh.zsh" "aliases.sh" "functions.zsh" "completions.zsh" "TOOLS.md")
    local verified=0
    for link in "${expected_links[@]}"; do
        if [[ -L "$LITEZSH_DIR/$link" ]] && [[ -e "$LITEZSH_DIR/$link" ]]; then
            ((verified++))
        fi
    done

    if [[ $verified -eq ${#expected_links[@]} ]]; then
        print_success "LiteZsh config installed ($verified/${#expected_links[@]} symlinks verified)"
    else
        print_error "Only $verified/${#expected_links[@]} symlinks verified - check permissions"
    fi

    # Install starship config (shared location)
    install_starship_config

    # Verify starship config was created
    if [[ ! -L "$HOME/.config/starship.toml" ]] && [[ ! -f "$HOME/.config/starship.toml" ]]; then
        print_warning "Starship config not created - creating manually..."
        ln -sf "$(readlink -f "$SCRIPT_DIR/../shared/prompt/starship.toml")" "$HOME/.config/starship.toml"
    fi

    # Add to .zshrc BEFORE changing shell (prevents zsh newuser wizard)
    if ! grep -q "litezsh/litezsh.zsh" "$HOME/.zshrc" 2>/dev/null; then
        print_status "Adding LiteZsh to ~/.zshrc..."
        # Create .zshrc if it doesn't exist
        touch "$HOME/.zshrc"
        echo '' >> "$HOME/.zshrc"
        echo '# LiteZsh' >> "$HOME/.zshrc"
        echo '[[ -f ~/.local/share/litezsh/litezsh.zsh ]] && source ~/.local/share/litezsh/litezsh.zsh' >> "$HOME/.zshrc"
    else
        print_status "LiteZsh already in ~/.zshrc"
    fi

    # Set zsh as default shell (after .zshrc is set up)
    set_default_shell

    echo ""
    print_success "Installation complete!"
    echo ""
    echo -e "${YELLOW}╔════════════════════════════════════════════╗${NC}"
    echo -e "${YELLOW}║  LOG OUT AND BACK IN to start using zsh!   ║${NC}"
    echo -e "${YELLOW}╚════════════════════════════════════════════╝${NC}"
    echo ""
    echo "Or run 'zsh' to try it now without logging out."
    echo "Type 'tools' to see the quick reference."
}

main "$@"
