#!/usr/bin/env bash
# mypctools/install.sh
# Bootstrap script - installs gum, sets up PATH
# v0.1.0

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib/distro-detect.sh"

# Colors (inline since helpers.sh needs gum check)
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m'

print_step() { echo -e "${BLUE}==>${NC} $1"; }
print_ok() { echo -e "${GREEN}✓${NC} $1"; }
print_warn() { echo -e "${YELLOW}!${NC} $1"; }
print_fail() { echo -e "${RED}✗${NC} $1"; }

echo ""
echo "╔═══════════════════════════════════════╗"
echo "║       mypctools installer v0.1        ║"
echo "╚═══════════════════════════════════════╝"
echo ""

print_step "Detected: $DISTRO_NAME ($DISTRO_TYPE)"

# Install gum if not present
install_gum() {
    print_step "Installing gum..."

    case "$DISTRO_TYPE" in
        debian)
            # Add Charm repo
            sudo mkdir -p /etc/apt/keyrings
            local gpg_key="/tmp/charm_gpg.key"
            if ! curl -fsSL --retry 3 --connect-timeout 10 https://repo.charm.sh/apt/gpg.key -o "$gpg_key"; then
                print_fail "Failed to download Charm GPG key"
                exit 1
            fi
            sudo gpg --dearmor -o /etc/apt/keyrings/charm.gpg < "$gpg_key"
            rm -f "$gpg_key"
            echo "deb [signed-by=/etc/apt/keyrings/charm.gpg] https://repo.charm.sh/apt/ * *" | sudo tee /etc/apt/sources.list.d/charm.list
            sudo apt update && sudo apt install -y gum
            ;;
        arch)
            sudo pacman -S --noconfirm gum
            ;;
        *)
            print_fail "Unsupported distro for automatic gum install."
            print_warn "Please install gum manually: https://github.com/charmbracelet/gum#installation"
            exit 1
            ;;
    esac
}

# Check for gum
if command -v gum &>/dev/null; then
    print_ok "gum is already installed"
else
    print_warn "gum not found"
    read -rp "Install gum now? [Y/n] " response
    response=${response:-Y}
    if [[ "$response" =~ ^[Yy] ]]; then
        install_gum
        print_ok "gum installed"
    else
        print_fail "gum is required. Exiting."
        exit 1
    fi
fi

# Make all scripts executable
print_step "Making scripts executable..."
find "$SCRIPT_DIR" -name "*.sh" -exec chmod +x {} \;
print_ok "Scripts are now executable"

# Setup PATH symlink
print_step "Setting up PATH..."
mkdir -p "$HOME/.local/bin"

SYMLINK_PATH="$HOME/.local/bin/mypctools"

if [[ -L "$SYMLINK_PATH" ]]; then
    rm "$SYMLINK_PATH"
fi

ln -s "$SCRIPT_DIR/launcher.sh" "$SYMLINK_PATH"
print_ok "Symlink created: $SYMLINK_PATH"

# Check if ~/.local/bin is in PATH
if [[ ":$PATH:" != *":$HOME/.local/bin:"* ]]; then
    print_warn "~/.local/bin is not in your PATH"
    print_warn "Add this to your .bashrc or .zshrc:"
    echo ""
    echo '    export PATH="$HOME/.local/bin:$PATH"'
    echo ""
fi

echo ""
echo "╔═══════════════════════════════════════╗"
echo "║          Installation complete!       ║"
echo "╚═══════════════════════════════════════╝"
echo ""
print_ok "Run 'mypctools' from anywhere, or './launcher.sh' from this directory"
echo ""
