#!/usr/bin/env bash
# Shared functions for terminal emulator installers
# v1.0.0

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

# Safe symlink with validation and backup
safe_symlink() {
    local source="$1"
    local target="$2"
    local name="${3:-$(basename "$target")}"

    local resolved_source
    resolved_source=$(readlink -f "$source" 2>/dev/null)

    if [[ ! -f "$resolved_source" ]]; then
        print_warning "Source file not found: $source"
        return 1
    fi

    if [[ -L "$target" ]]; then
        local current_target
        current_target=$(readlink -f "$target" 2>/dev/null)
        if [[ "$current_target" == "$resolved_source" ]]; then
            print_success "$name already configured"
            return 0
        fi
    fi

    if [[ -e "$target" || -L "$target" ]]; then
        local backup="$target.backup.$(date +%Y%m%d_%H%M%S)"
        mv "$target" "$backup"
        print_status "Backed up existing $name"
    fi

    ln -sf "$resolved_source" "$target" && print_success "Linked $name" || { print_warning "Failed to link $name"; return 1; }
}

# Sudo prompt and keepalive
init_sudo() {
    echo "This installer requires sudo privileges to function properly."
    echo "Read the entire script if you do not trust the author."
    echo ""
    sudo -v || { print_error "Sudo access required. Aborting."; exit 1; }

    while true; do sudo -n true; sleep 60; kill -0 "$$" || exit; done 2>/dev/null &
}

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

# Install Iosevka Nerd Font
install_font() {
    if fc-list | grep -qi "iosevka.*nerd"; then
        print_success "Iosevka Nerd Font already installed"
        return 0
    fi

    print_status "Installing Iosevka Nerd Font..."

    mkdir -p "$FONT_DIR"

    local api_url="https://api.github.com/repos/ryanoasis/nerd-fonts/releases/latest"
    local download_url
    download_url=$(curl -fsSL "$api_url" 2>/dev/null | grep -oP '"browser_download_url":\s*"\K[^"]*IosevkaTerm\.zip[^"]*' | head -1)

    if [ -z "$download_url" ]; then
        print_warning "Could not find IosevkaTerm font download URL"
        print_warning "Please install Iosevka Nerd Font manually"
        return 1
    fi

    local tmp_dir=$(mktemp -d)

    (
        cd "$tmp_dir" || exit 1
        print_status "Downloading font..."
        curl -fsSL -o "IosevkaTerm.zip" "$download_url" || exit 1
        print_status "Extracting font..."
        unzip -q "IosevkaTerm.zip" -d "$FONT_DIR"
    )
    local rc=$?

    rm -rf "$tmp_dir"

    if [[ $rc -ne 0 ]]; then
        print_warning "Failed to download font"
        return 1
    fi

    print_status "Updating font cache..."
    fc-cache -fv >/dev/null 2>&1

    print_success "Installed Iosevka Nerd Font"
}

# Set terminal as default
# Usage: set_default_terminal "terminal_name" "desktop_file_id"
set_default_terminal() {
    local terminal_name="$1"
    local desktop_file="$2"

    local xdg_terminals="$HOME/.config/xdg-terminals.list"
    local backup_file="$HOME/.config/xdg-terminals.list.${terminal_name}-backup"

    echo ""
    read -rp "Set $terminal_name as default terminal? [y/N]: " set_default

    if [[ ! "$set_default" =~ ^[Yy]$ ]]; then
        print_status "Skipping default terminal setup"
        return 0
    fi

    # Detect desktop environment (case-insensitive)
    local desktop="${XDG_CURRENT_DESKTOP:-unknown}"
    local desktop_lower="${desktop,,}"
    print_status "Detected desktop: $desktop"

    # GNOME (Ubuntu) - uses update-alternatives
    if [[ "$desktop_lower" == *"gnome"* ]] && [[ "$desktop_lower" != *"cosmic"* ]]; then
        print_status "GNOME detected - using update-alternatives"
        if command -v update-alternatives &>/dev/null; then
            local terminal_path
            terminal_path=$(command -v "$terminal_name")
            if update-alternatives --list x-terminal-emulator 2>/dev/null | grep -q "$terminal_name"; then
                sudo update-alternatives --set x-terminal-emulator "$terminal_path"
                print_success "Set $terminal_name as default via update-alternatives"
            else
                sudo update-alternatives --install /usr/bin/x-terminal-emulator x-terminal-emulator "$terminal_path" 50
                sudo update-alternatives --set x-terminal-emulator "$terminal_path"
                print_success "Registered and set $terminal_name as default terminal"
            fi
        else
            print_warning "update-alternatives not found - cannot set default on GNOME"
            print_warning "You may need to set $terminal_name as default manually in Settings"
        fi
        return 0
    fi

    # COSMIC - uses custom keybinding
    if [[ "$desktop_lower" == *"cosmic"* ]]; then
        print_status "COSMIC detected - setting up custom keybinding"
        local cosmic_shortcuts_dir="$HOME/.config/cosmic/com.system76.CosmicSettings.Shortcuts/v1"
        mkdir -p "$cosmic_shortcuts_dir"

        cat > "$cosmic_shortcuts_dir/custom" << EOF
{
    (modifiers: [Super], key: "Return"): Spawn("$terminal_name"),
}
EOF
        print_success "Set Super+Enter to launch $terminal_name"
        print_status "Note: Log out and back in for changes to take effect"
        return 0
    fi

    # Hyprland/wlroots/X11 - use xdg-terminal-exec spec
    print_status "Using xdg-terminals.list (xdg-terminal-exec spec)"

    if [ -f "$xdg_terminals" ] && [ ! -f "$backup_file" ]; then
        cp "$xdg_terminals" "$backup_file"
        print_status "Backed up original terminal config"
    fi

    if [ -f "$xdg_terminals" ]; then
        grep -v "^${desktop_file}$" "$xdg_terminals" > "$xdg_terminals.tmp" 2>/dev/null || true
        echo "$desktop_file" > "$xdg_terminals"
        cat "$xdg_terminals.tmp" >> "$xdg_terminals" 2>/dev/null || true
        rm -f "$xdg_terminals.tmp"
    else
        echo "$desktop_file" > "$xdg_terminals"
    fi

    print_success "Set $terminal_name as default terminal"
}
