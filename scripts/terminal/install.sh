#!/usr/bin/env bash
# LiteBash Terminal (foot) Installer
# v1.4.0 - Symlink configs instead of generating; removed Shift+Space binding

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
FONT_DIR="$HOME/.local/share/fonts"

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

# Wayland check
if [ -z "$WAYLAND_DISPLAY" ]; then
    print_error "Wayland not detected. foot is Wayland-only."
    echo "If you're on X11, foot will not work."
    exit 1
fi
print_success "Wayland detected"

# Detect package manager
detect_distro() {
    if command -v pacman &>/dev/null; then
        PKG_MGR="pacman"
        PKG_INSTALL="sudo pacman -S --noconfirm --needed"
    elif command -v apt &>/dev/null; then
        PKG_MGR="apt"
        PKG_INSTALL="sudo apt install -y"
    elif command -v dnf &>/dev/null; then
        PKG_MGR="dnf"
        PKG_INSTALL="sudo dnf install -y"
    else
        print_error "No supported package manager found (pacman/apt/dnf)"
        exit 1
    fi
    print_status "Detected package manager: $PKG_MGR"
}

# Theme selection
select_theme() {
    echo ""
    echo "Select theme:"
    echo "  1) Catppuccin Mocha (default)"
    echo "  2) Tokyo Night"
    echo "  3) HackTheBox"
    echo ""
    read -rp "[1/2/3]: " theme_choice
    case "$theme_choice" in
        2) THEME="tokyo-night" ;;
        3) THEME="hackthebox" ;;
        *) THEME="catppuccin-mocha" ;;
    esac
    print_status "Selected theme: $THEME"
}

# Install foot
install_foot() {
    if command -v foot &>/dev/null; then
        print_success "foot already installed"
        return 0
    fi

    print_status "Installing foot..."
    case "$PKG_MGR" in
        pacman) $PKG_INSTALL foot ;;
        apt) $PKG_INSTALL foot ;;
        dnf) $PKG_INSTALL foot ;;
    esac
    print_success "Installed foot"
}

# Install Iosevka Nerd Font
install_font() {
    # Check if already installed
    if fc-list | grep -qi "iosevka.*nerd"; then
        print_success "Iosevka Nerd Font already installed"
        return 0
    fi

    print_status "Installing Iosevka Nerd Font..."

    mkdir -p "$FONT_DIR"

    # Get latest release URL
    local api_url="https://api.github.com/repos/ryanoasis/nerd-fonts/releases/latest"
    local download_url
    download_url=$(curl -fsSL "$api_url" 2>/dev/null | grep -oP '"browser_download_url":\s*"\K[^"]*IosevkaTerm\.zip[^"]*' | head -1)

    if [ -z "$download_url" ]; then
        print_warning "Could not find IosevkaTerm font download URL"
        print_warning "Please install Iosevka Nerd Font manually"
        return 1
    fi

    local tmp_dir=$(mktemp -d)
    cd "$tmp_dir"

    print_status "Downloading font..."
    if ! curl -fsSL -o "IosevkaTerm.zip" "$download_url"; then
        print_warning "Failed to download font"
        rm -rf "$tmp_dir"
        return 1
    fi

    print_status "Extracting font..."
    unzip -q "IosevkaTerm.zip" -d "$FONT_DIR"

    rm -rf "$tmp_dir"

    print_status "Updating font cache..."
    fc-cache -fv >/dev/null 2>&1

    print_success "Installed Iosevka Nerd Font"
}

# Create foot config (symlink to repo config)
create_config() {
    local config_dir="$HOME/.config/foot"
    mkdir -p "$config_dir"

    print_status "Linking foot config..."

    # Map theme name to config file
    local config_file
    case "$THEME" in
        hackthebox) config_file="foot-hackthebox.ini" ;;
        catppuccin-mocha) config_file="foot-catppuccin-mocha.ini" ;;
        tokyo-night) config_file="foot-tokyo-night.ini" ;;
        *) config_file="foot-hackthebox.ini" ;;
    esac

    # Symlink config (edits to repo file take effect immediately)
    ln -sf "$SCRIPT_DIR/configs/$config_file" "$config_dir/foot.ini"

    print_success "Linked foot.ini -> $config_file"
}

# Set foot as default terminal
set_default_terminal() {
    local xdg_terminals="$HOME/.config/xdg-terminals.list"
    local backup_file="$HOME/.config/xdg-terminals.list.litebash-backup"

    echo ""
    read -rp "Set foot as default terminal? [y/N]: " set_default

    if [[ ! "$set_default" =~ ^[Yy]$ ]]; then
        print_status "Skipping default terminal setup"
        return 0
    fi

    # Detect desktop environment (case-insensitive)
    local desktop="${XDG_CURRENT_DESKTOP:-unknown}"
    local desktop_lower="${desktop,,}"  # lowercase for comparison
    print_status "Detected desktop: $desktop"

    # GNOME (Ubuntu) - uses update-alternatives, no xdg-terminal-exec support
    # Skip if COSMIC is detected (Pop!_OS 24.04+ uses cosmic, not GNOME)
    if [[ "$desktop_lower" == *"gnome"* ]] && [[ "$desktop_lower" != *"cosmic"* ]]; then
        print_status "GNOME detected - using update-alternatives"
        if command -v update-alternatives &>/dev/null; then
            # Check if foot is registered as an alternative
            if update-alternatives --list x-terminal-emulator 2>/dev/null | grep -q foot; then
                sudo update-alternatives --set x-terminal-emulator /usr/bin/foot
                print_success "Set foot as default via update-alternatives"
            else
                # Register foot as an alternative first
                sudo update-alternatives --install /usr/bin/x-terminal-emulator x-terminal-emulator /usr/bin/foot 50
                sudo update-alternatives --set x-terminal-emulator /usr/bin/foot
                print_success "Registered and set foot as default terminal"
            fi
        else
            print_warning "update-alternatives not found - cannot set default on GNOME"
            print_warning "You may need to set foot as default manually in Settings"
        fi
        return 0
    fi

    # COSMIC - uses custom keybinding (xdg-terminals.list doesn't work)
    # COSMIC hardcodes cosmic-term in system_actions, so we create a custom Super+Enter binding
    if [[ "$desktop_lower" == *"cosmic"* ]]; then
        print_status "COSMIC detected - setting up custom keybinding"
        local cosmic_shortcuts_dir="$HOME/.config/cosmic/com.system76.CosmicSettings.Shortcuts/v1"
        mkdir -p "$cosmic_shortcuts_dir"

        # Create custom shortcuts file with Super+Enter -> foot
        cat > "$cosmic_shortcuts_dir/custom" << 'EOF'
{
    (modifiers: [Super], key: "Return"): Spawn("foot"),
}
EOF
        print_success "Set Super+Enter to launch foot"
        print_status "Note: Log out and back in for changes to take effect"
        return 0
    fi

    # Hyprland/wlroots - use xdg-terminal-exec spec
    # This covers: Hyprland, Sway, and other wlroots compositors
    print_status "Using xdg-terminals.list (xdg-terminal-exec spec)"

    # Backup original config (only if we haven't already)
    if [ -f "$xdg_terminals" ] && [ ! -f "$backup_file" ]; then
        cp "$xdg_terminals" "$backup_file"
        print_status "Backed up original terminal config"
    fi

    # Create xdg-terminals.list with foot first
    if [ -f "$xdg_terminals" ]; then
        grep -v "^foot.desktop$" "$xdg_terminals" > "$xdg_terminals.tmp" 2>/dev/null || true
        echo "foot.desktop" > "$xdg_terminals"
        cat "$xdg_terminals.tmp" >> "$xdg_terminals" 2>/dev/null || true
        rm -f "$xdg_terminals.tmp"
    else
        echo "foot.desktop" > "$xdg_terminals"
    fi

    print_success "Set foot as default terminal"
}

# Main
main() {
    detect_distro
    select_theme

    install_foot
    install_font
    create_config
    set_default_terminal

    echo ""
    print_success "Installation complete!"
    echo ""
    echo "Start foot terminal to see the new config."
    echo "You may need to log out and back in for font changes to take effect."
}

main "$@"
