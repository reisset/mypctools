#!/usr/bin/env bash
# mypctools/apps/dev-tools.sh
# Developer tools installation menu
# v0.5.0

_DEV_TOOLS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$_DEV_TOOLS_DIR/../lib/helpers.sh"
source "$_DEV_TOOLS_DIR/../lib/theme.sh"
source "$_DEV_TOOLS_DIR/../lib/package-manager.sh"

show_dev_tools_menu() {
    clear
    show_subheader "Developer Tools" "Install Apps >"

    local choices
    choices=$(themed_choose_multi "Space=select, Enter=confirm, Empty=back" \
        "Docker" \
        "Docker Compose" \
        "LazyDocker" \
        "Lazygit" \
        "VSCode" \
        "Cursor" \
        ".NET SDK 10" \
        "Python (latest)")

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
                "Docker")
                    install_package "Docker" "docker.io" "docker" "" ""
                    ;;
                "Docker Compose")
                    install_package "Docker Compose" "docker-compose-plugin" "docker-compose" "" "install_docker_compose_fallback"
                    ;;
                "LazyDocker")
                    install_package "LazyDocker" "" "lazydocker" "" "install_lazydocker_fallback"
                    ;;
                "Lazygit")
                    install_package "Lazygit" "" "lazygit" "" "install_lazygit_fallback"
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
            [[ $? -eq 0 ]] && ((succeeded++)) || ((failed++))
        done <<< "$choices"
        show_install_summary $succeeded $failed $total
        themed_pause
    fi
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    show_dev_tools_menu
fi
