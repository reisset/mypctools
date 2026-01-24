#!/bin/bash

# MyBash V2 Installer
# Sets up Kitty, Starship, Yazi, and modern CLI tools.
#
# Version: 2.8.8
# Changelog:
#   2.8.8 - Fix lazygit GitHub release pattern (x86_64 not amd64)
#   2.8.7 - Remove gping (release pattern incompatibility)
#   2.8.6 - Add COSMIC desktop support (Pop!_OS 24.04)
#   2.8.5 - Fix missing CYAN color, add GNOME Ctrl+Alt+T shortcut support
#   2.8.4 - Fix CachyOS detection and glow GitHub fallback architecture
#   2.8.3 - Fix KDE Ctrl+Alt+T: override konsole.desktop to stop it stealing shortcut
#   2.8.2 - Fix KDE shortcut: write to [services][kitty.desktop] not [kitty.desktop]
#   2.8.1 - Fix gh install (x86_64→amd64) and KDE Ctrl+Alt+T shortcut registration
#   2.8.0 - Add GitHub CLI (gh), improve KDE Plasma support
#   2.7.2 - Add KDE Plasma support for setting Kitty as default terminal
#   2.7.1 - Time display and cleaner UI
#   2.7.0 - Starship enhancements and cleaner welcome
#   2.6.0 - Kitty kittens integration and clean ASCII art

set -e

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIGS_DIR="$REPO_DIR/configs"
SCRIPTS_DIR="$REPO_DIR/scripts"
BIN_DIR="$REPO_DIR/bin"
LOCAL_BIN="$HOME/.local/bin"
mkdir -p "$LOCAL_BIN"

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# State
SERVER_MODE=false
USE_SUDO=false
ARCH=$(uname -m)

# Distro Detection
detect_distro() {
    if [[ -f /etc/os-release ]]; then
        . /etc/os-release
        if [[ "$ID" == "arch" || "$ID" == "cachyos" || "$ID_LIKE" == *"arch"* ]]; then
            echo "arch"
        elif [[ "$ID" == "debian" || "$ID" == "ubuntu" || "$ID_LIKE" == *"debian"* || "$ID_LIKE" == *"ubuntu"* ]]; then
            echo "debian"
        else
            echo "unknown"
        fi
    else
        echo "unknown"
    fi
}
DISTRO=$(detect_distro)

# Package Manager Abstraction
pkg_update() {
    case "$DISTRO" in
        arch) sudo pacman -Sy ;;
        debian) sudo apt update ;;
    esac
}

pkg_install() {
    case "$DISTRO" in
        arch) sudo pacman -S --noconfirm --needed "$@" ;;
        debian) sudo apt install -y "$@" ;;
    esac
}

# Helper Functions
log_info() { echo -e "${GREEN}[INFO]${NC} $1"; }
log_warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }

confirm() {
    echo -ne "${YELLOW}[?] $1 (Y/n) ${NC}"
    read -r response
    [[ "$response" =~ ^[Nn]$ ]] && return 1
    return 0
}

confirm_no() {
    echo -ne "${YELLOW}[?] $1 (y/N) ${NC}"
    read -r response
    [[ "$response" =~ ^[Yy]$ ]]
}

# Print a boxed header message
print_header() {
    local msg="$1"
    local color="${2:-$CYAN}"
    local width=65
    local pad=$(( (width - ${#msg}) / 2 ))
    echo ""
    echo -e "${color}╔$(printf '═%.0s' $(seq 1 $width))╗${NC}"
    echo -e "${color}║$(printf ' %.0s' $(seq 1 $pad))${msg}$(printf ' %.0s' $(seq 1 $((width - pad - ${#msg}))))║${NC}"
    echo -e "${color}╚$(printf '═%.0s' $(seq 1 $width))╝${NC}"
    echo ""
}

print_success_box() {
    local msg="$1"
    print_header "$msg" "$GREEN"
}

get_github_arch() {
    case "$ARCH" in
        aarch64) echo "arm64" ;;
        x86_64)  echo "amd64" ;;
        *)       echo "$ARCH" ;;
    esac
}

# Parse arguments
for arg in "$@"; do
    case $arg in
        --server)
            SERVER_MODE=true
            shift
            ;;
    esac
done

print_header "MyBash V2 Installer" "$CYAN"

log_info "Initializing installation..."
if $SERVER_MODE; then
    log_info "Mode: Server/Headless (Skipping desktop tools)"
else
    log_info "Mode: Full Desktop"
fi

if [[ "$ARCH" == "x86_64" ]]; then
    log_info "Detected Architecture: x86_64"
elif [[ "$ARCH" == "aarch64" ]]; then
    log_info "Detected Architecture: ARM64"
else
    log_warn "Architecture $ARCH might require manual steps for some tools."
fi

# Log detected distro
case "$DISTRO" in
    arch)
        log_info "Detected Distribution: Arch-based (pacman)"
        ;;
    debian)
        log_info "Detected Distribution: Debian/Ubuntu (apt)"
        ;;
    *)
        log_warn "Unrecognized distribution. Will use GitHub-only installations."
        log_warn "System packages will be skipped."
        ;;
esac

# Check Sudo
if confirm "Do you want to use sudo for system-wide installs (recommended)?"; then
    if sudo -v; then
        USE_SUDO=true
        log_info "Sudo privileges confirmed."
    else
        log_warn "Sudo failed. Falling back to local installation where possible."
    fi
fi

# Deps
if ! command -v curl &> /dev/null || ! command -v unzip &> /dev/null || ! command -v bzip2 &> /dev/null; then
    if $USE_SUDO && [[ "$DISTRO" != "unknown" ]]; then
        pkg_update
        case "$DISTRO" in
            arch) pkg_install curl unzip fontconfig git bzip2 tar wget base-devel ;;
            debian) pkg_install curl unzip fontconfig git bzip2 tar wget ;;
        esac
    else
        log_warn "Ensure 'curl', 'unzip', 'git', 'fontconfig', 'bzip2', 'tar', and 'wget' are installed."
    fi
fi

# Helper for GitHub Releases
install_from_github() {
    local repo=$1
    local binary_name=$2
    local match_pattern=$3

    log_info "Installing $binary_name from GitHub ($repo)..."

    local latest_url
    latest_url=$(curl -s "https://api.github.com/repos/$repo/releases/latest" | \
        grep "browser_download_url" | \
        grep -E "$match_pattern" | \
        cut -d '"' -f 4 | head -n 1)

    if [ -z "$latest_url" ]; then
        log_error "Could not find release for $binary_name."
        return 1
    fi

    # Security: Validate URL is from GitHub and uses HTTPS
    if [[ ! "$latest_url" =~ ^https://github\.com/ ]]; then
        log_error "Security: Invalid or non-GitHub URL detected: $latest_url"
        return 1
    fi

    log_info "Downloading $latest_url..."
    # MODIFIED: Add retry logic with --retry and --retry-delay
    if ! curl -fL \
         --retry 5 \
         --retry-delay 3 \
         --retry-all-errors \
         --connect-timeout 10 \
         -o "/tmp/$binary_name.archive" \
         "$latest_url"; then
        log_error "Failed to download $binary_name after 5 retries"
        return 1
    fi

    # Use dedicated extraction directory for clean cleanup
    local extract_dir="/tmp/$binary_name-extracted"
    mkdir -p "$extract_dir"

    if [[ "$latest_url" == *.tar.gz ]]; then
        tar -xzf "/tmp/$binary_name.archive" -C "$extract_dir"
    elif [[ "$latest_url" == *.tar.bz2 || "$latest_url" == *.tbz ]]; then
        tar -xjf "/tmp/$binary_name.archive" -C "$extract_dir"
    elif [[ "$latest_url" == *.tar.xz ]]; then
        tar -xJf "/tmp/$binary_name.archive" -C "$extract_dir"
    elif [[ "$latest_url" == *.zip ]]; then
        unzip -o "/tmp/$binary_name.archive" -d "$extract_dir"
    else
        # Assume it's a single binary
        mv "/tmp/$binary_name.archive" "$extract_dir/$binary_name"
        chmod +x "$extract_dir/$binary_name"
    fi

    # Find binary in extraction directory
    local bin_path
    bin_path=$(find "$extract_dir" -type f -name "$binary_name" | head -n 1)

    # If not found exactly, try finding something that starts with the name
    if [ -z "$bin_path" ]; then
        bin_path=$(find "$extract_dir" -type f -name "$binary_name*" | head -n 1)
    fi

    if [ -n "$bin_path" ]; then
        chmod +x "$bin_path"
        mv "$bin_path" "$LOCAL_BIN/"
        log_info "Installed $binary_name to $LOCAL_BIN"
    else
        log_error "Binary $binary_name not found after extraction."
    fi

    rm -rf "/tmp/$binary_name.archive" "$extract_dir"
}

# --------------------------------------------------------------------------
# 1.5 Fonts (Desktop only - servers don't render fonts, the SSH client does)
# --------------------------------------------------------------------------

if ! $SERVER_MODE; then
    if ! fc-list : family | grep -qi "JetBrainsMono Nerd Font"; then
        if confirm "Install JetBrainsMono Nerd Font (Recommended for icons)?"; then
            log_info "Downloading JetBrainsMono Nerd Font..."
            mkdir -p "$HOME/.local/share/fonts"

            FONT_ZIP="/tmp/JetBrainsMono.zip"
            # Using v3.2.1 (Latest stable at time of writing)
            if curl -fL \
                --retry 5 \
                --retry-delay 3 \
                --connect-timeout 10 \
                -o "$FONT_ZIP" \
                "https://github.com/ryanoasis/nerd-fonts/releases/download/v3.2.1/JetBrainsMono.zip"; then

                unzip -o -q "$FONT_ZIP" -d "$HOME/.local/share/fonts"
                rm -f "$FONT_ZIP"

                log_info "Rebuilding font cache (this may take a moment)..."
                fc-cache -f "$HOME/.local/share/fonts"
                log_info "JetBrainsMono Nerd Font installed."
            else
                log_error "Failed to download font."
            fi
        fi
    else
        log_info "JetBrainsMono Nerd Font is already installed."
    fi
fi

# --------------------------------------------------------------------------
# 2. Tools
# --------------------------------------------------------------------------

# Kitty (Optional)
if ! $SERVER_MODE; then
    if ! command -v kitty &> /dev/null; then
        if confirm "Install Kitty Terminal (GPU-accelerated, fast)?"; then
            log_info "Installing Kitty from official script..."
            
            # Download installer to temp file (Security: No pipe to shell)
            kitty_installer="/tmp/kitty_installer.sh"
            if curl -L \
                 --retry 5 \
                 --retry-delay 3 \
                 --retry-all-errors \
                 --connect-timeout 10 \
                 "https://sw.kovidgoyal.net/kitty/installer.sh" \
                 -o "$kitty_installer"; then
                chmod +x "$kitty_installer"
                
                # Run installer with launch=n to prevent auto-start
                "$kitty_installer" launch=n
                
                # Symlink kitty and kitten to local bin
                ln -sf ~/.local/kitty.app/bin/kitty "$LOCAL_BIN/kitty"
                ln -sf ~/.local/kitty.app/bin/kitten "$LOCAL_BIN/kitten"
                
                # Desktop Integration
                cp ~/.local/kitty.app/share/applications/kitty.desktop ~/.local/share/applications/
                # Fix icon path in desktop file
                sed -i "s|Icon=kitty|Icon=$(readlink -f ~)/.local/kitty.app/share/icons/hicolor/256x256/apps/kitty.png|g" ~/.local/share/applications/kitty.desktop
                # Ensure Exec path is correct
                sed -i "s|Exec=kitty|Exec=$(readlink -f ~)/.local/bin/kitty|g" ~/.local/share/applications/kitty.desktop

                log_info "Kitty installed successfully."
                rm -f "$kitty_installer"
            else
                log_error "Failed to download Kitty installer."
            fi
        fi
    else
        log_info "Kitty is already installed."
    fi

    # Set Kitty as Default Terminal
    # Check both PATH and local bin location
    kitty_path=""
    if command -v kitty &> /dev/null; then
        kitty_path="$(command -v kitty)"
    elif [ -x "$LOCAL_BIN/kitty" ]; then
        kitty_path="$LOCAL_BIN/kitty"
    fi

    if [ -n "$kitty_path" ]; then
        # For system-wide installations, use update-alternatives
        if [[ "$kitty_path" == /usr/* ]] && $USE_SUDO; then
            if confirm_no "Set Kitty as default terminal (update-alternatives)?"; then
                if ! sudo update-alternatives --list x-terminal-emulator 2>/dev/null | grep -q "kitty"; then
                    sudo update-alternatives --install /usr/bin/x-terminal-emulator x-terminal-emulator "$kitty_path" 50
                fi
                sudo update-alternatives --set x-terminal-emulator "$kitty_path"
                log_info "Kitty set as default via update-alternatives."
            fi
        fi

        # GNOME: Set via gsettings and configure Ctrl+Alt+T shortcut
        if command -v gsettings &> /dev/null && [[ "$XDG_CURRENT_DESKTOP" == *"GNOME"* ]]; then
            if confirm_no "Set Kitty as default terminal (GNOME)?"; then
                gsettings set org.gnome.desktop.default-applications.terminal exec "$kitty_path"
                # Clear exec-arg to avoid issues with some shortcuts expecting specific args
                gsettings set org.gnome.desktop.default-applications.terminal exec-arg ''

                # Disable built-in terminal shortcut
                gsettings set org.gnome.settings-daemon.plugins.media-keys terminal "[]" 2>/dev/null || true

                # Get existing custom keybindings and append kitty
                existing=$(gsettings get org.gnome.settings-daemon.plugins.media-keys custom-keybindings 2>/dev/null || echo "@as []")
                if [[ "$existing" == "@as []" ]]; then
                    gsettings set org.gnome.settings-daemon.plugins.media-keys custom-keybindings "['/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/kitty/']"
                elif [[ "$existing" != *"kitty"* ]]; then
                    new_bindings="${existing%]}, '/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/kitty/']"
                    gsettings set org.gnome.settings-daemon.plugins.media-keys custom-keybindings "$new_bindings"
                fi

                # Configure the kitty shortcut
                gsettings set org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/kitty/ name "Kitty Terminal"
                gsettings set org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/kitty/ command "gtk-launch kitty"
                gsettings set org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/kitty/ binding "<Control><Alt>t"

                log_info "Kitty set as default via GNOME settings."
                log_info "Ctrl+Alt+T shortcut configured for Kitty."
            fi
        fi

        # KDE Plasma: Set default terminal and Ctrl+Alt+T shortcut
        if [[ "$XDG_CURRENT_DESKTOP" == *"KDE"* ]]; then
            if confirm_no "Set Kitty as default terminal (KDE Plasma)?"; then
                kwrite_cmd=""
                if command -v kwriteconfig6 &> /dev/null; then
                    kwrite_cmd="kwriteconfig6"
                elif command -v kwriteconfig5 &> /dev/null; then
                    kwrite_cmd="kwriteconfig5"
                fi

                if [[ -n "$kwrite_cmd" ]]; then
                    # Set default terminal application
                    $kwrite_cmd --file kdeglobals --group General --key TerminalApplication kitty
                    $kwrite_cmd --file kdeglobals --group General --key TerminalService kitty.desktop

                    # Create kglobalaccel desktop file for Ctrl+Alt+T shortcut
                    mkdir -p ~/.local/share/kglobalaccel
                    cat > ~/.local/share/kglobalaccel/kitty.desktop << 'DESKTOP'
[Desktop Entry]
Type=Application
Name=kitty
Exec=kitty
Icon=kitty
X-KDE-Shortcuts=Ctrl+Alt+T
DESKTOP
                    # Set correct Exec path
                    sed -i "s|Exec=kitty|Exec=$kitty_path|g" ~/.local/share/kglobalaccel/kitty.desktop

                    # Create local override of konsole.desktop to remove its Ctrl+Alt+T shortcut
                    # This prevents konsole from re-claiming the shortcut on login
                    cat > ~/.local/share/applications/org.kde.konsole.desktop << 'KONSOLE'
[Desktop Entry]
Type=Application
Name=Konsole
Exec=konsole
Icon=utilities-terminal
X-KDE-Shortcuts=
KONSOLE

                    # Disable Konsole's Ctrl+Alt+T shortcut in kglobalshortcutsrc
                    $kwrite_cmd --file kglobalshortcutsrc --group "services" --group "org.kde.konsole.desktop" --key "_launch" "none,none,Konsole"

                    # Register Kitty's Ctrl+Alt+T shortcut
                    $kwrite_cmd --file kglobalshortcutsrc --group "services" --group "kitty.desktop" --key "_launch" "Ctrl+Alt+T,Ctrl+Alt+T,Kitty"

                    # Rebuild KDE caches to pick up changes
                    update-desktop-database ~/.local/share/applications 2>/dev/null || true
                    kbuildsycoca6 2>/dev/null || kbuildsycoca5 2>/dev/null || true

                    log_info "Kitty set as default terminal for KDE Plasma."
                    log_info "Log out and back in for Ctrl+Alt+T shortcut to take effect."
                fi
            fi
        fi

        # COSMIC Desktop: Set Kitty as default terminal with Super+Enter
        if [[ "${XDG_CURRENT_DESKTOP,,}" == *"cosmic"* ]]; then
            if confirm_no "Set Kitty as default terminal (COSMIC)?"; then
                cosmic_shortcuts_dir="$HOME/.config/cosmic/com.system76.CosmicSettings.Shortcuts/v1"
                mkdir -p "$cosmic_shortcuts_dir"

                # Set Kitty as the terminal application
                cat > "$cosmic_shortcuts_dir/system_actions" << EOF
{
    Terminal: "$kitty_path",
}
EOF

                # Remap: Super+Enter = Terminal, Super+T = disabled
                cat > "$cosmic_shortcuts_dir/custom" << 'EOF'
{
    (modifiers: [Super], key: "Return"): System(Terminal),
    (modifiers: [Super], key: "t"): Disable,
}
EOF

                log_info "Kitty set as default terminal for COSMIC."
                log_info "Super+Enter launches Kitty. Super+T disabled."
            fi
        fi
    fi
fi

# Starship
if ! command -v starship &> /dev/null; then
    if confirm "Install Starship?"; then
        log_info "Downloading Starship installer..."
        starship_installer="/tmp/starship_install.sh"

        # Download the installer script
        if ! curl -sS \
             --retry 5 \
             --retry-delay 3 \
             --retry-all-errors \
             --connect-timeout 10 \
             https://starship.rs/install.sh \
             -o "$starship_installer"; then
            log_error "Failed to download Starship installer"
        else
            # Make it executable and run it
            chmod +x "$starship_installer"
            "$starship_installer" -y $(! $USE_SUDO && echo "-b $LOCAL_BIN")
            rm -f "$starship_installer"
        fi
    fi
fi

# Yazi
if ! command -v yazi &> /dev/null; then
    if confirm "Install Yazi?"; then
        if $USE_SUDO && [[ "$DISTRO" == "arch" ]]; then
            pkg_install yazi
        else
            # yazi-x86_64-unknown-linux-gnu.zip
            install_from_github "sxyazi/yazi" "yazi" "$ARCH.*linux-gnu.zip"
        fi
    fi
fi

# Eza, Rg, Bat, FZF
if $USE_SUDO && [[ "$DISTRO" != "unknown" ]]; then
    case "$DISTRO" in
        arch)
            # Arch: All these tools are in official repos
            pkg_install eza ripgrep bat fzf
            ;;
        debian)
            # Eza (needs repo setup on Debian)
            if ! command -v eza &> /dev/null; then
                log_info "Installing Eza setup..."
                sudo mkdir -p /etc/apt/keyrings

                # Download GPG key to temporary location first
                eza_gpg_tmp="/tmp/eza_gierens.asc"
                if ! wget --tries=5 \
                          --waitretry=3 \
                          --timeout=10 \
                          -qO "$eza_gpg_tmp" \
                          https://raw.githubusercontent.com/eza-community/eza/main/deb.asc; then
                    log_error "Failed to download eza GPG key after retries"
                else
                    # Import and verify the key
                    sudo gpg --dearmor -o /etc/apt/keyrings/gierens.gpg --yes < "$eza_gpg_tmp"
                    rm -f "$eza_gpg_tmp"

                    echo "deb [signed-by=/etc/apt/keyrings/gierens.gpg] http://deb.gierens.de stable main" | sudo tee /etc/apt/sources.list.d/gierens.list
                    sudo chmod 644 /etc/apt/keyrings/gierens.gpg /etc/apt/sources.list.d/gierens.list
                    sudo apt update
                    sudo apt install -y eza
                fi
            fi

            # Common tools
            sudo apt install -y ripgrep bat fzf

            # Symlink batcat to bat if needed (Debian uses batcat due to name conflict)
            if command -v batcat &> /dev/null && ! command -v bat &> /dev/null; then
                mkdir -p "$LOCAL_BIN"
                ln -sf /usr/bin/batcat "$LOCAL_BIN/bat"
            fi
            ;;
    esac
else
    # Local fallbacks (GitHub binaries)
    [ ! -x "$LOCAL_BIN/eza" ] && install_from_github "eza-community/eza" "eza" "$ARCH.*linux-gnu.tar.gz"
    [ ! -x "$LOCAL_BIN/rg" ] && install_from_github "BurntSushi/ripgrep" "rg" "linux-musl.tar.gz"
    [ ! -x "$LOCAL_BIN/bat" ] && install_from_github "sharkdp/bat" "bat" "$ARCH.*linux-musl.tar.gz"

    if [ ! -x "$LOCAL_BIN/fzf" ]; then
        log_info "Installing FZF locally..."
        git clone --depth 1 https://github.com/junegunn/fzf.git ~/.fzf
        ~/.fzf/install --bin
        ln -sf ~/.fzf/bin/fzf "$LOCAL_BIN/fzf"
    fi
fi

# --------------------------------------------------------------------------
# 2.5 Modern CLI Tools (Learning-First)
# --------------------------------------------------------------------------

log_info "Installing Modern CLI Tools (Learning-First)..."

if $USE_SUDO && [[ "$DISTRO" != "unknown" ]]; then
    case "$DISTRO" in
        arch)
            # Arch: Most tools are in official repos
            # Skip tealdeer if any tldr implementation is already installed (avoids conflict)
            arch_packages="btop fd micro zoxide glow dust git-delta procs"
            if ! command -v tldr &> /dev/null; then
                arch_packages="tealdeer $arch_packages"
            fi
            pkg_install $arch_packages
            if ! $SERVER_MODE; then
                pkg_install lazygit github-cli
            fi
            ;;
        debian)
            # APT Installations (where available)
            # Note: git-delta not included - uses GitHub fallback for broader compatibility
            # Skip tealdeer if any tldr implementation is already installed (avoids conflict)
            deb_packages="btop fd-find micro"
            if ! command -v tldr &> /dev/null; then
                deb_packages="tealdeer $deb_packages"
            fi
            sudo apt install -y $deb_packages

            # Symlink fd if installed via apt (Debian uses fdfind)
            if command -v fdfind &> /dev/null; then
                ln -sf "$(which fdfind)" "$LOCAL_BIN/fd"
            fi
            ;;
    esac

    # GPU Monitor (NVTOP) - both distros have this
    if ! $SERVER_MODE; then
        if lspci 2>/dev/null | grep -iE 'vga|3d|display' | grep -qvE 'intel.*integrated'; then
            if confirm "Discrete GPU detected. Install nvtop?"; then
                pkg_install nvtop
            fi
        fi
    fi
fi

# GitHub fallbacks for tools not installed via package manager
# Zoxide
if ! command -v zoxide &> /dev/null; then
    install_from_github "ajeetdsouza/zoxide" "zoxide" "$ARCH.*linux-musl.tar.gz"
fi

# Glow (uses x86_64/arm64 naming, not amd64)
if ! command -v glow &> /dev/null; then
    glow_arch=$(case "$ARCH" in x86_64) echo "x86_64" ;; aarch64) echo "arm64" ;; *) echo "$ARCH" ;; esac)
    install_from_github "charmbracelet/glow" "glow" "Linux_${glow_arch}\.tar\.gz"
fi

# Btop
if ! command -v btop &> /dev/null; then
    install_from_github "aristocratos/btop" "btop" "$ARCH.*linux-musl.tbz"
fi

# Tealdeer (tldr)
if ! command -v tldr &> /dev/null; then
    install_from_github "dbrgn/tealdeer" "tldr" "tealdeer-linux-$(get_github_arch)-musl"
fi

# Dust
if ! command -v dust &> /dev/null; then
    install_from_github "bootandy/dust" "dust" "$ARCH.*linux-musl.tar.gz"
fi

# FD (Fallback)
if ! command -v fd &> /dev/null && ! command -v fdfind &> /dev/null; then
    install_from_github "sharkdp/fd" "fd" "$ARCH.*linux-musl.tar.gz"
fi

# Delta (Fallback)
if ! command -v delta &> /dev/null; then
    install_from_github "dandavison/delta" "delta" "$ARCH.*linux-gnu.tar.gz"
fi

# Micro Editor
if ! command -v micro &> /dev/null; then
    install_from_github "zyedidia/micro" "micro" "linux$(get_github_arch).tar.gz"
fi

# Lazygit
if ! $SERVER_MODE; then
    if ! command -v lazygit &> /dev/null; then
        install_from_github "jesseduffield/lazygit" "lazygit" "lazygit_.*_linux_$ARCH\.tar\.gz"
    fi
fi

# Procs
if ! command -v procs &> /dev/null; then
    install_from_github "dalance/procs" "procs" "$ARCH-linux.zip"
fi

# GitHub CLI (gh) - Desktop only
if ! $SERVER_MODE; then
    if ! command -v gh &> /dev/null; then
        install_from_github "cli/cli" "gh" "gh_.*_linux_$(get_github_arch)\.tar\.gz"
    fi
fi

# Copy documentation and scripts to local share for aliases
mkdir -p "$HOME/.local/share/mybash"
cp "$REPO_DIR/docs/TOOLS.md" "$HOME/.local/share/mybash/TOOLS.md"
cp "$REPO_DIR/asciiart.txt" "$HOME/.local/share/mybash/asciiart.txt"
cp -r "$REPO_DIR/scripts" "$HOME/.local/share/mybash/"
cp -r "$REPO_DIR/bin" "$HOME/.local/share/mybash/"

# Install mybash CLI to PATH
cp "$BIN_DIR/mybash" "$LOCAL_BIN/mybash"
chmod +x "$LOCAL_BIN/mybash"
log_info "Installed mybash CLI (run 'mybash -h' for help)"

# Git Delta Configuration
if command -v delta &> /dev/null; then
    if confirm "Configure git to use delta for diffs?"; then
        git config --global include.path "$CONFIGS_DIR/delta.gitconfig"
        log_info "Delta git configuration enabled."
    fi
fi

# --------------------------------------------------------------------------
# 3. Configuration
# --------------------------------------------------------------------------

log_info "Linking Configurations..."

if [ -d "$HOME/.config" ]; then
    # Kitty Config
    # Check if kitty is installed (path or local bin)
    if ! $SERVER_MODE && { command -v kitty &> /dev/null || [ -x "$LOCAL_BIN/kitty" ]; }; then
        mkdir -p "$HOME/.config/kitty"
        ln -sf "$CONFIGS_DIR/kitty.conf" "$HOME/.config/kitty/kitty.conf"
        log_info "Linked Kitty config."
    fi

    # Always link Starship
    ln -sf "$CONFIGS_DIR/starship_text.toml" "$HOME/.config/starship.toml"
    log_info "Linked Starship config."
fi

# Bashrc Hook
SOURCE_LINE="source $SCRIPTS_DIR/bashrc_custom.sh"
if ! grep -qF "$SOURCE_LINE" "$HOME/.bashrc"; then
    echo "" >> "$HOME/.bashrc"
    echo "# MyBash Custom Config" >> "$HOME/.bashrc"
    echo "$SOURCE_LINE" >> "$HOME/.bashrc"
    log_info "Added source line to ~/.bashrc"
else
    log_info "bashrc already contains the source line."
fi

# --------------------------------------------------------------------------
# 4. Generate Install Manifest
# --------------------------------------------------------------------------

log_info "Generating installation manifest..."

MANIFEST_FILE="$HOME/.mybash-manifest.txt"
rm -f "$MANIFEST_FILE"  # Clear old manifest if exists

# Record timestamp
echo "# MyBash Installation Manifest" >> "$MANIFEST_FILE"
echo "# Generated: $(date)" >> "$MANIFEST_FILE"
echo "# Installation Mode: $(if $SERVER_MODE; then echo 'server'; else echo 'desktop'; fi)" >> "$MANIFEST_FILE"
echo "" >> "$MANIFEST_FILE"

# Track symlinked configs
echo "# Configuration Symlinks" >> "$MANIFEST_FILE"
if [ -L "$HOME/.config/starship.toml" ]; then
    echo "symlink:$HOME/.config/starship.toml" >> "$MANIFEST_FILE"
fi
if [ -L "$HOME/.config/kitty/kitty.conf" ]; then
    echo "symlink:$HOME/.config/kitty/kitty.conf" >> "$MANIFEST_FILE"
fi

# Track bashrc modification
if grep -qF "source $SCRIPTS_DIR/bashrc_custom.sh" "$HOME/.bashrc"; then
    echo "bashrc_line:source $SCRIPTS_DIR/bashrc_custom.sh" >> "$MANIFEST_FILE"
fi

# Track installed binaries in ~/.local/bin
echo "" >> "$MANIFEST_FILE"
echo "# Installed Binaries" >> "$MANIFEST_FILE"
for binary in eza bat rg fzf zoxide yazi starship kitty kitten \
              btop dust fd delta lazygit procs gh \
              glow tldr micro mybash; do
    if [ -x "$LOCAL_BIN/$binary" ]; then
        echo "binary:$LOCAL_BIN/$binary" >> "$MANIFEST_FILE"
    fi
done

# Track git config changes
if git config --global --get include.path 2>/dev/null | grep -q "delta.gitconfig"; then
    echo "git_config:include.path=$CONFIGS_DIR/delta.gitconfig" >> "$MANIFEST_FILE"
fi

log_info "Manifest saved to $MANIFEST_FILE"

print_success_box "Installation Complete!"
log_warn "IMPORTANT: To see icons, set your terminal font to 'JetBrainsMono Nerd Font' (or MesloLGS) manually if not using Kitty."
log_info "Restart your shell to apply changes."
