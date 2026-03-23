#!/usr/bin/env bash
# GNOME Ubuntu Defaults Installer v1.0.0
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

# ---- Guard: yay ----
if ! command_exists paru; then
    print_error "paru is required but not installed."
    exit 1
fi

init_sudo

# ---- Step 1: Install AUR packages ----
print_status "Installing packages via paru..."

PACKAGES=(
    gnome-shell-extension-dash-to-dock
    gnome-shell-extension-appindicator
    gnome-shell-extension-desktop-icons-ng
    yaru-gtk-theme
    yaru-icon-theme
    ttf-ubuntu-font-family
    gnome-tweaks
)

paru -S --noconfirm --needed "${PACKAGES[@]}" || {
    print_warning "Some packages may have failed. Continuing..."
}
print_success "Packages installed"

# ---- Step 2: Enable extensions by UUID discovery ----
# NOTE: Extension UUIDs are discovered from `gnome-extensions list` after install,
# NOT hardcoded from Ubuntu docs. Arch AUR packages may use different UUIDs than
# Ubuntu's system packages. The patterns below match the UUID prefix.
print_status "Discovering and enabling extensions..."

declare -A EXT_PATTERNS=(
    ["dash-to-dock"]="dash-to-dock@"
    ["appindicator"]="appindicatorsupport@"
    ["desktop-icons-ng"]="ding@"
)

INSTALLED_EXTS="$(gnome-extensions list 2>/dev/null)"

declare -A DISCOVERED_UUIDS=()
for key in "${!EXT_PATTERNS[@]}"; do
    pattern="${EXT_PATTERNS[$key]}"
    uuid="$(echo "$INSTALLED_EXTS" | grep -i "$pattern" | head -1)"
    if [[ -n "$uuid" ]]; then
        DISCOVERED_UUIDS["$key"]="$uuid"
        print_success "Found extension: $uuid"
    else
        print_warning "Extension matching '$pattern' not found in gnome-extensions list"
    fi
done

# Enable discovered extensions
for key in "${!DISCOVERED_UUIDS[@]}"; do
    uuid="${DISCOVERED_UUIDS[$key]}"
    print_status "Enabling $uuid..."
    gnome-extensions enable "$uuid" 2>/dev/null || {
        print_warning "Failed to enable $uuid"
    }
done

# Post-enable validation
print_status "Validating enabled extensions..."
ENABLED_EXTS="$(gnome-extensions list --enabled 2>/dev/null)"
VALIDATED=0
for key in "${!DISCOVERED_UUIDS[@]}"; do
    uuid="${DISCOVERED_UUIDS[$key]}"
    if echo "$ENABLED_EXTS" | grep -q "$uuid"; then
        print_success "Verified: $uuid is enabled"
        ((VALIDATED++))
    else
        print_warning "Extension $uuid was not enabled successfully"
    fi
done
print_status "Validated $VALIDATED/${#DISCOVERED_UUIDS[@]} extensions"

# ---- Step 3: Apply gsettings (Ubuntu defaults) ----
print_status "Applying Ubuntu GNOME defaults..."

# GTK theme and icons
gsettings set org.gnome.desktop.interface gtk-theme 'Yaru-dark'
gsettings set org.gnome.desktop.interface icon-theme 'Yaru'
gsettings set org.gnome.desktop.interface cursor-theme 'Yaru'

# Fonts
gsettings set org.gnome.desktop.interface font-name 'Ubuntu 11'
gsettings set org.gnome.desktop.interface document-font-name 'Ubuntu 11'
gsettings set org.gnome.desktop.interface monospace-font-name 'Ubuntu Mono 13'
gsettings set org.gnome.desktop.wm.preferences titlebar-font 'Ubuntu Bold 11'

# Window button layout
gsettings set org.gnome.desktop.wm.preferences button-layout 'appmenu:minimize,maximize,close'

# Dash-to-dock settings (only if extension was discovered)
if [[ -n "${DISCOVERED_UUIDS[dash-to-dock]:-}" ]]; then
    DOCK_SCHEMA="org.gnome.shell.extensions.dash-to-dock"
    gsettings set "$DOCK_SCHEMA" dock-position 'BOTTOM'
    gsettings set "$DOCK_SCHEMA" dash-max-icon-size 48
    gsettings set "$DOCK_SCHEMA" autohide true
    gsettings set "$DOCK_SCHEMA" intellihide true
    gsettings set "$DOCK_SCHEMA" show-trash true
    gsettings set "$DOCK_SCHEMA" show-mounts true
    print_success "Dock configured (bottom, icon size 48, autohide)"
else
    print_warning "Skipping dock settings (dash-to-dock not found)"
fi

print_success "GNOME settings applied"

# ---- Step 4: Create marker ----
mkdir -p "$MARKER_DIR"
touch "$MARKER_DIR/installed"

# Save discovered UUIDs for uninstall
: > "$MARKER_DIR/enabled-extensions.txt"
for key in "${!DISCOVERED_UUIDS[@]}"; do
    echo "${DISCOVERED_UUIDS[$key]}" >> "$MARKER_DIR/enabled-extensions.txt"
done

# ---- Done ----
echo ""
print_success "Ubuntu GNOME defaults applied!"
echo ""
print_info "You may need to log out and log back in for all changes to take effect."
print_info "Use GNOME Tweaks for further customization."
echo ""
