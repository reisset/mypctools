#!/usr/bin/env bash
# mypctools/apps/browsers.sh
# Browser installation menu
# v0.2.0

_BROWSERS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$_BROWSERS_DIR/../lib/helpers.sh"
source "$_BROWSERS_DIR/../lib/theme.sh"
source "$_BROWSERS_DIR/../lib/package-manager.sh"

show_browsers_menu() {
    clear
    show_subheader "Browsers" "Install Apps >"

    local choices
    choices=$(themed_choose_multi "Space=select, Enter=confirm, Empty=back" \
        "Brave Browser" \
        "Firefox")

    if [[ -z "$choices" ]]; then
        return
    fi

    # Build preview list
    local preview_items=()
    while read -r choice; do
        preview_items+=("$choice")
    done <<< "$choices"
    show_preview_box "Selected for installation:" "${preview_items[@]}"
    echo ""

    if themed_confirm "Proceed with installation?"; then
        local total=${#preview_items[@]} current=0 succeeded=0 failed=0
        while read -r choice; do
            ((current++))
            print_info "[$current/$total] $choice"
            case "$choice" in
                "Brave Browser")
                    install_package "Brave Browser" "brave-browser" "brave-bin" "" "install_brave_fallback"
                    ;;
                "Firefox")
                    install_package "Firefox" "firefox" "firefox" "org.mozilla.firefox" ""
                    ;;
            esac
            [[ $? -eq 0 ]] && ((succeeded++)) || ((failed++))
        done <<< "$choices"
        show_install_summary $succeeded $failed $total
        notify_done "mypctools" "$succeeded/$total browsers installed"
        themed_pause
    fi
}

# Run if executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    show_browsers_menu
fi
