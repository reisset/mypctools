#!/usr/bin/env bash
# LiteBash Shell Uninstaller
# v1.2.0 - Removed set -e for reliability

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
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

# Source shared tool lib
source "$SCRIPT_DIR/../../lib/tools-install.sh"

# Sudo check
echo "This uninstaller requires sudo privileges to function properly."
echo ""
sudo -v || { print_error "Sudo access required. Aborting."; exit 1; }

# Remove bashrc entry
print_status "Removing LiteBash from ~/.bashrc..."
if [ -f "$HOME/.bashrc" ]; then
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

# Remove starship config (only if it points to our shared config)
uninstall_starship_config

# Ask about removing tools
echo ""
read -rp "Remove installed CLI tools? [y/N]: " remove_tools
if [[ "$remove_tools" =~ ^[Yy]$ ]]; then
    uninstall_local_tools
    print_pkg_removal_instructions
else
    print_status "Tools left in place."
fi

echo ""
print_success "Shell config removed."
echo "Restart your shell to complete uninstallation."
