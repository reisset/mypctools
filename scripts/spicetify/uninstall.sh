#!/usr/bin/env bash
# mypctools/scripts/spicetify/uninstall.sh
# Restore vanilla Spotify (remove Spicetify theme)
# v1.0.0

_SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$_SCRIPT_DIR/../../lib/helpers.sh"

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
    print_info "Restart Spotify to see the changes."
    print_info "Note: Spicetify CLI is still installed at $SPICETIFY_DIR"
    print_info "To fully remove: rm -rf $SPICETIFY_DIR ~/.config/spicetify"
else
    print_error "Failed to restore Spotify"
    exit 1
fi
