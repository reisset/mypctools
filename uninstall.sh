#!/usr/bin/env bash
# mypctools/uninstall.sh
# Clean removal script
# v0.1.1 - Removed set -e for reliability

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

source "$SCRIPT_DIR/lib/print.sh"

echo ""
echo "╔═══════════════════════════════════════╗"
echo "║       mypctools uninstaller           ║"
echo "╚═══════════════════════════════════════╝"
echo ""

# Remove symlink
SYMLINK_PATH="$HOME/.local/bin/mypctools"

if [[ -L "$SYMLINK_PATH" ]]; then
    print_status "Removing symlink..."
    rm "$SYMLINK_PATH"
    print_success "Symlink removed"
else
    print_warning "Symlink not found at $SYMLINK_PATH"
fi

# Ask about removing directory
echo ""
read -rp "Also remove the mypctools directory? [y/N] " response
response=${response:-N}

if [[ "$response" =~ ^[Yy] ]]; then
    print_status "Removing directory..."
    rm -rf "$SCRIPT_DIR"
    print_success "Directory removed"
    echo ""
    print_success "mypctools has been completely removed"
else
    print_success "Directory kept at: $SCRIPT_DIR"
    echo ""
    print_success "mypctools symlink removed. Directory preserved."
fi

echo ""
