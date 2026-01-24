#!/usr/bin/env bash
# mypctools/apps/browsers.sh
# Browser installation menu
# v0.1.0

_BROWSERS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$_BROWSERS_DIR/../lib/helpers.sh"
source "$_BROWSERS_DIR/../lib/package-manager.sh"

show_browsers_menu() {
    print_header "Browsers"

    local choices
    choices=$(gum choose --no-limit --header "Select browsers (Space=select, Enter=confirm):" \
        "Brave Browser" \
        "Firefox" \
        "Back")

    if [[ -z "$choices" ]] || [[ "$choices" == "Back" ]]; then
        return
    fi

    echo ""
    print_header "Would install the following:"
    while read -r choice; do
        [[ "$choice" != "Back" ]] && print_info "$choice"
    done <<< "$choices"
    echo ""

    gum confirm "Proceed with installation?" && {
        while read -r choice; do
            case "$choice" in
                "Brave Browser")
                    install_package "Brave Browser" "brave-browser" "brave-bin" "" "install_brave_fallback"
                    ;;
                "Firefox")
                    install_package "Firefox" "firefox" "firefox" "org.mozilla.firefox" ""
                    ;;
            esac
        done <<< "$choices"
        print_success "Done!"
        read -rp "Press Enter to continue..."
    }
}

# Run if executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    show_browsers_menu
fi
