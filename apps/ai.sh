#!/usr/bin/env bash
# mypctools/apps/ai.sh
# AI tools installation menu
# v0.3.0

_AI_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$_AI_DIR/../lib/helpers.sh"
source "$_AI_DIR/../lib/theme.sh"
source "$_AI_DIR/../lib/package-manager.sh"

show_ai_menu() {
    clear
    show_subheader "AI Tools"

    local choices
    choices=$(themed_choose_multi "Space=select, Enter=confirm" \
        "OpenCode" \
        "Claude Code" \
        "Mistral Vibe CLI" \
        "Ollama" \
        "LM Studio" \
        "Back")

    if [[ -z "$choices" ]] || [[ "$choices" == "Back" ]]; then
        return
    fi

    echo ""
    show_subheader "Would install"
    while read -r choice; do
        [[ "$choice" != "Back" ]] && print_info "$choice"
    done <<< "$choices"
    echo ""

    if themed_confirm "Proceed with installation?"; then
        while read -r choice; do
            case "$choice" in
                "OpenCode")
                    install_package "OpenCode" "" "opencode-bin" "" "install_opencode_fallback"
                    ;;
                "Claude Code")
                    install_package "Claude Code" "" "" "" "install_claude_code_fallback"
                    ;;
                "Mistral Vibe CLI")
                    install_package "Mistral Vibe CLI" "" "" "" "install_mistral_vibe_fallback"
                    ;;
                "Ollama")
                    install_package "Ollama" "" "ollama" "" "install_ollama_fallback"
                    ;;
                "LM Studio")
                    install_package "LM Studio" "" "" "ai.lmstudio.LMStudio" ""
                    ;;
            esac
        done <<< "$choices"
        print_success "Done!"
        read -rp "Press Enter to continue..."
    fi
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    show_ai_menu
fi
