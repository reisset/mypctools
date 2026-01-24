#!/usr/bin/env bash
# mypctools/apps/cli-utils.sh
# CLI utilities installation menu
# v0.1.0

_CLI_UTILS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$_CLI_UTILS_DIR/../lib/helpers.sh"
source "$_CLI_UTILS_DIR/../lib/package-manager.sh"

show_cli_utils_menu() {
    print_header "CLI Utilities"

    local choices
    choices=$(gum choose --no-limit --header "Select utilities (Space=select, Enter=confirm):" \
        "fzf - Fuzzy finder" \
        "bat - Better cat" \
        "eza - Better ls" \
        "ripgrep - Better grep" \
        "fd-find - Better find" \
        "btop - Better htop" \
        "tldr - Simplified man pages" \
        "zoxide - Smarter cd" \
        "caligula - ISO burner" \
        "gum - TUI toolkit" \
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
                "fzf - Fuzzy finder")
                    install_package "fzf" "fzf" "fzf" "" ""
                    ;;
                "bat - Better cat")
                    install_package "bat" "bat" "bat" "" ""
                    ;;
                "eza - Better ls")
                    install_package "eza" "eza" "eza" "" ""
                    ;;
                "ripgrep - Better grep")
                    install_package "ripgrep" "ripgrep" "ripgrep" "" ""
                    ;;
                "fd-find - Better find")
                    install_package "fd-find" "fd-find" "fd" "" ""
                    ;;
                "btop - Better htop")
                    install_package "btop" "btop" "btop" "" ""
                    ;;
                "tldr - Simplified man pages")
                    install_package "tldr" "tldr" "tldr" "" ""
                    ;;
                "zoxide - Smarter cd")
                    install_package "zoxide" "zoxide" "zoxide" "" ""
                    ;;
                "caligula - ISO burner")
                    install_package "caligula" "" "caligula" "" ""
                    ;;
                "gum - TUI toolkit")
                    install_package "gum" "gum" "gum" "" ""
                    ;;
            esac
        done
        print_success "Done!"
        read -rp "Press Enter to continue..."
    }
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    show_cli_utils_menu
fi
