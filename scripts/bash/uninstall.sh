#!/bin/bash

# MyBash V2 Uninstaller
# Safely removes all MyBash configurations and restores original state

set -e

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MANIFEST_FILE="$HOME/.mybash-manifest.txt"

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

log_info() { echo -e "${GREEN}[INFO]${NC} $1"; }
log_warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }

confirm() {
    echo -ne "${YELLOW}[?] $1 (y/N) ${NC}"
    read -r response
    [[ "$response" =~ ^[Yy]$ ]]
}

echo "============================================="
echo "MyBash V2 Uninstaller"
echo "============================================="
echo ""

# Check if manifest exists
if [ ! -f "$MANIFEST_FILE" ]; then
    log_warn "No installation manifest found at $MANIFEST_FILE"
    if ! confirm "Continue with manual uninstall?"; then
        echo "Uninstall cancelled."
        exit 0
    fi
    MANUAL_MODE=true
else
    log_info "Found installation manifest"
    MANUAL_MODE=false
fi

# Step 1: Remove bashrc source line
log_info "Step 1: Cleaning up ~/.bashrc"
if grep -qF "# MyBash Custom Config" "$HOME/.bashrc"; then
    if confirm "Remove MyBash source line from ~/.bashrc?"; then
        # Create backup
        cp "$HOME/.bashrc" "$HOME/.bashrc.mybash-backup-$(date +%Y%m%d-%H%M%S)"
        log_info "Created backup at ~/.bashrc.mybash-backup-*"

        # Remove MyBash section (the comment + source line)
        sed -i '/# MyBash Custom Config/d' "$HOME/.bashrc"
        sed -i "\|source.*bashrc_custom.sh|d" "$HOME/.bashrc"
        log_info "Removed MyBash from ~/.bashrc"
    fi
else
    log_info "No MyBash entries found in ~/.bashrc"
fi

# Step 2: Remove configuration symlinks
log_info "Step 2: Removing configuration symlinks"

if [ -L "$HOME/.config/starship.toml" ]; then
    if confirm "Remove Starship config symlink?"; then
        rm "$HOME/.config/starship.toml"
        log_info "Removed ~/.config/starship.toml"
    fi
fi

if [ -L "$HOME/.config/kitty/kitty.conf" ]; then
    if confirm "Remove Kitty config symlink?"; then
        rm "$HOME/.config/kitty/kitty.conf"
        log_info "Removed ~/.config/kitty/kitty.conf"
    fi
fi

# Step 3: Remove git delta configuration
if git config --global --get include.path 2>/dev/null | grep -q "delta.gitconfig"; then
    if confirm "Remove git delta configuration?"; then
        git config --global --unset include.path
        log_info "Removed git delta config"
    fi
fi

# Step 4: Restore default terminal (before removing Kitty)
log_info "Step 4: Checking default terminal configuration"
TERMINAL_RESTORED=false

# Check if Kitty is set as default via update-alternatives
if update-alternatives --query x-terminal-emulator 2>/dev/null | grep -qi "kitty"; then
    if confirm "Kitty is set as default terminal. Restore gnome-terminal as default?"; then
        if command -v gnome-terminal &> /dev/null; then
            sudo update-alternatives --set x-terminal-emulator /usr/bin/gnome-terminal.wrapper 2>/dev/null || \
            sudo update-alternatives --set x-terminal-emulator /usr/bin/gnome-terminal 2>/dev/null || \
            log_warn "Could not restore gnome-terminal via update-alternatives"
            TERMINAL_RESTORED=true
            log_info "Restored gnome-terminal as default terminal (update-alternatives)"
        else
            log_warn "gnome-terminal not found - you may need to manually set a default terminal"
        fi
    fi
fi

# Check if Kitty is set as default via GNOME settings
if command -v gsettings &> /dev/null; then
    current_term=$(gsettings get org.gnome.desktop.default-applications.terminal exec 2>/dev/null || echo "")
    if [[ "$current_term" == *"kitty"* ]]; then
        if [ "$TERMINAL_RESTORED" = true ] || confirm "Kitty is set in GNOME settings. Restore gnome-terminal?"; then
            if command -v gnome-terminal &> /dev/null; then
                gsettings set org.gnome.desktop.default-applications.terminal exec 'gnome-terminal'
                log_info "Restored gnome-terminal in GNOME settings"
            fi
        fi
    fi
fi

# Check if Kitty is set in COSMIC
cosmic_shortcuts_dir="$HOME/.config/cosmic/com.system76.CosmicSettings.Shortcuts/v1"
if [ -f "$cosmic_shortcuts_dir/system_actions" ]; then
    if grep -qi "kitty" "$cosmic_shortcuts_dir/system_actions" 2>/dev/null; then
        if confirm "Kitty is set in COSMIC settings. Restore defaults?"; then
            rm -f "$cosmic_shortcuts_dir/system_actions"
            rm -f "$cosmic_shortcuts_dir/custom"
            log_info "Removed COSMIC customizations (Super+T restored, Super+Enter cleared)"
        fi
    fi
fi

# Step 5: Ask about installed binaries
log_info "Step 5: Installed binaries in ~/.local/bin"
echo ""
log_warn "The following MyBash-installed tools were found:"
echo ""

BINARIES_TO_REMOVE=()
if [ "$MANUAL_MODE" = true ]; then
    # Manual detection
    for binary in eza bat rg fzf zoxide yazi starship btop dust fd delta \
                  lazygit procs glow tldr micro mybash; do
        if [ -x "$HOME/.local/bin/$binary" ]; then
            echo "  - $binary"
            BINARIES_TO_REMOVE+=("$HOME/.local/bin/$binary")
        fi
    done
else
    # Read from manifest
    while IFS= read -r line; do
        if [[ $line == binary:* ]]; then
            binary_path="${line#binary:}"
            if [ -f "$binary_path" ]; then
                echo "  - $(basename "$binary_path")"
                BINARIES_TO_REMOVE+=("$binary_path")
            fi
        fi
    done < "$MANIFEST_FILE"
fi

echo ""
if [ ${#BINARIES_TO_REMOVE[@]} -gt 0 ]; then
    if confirm "Remove all MyBash-installed binaries? (You can reinstall via apt/cargo if needed)"; then
        for binary_path in "${BINARIES_TO_REMOVE[@]}"; do
            rm -f "$binary_path"
            log_info "Removed $binary_path"
        done
    else
        log_info "Keeping installed binaries"
    fi
else
    log_info "No binaries found to remove"
fi

# Step 6: Remove manifest
if [ -f "$MANIFEST_FILE" ]; then
    rm "$MANIFEST_FILE"
    log_info "Removed installation manifest"
fi

# Step 7: Remove copied TOOLS.md
if [ -f "$HOME/.local/share/mybash/TOOLS.md" ]; then
    rm -rf "$HOME/.local/share/mybash"
    log_info "Removed ~/.local/share/mybash/"
fi

echo ""
echo "============================================="
log_info "MyBash uninstall complete!"
echo "============================================="
echo ""
log_info "Your original .bashrc has been restored (backup saved)"
log_info "Please restart your terminal or run: source ~/.bashrc"
echo ""
log_warn "Note: APT-installed packages (if any) were not removed."
log_warn "To remove them manually, run:"
echo "  sudo apt remove eza bat ripgrep fzf btop fd-find"
echo ""

# Clean up current shell environment to prevent starship errors
# (The current shell still has starship in PROMPT_COMMAND but the binary was deleted)
if [[ -n "$PROMPT_COMMAND" ]]; then
    unset PROMPT_COMMAND
fi
# Reset to a basic prompt
export PS1='\u@\h:\w\$ '

log_info "Shell prompt reset for this session."
