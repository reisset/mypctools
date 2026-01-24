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
        "Zen Browser" \
        "Back")

    if [[ -z "$choices" ]] || [[ "$choices" == "Back" ]]; then
        return
    fi

    echo ""
    print_header "Would install the following:"
    echo "$choices" | while read -r choice; do
        [[ "$choice" != "Back" ]] && print_info "$choice"
    done
    echo ""

    gum confirm "Proceed with installation?" && {
        echo "$choices" | while read -r choice; do
            case "$choice" in
                "Brave Browser")
                    install_package "Brave Browser" "brave-browser" "brave-bin" "com.brave.Browser" ""
                    ;;
                "Firefox")
                    install_package "Firefox" "firefox" "firefox" "org.mozilla.firefox" ""
                    ;;
                "Zen Browser")
                    install_package "Zen Browser" "" "zen-browser-bin" "io.github.nickvergessen.zenbrowser" ""
                    ;;
            esac
        done
        print_success "Done!"
        read -rp "Press Enter to continue..."
    }
}

# Run if executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    show_browsers_menu
fi
