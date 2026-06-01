#!/usr/bin/env bash
# mypctools/scripts/spicetify/uninstall.sh
# Restore vanilla Spotify (remove Spicetify theme)
# v1.0.0

_SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$_SCRIPT_DIR/../../lib/print.sh"

SPICETIFY_DIR="$HOME/.spicetify"

print_header "Spicetify Uninstaller"
echo ""

# Check if spicetify is installed
export PATH="$SPICETIFY_DIR:$PATH"

if ! command_exists spicetify; then
    print_warning "Spicetify not found - nothing to restore"
    exit 0
fi

print_info "Restoring vanilla Spotify..."
if spicetify restore; then
    print_success "Spotify restored to vanilla"
    echo ""

    # Restore Spotify directory permissions narrowed by the installer
    get_spotify_path() {
        if [[ -d "/opt/spotify" ]]; then echo "/opt/spotify"
        elif [[ -d "/usr/share/spotify" ]]; then echo "/usr/share/spotify"
        elif [[ -d "/usr/lib/spotify" ]]; then echo "/usr/lib/spotify"
        fi
    }
    SPOTIFY_PATH=$(get_spotify_path)
    if [[ -n "$SPOTIFY_PATH" ]]; then
        ensure_sudo && \
        sudo chmod g-w "$SPOTIFY_PATH" && \
        sudo chmod -R g-w "$SPOTIFY_PATH/Apps" && \
        print_success "Spotify permissions restored"
    fi

    print_info "Restart Spotify to see the changes."
    print_info "Note: Spicetify CLI is still installed at $SPICETIFY_DIR"
    print_info "To fully remove: rm -rf $SPICETIFY_DIR ~/.config/spicetify"
else
    print_error "Failed to restore Spotify"
    exit 1
fi
