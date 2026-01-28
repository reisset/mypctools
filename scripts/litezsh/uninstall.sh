#!/usr/bin/env bash
# LiteZsh Shell Uninstaller
# v1.1.0 - Uses shared tool installation lib

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LITEZSH_DIR="$HOME/.local/share/litezsh"
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

# Source shared tool lib
source "$SCRIPT_DIR/../../lib/tools-install.sh"

# Sudo check
echo "This uninstaller requires sudo privileges to function properly."
echo ""
sudo -v || { print_error "Sudo access required. Aborting."; exit 1; }

# Restore bash as default shell
restore_default_shell() {
    local current_shell
    current_shell=$(basename "$SHELL")

    if [[ "$current_shell" != "zsh" ]]; then
        print_status "Shell is not zsh, skipping shell change"
        return 0
    fi

    local bash_path
    bash_path=$(which bash)
    print_status "Restoring bash as default shell..."
    chsh -s "$bash_path"
    print_success "Restored bash as default shell (logout/login to apply)"
}

# Remove .zshrc entry
print_status "Removing LiteZsh from ~/.zshrc..."
if [[ -f "$HOME/.zshrc" ]]; then
    sed -i '/# LiteZsh/d' "$HOME/.zshrc"
    sed -i '/litezsh\/litezsh.zsh/d' "$HOME/.zshrc"
    print_success "Removed from ~/.zshrc"
fi

# Remove litezsh directory (includes plugins)
if [[ -d "$LITEZSH_DIR" ]]; then
    print_status "Removing $LITEZSH_DIR..."
    rm -rf "$LITEZSH_DIR"
    print_success "Removed LiteZsh config directory"
fi

# Remove zsh cache
if [[ -d "$HOME/.cache/zsh" ]]; then
    print_status "Removing zsh cache..."
    rm -rf "$HOME/.cache/zsh"
    print_success "Removed zsh cache"
fi

# Remove starship config (only if it points to our shared config)
uninstall_starship_config

# Ask about removing tools
echo ""
read -rp "Remove installed CLI tools? [y/N]: " remove_tools
if [[ "$remove_tools" =~ ^[Yy]$ ]]; then
    uninstall_local_tools
    print_pkg_removal_instructions "zsh"
else
    print_status "Tools left in place."
fi

# Restore bash
restore_default_shell

echo ""
print_success "LiteZsh removed."
echo "Restart your shell or log out/in to complete uninstallation."
