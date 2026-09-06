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

# Check dependencies
command -v git &>/dev/null || error "git is required but not installed"
command -v curl &>/dev/null || error "curl is required but not installed"
command -v sha256sum &>/dev/null || error "sha256sum is required but not installed"

# Create directories
mkdir -p "$BIN_DIR"
mkdir -p "$INSTALL_DIR"

# Clone or update repo (for scripts/)
# This checkout is a read-only mirror, so it is force-synced rather than merged —
# a plain pull cannot recover if the remote history has been rewritten.
if [[ -d "$INSTALL_DIR/.git" ]]; then
    info "Updating mypctools..."
    if [[ "$(git -C "$INSTALL_DIR" rev-parse --is-shallow-repository)" == "true" ]]; then
        git -C "$INSTALL_DIR" fetch --unshallow --tags --force --prune --quiet origin
    else
        git -C "$INSTALL_DIR" fetch --tags --force --prune --quiet origin
    fi
    git -C "$INSTALL_DIR" reset --hard --quiet origin/main
else
    info "Cloning mypctools..."
    rm -rf "$INSTALL_DIR"
    git clone --quiet "https://github.com/$REPO.git" "$INSTALL_DIR"
fi
success "Repository ready at $INSTALL_DIR"

# Download binary from latest release and verify it the same way the in-app
# self-updater does — fail closed rather than install an unverified binary.
# Staged inside BIN_DIR so the final move is an atomic same-filesystem rename.
info "Downloading mypctools binary..."
BASE_URL="https://github.com/$REPO/releases/latest/download"
BIN_NAME="mypctools-linux-$ARCH"
TMP_DIR=$(mktemp -d "$BIN_DIR/.mypctools-install.XXXXXX")
trap 'rm -rf "$TMP_DIR"' EXIT

if ! curl -fsSL "$BASE_URL/$BIN_NAME" -o "$TMP_DIR/$BIN_NAME"; then
    error "Failed to download binary. Check that a release exists at: $BASE_URL/$BIN_NAME"
fi

if ! curl -fsSL "$BASE_URL/checksums.txt" -o "$TMP_DIR/checksums.txt"; then
    error "Failed to download checksums.txt — refusing to install an unverified binary"
fi

EXPECTED=$(awk -v f="$BIN_NAME" '$NF == f || $NF == "*" f { print $1 }' "$TMP_DIR/checksums.txt")
[[ -n "$EXPECTED" ]] || error "No checksum published for $BIN_NAME — refusing to install"

ACTUAL=$(sha256sum "$TMP_DIR/$BIN_NAME" | awk '{print $1}')
[[ "$ACTUAL" == "$EXPECTED" ]] || error "Checksum mismatch for $BIN_NAME (expected $EXPECTED, got $ACTUAL)"

chmod +x "$TMP_DIR/$BIN_NAME"
mv "$TMP_DIR/$BIN_NAME" "$BIN_DIR/mypctools"
success "Binary installed and verified (sha256 ${ACTUAL:0:12}...)"

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
