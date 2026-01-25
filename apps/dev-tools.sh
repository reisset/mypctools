#!/usr/bin/env bash
# mypctools/apps/dev-tools.sh
# Developer tools installation menu
# v0.3.0

_DEV_TOOLS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$_DEV_TOOLS_DIR/../lib/helpers.sh"
source "$_DEV_TOOLS_DIR/../lib/theme.sh"
source "$_DEV_TOOLS_DIR/../lib/package-manager.sh"

show_dev_tools_menu() {
    clear
    show_subheader "Developer Tools"

    local choices
    choices=$(themed_choose_multi "Space=select, Enter=confirm, Empty=back" \
        "Docker" \
        "LazyDocker" \
        "VSCode" \
        "Cursor" \
        ".NET SDK 10" \
        "Python (latest)")

    if [[ -z "$choices" ]]; then
        return
    fi

    echo ""
    show_subheader "Would install"
    while read -r choice; do
        print_info "$choice"
    done <<< "$choices"
    echo ""

    if themed_confirm "Proceed with installation?"; then
        while read -r choice; do
            case "$choice" in
                "Docker")
                    install_package "Docker" "docker.io" "docker" "" ""
                    ;;
                "LazyDocker")
                    install_package "LazyDocker" "" "lazydocker" "" "install_lazydocker_fallback"
                    ;;
                "VSCode")
                    install_package "VSCode" "code" "code" "com.visualstudio.code" "install_vscode_fallback"
                    ;;
                "Cursor")
                    install_package "Cursor" "" "cursor-bin" "" "install_cursor_fallback"
                    ;;
                ".NET SDK 10")
                    install_package ".NET SDK 10" "dotnet-sdk-10.0" "dotnet-sdk" "" "install_dotnet_fallback"
                    ;;
                "Python (latest)")
                    install_package "Python" "python3" "python" "" ""
                    ;;
            esac
        done <<< "$choices"
        print_success "Done!"
        read -rp "Press Enter to continue..."
    fi
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    show_dev_tools_menu
fi
