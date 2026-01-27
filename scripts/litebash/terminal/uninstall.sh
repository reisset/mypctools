#!/usr/bin/env bash
# LiteBash Terminal (foot) Uninstaller
# v1.0.0

set -e

FOOT_CONFIG="$HOME/.config/foot/foot.ini"
FOOT_DIR="$HOME/.config/foot"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

print_status() { echo -e "${BLUE}[*]${NC} $1"; }
print_success() { echo -e "${GREEN}[✓]${NC} $1"; }
print_warning() { echo -e "${YELLOW}[!]${NC} $1"; }
print_error() { echo -e "${RED}[✗]${NC} $1"; }

# Sudo check (for potential future cleanup)
echo "This uninstaller requires sudo privileges to function properly."
echo ""
sudo -v || { print_error "Sudo access required. Aborting."; exit 1; }

# Remove foot config
if [ -f "$FOOT_CONFIG" ]; then
    # Check if there are other files in the foot config dir
    file_count=$(find "$FOOT_DIR" -maxdepth 1 -type f | wc -l)

    if [ "$file_count" -eq 1 ]; then
        # Only our config exists, remove the whole directory
        print_status "Removing foot config directory..."
        rm -rf "$FOOT_DIR"
        print_success "Removed $FOOT_DIR"
    else
        # Other configs exist, only remove our file
        print_status "Removing foot.ini (keeping other configs)..."
        rm -f "$FOOT_CONFIG"
        print_success "Removed foot.ini"
    fi
else
    print_warning "No foot config found at $FOOT_CONFIG"
fi

# Note about fonts
print_status "Fonts left in place (~/.local/share/fonts)"

echo ""
print_success "foot config removed."
echo ""
echo "To remove foot itself, run:"
if command -v pacman &>/dev/null; then
    echo "  sudo pacman -Rs foot"
elif command -v apt &>/dev/null; then
    echo "  sudo apt remove foot"
elif command -v dnf &>/dev/null; then
    echo "  sudo dnf remove foot"
fi
