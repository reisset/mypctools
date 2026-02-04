#!/usr/bin/env bash
# mypctools/apps/flatpak-manager.sh
# TUI for managing Flatpak apps
# v0.11.0

_FLATPAK_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$_FLATPAK_DIR/../lib/helpers.sh"
source "$_FLATPAK_DIR/../lib/theme.sh"

# List installed flatpak apps in a table
list_flatpak_apps() {
    clear
    show_subheader "Installed Flatpak Apps" "Flatpak Manager >"

    local app_data
    app_data=$(flatpak list --app --columns=name,application,version 2>/dev/null)

    if [[ -z "$app_data" ]]; then
        print_warning "No Flatpak apps installed."
        themed_pause
        return
    fi

    # Build CSV for gum table
    local csv="Name,Application ID,Version"
    while IFS=$'\t' read -r name app_id version; do
        csv+=$'\n'"$name,$app_id,$version"
    done <<< "$app_data"

    echo "$csv" | gum table --widths 25,40,12 --height 20
    themed_pause
}

# Update all flatpak apps
update_flatpak_apps() {
    clear
    show_subheader "Update Flatpaks" "Flatpak Manager >"

    echo ""
    show_divider
    echo ""
    print_info "Updating all Flatpak apps..."
    flatpak update -y
    echo ""
    show_divider
    echo ""
    print_success "Flatpak update complete"
    notify_done "mypctools" "Flatpak update complete"
    themed_pause
}

# Remove unused runtimes
clean_flatpak_runtimes() {
    clear
    show_subheader "Clean Unused Runtimes" "Flatpak Manager >"

    local unused
    unused=$(flatpak uninstall --unused 2>/dev/null | head -20)

    if [[ -z "$unused" ]]; then
        print_info "No unused runtimes to remove."
        themed_pause
        return
    fi

    echo "$unused"
    echo ""
    if themed_confirm "Remove unused runtimes?"; then
        echo ""
        show_divider
        echo ""
        flatpak uninstall --unused -y
        echo ""
        show_divider
        echo ""
        print_success "Unused runtimes removed"
        notify_done "mypctools" "Flatpak cleanup complete"
    fi
    themed_pause
}

# Main flatpak manager menu
show_flatpak_manager() {
    if ! command_exists flatpak; then
        print_warning "Flatpak is not installed on this system."
        themed_pause
        return
    fi

    while true; do
        clear
        show_subheader "Flatpak Manager" "System Setup >"

        # Stats line
        local app_count runtime_count
        app_count=$(flatpak list --app 2>/dev/null | wc -l)
        runtime_count=$(flatpak list --runtime 2>/dev/null | wc -l)
        print_info "$app_count apps, $runtime_count runtimes installed"
        echo ""

        local choice
        choice=$(themed_choose "" \
            "List Installed Apps" \
            "Update All" \
            "Clean Unused Runtimes" \
            "$ICON_BACK  Back")

        case "$choice" in
            "List Installed Apps")
                list_flatpak_apps
                ;;
            "Update All")
                update_flatpak_apps
                ;;
            "Clean Unused Runtimes")
                clean_flatpak_runtimes
                ;;
            *"Back"|"")
                break
                ;;
        esac
    done
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    show_flatpak_manager
fi
