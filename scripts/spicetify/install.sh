#!/usr/bin/env bash
# mypctools/scripts/spicetify/install.sh
# Spicetify + StarryNight theme installer
# v1.0.1
#
# Changelog:
#   1.0.1 - Fix first-run failure by fixing permissions before spicetify install
#         - Spicetify installer runs auto-backup which needs write access to Spotify dir
#   1.0.0 - Initial release
#         - Installs spicetify CLI
#         - Configures StarryNight theme with gum-based color scheme selection
#         - Works with native Spotify installs (apt/pacman) - NOT Flatpak/Snap

set -e

_SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$_SCRIPT_DIR/../../lib/helpers.sh"
source "$_SCRIPT_DIR/../../lib/theme.sh"

SPICETIFY_DIR="$HOME/.spicetify"
SPICETIFY_CONFIG="$HOME/.config/spicetify"
TEMP_DIR=""

cleanup() {
    [[ -n "$TEMP_DIR" && -d "$TEMP_DIR" ]] && rm -rf "$TEMP_DIR"
}
trap cleanup EXIT

# Detect native Spotify installation path
get_spotify_path() {
    if [[ -d "/opt/spotify" ]]; then
        echo "/opt/spotify"
    elif [[ -d "/usr/share/spotify" ]]; then
        echo "/usr/share/spotify"
    else
        echo ""
    fi
}

# Check if native Spotify is installed (not Flatpak/Snap)
has_native_spotify() {
    local spotify_path
    spotify_path=$(get_spotify_path)

    # Must have native install
    [[ -z "$spotify_path" ]] && return 1

    # Check it's not flatpak
    if command_exists flatpak; then
        if flatpak list --app 2>/dev/null | grep -qi "spotify"; then
            print_warning "Flatpak Spotify detected - Spicetify only works with native installs"
            return 1
        fi
    fi

    # Check it's not snap
    if [[ -d "/snap/spotify" ]]; then
        print_warning "Snap Spotify detected - Spicetify only works with native installs"
        return 1
    fi

    return 0
}

# -----------------------------------------------------------------------------
# Main install logic
# -----------------------------------------------------------------------------

print_header "Spicetify + StarryNight Installer"
echo ""

# Preflight: Check for native Spotify
print_info "Checking for native Spotify..."
if ! has_native_spotify; then
    print_error "Native Spotify not found."
    echo ""
    print_info "Spicetify requires Spotify installed via:"
    print_info "  - Arch: spotify (AUR)"
    print_info "  - Debian/Ubuntu: spotify-client (official repo)"
    print_info "  - NOT Flatpak or Snap"
    echo ""
    exit 1
fi

SPOTIFY_PATH=$(get_spotify_path)
print_success "Found Spotify at $SPOTIFY_PATH"

# Fix Spotify permissions FIRST (before spicetify install, since installer runs auto-backup)
print_info "Fixing Spotify permissions (requires sudo)..."
ensure_sudo || exit 1
sudo chmod a+wr "$SPOTIFY_PATH"
sudo chmod a+wr "$SPOTIFY_PATH/Apps" -R
print_success "Permissions fixed"

# Check required commands
for cmd in curl git tar; do
    if ! command_exists "$cmd"; then
        print_error "Required command '$cmd' not found. Please install it first."
        exit 1
    fi
done

# Install spicetify CLI
if [[ -f "$SPICETIFY_DIR/spicetify" ]]; then
    print_success "Spicetify already installed"
else
    print_info "Installing spicetify CLI..."
    curl -fsSL https://raw.githubusercontent.com/spicetify/cli/main/install.sh | sh
    print_success "Spicetify installed"
fi

# Add to PATH for this session
export PATH="$SPICETIFY_DIR:$PATH"

if ! command_exists spicetify; then
    print_error "Spicetify not found in PATH after install. Try opening a new terminal."
    exit 1
fi

# Create backup
if [[ -d "$SPICETIFY_CONFIG/Backup" ]]; then
    print_success "Spicetify backup already exists"
else
    print_info "Creating spicetify backup..."
    spicetify backup
    print_success "Backup created"
fi

# Download and install StarryNight theme
print_info "Downloading StarryNight theme..."
TEMP_DIR=$(mktemp -d)
git clone --depth=1 --quiet https://github.com/spicetify/spicetify-themes.git "$TEMP_DIR/themes"
mkdir -p "$SPICETIFY_CONFIG/Themes"
cp -r "$TEMP_DIR/themes/StarryNight" "$SPICETIFY_CONFIG/Themes/"
print_success "StarryNight theme installed"

# Color scheme selection with gum
echo ""
print_header "Select a color scheme"
selected=$(gum choose --header "StarryNight color schemes:" \
    "Base" \
    "Cotton Candy" \
    "Forest" \
    "Galaxy" \
    "Orange" \
    "Sky" \
    "Sunrise")

if [[ -z "$selected" ]]; then
    print_warning "No selection - using Base"
    selected="Base"
fi

print_info "Selected: $selected"

# Apply theme
print_info "Configuring spicetify..."
spicetify config current_theme StarryNight
spicetify config color_scheme "$selected"

print_info "Applying theme..."
spicetify apply
print_success "Theme applied!"

# Done
echo ""
print_success "Spicetify + StarryNight setup complete!"
echo ""
print_info "Restart Spotify to see your new theme."
echo ""
print_info "Useful commands:"
print_info "  spicetify apply              - Reapply after Spotify updates"
print_info "  spicetify restore            - Restore vanilla Spotify"
print_info "  spicetify config color_scheme <name> && spicetify apply"
print_info "                               - Change color scheme"
echo ""
