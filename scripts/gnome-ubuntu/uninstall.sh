#!/usr/bin/env bash
# GNOME Ubuntu Defaults Uninstaller v1.0.0
# Resets GNOME settings to defaults, disables extensions
# Does NOT uninstall AUR packages

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"

source "$REPO_DIR/lib/print.sh"

MARKER_DIR="$HOME/.local/share/gnome-ubuntu"

print_header "GNOME Ubuntu Defaults Uninstaller"
echo ""

# ---- Step 1: Disable extensions ----
# UUIDs match the Arch AUR package builds
print_status "Disabling extensions..."

EXTENSION_UUIDS=(
    "dash-to-dock@micxgx.gmail.com"
    "appindicatorsupport@rgcjonas.gmail.com"
    "ding@rastersoft.com"
)

for uuid in "${EXTENSION_UUIDS[@]}"; do
    print_status "Disabling $uuid..."
    gnome-extensions disable "$uuid" 2>/dev/null || print_warning "Failed to disable $uuid"
done
print_success "Extensions disabled"

# ---- Step 2: Reset gsettings to defaults ----
print_status "Resetting GNOME settings to defaults..."

gsettings reset org.gnome.desktop.interface gtk-theme
gsettings reset org.gnome.desktop.interface icon-theme
gsettings reset org.gnome.desktop.interface cursor-theme
gsettings reset org.gnome.desktop.interface font-name
gsettings reset org.gnome.desktop.interface document-font-name
gsettings reset org.gnome.desktop.interface monospace-font-name
gsettings reset org.gnome.desktop.wm.preferences titlebar-font
gsettings reset org.gnome.desktop.wm.preferences button-layout
gsettings reset org.gnome.desktop.interface color-scheme
gsettings reset org.gnome.desktop.interface enable-hot-corners
gsettings reset org.gnome.desktop.peripherals.touchpad tap-to-click

DOCK_SCHEMA="org.gnome.shell.extensions.dash-to-dock"
gsettings reset "$DOCK_SCHEMA" dock-position 2>/dev/null
gsettings reset "$DOCK_SCHEMA" dash-max-icon-size 2>/dev/null
gsettings reset "$DOCK_SCHEMA" autohide 2>/dev/null
gsettings reset "$DOCK_SCHEMA" intellihide 2>/dev/null
gsettings reset "$DOCK_SCHEMA" show-trash 2>/dev/null
gsettings reset "$DOCK_SCHEMA" show-mounts 2>/dev/null
gsettings reset "$DOCK_SCHEMA" show-apps-at-top 2>/dev/null
gsettings reset "$DOCK_SCHEMA" click-action 2>/dev/null

print_success "GNOME settings reset to defaults"

# ---- Step 3: Remove marker ----
if [[ -d "$MARKER_DIR" ]]; then
    rm -rf "$MARKER_DIR"
    print_success "Marker removed"
fi

# ---- Done ----
echo ""
print_success "Ubuntu GNOME defaults removed!"
echo ""
print_info "AUR packages were NOT uninstalled. To remove them manually:"
print_info "  paru -R gnome-shell-extension-dash-to-dock gnome-shell-extension-appindicator \\"
print_info "    gnome-shell-extension-desktop-icons-ng yaru-gtk-theme yaru-icon-theme \\"
print_info "    ttf-ubuntu-font-family gnome-tweaks"
print_info "You may need to log out and log back in for all changes to take effect."
echo ""
