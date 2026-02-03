#!/usr/bin/env bash
# LiteBash Shell Installer
# v1.4.0 - Removed set -e for reliability, explicit error handling

# NOTE: We intentionally do NOT use 'set -e' here.
# The script must complete all critical steps (config, .bashrc, shell change)
# even if optional steps fail (individual package installs, etc.)

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

# Set bash as default shell (for users switching from zsh)
set_default_shell() {
    local bash_path
    bash_path=$(which bash)

    # Check /etc/passwd directly (more reliable than $SHELL)
    local current_shell
    current_shell=$(getent passwd "$USER" | cut -d: -f7)

    if [[ "$current_shell" == "$bash_path" ]]; then
        print_success "bash is already the default shell"
        return 0
    fi

    # Refresh sudo credentials (may have expired during long install)
    print_status "Requesting sudo for shell change..."
    if ! sudo -v; then
        print_error "Could not get sudo access for shell change"
        print_status "Please run manually: chsh -s $bash_path"
        return 1
    fi

    print_status "Setting bash as default shell..."

    # Try chsh first, then usermod as fallback
    local changed=false
    if sudo chsh -s "$bash_path" "$USER" 2>/dev/null; then
        changed=true
    elif sudo usermod -s "$bash_path" "$USER" 2>/dev/null; then
        changed=true
    fi

    if [[ "$changed" == "true" ]]; then
        local new_shell
        new_shell=$(getent passwd "$USER" | cut -d: -f7)
        if [[ "$new_shell" == "$bash_path" ]]; then
            print_success "Set bash as default shell"
            return 0
        fi
    fi

    print_warning "Could not change shell automatically. Run: chsh -s $bash_path"
    return 1
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
    mkdir -p "$LITEBASH_DIR"
    mkdir -p "$HOME/.config"

    # Update package database
    print_status "Updating package database..."
    $PKG_UPDATE || print_warning "Package database update had issues (continuing anyway)"

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

    # Create Debian symlinks + install all GitHub tools
    create_debian_symlinks
    install_all_tools

    # Copy config files (aliases and TOOLS.md are shared)
    print_status "Installing LiteBash config..."
    local copy_errors=0
    cp "$SCRIPT_DIR/litebash.sh" "$LITEBASH_DIR/" || ((copy_errors++))
    cp "$SCRIPT_DIR/../shared/shell/aliases.sh" "$LITEBASH_DIR/" || ((copy_errors++))
    cp "$SCRIPT_DIR/functions.sh" "$LITEBASH_DIR/" || ((copy_errors++))
    cp "$SCRIPT_DIR/../shared/shell/TOOLS.md" "$LITEBASH_DIR/" || ((copy_errors++))

    if [[ $copy_errors -eq 0 ]]; then
        print_success "LiteBash config installed"
    else
        print_warning "Some config files failed to copy ($copy_errors errors)"
    fi

    # Install starship config (shared location)
    install_starship_config

    # Verify starship config was created
    if [[ ! -L "$HOME/.config/starship.toml" ]] && [[ ! -f "$HOME/.config/starship.toml" ]]; then
        print_warning "Starship config not created - creating manually..."
        ln -sf "$(readlink -f "$SCRIPT_DIR/../shared/prompt/starship.toml")" "$HOME/.config/starship.toml"
    fi

    # Set up .bashrc BEFORE changing shell
    # If .bashrc has conflicting configs (oh-my-bash, bash-it, distro frameworks),
    # back it up and write a clean one. Otherwise just append.
    local needs_clean_bashrc=false
    if [[ -f "$HOME/.bashrc" ]]; then
        if grep -qE '(oh-my-bash|bash-it|OSH_THEME|BASH_IT|cachyos-config|powerline-shell)' "$HOME/.bashrc" 2>/dev/null; then
            needs_clean_bashrc=true
        fi
    fi

    if [[ "$needs_clean_bashrc" == "true" ]]; then
        print_warning "Existing .bashrc has conflicting configs (oh-my-bash/bash-it/distro)"
        print_status "Backing up to ~/.bashrc.pre-litebash"
        cp "$HOME/.bashrc" "$HOME/.bashrc.pre-litebash"

        print_status "Writing clean .bashrc..."
        cat > "$HOME/.bashrc" << 'BASHRC'
export PATH="$HOME/.local/bin:$PATH"

# LiteBash
[ -f ~/.local/share/litebash/litebash.sh ] && source ~/.local/share/litebash/litebash.sh
BASHRC
        print_success "Clean .bashrc created (backup: ~/.bashrc.pre-litebash)"
    elif ! grep -q "litebash/litebash.sh" "$HOME/.bashrc" 2>/dev/null; then
        print_status "Adding LiteBash to ~/.bashrc..."
        echo '' >> "$HOME/.bashrc"
        echo '# LiteBash' >> "$HOME/.bashrc"
        echo '[ -f ~/.local/share/litebash/litebash.sh ] && source ~/.local/share/litebash/litebash.sh' >> "$HOME/.bashrc"
    else
        print_status "LiteBash already in ~/.bashrc"
    fi

    # Set bash as default shell
    set_default_shell

    echo ""
    print_success "Installation complete!"
    echo ""
    echo "Restart your shell or run: source ~/.bashrc"
    echo "Type 'tools' to see the quick reference."
}

main "$@"
