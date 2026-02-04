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

# Check if running as root
check_root() { [[ $EUID -eq 0 ]]; }

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

# Check if a script bundle is installed
is_script_installed() {
    case "$1" in
        litebash)    [[ -f "$HOME/.local/share/litebash/litebash.sh" ]] ;;
        litezsh)     [[ -f "$HOME/.local/share/litezsh/litezsh.zsh" ]] ;;
        terminal)    [[ -f "$HOME/.config/foot/foot.ini" ]] ;;
        alacritty)   [[ -f "$HOME/.config/alacritty/alacritty.toml" ]] ;;
        ghostty)     [[ -f "$HOME/.config/ghostty/config" ]] ;;
        kitty)       [[ -f "$HOME/.config/kitty/kitty.conf" ]] ;;
        fastfetch)   [[ -f "$HOME/.config/fastfetch/config.jsonc" ]] ;;
        screensaver) [[ -f "$HOME/.local/bin/mypctools-screensaver-launch" ]] ;;
        claude)      [[ -f "$HOME/.claude/statusline.sh" ]] ;;
        spicetify)   [[ -f "$HOME/.spicetify/spicetify" ]] ;;
        *)           return 1 ;;
    esac
}

# Build a display label with ✓ badge if script bundle is installed
script_label() {
    local name="$1" bundle_id="$2"
    if is_script_installed "$bundle_id"; then
        echo "$name  ✓"
    else
        echo "$name"
    fi
}

# Append a timestamped line to the operation log
log_action() {
    local log_dir="$HOME/.local/share/mypctools"
    local log_file="$log_dir/mypctools.log"
    mkdir -p "$log_dir"
    echo "$(date '+%Y-%m-%d %H:%M:%S') | $1" >> "$log_file"
}

# Desktop notification after long operations (no-op if notify-send unavailable)
notify_done() {
    local title="${1:-mypctools}"
    local message="${2:-Operation complete}"
    command -v notify-send &>/dev/null && notify-send "$title" "$message" 2>/dev/null || true
}
