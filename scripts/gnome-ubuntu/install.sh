#!/usr/bin/env bash
# GNOME Ubuntu Defaults Installer v2.0.0
# Applies Ubuntu's GNOME look and feel on Arch-based systems

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"

source "$REPO_DIR/lib/print.sh"
source "$REPO_DIR/lib/distro-detect.sh"

MARKER_DIR="$HOME/.local/share/gnome-ubuntu"

print_header "GNOME Ubuntu Defaults Installer"
echo ""

# ---- Guard: Arch only ----
if [[ "$DISTRO_TYPE" != "arch" ]]; then
    print_error "This bundle requires an Arch-based distro (detected: $DISTRO_TYPE)."
    exit 1
fi

# ---- Guard: GNOME session ----
if [[ "$XDG_CURRENT_DESKTOP" != *"GNOME"* ]]; then
    print_error "GNOME desktop not detected (XDG_CURRENT_DESKTOP=$XDG_CURRENT_DESKTOP)."
    print_error "Log into a GNOME session before running this installer."
    exit 1
fi

# ---- Guard: paru ----
if ! command_exists paru; then
    print_error "paru is required but not installed."
    exit 1
fi

# Pre-cache sudo so paru doesn't prompt inside the TUI
init_sudo

# ---- Step 1: Install AUR packages ----
print_status "Installing packages via paru..."

PACKAGES=(
    gnome-shell-extension-dash-to-dock
    gnome-shell-extension-appindicator
    gnome-shell-extension-desktop-icons-ng
    gnome-shell-extension-tiling-assistant
    yaru-gtk-theme
    yaru-icon-theme
    ttf-ubuntu-font-family
    gnome-tweaks
    gnome-extensions-app
)

paru -S --noconfirm --needed "${PACKAGES[@]}" || {
    print_warning "Some packages may have failed. Continuing..."
}
print_success "Packages installed"

# ---- Step 2: Enable extensions ----
# UUIDs verified from Arch AUR packages via `gnome-extensions list` after install.
# These match the AUR package builds, not Ubuntu system package UUIDs.
# Ensure GNOME Shell allows user extensions
gsettings set org.gnome.shell disable-user-extensions false
print_status "Enabling extensions..."

EXTENSION_UUIDS=(
    "dash-to-dock@micxgx.gmail.com"
    "appindicatorsupport@rgcjonas.gmail.com"
    "ding@rastersoft.com"
    "tiling-assistant@leleat-on-github"
)

for uuid in "${EXTENSION_UUIDS[@]}"; do
    print_status "Enabling $uuid..."
    gnome-extensions enable "$uuid" 2>/dev/null || {
        print_warning "Failed to enable $uuid (may need log out/in first)"
    }
done

# Post-enable validation
print_status "Validating enabled extensions..."
ENABLED_EXTS="$(gnome-extensions list --enabled 2>/dev/null)"
VALIDATED=0
for uuid in "${EXTENSION_UUIDS[@]}"; do
    if echo "$ENABLED_EXTS" | grep -q "$uuid"; then
        print_success "Verified: $uuid is enabled"
        ((VALIDATED++))
    else
        print_warning "$uuid not active yet (will activate after log out/in)"
    fi
done
print_status "Validated $VALIDATED/${#EXTENSION_UUIDS[@]} extensions"

# ---- Step 3: Apply gsettings (Ubuntu defaults) ----
print_status "Applying Ubuntu GNOME defaults..."

# GTK theme and icons
gsettings set org.gnome.desktop.interface gtk-theme 'Yaru-dark'
gsettings set org.gnome.desktop.interface icon-theme 'Yaru'
gsettings set org.gnome.desktop.interface cursor-theme 'Yaru'
gsettings set org.gnome.desktop.interface color-scheme 'prefer-dark'
gsettings set org.gnome.desktop.interface accent-color 'orange' 2>/dev/null

# Fonts
gsettings set org.gnome.desktop.interface font-name 'Ubuntu 11'
gsettings set org.gnome.desktop.interface document-font-name 'Ubuntu 11'
gsettings set org.gnome.desktop.interface monospace-font-name 'Ubuntu Mono 13'
gsettings set org.gnome.desktop.interface font-antialiasing 'rgba'
gsettings set org.gnome.desktop.wm.preferences titlebar-font 'Ubuntu Bold 11'
gsettings set org.gnome.desktop.wm.preferences titlebar-uses-system-font false

# UX defaults
gsettings set org.gnome.desktop.interface enable-hot-corners false
gsettings set org.gnome.desktop.peripherals.touchpad tap-to-click true

# Window button layout (no appmenu on left, matches Ubuntu)
gsettings set org.gnome.desktop.wm.preferences button-layout ':minimize,maximize,close'
gsettings set org.gnome.desktop.wm.preferences action-middle-click-titlebar 'lower'

# Shell
gsettings set org.gnome.shell always-show-log-out true 2>/dev/null

# Mutter (window manager core)
gsettings set org.gnome.mutter edge-tiling true
gsettings set org.gnome.mutter dynamic-workspaces true
gsettings set org.gnome.mutter workspaces-only-on-primary true

# Keybindings — Alt+Tab switches individual windows (not app groups), Super+D shows desktop
gsettings set org.gnome.desktop.wm.keybindings switch-applications "['<Super>Tab']"
gsettings set org.gnome.desktop.wm.keybindings switch-applications-backward "['<Shift><Super>Tab']"
gsettings set org.gnome.desktop.wm.keybindings switch-windows "['<Alt>Tab']"
gsettings set org.gnome.desktop.wm.keybindings switch-windows-backward "['<Shift><Alt>Tab']"
gsettings set org.gnome.desktop.wm.keybindings show-desktop "['<Super>d']"

# Tiling assistant keybindings (Super+arrows for half/full tiling)
TILING_SCHEMA="org.gnome.shell.extensions.tiling-assistant"
gsettings set "$TILING_SCHEMA" tile-maximize "['<Super>Up']" 2>/dev/null
gsettings set "$TILING_SCHEMA" restore-window "['<Super>Down']" 2>/dev/null
gsettings set "$TILING_SCHEMA" tile-left-half "['<Super>Left']" 2>/dev/null
gsettings set "$TILING_SCHEMA" tile-right-half "['<Super>Right']" 2>/dev/null
print_success "Window tiling configured (Super+arrows)"

# Power — never sleep on AC (Ubuntu default)
gsettings set org.gnome.settings-daemon.plugins.power sleep-inactive-ac-timeout 0 2>/dev/null
gsettings set org.gnome.settings-daemon.plugins.power power-button-action 'interactive' 2>/dev/null

# Nautilus
gsettings set org.gnome.nautilus.icon-view default-zoom-level 'small' 2>/dev/null

# Desktop icons (ding extension) — no trash/volumes on desktop, icons in bottom-right
DING_SCHEMA="org.gnome.shell.extensions.ding"
gsettings set "$DING_SCHEMA" show-trash false 2>/dev/null
gsettings set "$DING_SCHEMA" show-volumes false 2>/dev/null
gsettings set "$DING_SCHEMA" start-corner 'bottom-right' 2>/dev/null

# Dash-to-dock settings (matches Ubuntu defaults)
DOCK_SCHEMA="org.gnome.shell.extensions.dash-to-dock"
gsettings set "$DOCK_SCHEMA" dock-position 'LEFT' 2>/dev/null
gsettings set "$DOCK_SCHEMA" extend-height true 2>/dev/null
gsettings set "$DOCK_SCHEMA" autohide false 2>/dev/null
gsettings set "$DOCK_SCHEMA" intellihide false 2>/dev/null
gsettings set "$DOCK_SCHEMA" dash-max-icon-size 48 2>/dev/null
gsettings set "$DOCK_SCHEMA" show-trash true 2>/dev/null
gsettings set "$DOCK_SCHEMA" show-mounts true 2>/dev/null
gsettings set "$DOCK_SCHEMA" show-apps-at-top false 2>/dev/null
gsettings set "$DOCK_SCHEMA" click-action 'minimize' 2>/dev/null
gsettings set "$DOCK_SCHEMA" hot-keys false 2>/dev/null
gsettings set "$DOCK_SCHEMA" shortcut "['']" 2>/dev/null
print_success "Dock configured (left, full-height, always-visible, icon size 48)"

print_success "GNOME settings applied"

# ---- Step 4: Create marker ----
mkdir -p "$MARKER_DIR"
touch "$MARKER_DIR/installed"


# ---- Done ----
echo ""
print_success "Ubuntu GNOME defaults applied!"
echo ""
print_info "You may need to log out and log back in for all changes to take effect."
print_info "Use GNOME Tweaks or GNOME Extensions for further customization."
echo ""
