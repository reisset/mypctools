#!/usr/bin/env bash
# mypctools/uninstall.sh
# Clean removal script
# v0.1.0

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m'

print_step() { echo -e "${BLUE}==>${NC} $1"; }
print_ok() { echo -e "${GREEN}✓${NC} $1"; }
print_warn() { echo -e "${YELLOW}!${NC} $1"; }

echo ""
echo "╔═══════════════════════════════════════╗"
echo "║       mypctools uninstaller           ║"
echo "╚═══════════════════════════════════════╝"
echo ""

# Remove symlink
SYMLINK_PATH="$HOME/.local/bin/mypctools"

if [[ -L "$SYMLINK_PATH" ]]; then
    print_step "Removing symlink..."
    rm "$SYMLINK_PATH"
    print_ok "Symlink removed"
else
    print_warn "Symlink not found at $SYMLINK_PATH"
fi

# Ask about removing directory
echo ""
read -rp "Also remove the mypctools directory? [y/N] " response
response=${response:-N}

if [[ "$response" =~ ^[Yy] ]]; then
    print_step "Removing directory..."
    rm -rf "$SCRIPT_DIR"
    print_ok "Directory removed"
    echo ""
    print_ok "mypctools has been completely removed"
else
    print_ok "Directory kept at: $SCRIPT_DIR"
    echo ""
    print_ok "mypctools symlink removed. Directory preserved."
fi

echo ""
