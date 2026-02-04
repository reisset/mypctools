#!/usr/bin/env bash
# mypctools/lib/theme.sh
# Theme colors, presets, icons, and styled component functions
# v0.3.0

# --- Theme Presets ---

_apply_theme_default() {
    THEME_PRIMARY="#00ffff"
    THEME_SECONDARY="#0087ff"
    THEME_MUTED="#6c6c6c"
    THEME_SUCCESS="#5fff00"
    THEME_WARNING="#ffaf00"
    THEME_ERROR="#ff0000"
    THEME_ACCENT="#af87ff"
}

_apply_theme_catppuccin() {
    THEME_PRIMARY="#89b4fa"    # Blue
    THEME_SECONDARY="#74c7ec"  # Sapphire
    THEME_MUTED="#6c7086"      # Overlay0
    THEME_SUCCESS="#a6e3a1"    # Green
    THEME_WARNING="#fab387"    # Peach
    THEME_ERROR="#f38ba8"      # Red
    THEME_ACCENT="#cba6f7"     # Mauve
}

_apply_theme_tokyo_night() {
    THEME_PRIMARY="#7aa2f7"    # Blue
    THEME_SECONDARY="#7dcfff"  # Cyan
    THEME_MUTED="#565f89"      # Comment
    THEME_SUCCESS="#9ece6a"    # Green
    THEME_WARNING="#ff9e64"    # Orange
    THEME_ERROR="#f7768e"      # Red
    THEME_ACCENT="#bb9af7"     # Purple
}

# Load theme from config or default
_load_theme() {
    local theme_file="$HOME/.config/mypctools/theme"
    local theme_name="default"
    if [[ -f "$theme_file" ]]; then
        theme_name=$(cat "$theme_file" 2>/dev/null)
    fi
    case "$theme_name" in
        catppuccin)   _apply_theme_catppuccin ;;
        tokyo-night)  _apply_theme_tokyo_night ;;
        *)            _apply_theme_default ;;
    esac
}

_load_theme

# --- GUM Environment Variables ---

_export_gum_env() {
    export GUM_CHOOSE_CURSOR_FOREGROUND="$THEME_PRIMARY"
    export GUM_CHOOSE_SELECTED_FOREGROUND="$THEME_PRIMARY"
    export GUM_CHOOSE_HEADER_FOREGROUND="$THEME_MUTED"
    export GUM_CHOOSE_CURSOR_PREFIX="> "
    export GUM_CHOOSE_PADDING="0 1"
    export GUM_CONFIRM_PROMPT_FOREGROUND="$THEME_PRIMARY"
    export GUM_CONFIRM_SELECTED_BACKGROUND="$THEME_PRIMARY"
    export GUM_FILTER_INDICATOR_FOREGROUND="$THEME_PRIMARY"
    export GUM_FILTER_MATCH_FOREGROUND="$THEME_ACCENT"
    export GUM_FILTER_PROMPT_FOREGROUND="$THEME_MUTED"
    export GUM_FILTER_PADDING="0 1"
    export GUM_SPIN_SPINNER_FOREGROUND="$THEME_PRIMARY"
    export GUM_SPIN_TITLE_FOREGROUND="$THEME_MUTED"
    export GUM_TABLE_BORDER_FOREGROUND="$THEME_SECONDARY"
    export GUM_TABLE_HEADER_FOREGROUND="$THEME_MUTED"
    export GUM_TABLE_SELECTED_FOREGROUND="$THEME_PRIMARY"
}

_export_gum_env

# --- Menu Icons (Nerd Font) ---

ICON_APPS=$'\uf019'        # nf-fa-download
ICON_SCRIPTS=$'\uf121'     # nf-fa-code
ICON_SYSTEM=$'\uf013'      # nf-fa-cog
ICON_AI=$'\uf0eb'          # nf-fa-lightbulb_o
ICON_BROWSER=$'\uf0ac'     # nf-fa-globe
ICON_GAMING=$'\uf11b'      # nf-fa-gamepad
ICON_MEDIA=$'\uf001'       # nf-fa-music
ICON_DEV=$'\uf120'         # nf-fa-terminal
ICON_UPDATE=$'\uf021'      # nf-fa-refresh
ICON_CLEANUP=$'\uf1b8'     # nf-fa-trash
ICON_SERVICE=$'\uf233'     # nf-fa-server
ICON_INFO=$'\uf05a'        # nf-fa-info_circle
ICON_EXIT=$'\uf2f5'        # nf-fa-sign_out
ICON_BACK=$'\uf060'        # nf-fa-arrow_left
ICON_THEME=$'\uf53f'       # nf-fa-palette

# --- Spinner Types ---

SPINNER_INSTALL="dot"
SPINNER_CLEANUP="pulse"

# --- Styled Components ---

# Styled section header with box
show_subheader() {
    local title="$1"
    local breadcrumb="$2"
    if [[ -n "$breadcrumb" ]]; then
        gum style --foreground "$THEME_MUTED" --margin "0 0 0 1" "$breadcrumb"
    fi
    gum style \
        --foreground "$THEME_PRIMARY" \
        --border rounded \
        --border-foreground "$THEME_SECONDARY" \
        --padding "0 2" \
        --margin "0 0 1 0" \
        "$title"
}

# Themed horizontal divider (auto-sizes to terminal width)
show_divider() {
    local width="${COLUMNS:-$(tput cols 2>/dev/null || echo 40)}"
    local line
    line=$(printf '─%.0s' $(seq 1 "$width"))
    gum style --foreground "$THEME_MUTED" "$line"
}

# Themed single-select menu
themed_choose() {
    local header="$1"
    shift
    gum choose --header "$header" "$@"
}

# Themed multi-select menu
themed_choose_multi() {
    local header="$1"
    shift
    gum choose --no-limit \
        --cursor-prefix "[ ] " \
        --selected-prefix "[✓] " \
        --unselected-prefix "[ ] " \
        --header "$header" \
        "$@"
}

# Themed confirmation prompt
themed_confirm() {
    gum confirm \
        --prompt.foreground "$THEME_PRIMARY" \
        --selected.background "$THEME_PRIMARY" \
        "$1"
}

# Themed spinner
themed_spin() {
    local spinner_type="${1:-dot}"
    local title="$2"
    shift 2
    gum spin \
        --spinner "$spinner_type" \
        --show-error \
        --title "$title" \
        -- "$@" < /dev/null
}

# Themed pager for long output
themed_pager() {
    gum pager --soft-wrap
}

# Themed pause
themed_pause() {
    echo ""
    gum style --foreground "$THEME_MUTED" "Press Enter to continue..."
    read -r
}

# Install summary after batch operations
show_install_summary() {
    local succeeded="$1" failed="$2" total="$3"
    echo ""
    if [[ "$failed" -eq 0 ]]; then
        gum style --foreground "$THEME_SUCCESS" "All $total package(s) processed successfully"
    else
        gum style --foreground "$THEME_WARNING" \
            "Completed: $succeeded/$total succeeded, $failed failed"
    fi
}

# Styled preview box for selections
show_preview_box() {
    local title="$1"
    shift
    local content=""
    for item in "$@"; do
        content+="  → $item"$'\n'
    done
    content="${content%$'\n'}"
    echo ""
    gum style \
        --border rounded \
        --border-foreground "$THEME_SECONDARY" \
        --padding "0 2" \
        --foreground "$THEME_MUTED" \
        "$title"
    gum style \
        --foreground "$THEME_PRIMARY" \
        --margin "0 0 0 2" \
        "$content"
}
