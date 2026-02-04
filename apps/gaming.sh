#!/usr/bin/env bash
# mypctools/apps/gaming.sh
# Gaming apps installation menu
# v0.2.0

_GAMING_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$_GAMING_DIR/../lib/helpers.sh"
source "$_GAMING_DIR/../lib/theme.sh"
source "$_GAMING_DIR/../lib/package-manager.sh"

show_gaming_menu() {
    clear
    show_subheader "Gaming" "Install Apps >"

    local choices
    choices=$(themed_choose_multi "Space=select, Enter=confirm, Empty=back" \
        "Steam" \
        "Lutris" \
        "ProtonUp-Qt" \
        "Heroic Games Launcher")

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
            [[ $? -eq 0 ]] && ((succeeded++)) || ((failed++))
        done <<< "$choices"
        show_install_summary $succeeded $failed $total
        themed_pause
    fi
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    show_gaming_menu
fi
