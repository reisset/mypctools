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
    show_subheader "AI Tools" "Install Apps >"

    local choices
    choices=$(themed_choose_multi "Space=select, Enter=confirm, Empty=back" \
        "$(app_label "OpenCode" "opencode-bin" "" "" "opencode")" \
        "$(app_label "Claude Code" "" "" "" "claude")" \
        "$(app_label "Mistral Vibe CLI" "" "" "" "mistral-vibe")" \
        "$(app_label "Ollama" "ollama" "" "" "ollama")" \
        "$(app_label "LM Studio" "" "" "" "lmstudio")")

    if [[ -z "$choices" ]]; then
        return
    fi

    # Build preview list (strip badge for display and matching)
    local preview_items=()
    while read -r choice; do
        choice="${choice%  ✓}"
        preview_items+=("$choice")
    done <<< "$choices"
    show_preview_box "Selected for installation:" "${preview_items[@]}"
    echo ""

    if themed_confirm "Proceed with installation?"; then
        local total=${#preview_items[@]} current=0 succeeded=0 failed=0
        while read -r choice; do
            choice="${choice%  ✓}"
            ((current++))
            print_info "[$current/$total] $choice"
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
                    install_package "LM Studio" "" "" "" "install_lmstudio_fallback"
                    ;;
            esac
            [[ $? -eq 0 ]] && ((succeeded++)) || ((failed++))
        done <<< "$choices"
        show_install_summary $succeeded $failed $total
        notify_done "mypctools" "$succeeded/$total AI tools installed"
        themed_pause
    fi
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    show_ai_menu
fi
