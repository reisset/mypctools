#!/usr/bin/env bash
# mypctools/apps/gaming.sh
# Gaming apps installation menu
# v0.1.0

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../lib/helpers.sh"
source "$SCRIPT_DIR/../lib/package-manager.sh"

show_gaming_menu() {
    print_header "Gaming"

    local choices
    choices=$(gum choose --no-limit --header "Select gaming apps to install:" \
        "Steam" \
        "Lutris" \
        "ProtonUp-Qt" \
        "Heroic Games Launcher" \
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
                "Steam")
                    install_package "Steam" "steam" "steam" "com.valvesoftware.Steam" ""
                    ;;
                "Lutris")
                    install_package "Lutris" "lutris" "lutris" "net.lutris.Lutris" ""
                    ;;
                "ProtonUp-Qt")
                    install_package "ProtonUp-Qt" "" "protonup-qt" "net.davidotek.pupgui2" ""
                    ;;
                "Heroic Games Launcher")
                    install_package "Heroic Games Launcher" "" "heroic-games-launcher-bin" "com.heroicgameslauncher.hgl" ""
                    ;;
            esac
        done
        print_success "Done!"
        read -rp "Press Enter to continue..."
    }
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    show_gaming_menu
fi
