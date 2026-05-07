#!/usr/bin/env bash
# GNOME Ubuntu Defaults Installer v3.0.0
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
    print_error "On CachyOS paru ships by default; if missing, reinstall via:"
    print_error "  sudo pacman -S --needed base-devel git && git clone https://aur.archlinux.org/paru.git && cd paru && makepkg -si"
    exit 1
fi

# ---- Guard: D-Bus session ----
if [[ -z "$DBUS_SESSION_BUS_ADDRESS" ]]; then
    print_error "No D-Bus session found — run from a graphical login, not SSH/TTY."
    print_error "gsettings and gnome-extensions require an active GNOME session."
    exit 1
fi

# ---- Guard: already installed ----
if [[ -f "$MARKER_DIR/installed" && "$1" != "--force" ]]; then
    print_info "gnome-ubuntu already installed. Use '--force' to re-run."
    exit 0
fi

# Pre-cache sudo so paru doesn't prompt inside the TUI
init_sudo

# ---- Step 1: Install packages ----
# gnome-shell-extension-no-overview is in the CachyOS repo; install it via pacman
# first so paru doesn't need to resolve it through AUR.
print_status "Installing system packages..."
sudo pacman -S --noconfirm --needed gnome-shell-extension-no-overview || {
    print_warning "gnome-shell-extension-no-overview not found in repos — will try via paru"
}

print_status "Installing AUR packages via paru..."

AUR_PACKAGES=(
    gnome-shell-extension-dash-to-dock
    gnome-shell-extension-appindicator
    gnome-shell-extension-desktop-icons-ng
    gnome-shell-extension-tiling-assistant
    yaru-gtk-theme
    yaru-gnome-shell-theme
    yaru-icon-theme
    ttf-ubuntu-font-family
    gnome-tweaks
)

failed_pkgs=()
for pkg in "${AUR_PACKAGES[@]}"; do
    print_status "Installing $pkg..."
    paru -S --noconfirm --needed "$pkg" || failed_pkgs+=("$pkg")
done
if [[ ${#failed_pkgs[@]} -gt 0 ]]; then
    print_warning "Failed to install: ${failed_pkgs[*]}"
fi

# Report which Yaru packages actually landed
for pkg in yaru-gtk-theme yaru-gnome-shell-theme yaru-icon-theme; do
    if paru -Q "$pkg" &>/dev/null; then
        print_success "$pkg installed"
    else
        print_error "$pkg NOT installed — theme may not apply correctly"
    fi
done

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
    "no-overview@fthx"
)

# Try gnome-extensions enable (requires live GNOME Shell); fall back to writing
# the UUID directly into gsettings so it persists even when run from a TUI/exec context.
enable_extension() {
    local uuid="$1"
    gnome-extensions enable "$uuid" 2>/dev/null && return 0
    if ! command_exists python3; then
        print_warning "python3 not found — cannot apply gsettings fallback for $uuid"
        return 1
    fi
    python3 - "$uuid" << 'PYEOF' 2>/dev/null
import sys, subprocess, re
uuid = sys.argv[1]
r = subprocess.run(['gsettings', 'get', 'org.gnome.shell', 'enabled-extensions'],
                   capture_output=True, text=True)
current = r.stdout.strip()
items = re.findall(r"'([^']+)'", current)
if uuid not in items:
    items.append(uuid)
    subprocess.run(['gsettings', 'set', 'org.gnome.shell', 'enabled-extensions',
                    '[' + ', '.join(f"'{i}'" for i in items) + ']'])
PYEOF
}

for uuid in "${EXTENSION_UUIDS[@]}"; do
    print_status "Enabling $uuid..."
    enable_extension "$uuid" || print_warning "Failed to enable $uuid"
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
        print_warning "$uuid not active in live session (will activate after log out/in)"
    fi
done
print_status "Validated $VALIDATED/${#EXTENSION_UUIDS[@]} extensions"

# ---- Step 3: Apply gsettings (Ubuntu defaults) ----
GNOME_MAJOR=$(gnome-shell --version 2>/dev/null | awk '{print $3}' | cut -d. -f1)
print_status "Applying Ubuntu GNOME defaults (GNOME ${GNOME_MAJOR:-unknown})..."

# GTK theme and icons
gsettings set org.gnome.desktop.interface gtk-theme 'Yaru-dark'
gsettings set org.gnome.desktop.interface icon-theme 'Yaru'
gsettings set org.gnome.desktop.interface cursor-theme 'Yaru'
gsettings set org.gnome.desktop.interface color-scheme 'prefer-dark'
if [[ "${GNOME_MAJOR:-0}" -ge 47 ]]; then
    gsettings set org.gnome.desktop.interface accent-color 'orange' 2>/dev/null
fi

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
# edge-tiling is disabled here because tiling-assistant fully replaces mutter's
# built-in edge-tiling with its own popup-based tiling. Running both causes conflicts.
gsettings set org.gnome.mutter edge-tiling false
gsettings set org.gnome.mutter dynamic-workspaces true
gsettings set org.gnome.mutter workspaces-only-on-primary true

# Keybindings — Alt+Tab switches individual windows (not app groups), Super+D shows desktop
gsettings set org.gnome.desktop.wm.keybindings switch-applications "['<Super>Tab']"
gsettings set org.gnome.desktop.wm.keybindings switch-applications-backward "['<Shift><Super>Tab']"
gsettings set org.gnome.desktop.wm.keybindings switch-windows "['<Alt>Tab']"
gsettings set org.gnome.desktop.wm.keybindings switch-windows-backward "['<Shift><Alt>Tab']"
gsettings set org.gnome.desktop.wm.keybindings show-desktop "['<Super>d']"

# Tiling assistant (replaces mutter edge-tiling with popup-based tiling)
TILING_SCHEMA="org.gnome.shell.extensions.tiling-assistant"
gsettings set "$TILING_SCHEMA" tile-maximize "['<Super>Up']" 2>/dev/null
gsettings set "$TILING_SCHEMA" restore-window "['<Super>Down']" 2>/dev/null
gsettings set "$TILING_SCHEMA" tile-left-half "['<Super>Left']" 2>/dev/null
gsettings set "$TILING_SCHEMA" tile-right-half "['<Super>Right']" 2>/dev/null
gsettings set "$TILING_SCHEMA" enable-tiling-popup true 2>/dev/null
gsettings set "$TILING_SCHEMA" tiling-popup-all-workspace true 2>/dev/null
gsettings set "$TILING_SCHEMA" focus-hint 1 2>/dev/null
gsettings set "$TILING_SCHEMA" focus-hint-outline-style 1 2>/dev/null
print_success "Window tiling configured (Super+arrows, drag-to-edge popup enabled)"

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
gsettings set "$DOCK_SCHEMA" dock-fixed false 2>/dev/null
gsettings set "$DOCK_SCHEMA" autohide false 2>/dev/null
gsettings set "$DOCK_SCHEMA" intellihide true 2>/dev/null
gsettings set "$DOCK_SCHEMA" dash-max-icon-size 48 2>/dev/null
gsettings set "$DOCK_SCHEMA" show-trash true 2>/dev/null
gsettings set "$DOCK_SCHEMA" show-mounts true 2>/dev/null
gsettings set "$DOCK_SCHEMA" show-apps-at-top false 2>/dev/null
gsettings set "$DOCK_SCHEMA" show-show-apps-button true 2>/dev/null
gsettings set "$DOCK_SCHEMA" click-action 'minimize' 2>/dev/null
gsettings set "$DOCK_SCHEMA" running-indicator-style 'DOTS' 2>/dev/null
gsettings set "$DOCK_SCHEMA" custom-theme-shrink true 2>/dev/null
gsettings set "$DOCK_SCHEMA" transparency-mode 'FIXED' 2>/dev/null
gsettings set "$DOCK_SCHEMA" background-opacity 0.8 2>/dev/null
gsettings set "$DOCK_SCHEMA" disable-overview-on-startup true 2>/dev/null
gsettings set "$DOCK_SCHEMA" hot-keys false 2>/dev/null
gsettings set "$DOCK_SCHEMA" shortcut "['']" 2>/dev/null
print_success "Dock configured (left, full-height, intellihide, DOTS indicators)"

print_success "GNOME settings applied"

# ---- Step 4: CachyOS Show Apps icon ----
# dash-to-dock uses the icon named view-app-grid-{session-mode}-symbolic.
# Standard GNOME sessions run as mode 'user', so it looks for
# view-app-grid-user-symbolic. Yaru ships view-app-grid-ubuntu-symbolic (for
# Ubuntu's session mode), not the user variant. We drop the CachyOS logo
# in the user's Yaru override dir so dash-to-dock picks it up.
print_status "Applying CachyOS Show Apps icon..."
CACHYOS_LOGO="/usr/share/icons/cachyos.svg"
ICON_OVERRIDE_DIR="$HOME/.local/share/icons/Yaru/scalable/actions"
if [[ -f "$CACHYOS_LOGO" ]]; then
    mkdir -p "$ICON_OVERRIDE_DIR"
    cp "$CACHYOS_LOGO" "$ICON_OVERRIDE_DIR/view-app-grid-user-symbolic.svg"
    gtk-update-icon-cache -f "$HOME/.local/share/icons/Yaru" 2>/dev/null || true
    print_success "Show Apps button: CachyOS logo applied"
else
    print_warning "CachyOS logo not found at $CACHYOS_LOGO, skipping Show Apps icon"
fi

# ---- Step 5: One-shot autostart to re-apply extension settings ----
# On a fresh install, tiling-assistant and dash-to-dock run their first-time
# initialization on the first GNOME login and reset some keys to schema defaults,
# overwriting what we set above. This autostart re-applies the settings once on
# the next login (after extensions have fully initialized), then removes itself.
print_status "Creating post-login settings autostart..."
AUTOSTART_DIR="$HOME/.config/autostart"
SETTINGS_SCRIPT="$MARKER_DIR/apply-settings.sh"
mkdir -p "$AUTOSTART_DIR" "$MARKER_DIR"

cat > "$SETTINGS_SCRIPT" << 'SETTINGS_EOF'
#!/usr/bin/env bash
# Re-apply gnome-ubuntu extension settings after first-login extension init
sleep 8  # wait for extensions to fully initialize

TILING_SCHEMA="org.gnome.shell.extensions.tiling-assistant"
DOCK_SCHEMA="org.gnome.shell.extensions.dash-to-dock"

gsettings set "$TILING_SCHEMA" tile-maximize "['<Super>Up']" 2>/dev/null
gsettings set "$TILING_SCHEMA" restore-window "['<Super>Down']" 2>/dev/null
gsettings set "$TILING_SCHEMA" tile-left-half "['<Super>Left']" 2>/dev/null
gsettings set "$TILING_SCHEMA" tile-right-half "['<Super>Right']" 2>/dev/null
gsettings set "$TILING_SCHEMA" enable-tiling-popup true 2>/dev/null
gsettings set "$TILING_SCHEMA" tiling-popup-all-workspace true 2>/dev/null
gsettings set "$TILING_SCHEMA" focus-hint 1 2>/dev/null
gsettings set "$TILING_SCHEMA" focus-hint-outline-style 1 2>/dev/null

gsettings set "$DOCK_SCHEMA" dock-position 'LEFT' 2>/dev/null
gsettings set "$DOCK_SCHEMA" extend-height true 2>/dev/null
gsettings set "$DOCK_SCHEMA" dock-fixed false 2>/dev/null
gsettings set "$DOCK_SCHEMA" autohide false 2>/dev/null
gsettings set "$DOCK_SCHEMA" intellihide true 2>/dev/null
gsettings set "$DOCK_SCHEMA" dash-max-icon-size 48 2>/dev/null
gsettings set "$DOCK_SCHEMA" show-trash true 2>/dev/null
gsettings set "$DOCK_SCHEMA" show-mounts true 2>/dev/null
gsettings set "$DOCK_SCHEMA" show-apps-at-top false 2>/dev/null
gsettings set "$DOCK_SCHEMA" show-show-apps-button true 2>/dev/null
gsettings set "$DOCK_SCHEMA" click-action 'minimize' 2>/dev/null
gsettings set "$DOCK_SCHEMA" running-indicator-style 'DOTS' 2>/dev/null
gsettings set "$DOCK_SCHEMA" custom-theme-shrink true 2>/dev/null
gsettings set "$DOCK_SCHEMA" transparency-mode 'FIXED' 2>/dev/null
gsettings set "$DOCK_SCHEMA" background-opacity 0.8 2>/dev/null
gsettings set "$DOCK_SCHEMA" disable-overview-on-startup true 2>/dev/null
gsettings set "$DOCK_SCHEMA" hot-keys false 2>/dev/null
gsettings set "$DOCK_SCHEMA" shortcut "['']" 2>/dev/null

# Self-remove: extension init only happens once, so we don't need this again
rm -f "$HOME/.config/autostart/gnome-ubuntu-settings.desktop"
SETTINGS_EOF
chmod +x "$SETTINGS_SCRIPT"

cat > "$AUTOSTART_DIR/gnome-ubuntu-settings.desktop" << DESKTOP_EOF
[Desktop Entry]
Type=Application
Name=GNOME Ubuntu Settings
Comment=Re-apply gnome-ubuntu extension settings after first-login init
Exec=$SETTINGS_SCRIPT
Hidden=false
NoDisplay=true
X-GNOME-Autostart-enabled=true
DESKTOP_EOF
print_success "Post-login settings autostart created"

# ---- Step 6: Create marker ----
touch "$MARKER_DIR/installed"


# ---- Done ----
echo ""
print_success "Ubuntu GNOME defaults applied!"
echo ""
print_info "Log out and back in for all changes to take effect."
print_info "On first login, extension settings are re-applied automatically after ~8s."
print_info "Use GNOME Tweaks or GNOME Extensions for further customization."
echo ""
