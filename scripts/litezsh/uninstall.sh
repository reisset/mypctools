#!/usr/bin/env bash
# LiteZsh Shell Uninstaller
# v1.2.0 - Removed set -e, fixed shell detection and chsh fallback

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LITEZSH_DIR="$HOME/.local/share/litezsh"
LOCAL_BIN="$HOME/.local/bin"

source "$SCRIPT_DIR/../../lib/print.sh"

# Source shared tool lib
source "$SCRIPT_DIR/../../lib/tools-install.sh"

# Sudo check
echo "This uninstaller requires sudo privileges to function properly."
echo ""
sudo -v || { print_error "Sudo access required. Aborting."; exit 1; }

# Restore bash as default shell
restore_default_shell() {
    # Use getent passwd instead of $SHELL (which can be empty in TUI context)
    local current_shell
    current_shell=$(basename "$(getent passwd "$USER" | cut -d: -f7)")

    if [[ "$current_shell" != "zsh" ]]; then
        print_status "Shell is not zsh, skipping shell change"
        return 0
    fi

    local bash_path
    bash_path=$(which bash)
    print_status "Restoring bash as default shell..."

    # Refresh sudo (may have expired during uninstall)
    sudo -v

    if ! chsh -s "$bash_path" 2>/dev/null; then
        print_warning "chsh failed, trying usermod..."
        if ! sudo usermod -s "$bash_path" "$USER" 2>/dev/null; then
            print_error "Could not change shell. Run manually: chsh -s $bash_path"
            return 1
        fi
    fi

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
