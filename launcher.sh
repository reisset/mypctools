#!/usr/bin/env bash
# mypctools/launcher.sh
# Main TUI launcher for mypctools
# v0.1.0

set -e

MYPCTOOLS_ROOT="$(cd "$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")" && pwd)"
source "$MYPCTOOLS_ROOT/lib/helpers.sh"
source "$MYPCTOOLS_ROOT/lib/distro-detect.sh"

VERSION="0.1.0"

# Check gum is installed
if ! command_exists gum; then
    print_error "gum is not installed. Run ./install.sh first."
    exit 1
fi

# Submenus
show_install_apps_menu() {
    while true; do
        local choice
        choice=$(gum choose --header "Install Apps" \
            "Browsers" \
            "Gaming" \
            "Media" \
            "Dev Tools" \
            "CLI Utilities" \
            "Back")

        case "$choice" in
            "Browsers")
                source "$MYPCTOOLS_ROOT/apps/browsers.sh"
                show_browsers_menu
                ;;
            "Gaming")
                source "$MYPCTOOLS_ROOT/apps/gaming.sh"
                show_gaming_menu
                ;;
            "Media")
                source "$MYPCTOOLS_ROOT/apps/media.sh"
                show_media_menu
                ;;
            "Dev Tools")
                source "$MYPCTOOLS_ROOT/apps/dev-tools.sh"
                show_dev_tools_menu
                ;;
            "CLI Utilities")
                source "$MYPCTOOLS_ROOT/apps/cli-utils.sh"
                show_cli_utils_menu
                ;;
            "Back"|"")
                break
                ;;
        esac
    done
}

show_scripts_menu() {
    while true; do
        local choice
        choice=$(gum choose --header "My Scripts" \
            "Bash Setup" \
            "Screensavers" \
            "Claude Setup" \
            "Back")

        case "$choice" in
            "Bash Setup")
                while true; do
                    local action
                    action=$(gum choose --header "Bash Setup" \
                        "Install" \
                        "Uninstall" \
                        "Back")

                    case "$action" in
                        "Install")
                            if [[ -f "$MYPCTOOLS_ROOT/scripts/bash/install.sh" ]]; then
                                bash "$MYPCTOOLS_ROOT/scripts/bash/install.sh"
                            else
                                print_warning "Install script not found."
                            fi
                            read -rp "Press Enter to continue..."
                            ;;
                        "Uninstall")
                            if [[ -f "$MYPCTOOLS_ROOT/scripts/bash/uninstall.sh" ]]; then
                                bash "$MYPCTOOLS_ROOT/scripts/bash/uninstall.sh"
                            else
                                print_warning "No uninstall script found."
                            fi
                            read -rp "Press Enter to continue..."
                            ;;
                        "Back"|"")
                            break
                            ;;
                    esac
                done
                ;;
            "Screensavers")
                while true; do
                    local action
                    action=$(gum choose --header "Screensavers" \
                        "Install" \
                        "Uninstall" \
                        "Back")

                    case "$action" in
                        "Install")
                            if [[ -f "$MYPCTOOLS_ROOT/scripts/screensavers/install.sh" ]]; then
                                bash "$MYPCTOOLS_ROOT/scripts/screensavers/install.sh"
                            else
                                print_warning "Install script not found."
                            fi
                            read -rp "Press Enter to continue..."
                            ;;
                        "Uninstall")
                            if [[ -f "$MYPCTOOLS_ROOT/scripts/screensavers/uninstall.sh" ]]; then
                                bash "$MYPCTOOLS_ROOT/scripts/screensavers/uninstall.sh"
                            else
                                print_warning "No uninstall script found."
                            fi
                            read -rp "Press Enter to continue..."
                            ;;
                        "Back"|"")
                            break
                            ;;
                    esac
                done
                ;;
            "Claude Setup")
                while true; do
                    local action
                    action=$(gum choose --header "Claude Setup" \
                        "Install" \
                        "Uninstall" \
                        "Back")

                    case "$action" in
                        "Install")
                            if [[ -f "$MYPCTOOLS_ROOT/scripts/claude/install.sh" ]]; then
                                bash "$MYPCTOOLS_ROOT/scripts/claude/install.sh"
                            else
                                print_warning "Install script not found."
                            fi
                            read -rp "Press Enter to continue..."
                            ;;
                        "Uninstall")
                            if [[ -f "$MYPCTOOLS_ROOT/scripts/claude/uninstall.sh" ]]; then
                                bash "$MYPCTOOLS_ROOT/scripts/claude/uninstall.sh"
                            else
                                print_warning "No uninstall script found."
                            fi
                            read -rp "Press Enter to continue..."
                            ;;
                        "Back"|"")
                            break
                            ;;
                    esac
                done
                ;;
            "Back"|"")
                break
                ;;
        esac
    done
}

show_system_setup_menu() {
    while true; do
        local choice
        choice=$(gum choose --header "System Setup" \
            "System Info" \
            "Coming Soon..." \
            "Back")

        case "$choice" in
            "System Info")
                echo ""
                print_header "System Information"
                print_info "Distro: $DISTRO_NAME"
                print_info "Type: $DISTRO_TYPE"
                print_info "Kernel: $(uname -r)"
                print_info "Shell: $SHELL"
                echo ""
                read -rp "Press Enter to continue..."
                ;;
            "Coming Soon...")
                print_info "More system setup options coming in future versions."
                read -rp "Press Enter to continue..."
                ;;
            "Back"|"")
                break
                ;;
        esac
    done
}

show_settings_menu() {
    while true; do
        local choice
        choice=$(gum choose --header "Settings" \
            "About" \
            "Check for Updates" \
            "Back")

        case "$choice" in
            "About")
                echo ""
                show_header "mypctools v$VERSION"
                echo ""
                print_info "A personal TUI for managing scripts and apps"
                print_info "Built with Gum by Charm"
                print_info "https://github.com/reisset/mypctools"
                echo ""
                read -rp "Press Enter to continue..."
                ;;
            "Check for Updates")
                print_info "[STUB] Would check for updates via git pull"
                read -rp "Press Enter to continue..."
                ;;
            "Back"|"")
                break
                ;;
        esac
    done
}

show_windows_menu() {
    echo ""
    print_header "Windows PowerShell Scripts"
    print_warning "These scripts are for Windows and cannot be run from here."
    print_info "Location: $MYPCTOOLS_ROOT/windows/powershell/"
    print_info "GitHub: https://github.com/reisset/mypowershell"
    echo ""

    gum confirm "Open folder in file manager?" && {
        if command_exists xdg-open; then
            xdg-open "$MYPCTOOLS_ROOT/windows/powershell/" 2>/dev/null || true
        fi
    }
}

# Main menu
main_menu() {
    while true; do
        clear
        show_header "mypctools v$VERSION"
        echo ""

        local choice
        choice=$(gum choose \
            "Install Apps" \
            "My Scripts" \
            "System Setup" \
            "Windows Scripts (Reference)" \
            "Settings" \
            "Exit")

        case "$choice" in
            "Install Apps")
                show_install_apps_menu
                ;;
            "My Scripts")
                show_scripts_menu
                ;;
            "System Setup")
                show_system_setup_menu
                ;;
            "Windows Scripts (Reference)")
                show_windows_menu
                ;;
            "Settings")
                show_settings_menu
                ;;
            "Exit"|"")
                print_success "Goodbye!"
                exit 0
                ;;
        esac
    done
}

# Run
main_menu
