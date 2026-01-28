#!/usr/bin/env bash
# mypctools/launcher.sh
# Main TUI launcher for mypctools
# v0.4.0

MYPCTOOLS_ROOT="$(cd "$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")" && pwd)"
source "$MYPCTOOLS_ROOT/lib/helpers.sh"
source "$MYPCTOOLS_ROOT/lib/theme.sh"
source "$MYPCTOOLS_ROOT/lib/distro-detect.sh"

VERSION="0.4.6"
UPDATE_AVAILABLE=""

LOGO='                              _              _
 _ __ ___  _   _ _ __   ___  | |_ ___   ___ | |___
| `_ ` _ \| | | | `_ \ / __| | __/ _ \ / _ \| / __|
| | | | | | |_| | |_) | (__  | || (_) | (_) | \__ \
|_| |_| |_|\__, | .__/ \___|  \__\___/ \___/|_|___/
           |___/|_|                                '

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

# Silent version check (runs in background)
check_for_updates() {
    if [[ -d "$MYPCTOOLS_ROOT/.git" ]]; then
        if timeout 3 git -C "$MYPCTOOLS_ROOT" fetch origin main &>/dev/null; then
            local behind
            behind=$(git -C "$MYPCTOOLS_ROOT" rev-list HEAD..origin/main --count 2>/dev/null)
            [[ "$behind" -gt 0 ]] && UPDATE_AVAILABLE="$behind"
        fi
    fi
}

# ASCII logo with version
show_logo() {
    sleep 0.5  # Wait for background update check
    gum style --foreground "$THEME_PRIMARY" --align center "$LOGO"
    local version_line="v$VERSION"
    if [[ -n "$UPDATE_AVAILABLE" ]]; then
        version_line="v$VERSION  •  ⬆ Update available ($UPDATE_AVAILABLE new)"
    fi
    gum style --foreground "$THEME_MUTED" --align center "$version_line"
    local sys_line="$DISTRO_NAME · $(uname -r) · $(basename "$SHELL")"
    gum style --foreground "$THEME_MUTED" --align center "$sys_line"
    echo
}

# Start background update check
check_for_updates &

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
            "Claude Setup" \
            "Spicetify Theme" \
            "LiteBash" \
            "LiteZsh" \
            "Terminal - foot" \
            "Back")

        case "$choice" in
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
            "Spicetify Theme")
                while true; do
                    clear
                    show_subheader "Spicetify Theme"
                    local action
                    action=$(themed_choose "" \
                        "Install" \
                        "Uninstall" \
                        "Back")

                    case "$action" in
                        "Install")
                            if [[ -f "$MYPCTOOLS_ROOT/scripts/spicetify/install.sh" ]]; then
                                bash "$MYPCTOOLS_ROOT/scripts/spicetify/install.sh"
                            else
                                print_warning "Install script not found."
                            fi
                            read -rp "Press Enter to continue..."
                            ;;
                        "Uninstall")
                            if [[ -f "$MYPCTOOLS_ROOT/scripts/spicetify/uninstall.sh" ]]; then
                                bash "$MYPCTOOLS_ROOT/scripts/spicetify/uninstall.sh"
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
            "LiteBash")
                while true; do
                    clear
                    show_subheader "LiteBash"
                    local action
                    action=$(themed_choose "" \
                        "Install" \
                        "Uninstall" \
                        "Back")

                    case "$action" in
                        "Install")
                            if [[ -f "$MYPCTOOLS_ROOT/scripts/litebash/install.sh" ]]; then
                                bash "$MYPCTOOLS_ROOT/scripts/litebash/install.sh"
                            else
                                print_warning "Install script not found."
                            fi
                            read -rp "Press Enter to continue..."
                            ;;
                        "Uninstall")
                            if [[ -f "$MYPCTOOLS_ROOT/scripts/litebash/uninstall.sh" ]]; then
                                bash "$MYPCTOOLS_ROOT/scripts/litebash/uninstall.sh"
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
            "LiteZsh")
                while true; do
                    clear
                    show_subheader "LiteZsh"
                    local action
                    action=$(themed_choose "" \
                        "Install" \
                        "Uninstall" \
                        "Back")

                    case "$action" in
                        "Install")
                            if [[ -f "$MYPCTOOLS_ROOT/scripts/litezsh/install.sh" ]]; then
                                bash "$MYPCTOOLS_ROOT/scripts/litezsh/install.sh"
                            else
                                print_warning "Install script not found."
                            fi
                            read -rp "Press Enter to continue..."
                            ;;
                        "Uninstall")
                            if [[ -f "$MYPCTOOLS_ROOT/scripts/litezsh/uninstall.sh" ]]; then
                                bash "$MYPCTOOLS_ROOT/scripts/litezsh/uninstall.sh"
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
            "Terminal - foot")
                while true; do
                    clear
                    show_subheader "Terminal - foot (Wayland)"
                    local action
                    action=$(themed_choose "" \
                        "Install" \
                        "Uninstall" \
                        "Back")

                    case "$action" in
                        "Install")
                            if [[ -f "$MYPCTOOLS_ROOT/scripts/terminal/install.sh" ]]; then
                                bash "$MYPCTOOLS_ROOT/scripts/terminal/install.sh"
                            else
                                print_warning "Install script not found."
                            fi
                            read -rp "Press Enter to continue..."
                            ;;
                        "Uninstall")
                            if [[ -f "$MYPCTOOLS_ROOT/scripts/terminal/uninstall.sh" ]]; then
                                bash "$MYPCTOOLS_ROOT/scripts/terminal/uninstall.sh"
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
            "Full System Update" \
            "System Cleanup" \
            "Service Manager" \
            "System Info" \
            "Back")

        case "$choice" in
            "Full System Update")
                ensure_sudo || continue
                case "$DISTRO_TYPE" in
                    debian) sudo apt update && sudo apt upgrade -y ;;
                    arch)   sudo pacman -Syu --noconfirm ;;
                    fedora) sudo dnf upgrade -y ;;
                    *)      print_error "Unsupported distro type: $DISTRO_TYPE" ;;
                esac
                echo ""
                read -rp "Press Enter to continue..."
                clear
                ;;
            "System Cleanup")
                ensure_sudo || continue
                case "$DISTRO_TYPE" in
                    debian)
                        sudo apt autoremove -y
                        sudo apt autoclean
                        sudo apt clean
                        ;;
                    arch)
                        orphans=$(pacman -Qtdq 2>/dev/null)
                        if [[ -n "$orphans" ]]; then
                            echo "$orphans"
                            if gum confirm "Remove these orphan packages?"; then
                                echo "$orphans" | sudo pacman -Rns --noconfirm -
                            fi
                        fi
                        if command_exists paccache; then
                            sudo paccache -rk2 < /dev/null
                        else
                            sudo pacman -Sc --noconfirm < /dev/null
                        fi
                        ;;
                    fedora)
                        sudo dnf autoremove -y
                        sudo dnf clean all
                        ;;
                    *)
                        print_error "Unsupported distro type: $DISTRO_TYPE"
                        ;;
                esac
                # User caches (all distros)
                rm -rf "$HOME/.cache/thumbnails"/* 2>/dev/null
                rm -rf "$HOME/.local/share/Trash"/* 2>/dev/null
                print_success "Cleanup complete"
                read -rp "Press Enter to continue..."
                clear
                ;;
            "Service Manager")
                source "$MYPCTOOLS_ROOT/apps/service-manager.sh"
                show_service_manager
                ;;
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
            "Back"|"")
                break
                ;;
        esac
    done
}

# Main menu
main_menu() {
    while true; do
        clear
        show_logo

        # Build menu options (add Pull Updates if available)
        local menu_options=("Install Apps" "My Scripts" "System Setup")
        if [[ -n "$UPDATE_AVAILABLE" ]]; then
            menu_options+=("⬆ Pull Updates")
        fi
        menu_options+=("Exit")

        local choice
        choice=$(themed_choose "" "${menu_options[@]}")

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
            "⬆ Pull Updates")
                clear
                show_subheader "Pull Updates"
                if git -C "$MYPCTOOLS_ROOT" pull origin main; then
                    print_success "Updated! Restart mypctools to use new version."
                else
                    print_error "Failed to pull updates"
                fi
                UPDATE_AVAILABLE=""
                read -rp "Press Enter to continue..."
                ;;
            "Exit"|"")
                print_success "Goodbye!"
                exit 0
                ;;
        esac
    done
}

# CLI flags
case "${1:-}" in
    --help|-h)
        echo "mypctools v$VERSION"
        echo "A personal TUI for managing scripts and apps"
        echo "Built with Gum by Charm"
        echo ""
        echo "Usage: mypctools [option]"
        echo ""
        echo "Options:"
        echo "  --help, -h       Show this help message"
        echo "  --version, -v    Show version number"
        echo ""
        echo "https://github.com/reisset/mypctools"
        exit 0
        ;;
    --version|-v)
        echo "mypctools v$VERSION"
        exit 0
        ;;
    "")
        ;;
    *)
        echo "Unknown option: $1"
        echo "Run 'mypctools --help' for usage."
        exit 1
        ;;
esac

# Run
main_menu
