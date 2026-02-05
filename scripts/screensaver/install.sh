#!/usr/bin/env bash
# Screensaver Bundle Installer
# Installs tte, screensaver scripts, alacritty config,
# Hyprland window rules, and hypridle idle trigger

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MYPCTOOLS_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

source "$MYPCTOOLS_ROOT/lib/print.sh"
source "$MYPCTOOLS_ROOT/lib/distro-detect.sh"

ASSETS_DIR="$HOME/.local/share/mypctools-screensaver"
HYPR_CONF="$HOME/.config/hypr/hyprland.conf"
HYPRIDLE_CONF="$HOME/.config/hypr/hypridle.conf"
SCREENSAVER_ALACRITTY_CONF="$HOME/.config/alacritty/screensaver.toml"

MARKER_START="# >>> mypctools-screensaver >>>"

print_header "Screensaver Installer"
echo ""

# ---- Preflight Checks ----

if [[ -z "$HYPRLAND_INSTANCE_SIGNATURE" ]] && ! pgrep -x Hyprland &>/dev/null; then
    print_error "Hyprland not detected. This screensaver requires Hyprland."
    exit 1
fi

if ! command_exists alacritty; then
    print_error "Alacritty not installed. Install it first via My Scripts > Terminal - alacritty."
    exit 1
fi

if ! command_exists jq; then
    print_error "jq is required but not installed."
    exit 1
fi

if ! command_exists hyprctl; then
    print_error "hyprctl not found."
    exit 1
fi

# ---- Step 1: Install pipx + tte ----

print_info "Installing tte (Terminal Text Effects)..."

if ! command_exists pipx; then
    print_info "Installing pipx..."
    ensure_sudo || exit 1
    case "$DISTRO_TYPE" in
        arch)   sudo pacman -S --noconfirm --needed python-pipx ;;
        debian) sudo apt install -y pipx ;;
        fedora) sudo dnf install -y pipx ;;
        *)
            print_error "Cannot install pipx on this distro. Install it manually."
            exit 1
            ;;
    esac
    pipx ensurepath &>/dev/null
    export PATH="$HOME/.local/bin:$PATH"
    print_success "pipx installed"
fi

if command_exists tte; then
    print_success "tte already installed"
else
    print_info "Installing terminaltexteffects via pipx..."
    pipx install terminaltexteffects
    export PATH="$HOME/.local/bin:$PATH"
    if command_exists tte; then
        print_success "tte installed"
    else
        print_error "Failed to install tte. Try: pipx install terminaltexteffects"
        exit 1
    fi
fi

# ---- Step 2: Install hypridle ----

if ! command_exists hypridle; then
    print_info "Installing hypridle..."
    ensure_sudo || exit 1
    case "$DISTRO_TYPE" in
        arch)   sudo pacman -S --noconfirm --needed hypridle ;;
        debian) sudo apt install -y hypridle ;;
        fedora) sudo dnf install -y hypridle ;;
        *)      print_warning "Cannot auto-install hypridle. Install it manually." ;;
    esac
    if command_exists hypridle; then
        print_success "hypridle installed"
    else
        print_warning "hypridle not found after install attempt. Idle trigger won't work."
    fi
else
    print_success "hypridle already installed"
fi

# ---- Step 3: Copy assets ----

print_info "Installing screensaver assets..."
mkdir -p "$ASSETS_DIR"
cp "$SCRIPT_DIR/assets/linux-gang.txt" "$ASSETS_DIR/"
cp "$SCRIPT_DIR/assets/tux.txt" "$ASSETS_DIR/"
print_success "ASCII art installed to $ASSETS_DIR"

# ---- Step 4: Install scripts to ~/.local/bin/ ----

print_info "Installing screensaver scripts..."
mkdir -p "$HOME/.local/bin"
cp "$SCRIPT_DIR/scripts/mypctools-screensaver-launch" "$HOME/.local/bin/"
cp "$SCRIPT_DIR/scripts/mypctools-screensaver-cmd" "$HOME/.local/bin/"
chmod +x "$HOME/.local/bin/mypctools-screensaver-launch"
chmod +x "$HOME/.local/bin/mypctools-screensaver-cmd"
print_success "Scripts installed to ~/.local/bin/"

# ---- Step 5: Install alacritty screensaver config ----

print_info "Installing screensaver alacritty config..."
mkdir -p "$HOME/.config/alacritty"
cp "$SCRIPT_DIR/configs/screensaver.toml" "$SCREENSAVER_ALACRITTY_CONF"
print_success "Screensaver alacritty config installed"

# ---- Step 6: Add Hyprland window rules ----

if [[ -f "$HYPR_CONF" ]]; then
    if grep -q "$MARKER_START" "$HYPR_CONF"; then
        print_success "Hyprland window rules already configured"
    else
        print_info "Adding Hyprland window rules..."
        cp "$HYPR_CONF" "$HYPR_CONF.backup.$(date +%Y%m%d_%H%M%S)"
        print_info "Backed up hyprland.conf"

        cat >> "$HYPR_CONF" << 'HYPR_EOF'

# >>> mypctools-screensaver >>>
windowrule = fullscreen on, match:class ^(mypctools\.screensaver)$
windowrule = no_anim on, match:class ^(mypctools\.screensaver)$
windowrule = border_size 0, match:class ^(mypctools\.screensaver)$
# <<< mypctools-screensaver <<<
HYPR_EOF
        print_success "Hyprland window rules added"
    fi
else
    print_warning "hyprland.conf not found at $HYPR_CONF"
    print_warning "Add these rules manually:"
    echo '  windowrule = fullscreen on, match:class ^(mypctools\.screensaver)$'
    echo '  windowrule = no_anim on, match:class ^(mypctools\.screensaver)$'
    echo '  windowrule = border_size 0, match:class ^(mypctools\.screensaver)$'
fi

# ---- Step 7: Configure hypridle ----

print_info "Configuring hypridle for screensaver..."

if [[ -f "$HYPRIDLE_CONF" ]]; then
    if grep -q "$MARKER_START" "$HYPRIDLE_CONF"; then
        print_success "hypridle screensaver listener already configured"
    else
        cp "$HYPRIDLE_CONF" "$HYPRIDLE_CONF.backup.$(date +%Y%m%d_%H%M%S)"
        print_info "Backed up existing hypridle.conf"

        cat >> "$HYPRIDLE_CONF" << IDLE_EOF

# >>> mypctools-screensaver >>>
listener {
    timeout = 300
    on-timeout = $HOME/.local/bin/mypctools-screensaver-launch
}
# <<< mypctools-screensaver <<<
IDLE_EOF
        print_success "hypridle screensaver listener added (5 minute timeout)"
    fi
else
    mkdir -p "$(dirname "$HYPRIDLE_CONF")"
    cat > "$HYPRIDLE_CONF" << IDLE_EOF
# hypridle configuration
# Generated by mypctools screensaver installer

general {
    lock_cmd = pidof hyprlock || hyprlock
    before_sleep_cmd = loginctl lock-session
    after_sleep_cmd = hyprctl dispatch dpms on
}

# >>> mypctools-screensaver >>>
listener {
    timeout = 300
    on-timeout = $HOME/.local/bin/mypctools-screensaver-launch
}
# <<< mypctools-screensaver <<<
IDLE_EOF
    print_success "Created hypridle.conf with screensaver listener (5 minute timeout)"
fi

# ---- Step 8: Ensure hypridle autostart ----

if [[ -f "$HYPR_CONF" ]] && ! grep -q "exec-once = hypridle" "$HYPR_CONF"; then
    print_info "Adding hypridle to Hyprland autostart..."
    # Insert after the existing exec-once block
    last_exec_line=$(grep -n "exec-once" "$HYPR_CONF" | tail -1 | cut -d: -f1)
    if [[ -n "$last_exec_line" ]]; then
        sed -i "${last_exec_line}a exec-once = hypridle" "$HYPR_CONF"
    else
        echo "exec-once = hypridle" >> "$HYPR_CONF"
    fi
    print_success "Added hypridle to Hyprland autostart"
fi

# Start hypridle if not running
if ! pgrep -x hypridle &>/dev/null; then
    hypridle &>/dev/null &
    disown
    print_success "hypridle started"
else
    # Restart to pick up new config
    killall hypridle 2>/dev/null
    sleep 0.5
    hypridle &>/dev/null &
    disown
    print_success "hypridle restarted with new config"
fi

# ---- Done ----

echo ""
print_success "Screensaver installation complete!"
echo ""
print_info "The screensaver will activate after 5 minutes of idle."
print_info "To test manually: mypctools-screensaver-launch"
print_info "To change idle timeout: edit ~/.config/hypr/hypridle.conf"
echo ""
