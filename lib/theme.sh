#!/usr/bin/env bash
# mypctools/lib/theme.sh
# Theme colors and styled component functions
# v0.1.0

# Theme Colors (ANSI 256)
THEME_PRIMARY=51       # Cyan/teal - headers, accents, cursor
THEME_SECONDARY=33     # Soft blue - borders, secondary elements
THEME_MUTED=242        # Gray - help text, dimmed info

# Styled section header line
show_subheader() {
    gum style --foreground "$THEME_PRIMARY" "═══ $1 ═══"
    echo ""
}

# Themed single-select menu
# Usage: themed_choose "Header text" "Option 1" "Option 2" ...
themed_choose() {
    local header="$1"
    shift
    gum choose \
        --cursor "> " \
        --cursor.foreground "$THEME_PRIMARY" \
        --selected.foreground "$THEME_PRIMARY" \
        --header.foreground "$THEME_MUTED" \
        --header "$header" \
        "$@"
}

# Themed multi-select menu
# Usage: themed_choose_multi "Header text" "Option 1" "Option 2" ...
themed_choose_multi() {
    local header="$1"
    shift
    gum choose --no-limit \
        --cursor "> " \
        --cursor.foreground "$THEME_PRIMARY" \
        --selected.foreground "$THEME_PRIMARY" \
        --cursor-prefix "[ ] " \
        --selected-prefix "[✓] " \
        --unselected-prefix "[ ] " \
        --header.foreground "$THEME_MUTED" \
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
