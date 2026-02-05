#!/usr/bin/env bash
# mypctools installer
# curl -fsSL https://raw.githubusercontent.com/reisset/mypctools/main/install.sh | bash

set -e

REPO="reisset/mypctools"
INSTALL_DIR="$HOME/.local/share/mypctools"
BIN_DIR="$HOME/.local/bin"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m'

info() { echo -e "${BLUE}[*]${NC} $1"; }
success() { echo -e "${GREEN}[✓]${NC} $1"; }
error() { echo -e "${RED}[✗]${NC} $1"; exit 1; }

echo ""
echo "╔═══════════════════════════════════════╗"
echo "║         mypctools installer           ║"
echo "╚═══════════════════════════════════════╝"
echo ""

# Detect architecture
ARCH=$(uname -m)
case "$ARCH" in
    x86_64)  ARCH="amd64" ;;
    aarch64) ARCH="arm64" ;;
    *)       error "Unsupported architecture: $ARCH" ;;
esac

info "Detected architecture: $ARCH"

# Create directories
mkdir -p "$BIN_DIR"
mkdir -p "$INSTALL_DIR"

# Clone or update repo (for scripts/)
if [[ -d "$INSTALL_DIR/.git" ]]; then
    info "Updating mypctools..."
    git -C "$INSTALL_DIR" pull --quiet
else
    info "Cloning mypctools..."
    rm -rf "$INSTALL_DIR"
    git clone --depth=1 --quiet "https://github.com/$REPO.git" "$INSTALL_DIR"
fi
success "Repository ready at $INSTALL_DIR"

# Download binary from latest release
info "Downloading mypctools binary..."
RELEASE_URL="https://github.com/$REPO/releases/latest/download/mypctools-linux-$ARCH"
if ! curl -fsSL "$RELEASE_URL" -o "$BIN_DIR/mypctools"; then
    error "Failed to download binary. Check that a release exists at: $RELEASE_URL"
fi
chmod +x "$BIN_DIR/mypctools"
success "Binary installed to $BIN_DIR/mypctools"

# Ensure ~/.local/bin is in PATH
if [[ ":$PATH:" != *":$BIN_DIR:"* ]]; then
    echo ""
    info "Add to your shell config:"
    echo '  export PATH="$HOME/.local/bin:$PATH"'
fi

echo ""
success "Installation complete!"
echo ""
info "Run 'mypctools' to start the TUI"
echo ""
