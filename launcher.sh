#!/usr/bin/env bash
# mypctools/launcher.sh
# Main TUI launcher for mypctools
# v0.3.0

set -e

MYPCTOOLS_ROOT="$(cd "$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")" && pwd)"
source "$MYPCTOOLS_ROOT/lib/helpers.sh"
source "$MYPCTOOLS_ROOT/lib/theme.sh"
source "$MYPCTOOLS_ROOT/lib/distro-detect.sh"

VERSION="0.3.0"

# Cleanup on interrupt
cleanup() {
    tput cnorm 2>/dev/null  # Show cursor
    stty echo 2>/dev/null   # Re-enable echo
    echo ""
    exit 130
}
trap cleanup SIGINT SIGTERM

# Don't run as root
if check_root; then
    print_error "Do not run as root. Use your normal user."
    exit 1
fi

# Check gum is installed
if ! command_exists gum; then
    print_error "gum is not installed. Run ./install.sh first."
    exit 1
fi

# Submenus
show_install_apps_menu() {
    while true; do
        clear
        show_subheader "Install Apps"
        local choice
        choice=$(themed_choose "" \
            "AI" \
            "Browsers" \
            "Gaming" \
            "Media" \
            "Dev Tools" \
            "CLI Utilities" \
            "Back")

        case "$choice" in
            "AI")
                source "$MYPCTOOLS_ROOT/apps/ai.sh"
                show_ai_menu
                ;;
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
        clear
        show_subheader "My Scripts"
        local choice
        choice=$(themed_choose "" \
            "Bash Setup" \
            "Screensavers" \
            "Claude Setup" \
            "Back")

        case "$choice" in
            "Bash Setup")
                while true; do
                    clear
                    show_subheader "Bash Setup"
                    local action
                    action=$(themed_choose "" \
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
                                print_warning "Uninstall script not found."
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
                    clear
                    show_subheader "Screensavers"
                    local action
                    action=$(themed_choose "" \
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
                                print_warning "Uninstall script not found."
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
                    clear
                    show_subheader "Claude Setup"
                    local action
                    action=$(themed_choose "" \
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
                                print_warning "Uninstall script not found."
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
        clear
        show_subheader "System Setup"
        local choice
        choice=$(themed_choose "" \
            "System Info" \
            "Coming Soon..." \
            "Back")

        case "$choice" in
            "System Info")
                clear
                show_subheader "System Information"

                # User@Host
                print_info "User: $USER@$(hostname)"

                # OS
                print_info "OS: $DISTRO_NAME"

                # Host (hardware model)
                local host_model=""
                [[ -f /sys/devices/virtual/dmi/id/product_name ]] && host_model=$(cat /sys/devices/virtual/dmi/id/product_name 2>/dev/null)
                [[ -n "$host_model" ]] && print_info "Host: $host_model"

                # Kernel
                print_info "Kernel: $(uname -r)"

                # Uptime
                local uptime_str
                uptime_str=$(uptime -p 2>/dev/null | sed 's/up //')
                print_info "Uptime: $uptime_str"

                # Packages
                local pkg_count=""
                if command_exists dpkg; then
                    pkg_count="$(dpkg --get-selections 2>/dev/null | wc -l) (dpkg)"
                elif command_exists pacman; then
                    pkg_count="$(pacman -Q 2>/dev/null | wc -l) (pacman)"
                fi
                if command_exists flatpak; then
                    local flatpak_count
                    flatpak_count=$(flatpak list --app 2>/dev/null | wc -l)
                    [[ -n "$pkg_count" ]] && pkg_count="$pkg_count, $flatpak_count (flatpak)" || pkg_count="$flatpak_count (flatpak)"
                fi
                [[ -n "$pkg_count" ]] && print_info "Packages: $pkg_count"

                # Shell
                print_info "Shell: $(basename "$SHELL")"

                # DE / WM
                [[ -n "$XDG_CURRENT_DESKTOP" ]] && print_info "DE: $XDG_CURRENT_DESKTOP"
                [[ -n "$XDG_SESSION_TYPE" ]] && print_info "Session: $XDG_SESSION_TYPE"

                # Terminal
                [[ -n "$TERM" ]] && print_info "Terminal: $TERM"

                # CPU
                local cpu_model
                cpu_model=$(grep -m1 'model name' /proc/cpuinfo 2>/dev/null | cut -d: -f2 | sed 's/^ //')
                [[ -n "$cpu_model" ]] && print_info "CPU: $cpu_model"

                # GPU
                local gpu_info
                gpu_info=$(lspci 2>/dev/null | grep -i 'vga\|3d\|display' | head -1 | sed 's/.*: //')
                [[ -n "$gpu_info" ]] && print_info "GPU: $gpu_info"

                # Memory
                local mem_total mem_used
                mem_total=$(grep MemTotal /proc/meminfo 2>/dev/null | awk '{printf "%.1f", $2/1024/1024}')
                mem_used=$(free -m 2>/dev/null | awk '/Mem:/ {printf "%.1f", $3/1024}')
                [[ -n "$mem_total" ]] && print_info "Memory: ${mem_used}GB / ${mem_total}GB"

                # Disk
                local disk_info
                disk_info=$(df -h / 2>/dev/null | awk 'NR==2 {print $3 " / " $2 " (" $5 " used)"}')
                [[ -n "$disk_info" ]] && print_info "Disk (/): $disk_info"

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
        clear
        show_subheader "Settings"
        local choice
        choice=$(themed_choose "" \
            "About" \
            "Check for Updates" \
            "Back")

        case "$choice" in
            "About")
                clear
                show_title "mypctools v$VERSION"
                print_info "A personal TUI for managing scripts and apps"
                print_info "Built with Gum by Charm"
                print_info "https://github.com/reisset/mypctools"
                echo ""
                read -rp "Press Enter to continue..."
                ;;
            "Check for Updates")
                clear
                show_subheader "Check for Updates"
                print_info "Checking for updates..."
                if git -C "$MYPCTOOLS_ROOT" fetch origin main &>/dev/null; then
                    local behind
                    behind=$(git -C "$MYPCTOOLS_ROOT" rev-list HEAD..origin/main --count 2>/dev/null)
                    if [[ "$behind" -gt 0 ]]; then
                        print_warning "$behind new commit(s) available"
                        if themed_confirm "Pull updates now?"; then
                            git -C "$MYPCTOOLS_ROOT" pull origin main
                            print_success "Updated! Restart mypctools to use new version."
                        fi
                    else
                        print_success "Already up to date!"
                    fi
                else
                    print_error "Failed to check for updates"
                fi
                read -rp "Press Enter to continue..."
                ;;
            "Back"|"")
                break
                ;;
        esac
    done
}

show_windows_menu() {
    clear
    show_subheader "Windows PowerShell Scripts"
    print_warning "These scripts are for Windows and cannot be run from here."
    print_info "Location: $MYPCTOOLS_ROOT/windows/powershell/"
    print_info "GitHub: https://github.com/reisset/mypowershell"
    echo ""

    if themed_confirm "Open folder in file manager?"; then
        if command_exists xdg-open; then
            xdg-open "$MYPCTOOLS_ROOT/windows/powershell/" 2>/dev/null || true
        fi
    fi
}

# Main menu
main_menu() {
    while true; do
        clear
        show_title "mypctools v$VERSION"

        local choice
        choice=$(themed_choose "" \
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
