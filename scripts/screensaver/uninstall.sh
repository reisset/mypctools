#!/usr/bin/env bash
# Screensaver Bundle Uninstaller
# Removes scripts, configs, and Hyprland/hypridle rules
# Does NOT uninstall tte, pipx, or hypridle

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MYPCTOOLS_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

source "$MYPCTOOLS_ROOT/lib/helpers.sh"

SCREENSAVER_CLASS="mypctools.screensaver"
ASSETS_DIR="$HOME/.local/share/mypctools-screensaver"
HYPR_CONF="$HOME/.config/hypr/hyprland.conf"
HYPRIDLE_CONF="$HOME/.config/hypr/hypridle.conf"
SCREENSAVER_ALACRITTY_CONF="$HOME/.config/alacritty/screensaver.toml"

MARKER_START="# >>> mypctools-screensaver >>>"
MARKER_END="# <<< mypctools-screensaver <<<"

print_header "Screensaver Uninstaller"
echo ""

# Kill running screensaver windows
if command_exists hyprctl; then
    pids=$(hyprctl clients -j 2>/dev/null | jq -r '.[] | select(.class == "'"$SCREENSAVER_CLASS"'") | .pid' 2>/dev/null)
    if [[ -n "$pids" ]]; then
        echo "$pids" | while read -r pid; do
            kill "$pid" 2>/dev/null
        done
        print_success "Killed running screensaver windows"
    fi
fi

# Remove scripts from ~/.local/bin/
for script in mypctools-screensaver-launch mypctools-screensaver-cmd; do
    if [[ -f "$HOME/.local/bin/$script" ]]; then
        rm "$HOME/.local/bin/$script"
        print_success "Removed $script"
    fi
done

# Remove assets
if [[ -d "$ASSETS_DIR" ]]; then
    rm -rf "$ASSETS_DIR"
    print_success "Removed screensaver assets"
fi

# Remove alacritty screensaver config
if [[ -f "$SCREENSAVER_ALACRITTY_CONF" ]]; then
    rm "$SCREENSAVER_ALACRITTY_CONF"
    print_success "Removed screensaver alacritty config"
fi

# Remove Hyprland window rules (between markers)
if [[ -f "$HYPR_CONF" ]] && grep -q "$MARKER_START" "$HYPR_CONF"; then
    sed -i "/$MARKER_START/,/$MARKER_END/d" "$HYPR_CONF"
    sed -i '/^$/N;/^\n$/d' "$HYPR_CONF"
    print_success "Removed Hyprland window rules"
fi

# Remove hypridle screensaver listener (between markers)
if [[ -f "$HYPRIDLE_CONF" ]] && grep -q "$MARKER_START" "$HYPRIDLE_CONF"; then
    sed -i "/$MARKER_START/,/$MARKER_END/d" "$HYPRIDLE_CONF"
    sed -i '/^$/N;/^\n$/d' "$HYPRIDLE_CONF"
    print_success "Removed hypridle screensaver listener"
fi

# Remove hypridle autostart if no other listeners remain
if [[ -f "$HYPR_CONF" ]] && grep -q "^exec-once = hypridle$" "$HYPR_CONF"; then
    if [[ ! -f "$HYPRIDLE_CONF" ]] || ! grep -q "listener {" "$HYPRIDLE_CONF"; then
        sed -i '/^exec-once = hypridle$/d' "$HYPR_CONF"
        print_success "Removed hypridle from Hyprland autostart"
        killall hypridle 2>/dev/null && print_info "Stopped hypridle"
    else
        print_info "Other hypridle listeners exist, keeping autostart entry"
    fi
fi

echo ""
print_success "Screensaver uninstall complete!"
echo ""
print_info "Note: tte and pipx were NOT removed (you may use them elsewhere)."
print_info "To remove: pipx uninstall terminaltexteffects && sudo pacman -R python-pipx"
print_info "hypridle was NOT removed. To remove: sudo pacman -R hypridle"
echo ""
