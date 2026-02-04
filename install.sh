#!/usr/bin/env bash
# mypctools/install.sh
# Bootstrap script - installs gum, sets up PATH
# v0.2.1 - Removed set -e for reliability

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib/distro-detect.sh"

source "$SCRIPT_DIR/lib/print.sh"

echo ""
echo "╔═══════════════════════════════════════╗"
echo "║       mypctools installer v0.1        ║"
echo "╚═══════════════════════════════════════╝"
echo ""

print_status "Detected: $DISTRO_NAME ($DISTRO_TYPE)"

# Install gum if not present
install_gum() {
    print_status "Installing gum..."

    case "$DISTRO_TYPE" in
        debian)
            # Add Charm repo
            sudo mkdir -p /etc/apt/keyrings
            local gpg_key
            gpg_key=$(mktemp)
            if ! curl -fsSL --retry 3 --connect-timeout 10 https://repo.charm.sh/apt/gpg.key -o "$gpg_key"; then
                print_error "Failed to download Charm GPG key"
                rm -f "$gpg_key"
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
            print_error "Unsupported distro for automatic gum install."
            print_warning "Please install gum manually: https://github.com/charmbracelet/gum#installation"
            exit 1
            ;;
    esac
}

# Check for gum
if command -v gum &>/dev/null; then
    print_success "gum is already installed"
else
    print_warning "gum not found"
    read -rp "Install gum now? [Y/n] " response
    response=${response:-Y}
    if [[ "$response" =~ ^[Yy] ]]; then
        install_gum
        print_success "gum installed"
    else
        print_error "gum is required. Exiting."
        exit 1
    fi
fi

# Make all scripts executable
print_status "Making scripts executable..."
find "$SCRIPT_DIR" -name "*.sh" -exec chmod +x {} \;
print_success "Scripts are now executable"

# Setup PATH symlink
print_status "Setting up PATH..."
mkdir -p "$HOME/.local/bin"

SYMLINK_PATH="$HOME/.local/bin/mypctools"
OUR_TARGET="$SCRIPT_DIR/launcher.sh"

if [[ -e "$SYMLINK_PATH" || -L "$SYMLINK_PATH" ]]; then
    # Check if it already points to our launcher
    current_target=$(readlink -f "$SYMLINK_PATH" 2>/dev/null || echo "")
    our_resolved=$(readlink -f "$OUR_TARGET" 2>/dev/null)

    if [[ "$current_target" == "$our_resolved" ]]; then
        print_success "Symlink already configured"
    else
        # Backup existing file/symlink before replacing
        backup_path="$SYMLINK_PATH.backup.$(date +%Y%m%d_%H%M%S)"
        mv "$SYMLINK_PATH" "$backup_path"
        print_warning "Backed up existing mypctools to: $backup_path"
        ln -s "$OUR_TARGET" "$SYMLINK_PATH"
        print_success "Symlink created: $SYMLINK_PATH"
    fi
else
    ln -s "$OUR_TARGET" "$SYMLINK_PATH"
    print_success "Symlink created: $SYMLINK_PATH"
fi

# Add ~/.local/bin to PATH in shell configs if not present
add_path_to_shell() {
    local shell_rc="$1"
    local path_line='export PATH="$HOME/.local/bin:$PATH"'

    if [[ -f "$shell_rc" ]]; then
        if ! grep -q '\.local/bin' "$shell_rc" 2>/dev/null; then
            echo "" >> "$shell_rc"
            echo "# Added by mypctools" >> "$shell_rc"
            echo "$path_line" >> "$shell_rc"
            print_success "Added ~/.local/bin to PATH in $(basename "$shell_rc")"
            return 0
        fi
    fi
    return 1
}

if [[ ":$PATH:" != *":$HOME/.local/bin:"* ]]; then
    print_warning "~/.local/bin is not in your PATH"

    # Add to current shell's rc file
    added=false
    if [[ -f "$HOME/.bashrc" ]]; then
        add_path_to_shell "$HOME/.bashrc" && added=true
    fi
    if [[ -f "$HOME/.zshrc" ]]; then
        add_path_to_shell "$HOME/.zshrc" && added=true
    fi

    if [[ "$added" == "true" ]]; then
        print_warning "Restart your shell or run: source ~/.bashrc (or ~/.zshrc)"
    else
        print_warning "Could not add PATH automatically. Add this to your shell config:"
        echo ""
        echo '    export PATH="$HOME/.local/bin:$PATH"'
        echo ""
    fi
fi

echo ""
echo "╔═══════════════════════════════════════╗"
echo "║          Installation complete!       ║"
echo "╚═══════════════════════════════════════╝"
echo ""
print_success "Run 'mypctools' from anywhere, or './launcher.sh' from this directory"
echo ""
