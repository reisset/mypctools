#!/usr/bin/env bash
# LiteZsh Shell Uninstaller
# v1.0.0

set -e

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

# Sudo check
echo "This uninstaller requires sudo privileges to function properly."
echo ""
sudo -v || { print_error "Sudo access required. Aborting."; exit 1; }

# Restore bash as default shell
restore_default_shell() {
    local current_shell=$(basename "$SHELL")

    if [[ "$current_shell" != "zsh" ]]; then
        print_status "Shell is not zsh, skipping shell change"
        return 0
    fi

    local bash_path=$(which bash)
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

# Remove starship config
if [[ -f "$HOME/.config/starship.toml" ]]; then
    print_status "Removing starship config..."
    rm -f "$HOME/.config/starship.toml"
    print_success "Removed starship.toml"
fi

# Ask about removing tools (same as litebash)
echo ""
read -rp "Remove installed CLI tools? [y/N]: " remove_tools
if [[ "$remove_tools" =~ ^[Yy]$ ]]; then
    print_status "Removing GitHub-installed tools from ~/.local/bin..."

    local_tools=(zoxide lazygit tldr glow dysk dust yazi starship)
    for tool in "${local_tools[@]}"; do
        if [[ -f "$LOCAL_BIN/$tool" ]]; then
            rm -f "$LOCAL_BIN/$tool"
            print_status "Removed $tool"
        fi
    done

    # Remove symlinks
    [[ -L "$LOCAL_BIN/bat" ]] && rm -f "$LOCAL_BIN/bat"
    [[ -L "$LOCAL_BIN/fd" ]] && rm -f "$LOCAL_BIN/fd"

    print_success "Removed tools from ~/.local/bin"

    # Package manager instructions (same as litebash)
    if command -v pacman &>/dev/null; then
        print_status "To remove system packages, run:"
        echo "  sudo pacman -Rs eza bat fzf ripgrep fd btop micro github-cli zsh"
    elif command -v apt &>/dev/null; then
        print_status "To remove system packages, run:"
        echo "  sudo apt remove eza bat fzf ripgrep fd-find btop micro gh zsh"
    elif command -v dnf &>/dev/null; then
        print_status "To remove system packages, run:"
        echo "  sudo dnf remove eza bat fzf ripgrep fd-find btop micro gh zsh"
    fi
else
    print_status "Tools left in place."
fi

# Restore bash
restore_default_shell

echo ""
print_success "LiteZsh removed."
echo "Restart your shell or log out/in to complete uninstallation."
