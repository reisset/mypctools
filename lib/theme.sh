#!/usr/bin/env bash
# mypctools/lib/theme.sh
# Theme colors and styled component functions
# v0.2.0

# Theme Colors (ANSI 256)
THEME_PRIMARY=51       # Cyan/teal - headers, accents, cursor
THEME_SECONDARY=33     # Soft blue - borders, secondary elements
THEME_MUTED=242        # Gray - help text, dimmed info

# State Colors (ANSI 256)
THEME_SUCCESS=82       # Green - success messages
THEME_WARNING=214      # Orange - warnings
THEME_ERROR=196        # Red - errors
THEME_ACCENT=141       # Purple - highlights/accents

# Spinner Types
SPINNER_INSTALL="dot"      # Package installs
SPINNER_UPDATE="globe"     # System updates
SPINNER_CLEANUP="pulse"    # Cleanup operations
SPINNER_DOWNLOAD="moon"    # Downloads

# Styled section header with box
show_subheader() {
    gum style \
        --foreground "$THEME_PRIMARY" \
        --border rounded \
        --border-foreground "$THEME_SECONDARY" \
        --padding "0 2" \
        --margin "0 0 1 0" \
        "$1"
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

# Themed single-select from stdin (for dynamic lists)
# Usage: echo -e "opt1\nopt2" | themed_choose_stdin "Header"
themed_choose_stdin() {
    local header="$1"
    gum choose \
        --cursor "> " \
        --cursor.foreground "$THEME_PRIMARY" \
        --selected.foreground "$THEME_PRIMARY" \
        --header.foreground "$THEME_MUTED" \
        --header "$header"
}

# Themed filter (fuzzy search from stdin)
# Usage: echo -e "opt1\nopt2" | themed_filter "Placeholder"
themed_filter() {
    local placeholder="${1:-Type to filter...}"
    gum filter \
        --placeholder "$placeholder" \
        --indicator "> " \
        --indicator.foreground "$THEME_PRIMARY" \
        --match.foreground "$THEME_ACCENT" \
        --prompt.foreground "$THEME_MUTED"
}

# Themed spinner
# Usage: themed_spin "install" "Installing..." command args
themed_spin() {
    local spinner_type="${1:-dot}"
    local title="$2"
    shift 2
    gum spin \
        --spinner "$spinner_type" \
        --spinner.foreground "$THEME_PRIMARY" \
        --title.foreground "$THEME_MUTED" \
        --show-error \
        --title "$title" \
        -- "$@" < /dev/null
}

# Themed pager for long output
# Usage: command | themed_pager
themed_pager() {
    gum pager --soft-wrap
}

# Show keyboard hints
show_keyhints() {
    local hints="${1:-↑/↓ Navigate  •  Enter Select  •  Esc Back}"
    gum style \
        --foreground "$THEME_MUTED" \
        --margin "1 0 0 0" \
        "$hints"
}

# Styled preview box for selections
# Usage: show_preview_box "Title" "item1" "item2" ...
show_preview_box() {
    local title="$1"
    shift
    local content=""
    for item in "$@"; do
        content+="  → $item"$'\n'
    done
    content="${content%$'\n'}"  # Remove trailing newline
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
