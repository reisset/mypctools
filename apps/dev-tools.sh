#!/usr/bin/env bash
# mypctools/apps/dev-tools.sh
# Developer tools installation menu
# v0.1.0

_DEV_TOOLS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$_DEV_TOOLS_DIR/../lib/helpers.sh"
source "$_DEV_TOOLS_DIR/../lib/package-manager.sh"

show_dev_tools_menu() {
    print_header "Developer Tools"

    local choices
    choices=$(gum choose --no-limit --header "Select tools (Space=select, Enter=confirm):" \
        "Docker" \
        "LazyDocker" \
        "VSCode" \
        "Cursor" \
        "LM Studio" \
        "Ollama" \
        ".NET SDK" \
        "Python (latest)" \
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
                "Docker")
                    install_package "Docker" "docker.io" "docker" "" ""
                    ;;
                "LazyDocker")
                    install_package "LazyDocker" "" "lazydocker" "" ""
                    ;;
                "VSCode")
                    install_package "VSCode" "code" "code" "com.visualstudio.code" "install_vscode_fallback"
                    ;;
                "Cursor")
                    install_package "Cursor" "" "cursor-bin" "" ""
                    ;;
                "LM Studio")
                    install_package "LM Studio" "" "" "ai.lmstudio.LMStudio" ""
                    ;;
                "Ollama")
                    install_package "Ollama" "" "ollama" "" ""
                    ;;
                ".NET SDK")
                    install_package ".NET SDK" "dotnet-sdk-8.0" "dotnet-sdk" "" ""
                    ;;
                "Python (latest)")
                    install_package "Python" "python3" "python" "" ""
                    ;;
            esac
        done
        print_success "Done!"
        read -rp "Press Enter to continue..."
    }
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    show_dev_tools_menu
fi
