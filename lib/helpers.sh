#!/usr/bin/env bash
# mypctools/lib/helpers.sh
# Shared helper functions for mypctools
# v0.3.0

# Source theme
_HELPERS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$_HELPERS_DIR/theme.sh"

# Print functions using gum for consistent styled output
print_header() {
    gum style --foreground "$THEME_PRIMARY" --bold "==> $1"
}

print_success() {
    gum style --foreground "$THEME_SUCCESS" "✓ $1"
}

print_error() {
    gum style --foreground "$THEME_ERROR" "✗ $1" >&2
}

print_warning() {
    gum style --foreground "$THEME_WARNING" "! $1"
}

print_info() {
    gum style --foreground "$THEME_SECONDARY" "→ $1"
}

# Logging
log_info() {
    echo "[INFO] $(date '+%Y-%m-%d %H:%M:%S') - $1"
}

log_error() {
    echo "[ERROR] $(date '+%Y-%m-%d %H:%M:%S') - $1" >&2
}

# Check if running as root
check_root() {
    if [[ $EUID -eq 0 ]]; then
        return 0
    else
        return 1
    fi
}

# Check if a command exists
command_exists() {
    [[ -n "$1" ]] && command -v "$1" &>/dev/null
}

# Ensure sudo credentials are cached (prompts user if needed)
# Call this BEFORE running sudo commands inside gum spin
ensure_sudo() {
    if ! sudo -v; then
        print_error "sudo authentication failed"
        return 1
    fi
}

# Desktop notification after long operations (no-op if notify-send unavailable)
notify_done() {
    local title="${1:-mypctools}"
    local message="${2:-Operation complete}"
    command -v notify-send &>/dev/null && notify-send "$title" "$message" 2>/dev/null || true
}
