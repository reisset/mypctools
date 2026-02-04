#!/usr/bin/env bash
# Fastfetch Config Uninstaller
# v1.0.0

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../../lib/print.sh"

CONFIG_FILE="$HOME/.config/fastfetch/config.jsonc"

if [[ -L "$CONFIG_FILE" ]]; then
    rm "$CONFIG_FILE"
    print_success "Removed config symlink"
elif [[ -f "$CONFIG_FILE" ]]; then
    print_warning "Config is not a symlink (may have been modified manually)"
    read -rp "Remove anyway? [y/N]: " confirm
    if [[ "$confirm" =~ ^[Yy]$ ]]; then
        rm "$CONFIG_FILE"
        print_success "Removed config file"
    fi
else
    print_status "No config file found"
fi

echo ""
print_success "Uninstall complete"
echo "fastfetch itself was not removed. Uninstall it via your package manager if desired."
