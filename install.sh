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
# Install anything missing rather than failing — stock Ubuntu Server and
# Raspberry Pi OS images frequently ship without git.
#
# This runs before the repo clone, so lib/distro-detect.sh isn't available yet
# and the package manager is detected inline. The script is executed as
# `curl | bash`, so stdin is the pipe: never prompt here. sudo is fine, it
# reads the password from /dev/tty.
ensure_deps() {
    local missing=() pkgs=() c
    for c in git curl sha256sum; do
        command -v "$c" &>/dev/null || missing+=("$c")
    done
    [[ ${#missing[@]} -eq 0 ]] && return 0

    info "Installing missing dependencies: ${missing[*]}"
    for c in "${missing[@]}"; do
        case "$c" in
            sha256sum) pkgs+=("coreutils") ;;
            *)         pkgs+=("$c") ;;
        esac
    done

    if command -v pacman &>/dev/null; then
        sudo pacman -S --noconfirm --needed "${pkgs[@]}" || error "Failed to install: ${pkgs[*]}"
    elif command -v apt-get &>/dev/null; then
        sudo apt-get update -qq
        sudo apt-get install -y "${pkgs[@]}" || error "Failed to install: ${pkgs[*]}"
    else
        error "Missing ${missing[*]}, and neither pacman nor apt was found. Install them and re-run."
    fi

    for c in "${missing[@]}"; do
        command -v "$c" &>/dev/null || error "$c is still unavailable after installing ${pkgs[*]}"
    done
}
ensure_deps

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

# Resolve the newest tag and download from its explicit URL. The
# releases/latest/download alias can keep serving the PREVIOUS release's assets
# for a while after a new one publishes, and since checksums.txt goes stale
# alongside the binary, the two still match and verification cannot catch it.
BASE_URL="https://github.com/$REPO/releases/latest/download"
TAG=$(curl -fsSL "https://api.github.com/repos/$REPO/releases/latest" 2>/dev/null \
    | grep -m1 '"tag_name"' | sed 's/.*: *"\(.*\)",*/\1/')
if [[ -n "$TAG" ]]; then
    BASE_URL="https://github.com/$REPO/releases/download/$TAG"
    info "Latest release: $TAG"
else
    info "Could not query the release API — falling back to latest/download"
fi

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

# Ensure ~/.local/bin is on PATH — write it rather than only advising, or
# mypctools is "command not found" immediately after this installer runs.
add_path_line() {
    local rc="$1" line="$2"
    [[ -f "$rc" ]] || return 0
    grep -q '\.local/bin' "$rc" 2>/dev/null && return 0
    printf '\n# Added by mypctools\n%s\n' "$line" >> "$rc"
    info "Added ~/.local/bin to PATH in $rc"
}

if [[ ":$PATH:" != *":$BIN_DIR:"* ]]; then
    add_path_line "$HOME/.bashrc" 'export PATH="$HOME/.local/bin:$PATH"'
    add_path_line "$HOME/.zshrc" 'export PATH="$HOME/.local/bin:$PATH"'
    add_path_line "$HOME/.config/fish/config.fish" 'fish_add_path "$HOME/.local/bin"'
    echo ""
    info "Not on PATH in this shell yet. Either restart it, or run:"
    echo '  export PATH="$HOME/.local/bin:$PATH"'
fi

echo ""
success "Installation complete!"
echo ""
info "Run 'mypctools' to start the TUI"
echo ""
