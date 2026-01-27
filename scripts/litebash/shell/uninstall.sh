#!/usr/bin/env bash
# LiteBash Shell Uninstaller
# v1.0.0

set -e

LITEBASH_DIR="$HOME/.local/share/litebash"
LOCAL_BIN="$HOME/.local/bin"

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
echo "This uninstaller requires sudo privileges to function properly."
echo ""
sudo -v || { print_error "Sudo access required. Aborting."; exit 1; }

# Remove bashrc entry
print_status "Removing LiteBash from ~/.bashrc..."
if [ -f "$HOME/.bashrc" ]; then
    # Remove the LiteBash block (comment + source line)
    sed -i '/# LiteBash/d' "$HOME/.bashrc"
    sed -i '/litebash\/litebash.sh/d' "$HOME/.bashrc"
    print_success "Removed from ~/.bashrc"
fi

# Remove litebash directory
if [ -d "$LITEBASH_DIR" ]; then
    print_status "Removing $LITEBASH_DIR..."
    rm -rf "$LITEBASH_DIR"
    print_success "Removed LiteBash config directory"
fi

# Remove starship config
if [ -f "$HOME/.config/starship.toml" ]; then
    print_status "Removing starship config..."
    rm -f "$HOME/.config/starship.toml"
    print_success "Removed starship.toml"
fi

# Ask about removing tools
echo ""
read -rp "Remove installed CLI tools? [y/N]: " remove_tools
if [[ "$remove_tools" =~ ^[Yy]$ ]]; then
    print_status "Removing GitHub-installed tools from ~/.local/bin..."

    # Tools installed to ~/.local/bin
    local_tools=(zoxide lazygit tldr glow dysk yazi starship)
    for tool in "${local_tools[@]}"; do
        if [ -f "$LOCAL_BIN/$tool" ]; then
            rm -f "$LOCAL_BIN/$tool"
            print_status "Removed $tool"
        fi
    done

    # Remove symlinks
    [ -L "$LOCAL_BIN/bat" ] && rm -f "$LOCAL_BIN/bat"
    [ -L "$LOCAL_BIN/fd" ] && rm -f "$LOCAL_BIN/fd"

    print_success "Removed tools from ~/.local/bin"

    # Detect package manager for system packages
    if command -v pacman &>/dev/null; then
        print_status "To remove system packages, run:"
        echo "  sudo pacman -Rs eza bat fzf ripgrep fd btop micro github-cli"
    elif command -v apt &>/dev/null; then
        print_status "To remove system packages, run:"
        echo "  sudo apt remove eza bat fzf ripgrep fd-find btop micro gh"
    elif command -v dnf &>/dev/null; then
        print_status "To remove system packages, run:"
        echo "  sudo dnf remove eza bat fzf ripgrep fd-find btop micro gh"
    fi
else
    print_status "Tools left in place."
fi

echo ""
print_success "Shell config removed."
echo "Restart your shell to complete uninstallation."
